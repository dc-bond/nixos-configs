{
  config,
  configVars,
  ...
}:

# client-agnostic email account definition. any home-manager email client
# (thunderbird, neomutt, msmtp, mbsync, etc.) opts into this account by setting
# `accounts.email.accounts.privateemail.<client>.enable = true` in its own module.

{

  accounts.email = {
    maildirBasePath = "${config.home.homeDirectory}/email";
    accounts.privateemail = {
      primary = true;
      address = configVars.users.chris.email;
      userName = configVars.users.chris.email;
      realName = configVars.users.chris.fullName;
      passwordCommand = "pass email/${configVars.users.chris.email}"; # used by msmtp/mbsync; thunderbird stores creds in its own nss db
      imap = {
        host = configVars.mailservers.namecheap.smtpHost;
        port = configVars.mailservers.namecheap.imapPort;
        tls.enable = true; # implicit TLS on 993
      };
      smtp = {
        host = configVars.mailservers.namecheap.smtpHost;
        port = configVars.mailservers.namecheap.smtpPort;
        tls.useStartTls = true; # STARTTLS on 587
      };
      signature = {
        showSignature = "append";
        delimiter = "-- ";
        text = ''
          Chris Bond
          chris@${configVars.domain1}
        '';
      };
      gpg = {
        key = configVars.users.chris.gpgKeyFingerprint;
        # signByDefault intentionally omitted: signing every unencrypted
        # outbound message leaks metadata and adds noise for non-PGP recipients.
        # clients that want auto-sign should set it in their own module.
      };
    };
  };

}
