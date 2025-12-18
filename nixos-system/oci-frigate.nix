{ 
  config,
  lib,
  pkgs, 
  configVars,
  ... 
}: 

let
  app = "frigate";
  hostData = configVars.hosts.${config.networking.hostName};
  storage = hostData.hardware.storageDrives.data;
in

{

  sops = {
    secrets = {
      frigateRtspUser = {};
      frigateRtspPasswd = {};
      #frigateMqttUser = {};
      #frigateMqttPasswd = {};
    };
    templates = {
      "${app}-env".content = ''
        FRIGATE_RTSP_USER=${config.sops.placeholder.frigateRtspUser}
        FRIGATE_RTSP_PASSWORD=${config.sops.placeholder.frigateRtspPasswd}
        NVIDIA_VISIBLE_DEVICES=all
        NVIDIA_DRIVER_CAPABILITIES=compute,utility,video
      '';
        #FRIGATE_MQTT_USER=${config.sops.placeholder.frigateMqttUser}
        #FRIGATE_MQTT_PASSWORD=${config.sops.placeholder.frigateMqttPasswd}
    };
  };

  environment = {
    systemPackages = with pkgs; [ ffmpeg-full ];
    etc."${app}.yml" = {
      text = ''
        logger:
          default: info
        
        database:
          path: /sqlite/frigate.db
        
        mqtt:
          enabled: false 
        #  enabled: true
        #  host: eclipse-mosquitto
        #  port: 1883
        #  topic_prefix: frigate
        #  client_id: frigate
        #  user: "{FRIGATE_MQTT_USER}"
        #  password: "{FRIGATE_MQTT_PASSWORD}"
        #  stats_interval: 300
        
        go2rtc:
          streams:
            front:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.132:554/s0
            front-detect:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.132:554/s2
            garage:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.131:554/s0
            garage-detect:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.131:554/s2
            gym:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.30:554/s0
            gym-detect:
              - rtsp://{FRIGATE_RTSP_USER}:{FRIGATE_RTSP_PASSWORD}@192.168.1.30:554/s2
          webrtc:
            candidates:
              - 192.168.1.2:8555
              - stun:8555
        
        cameras:
          front:
            enabled: true
            ffmpeg:
              inputs:
                - path: rtsp://127.0.0.1:8554/front
                  input_args: preset-rtsp-restream
                  roles:
                    - record
                - path: rtsp://127.0.0.1:8554/front-detect
                  input_args: preset-rtsp-restream
                  roles:
                    - detect
            detect:
              enabled: true
              width: 1024
              height: 576
              fps: 5
          garage:
            enabled: true
            ffmpeg:
              inputs:
                - path: rtsp://127.0.0.1:8554/garage
                  input_args: preset-rtsp-restream
                  roles:
                    - record
                - path: rtsp://127.0.0.1:8554/garage-detect
                  input_args: preset-rtsp-restream
                  roles:
                    - detect
            detect:
              enabled: true
              width: 1024
              height: 576
              fps: 5
          gym:
            enabled: true
            ffmpeg:
              inputs:
                - path: rtsp://127.0.0.1:8554/gym
                  input_args: preset-rtsp-restream
                  roles:
                    - record
                - path: rtsp://127.0.0.1:8554/gym-detect
                  input_args: preset-rtsp-restream
                  roles:
                    - detect
            detect:
              enabled: true
              width: 1024
              height: 576
              fps: 5
        
        ffmpeg: # global ffmpeg configuration for all cameras
          hwaccel_args: preset-nvidia-h264 # adds nvidia gpu hardware acceleration
          output_args: 
            record: preset-record-generic-audio-copy # adds audio to record streams
        
        birdseye: # global birdseye configuration for all cameras
          enabled: true
          restream: true # restream to http://192.168.1.2:8554/birdseye?
          mode: continuous
        
        motion: # global motion configuration for all cameras
          threshold: 25
          contour_area: 40
          delta_alpha: 0.2
          frame_alpha: 0.2
          frame_height: 50
          improve_contrast: false
        
        record: # global record configuration for all cameras
          enabled: true
          retain: # retain all clips containing any kind of motion for 3 days
            days: 3 
            mode: motion
          alerts: # retain all clips containing any kind of alert for 30 days 
            retain:
              days: 30
              mode: motion
          detections: # retain all clips containing any detection configured for 30 days
            retain:
              days: 30
              mode: motion
        
        detectors: # global detector configuration for all cameras
          #opticon-cpu:
          #  type: cpu
          #  num_threads: 3
          opticon-tpu:
            type: edgetpu
            device: pci
        
        snapshots: # global snapshot configuration for all cameras, requires object detection turned on
          enabled: true
          clean_copy: true
          timestamp: true
          bounding_box: true
          crop: false
          retain:
            default: 3
            objects:
              person: 30
      '';
      mode = "0755";
    };
  };

  hardware.coral.pcie.enable = true;

  virtualisation.oci-containers.containers = {

    "${app}" = {
      image = "ghcr.io/blakeblackshear/${app}:0.15.0"; # https://github.com/blakeblackshear/frigate/releases
      autoStart = true;
      environmentFiles = [ 
        config.sops.templates."${app}-env".path 
      ];
      log-driver = "journald";
      ports = [
        #"5000:5000/tcp" # main web view port
        "${configVars.hosts."${config.networking.hostName}".networking.ipv4}:8554:8554/tcp" # RTSP feeds
        "${configVars.hosts."${config.networking.hostName}".networking.ipv4}:8555:8555/tcp" # WebRTC over tcp
        "${configVars.hosts."${config.networking.hostName}".networking.ipv4}:8555:8555/udp" # WebRTC over udp
      ];
      volumes = [ 
        "/etc/localtime:/etc/localtime:ro" 
        "/etc/${app}.yml:/config/config.yml:ro"
        "${storage.mountPoint}/media/security-cameras:/media/frigate"
        "${app}:/sqlite"
      ]; 
      extraOptions = [
        "--network=${app}"
        "--ip=${configVars.containerServices.${app}.containers.${app}.ipv4}"
        "--tty=true"
        "--stop-signal=SIGINT"
        "--privileged" # ensure container access to udev rules for Coral device
        "--device=nvidia.com/gpu=all" # enable GPU utilization
        #"--device=/dev/apex_0:/dev/apex_0" # enable PCIe Coral device utilization
        "--shm-size=512m"
      ];
      labels = {
        "traefik.enable" = "true";
        "traefik.http.routers.${app}.entrypoints" = "websecure";
        "traefik.http.routers.${app}.rule" = "Host(`${app}.${configVars.domain2}`)";
        "traefik.http.routers.${app}.tls" = "true";
        "traefik.http.routers.${app}.tls.options" = "tls-13@file";
        "traefik.http.routers.${app}.middlewares" = "trusted-allow@file,secure-headers@file";
        "traefik.http.services.${app}.loadbalancer.server.port" = "5000"; # port for web view
      };
    };

  };

  systemd = {
    services = { 
      "docker-${app}" = {
        serviceConfig = {
          Restart = lib.mkOverride 500 "always";
          RestartMaxDelaySec = lib.mkOverride 500 "1m";
          RestartSec = lib.mkOverride 500 "100ms";
          RestartSteps = lib.mkOverride 500 9;
        };
        after = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        requires = [
          "docker-network-${app}.service"
          "docker-volume-${app}.service"
        ];
        partOf = [
          "docker-${app}-root.target"
        ];
        wantedBy = [
          "docker-${app}-root.target"
        ];
      };
      "docker-network-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
          ExecStop = "${pkgs.docker}/bin/docker network rm -f ${app}";
        };
        script = ''
          docker network inspect ${app} || docker network create --subnet ${configVars.containerServices.${app}.subnet} --driver bridge --scope local --attachable ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
      "docker-volume-${app}" = {
        path = [pkgs.docker];
        serviceConfig = {
          Type = "oneshot";
          RemainAfterExit = true;
        };
        script = ''
          docker volume inspect ${app} || docker volume create ${app}
        '';
        partOf = ["docker-${app}-root.target"];
        wantedBy = ["docker-${app}-root.target"];
      };
    };
    targets."docker-${app}-root" = {
      unitConfig = {
        Description = "root target for docker-${app}";
      };
      wantedBy = ["multi-user.target"];
    };
  }; 

}