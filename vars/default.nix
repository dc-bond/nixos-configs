{ 
  inputs, 
  lib 
}:

{

  username = "chris";
  userEmail = "chris@dcbond.com";
  domain1 = "dcbond.com";
  domain2 = "opticon.dev";
  domain3 = "professorbond.com";
  #userFullName = inputs.nix-secrets.full-name;
  #userEmail = inputs.nix-secrets.userEmail;
  #persistFolder = "/persist";
  #networking = import ./networking.nix { inherit lib; };

}