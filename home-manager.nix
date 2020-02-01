{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-package = pkgs.callPackage ./shadow-package.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
  };

  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    preferredScreens = cfg.preferredScreens;
    xsessionDesktopFile = cfg.provideXSession;
    desktopLauncher = cfg.enableDesktopLauncher;
    launchArgs = cfg.launchArgs;
  };
in
{
  imports = [ ./cfg.nix ];

  config = {
    home.packages = [ shadow-wrapped ];
  };
}
