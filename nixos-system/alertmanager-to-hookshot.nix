{
  pkgs,
  config,
  lib,
  ...
}:

let
  # Simple Python service that transforms Alertmanager webhooks to Matrix Hookshot format
  transformerScript = pkgs.writeText "alertmanager-transformer.py" ''
    #!/usr/bin/env python3
    from http.server import BaseHTTPRequestHandler, HTTPServer
    import json
    import os
    import urllib.request
    import urllib.error

    HOOKSHOT_URL = os.environ.get('HOOKSHOT_URL', '')
    PORT = int(os.environ.get('PORT', '9099'))

    def format_alert(alert):
        severity = alert.get('labels', {}).get('severity', 'unknown')
        alertname = alert.get('labels', {}).get('alertname', 'Unknown Alert')
        instance = alert.get('labels', {}).get('instance') or alert.get('labels', {}).get('host', 'unknown')
        description = alert.get('annotations', {}).get('description') or alert.get('annotations', {}).get('summary', 'No description')

        emoji = '🔴' if severity == 'critical' else '⚠️'
        return f"{emoji} **{alertname}** ({severity})\\n📍 {instance}\\n{description}"

    class AlertmanagerHandler(BaseHTTPRequestHandler):
        def log_message(self, format, *args):
            # Log to stdout for journald
            print(f"{self.address_string()} - {format % args}")

        def do_POST(self):
            try:
                content_length = int(self.headers['Content-Length'])
                body = self.rfile.read(content_length)
                data = json.loads(body.decode('utf-8'))

                # Transform Alertmanager payload to Hookshot format
                status = '🔴 **FIRING**' if data.get('status') == 'firing' else '✅ **RESOLVED**'
                alert_count = len(data.get('alerts', []))

                alerts = [format_alert(alert) for alert in data.get('alerts', [])]
                alerts_text = '\\n\\n---\\n\\n'.join(alerts)

                message = f"{status} - {alert_count} alert(s)\\n\\n{alerts_text}"

                # Send to Hookshot
                hookshot_payload = json.dumps({'text': message}).encode('utf-8')
                req = urllib.request.Request(
                    HOOKSHOT_URL,
                    data=hookshot_payload,
                    headers={'Content-Type': 'application/json'}
                )

                with urllib.request.urlopen(req, timeout=10) as response:
                    self.send_response(response.status)
                    self.end_headers()
                    self.wfile.write(response.read())

            except Exception as e:
                print(f"Error processing webhook: {e}")
                self.send_response(500)
                self.end_headers()
                self.wfile.write(f"Error: {str(e)}".encode('utf-8'))

    if __name__ == '__main__':
        if not HOOKSHOT_URL:
            print("ERROR: HOOKSHOT_URL environment variable not set")
            exit(1)

        server = HTTPServer(('127.0.0.1', PORT), AlertmanagerHandler)
        print(f"Alertmanager to Hookshot transformer listening on 127.0.0.1:{PORT}")
        print(f"Forwarding to: {HOOKSHOT_URL}")
        server.serve_forever()
  '';

in

{
  sops.secrets.chrisNotificationsWebhookUrl = {};

  sops.templates."alertmanager-hookshot-env".content = ''
    HOOKSHOT_URL=${config.sops.placeholder.chrisNotificationsWebhookUrl}
  '';

  systemd.services.alertmanager-to-hookshot = {
    description = "Alertmanager to Matrix Hookshot Transformer";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];

    serviceConfig = {
      Type = "simple";
      ExecStart = "${pkgs.python3}/bin/python3 ${transformerScript}";
      Restart = "on-failure";
      RestartSec = "10s";

      # Load the Hookshot webhook URL from secret
      EnvironmentFile = config.sops.templates."alertmanager-hookshot-env".path;
      Environment = [ "PORT=9099" ];

      # Security hardening
      DynamicUser = true;
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectSystem = "strict";
      ProtectHome = true;
      ProtectKernelTunels = true;
      ProtectKernelModules = true;
      ProtectControlGroups = true;
      RestrictAddressFamilies = [ "AF_INET" "AF_INET6" ];
      RestrictNamespaces = true;
      LockPersonality = true;
      MemoryDenyWriteExecute = true;
      RestrictRealtime = true;
      RestrictSUIDSGID = true;
      PrivateMounts = true;
    };
  };
}
