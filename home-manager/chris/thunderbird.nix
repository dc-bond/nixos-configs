{
  configVars,
  ...
}:

# GUI mail + CalDAV/CardDAV. imports email.nix for the underlying account and
# only adds thunderbird-specific overlays: profile, prefs, HTML signature,
# per-identity yubikey-backed openpgp settings, and nextcloud dav accounts.

let
  # HTML signature rendered inline on every outgoing mail. Kept here (not read from
  # a file) so the whole thunderbird identity is a single declarative artifact.
  htmlSignature = ''
    <div style="font-family: -apple-system, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif; color: #1f2937; font-size: 14px; line-height: 1.4;">
      <span style="display: inline-block; padding-right: 14px; border-right: 3px solid #2563eb; vertical-align: middle;">
        <span style="font-size: 20px; font-weight: 600; letter-spacing: -0.01em; color: #0f172a;">Chris Bond</span>
      </span>
      <span style="display: inline-block; padding-left: 11px; vertical-align: middle;">
        <span style="display: block;">
          <a href="mailto:chris@dcbond.com" style="color: #2563eb; text-decoration: none;">chris@dcbond.com</a>
        </span>
        <span style="display: block; color: #64748b; font-size: 12px; margin-top: 2px;">dcbond.com</span>
      </span>
    </div>
  '';

  nextcloudDav = "https://nextcloud.${configVars.domain1}/remote.php/dav";
  # nextcloud DAV principal path segment is the user's login name, URL-encoded.
  # for chris that's the fullName ("Chris Bond") -- verified via `nextcloud-occ dav:list-calendars`.
  # do NOT use the email address here; it authenticates but the collection URIs are keyed by principal.
  nextcloudPrincipal = builtins.replaceStrings [ " " ] [ "%20" ] configVars.users.chris.fullName;
in

{

  imports = [ ./email.nix ];

  programs.thunderbird = {
    enable = true;
    profiles.chris = {
      isDefault = true;
      # delegate all openpgp ops to system gpg-agent → scdaemon → yubikey. TB's
      # builtin RNP backend can't talk to smartcards; without this the yubikey
      # is invisible to the client.
      withExternalGnupg = true;
      settings = {
        # openpgp: prefer the system gpg keyring for correspondent pubkeys so
        # anything gpg trusts is available to TB without a separate import
        "mail.openpgp.fetch_pubkeys_from_gnupg" = true;
        # telemetry off
        "datareporting.healthreport.uploadEnabled" = false;
        "datareporting.policy.dataSubmissionEnabled" = false;
        "toolkit.telemetry.enabled" = false;
        "toolkit.telemetry.unified" = false;
        # ui / compose defaults
        "mailnews.start_page.enabled" = false;
        "mail.spellcheck.inline" = true;
        "mail.compose.default_to_paragraph" = true;
        "mail.identity.default.compose_html" = true;
        "mail.accounthub.enabled" = false;
        # threaded, newest-first
        "mailnews.default_sort_order" = 2;
        "mailnews.default_sort_type" = 18;
        "mailnews.default_view_flags" = 1;
        # calendar
        "calendar.timezone.useSystemTimezone" = true;
        "calendar.timezone.local" = "America/New_York";
        "calendar.week.start" = 0;
        # tag palette
        "mailnews.tags.$label1.tag" = "Important";
        "mailnews.tags.$label1.color" = "#FF0000";
        "mailnews.tags.$label2.tag" = "Work";
        "mailnews.tags.$label2.color" = "#FF9900";
        "mailnews.tags.$label3.tag" = "Personal";
        "mailnews.tags.$label3.color" = "#009900";
        "mailnews.tags.$label4.tag" = "To Do";
        "mailnews.tags.$label4.color" = "#3333FF";
        "mailnews.tags.$label5.tag" = "Later";
        "mailnews.tags.$label5.color" = "#993399";
      };
    };
  };

  accounts.email.accounts.privateemail.thunderbird = {
    enable = true;
    profiles = [ "chris" ];
    # runs per identity so we can key the prefs by the generated identity id
    perIdentitySettings = id: {
      "mail.identity.${id}.htmlSigFormat" = true;
      "mail.identity.${id}.htmlSigText" = htmlSignature;
      "mail.identity.${id}.sig_bottom" = false;
      "mail.identity.${id}.sig_on_fwd" = true;
      "mail.identity.${id}.reply_on_top" = 1;
      # openpgp posture (private key lives on yubikey; TB delegates via gpgme):
      # bind identity to the master fingerprint, prefer openpgp over s/mime,
      # autocrypt for gradual adoption, protected headers when encrypting,
      # opportunistic policy (never refuse to send unencrypted).
      "mail.identity.${id}.is_gnupg_key_id" = true;
      "mail.identity.${id}.openpgp_key_id" = "0x${configVars.users.chris.gpgKeyFingerprint}";
      "mail.identity.${id}.attachPgpKey" = false;
      "mail.identity.${id}.sign_mail" = false;
      "mail.identity.${id}.encryptionpolicy" = 0;
      "mail.identity.${id}.e2etechpref" = 0;
      "mail.identity.${id}.autoEncryptDrafts" = true;
      "mail.identity.${id}.protectSubject" = true;
      "mail.identity.${id}.sendAutocryptHeaders" = true;
    };
  };

  # TB registers one calendar per accounts.calendar entry from a specific
  # collection URL, not the home-collection. add more entries here to expose
  # other Nextcloud calendars in TB; get UUIDs from `nextcloud-occ dav:list-calendars "Chris Bond"` on aspen.
  accounts.calendar.accounts."Chris Personal" = {
    primary = true;
    remote = {
      type = "caldav";
      url = "${nextcloudDav}/calendars/${nextcloudPrincipal}/1ABA8967-F750-4631-AF2F-038CD16D74A7/";
      userName = configVars.users.chris.email;
    };
    thunderbird = {
      enable = true;
      profiles = [ "chris" ];
    };
  };

  accounts.contact.accounts."Chris Contacts" = {
    remote = {
      type = "carddav";
      url = "${nextcloudDav}/addressbooks/users/${nextcloudPrincipal}/contacts/";
      userName = configVars.users.chris.email;
    };
    thunderbird = {
      enable = true;
      profiles = [ "chris" ];
    };
  };

}
