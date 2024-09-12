{ 
  config, 
  pkgs, 
  ... 
}: 

{

  programs.firefox = {
    enable = true;
		policies = {
			AppAutoUpdate = false;
			BackgroundAppUpdate = false; 
			DisableBuiltinPDFViewer = false; # enabling potential security liability?
			DisableFirefoxStudies = true;
			DisableFirefoxAccounts = true; # firefox sync
			#DisableFirefoxScreenshots = true; # No screenshots?
			#DisableForgetButton = true; # Thing that can wipe history for X time, handled differently
			#DisableMasterPasswordCreation = true; # to be determined how to handle master password
			DisableProfileImport = true; # only allow nix-defined profiles
			DisableProfileRefresh = true; # disable the Refresh Firefox button on about:support and support.mozilla.org
			DisableSetDesktopBackground = true; # remove the “Set As Desktop Background…” menuitem when right clicking on an image to avoid potential conflict with declarative nix configs
			DisplayMenuBar = "default-off";
			DisablePocket = true;
			DisableTelemetry = true;
			DisableFormHistory = true;
			DisablePasswordReveal = true;
			DontCheckDefaultBrowser = true;
			HardwareAcceleration = true; # enabling exposes points for fingerprinting?
			OfferToSaveLogins = false;
			EnableTrackingProtection = {
				Value = true;
				Locked = true;
				Cryptomining = true;
				Fingerprinting = true;
				EmailTracking = true;
				# Exceptions = ["https://example.com"]
			};
			EncryptedMediaExtensions = {
				Enabled = true;
				Locked = true;
			};
			#ExtensionUpdate = false;
			FirefoxHome = {
				Search = true;
				TopSites = false;
				SponsoredTopSites = false;
				Highlights = false;
				Pocket = false;
				SponsoredPocket = false;
				Snippets = false;
				Locked = true;
			};
			FirefoxSuggest = {
				WebSuggestions = false;
				SponsoredSuggestions = false;
				ImproveSuggest = false;
				Locked = true;
			};
			#Handlers = {
			#	# FIXME-QA(Krey): Should be openned in evince if on GNOME
			#	mimeTypes."application/pdf".action = "saveToDisk";
			#};
			#extensions = {
			#	pdf = {
			#		action = "useHelperApp";
			#		ask = true;
			#		# FIXME-QA(Krey): Should only happen on GNOME
			#		handlers = [
			#			{
			#				name = "GNOME Document Viewer";
			#				path = "${pkgs.evince}/bin/evince";
			#			}
			#		];
			#	};
			#};
			NoDefaultBookmarks = true;
			PasswordManagerEnabled = false; # managed by bitwarden
			PDFjs = {
				Enabled = false; # security liability
				EnablePermissions = false;
			};
			 Permissions = {
			 	Camera = {
			 		#Allow = [https =//example.org,https =//example.org =1234];
			 		#Block = [https =//example.edu];
			 		BlockNewRequests = true;
			 		Locked = true;
			 	};
			 	Microphone = {
			 		#Allow = [https =//example.org];
			 		#Block = [https =//example.edu];
			 		BlockNewRequests = true;
			 		Locked = true;
			 	};
			 	Location = {
			 		#Allow = [https =//example.org];
			 		#Block = [https =//example.edu];
			 		BlockNewRequests = true;
			 		Locked = true;
			 	};
			 	Notifications = {
			 		#Allow = [https =//example.org];
			 		#Block = [https =//example.edu];
			 		BlockNewRequests = true;
			 		Locked = true;
			 	};
			 	Autoplay = {
			 		#Allow = [https =//example.org];
			 		#Block = [https =//example.edu];
			 		#Default = allow-audio-video | block-audio | block-audio-video;
			 		Locked = true;
			 	};
			 };
      
    };
  };

}
