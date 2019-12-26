{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-beta = pkgs.callPackage ./shadow-beta.nix {
    enableDiagnostics = cfg.enableDiag;
  };
in
{
  imports = [ ./cfg.nix ];

  config = {
    home.packages = [ shadow-beta ];
  };
}
