{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-beta = pkgs.callPackage ./shadow-beta.nix {
    desktopLauncher = cfg.enableDesktopLauncher;
    sessionCommand = cfg.provideSessionCommand;
    enableDiagnostics = cfg.enableDiagnostics;
    xsessionDesktopFile = cfg.provideXSession;
  };
in
{
  imports = [ ./cfg.nix ];

  config = {
    home.packages = [ shadow-beta ];
  };
}
