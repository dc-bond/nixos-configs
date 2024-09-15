{ 
  self, 
  config, 
  pkgs, 
  lib, 
  ... 
}:

let
	inherit (lib) mkForce;
in 

{

	programs.firefox = {
    enable = true;
		package = pkgs.firefox;
		policies = {
			ExtensionSettings = {
				"*" = {
					installation_mode = "blocked";
					blocked_install_message = "NOPE";
				};
			"3rdparty".Extensions = {
				"uBlock0@raymondhill.net".adminSettings = {
					userSettings = rec {
						uiTheme = "dark";
						uiAccentCustom = true;
						uiAccentCustom0 = "#8300ff";
						cloudStorageEnabled = mkForce false; # Security liability?
						importedLists = [
							"https://filters.adtidy.org/extension/ublock/filters/3.txt"
							"https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
						];
						externalLists = lib.concatStringsSep "\n" importedLists;
					};
					selectedFilterLists = [
						"CZE-0"
						"adguard-generic"
						"adguard-annoyance"
						"adguard-social"
						"adguard-spyware-url"
						"easylist"
						"easyprivacy"
						"https://github.com/DandelionSprout/adfilt/raw/master/LegitimateURLShortener.txt"
						"plowe-0"
						"ublock-abuse"
						"ublock-badware"
						"ublock-filters"
						"ublock-privacy"
						"ublock-quick-fixes"
						"ublock-unbreak"
						"urlhaus-1"
					];
				};
			};