{ lib, pkgs, ... }:

/* Helper to interact with the Shadow API

   Import example:
   let
     inherit (import ./utilities/shadow-api.nix { inherit lib; }) getLatestInfo;

     ...
   in
*/
rec {
  /* Return the latest version information for the given channel

     Example:
       getLatestInfo "preprod"
       => { channel = "preprod"; version = "3.1.6"; sha512 = "..."; path = "..."; }
  */
  getLatestInfo = channel: 
    let
        yamlInfo = builtins.fetchurl "https://storage.googleapis.com/shadow-update/launcher/${channel}/linux/ubuntu_18.04/latest-linux.yml";
        jsonInfo = (pkgs.runCommand "transform" { buildInputs = with pkgs; [ yq jq ]; } "cat ${yamlInfo} | yq -j . > $out");
        info = builtins.fromJSON (builtins.readFile jsonInfo);
    in
    { 
        channel = channel;
        version = info.version;
        sha512 = info.sha512;
        path = info.path;
    };
  
  /* Return the file information to give to fetchurl
     
     Example:
       getDownloadInfo info
       => { url = "..."; hash = "sha512-..."; }
  */
  getDownloadInfo = info: { 
      url = "https://update.shadow.tech/launcher/${info.channel}/linux/ubuntu_18.04/${info.path}";
      hash = "sha512-${info.sha512}"; 
  };
}