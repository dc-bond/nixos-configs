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
  # the two trailing divs are deliberate: with sig_bottom=false TB drops the sig
  # straight onto the quoted reply block with no separation. first is a rule to
  # visually close the block, second a blank line. both carry &nbsp; because an
  # empty <div>/<br> collapses to zero height and renders nothing; font-size/
  # line-height 0 on the rule keeps its nbsp from adding a stray text line.
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
    <div style="border-top: 1px solid #e2e8f0; max-width: 320px; margin-top: 10px; font-size: 0; line-height: 0;">&nbsp;</div>
    <div style="line-height: 1.4;">&nbsp;</div>
  '';

  nextcloudDav = "https://nextcloud.${configVars.domain1}/remote.php/dav";
  # nextcloud DAV principal path segment is the user's login name, URL-encoded.
  # for chris that's the fullName ("Chris Bond") -- verified via `nextcloud-occ dav:list-calendars`.
  # do NOT use the email address here; it authenticates but the collection URIs are keyed by principal.
  nextcloudPrincipal = builtins.replaceStrings [ " " ] [ "%20" ] configVars.users.chris.fullName;

  # base IMAP URL for special-folder identity prefs (TB ignores accounts.email
  # `folders`, so Sent/Drafts must be pinned per-identity). host matches email.nix.
  imapUrl = "imap://${builtins.replaceStrings [ "@" ] [ "%40" ] configVars.users.chris.email}@${configVars.mailservers.namecheap.smtpHost}";
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
        # appearance
        "mail.appearance.accentColor" = "teal";
        "mail.citation_color" = "#26a269";
        "mail.threadpane.listview" = 1; # table layout, not cards
        # confirmation prompts already dismissed in the UI
        "mailnews.emptyTrash.dontAskAgain" = true;
        "mail.prompt_purge_threshold" = false;
        "mail.close_message_window.on_delete" = true;
        "calendar.item.promptDelete" = false;
        "mail.shell.checkDefaultClient" = false;
        # compose
        "mail.collect_email_address_outgoing" = false; # never auto-fill Collected Addresses
        "mail.compose.autosaveinterval" = 2;
        "mail.compose.big_attachments.notify" = false;
        # privacy / security
        "mailnews.message_display.disable_remote_image" = true; # block remote images (tracking pixels)
        "mail.phishing.detection.enabled" = false;
        "network.trr.mode" = 5; # DoH off, use system resolver
      };
    };
  };

  accounts.email.accounts.privateemail.thunderbird = {
    enable = true;
    profiles = [ "chris" ];
    # nixpkgs hm thunderbird module keys identity prefs as `mail.identity.id_<hash>.*`
    # (see the option's example in nixpkgs). perIdentitySettings must reuse the
    # `id_` prefix or the overrides land on dead pref names TB never reads.
    #
    # openpgp posture is not repeated here: the hm module already writes
    # is_gnupg_key_id, openpgp_key_id, attachPgpKey=false, autoEncryptDrafts=true,
    # protectSubject=true, e2etechpref=0, encryptionpolicy=0, sign_mail=false
    # from `identity.gpg.key` + signByDefault in email.nix. autocrypt headers
    # advertise the pubkey to PGP-aware correspondents without visible noise.
    perIdentitySettings = id: {
      "mail.identity.id_${id}.htmlSigFormat" = true;
      "mail.identity.id_${id}.htmlSigText" = htmlSignature;
      "mail.identity.id_${id}.sig_bottom" = false;
      "mail.identity.id_${id}.sig_on_fwd" = true;
      "mail.identity.id_${id}.reply_on_top" = 1;
      "mail.identity.id_${id}.sendAutocryptHeaders" = true;
      # pin server special folders instead of relying on TB auto-detect
      "mail.identity.id_${id}.fcc_folder" = "${imapUrl}/Sent";
      "mail.identity.id_${id}.fcc_folder_picker_mode" = "1";
      "mail.identity.id_${id}.draft_folder" = "${imapUrl}/Drafts";
      "mail.identity.id_${id}.drafts_folder_picker_mode" = "1";
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
      color = "#26a269";
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

  # Nextcloud's auto-generated system address book (one read-only card per user
  # account); synced for autocomplete since these never land in the personal book.
  accounts.contact.accounts."Company Directory" = {
    remote = {
      type = "carddav";
      url = "${nextcloudDav}/addressbooks/system/system/system/";
      userName = configVars.users.chris.email;
    };
    thunderbird = {
      enable = true;
      profiles = [ "chris" ];
    };
  };

}
