{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-package = pkgs.callPackage ./shadow-package.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    xsessionDesktopFile = cfg.provideXSession;
    launchArgs = cfg.launchArgs;

    menuOverride = cfg.customSessionMenu;
    customStartScript = cfg.customSessionStartScript;
  };
in {
  imports = [ ./cfg.nix ];

  config = mkIf cfg.enable { home.packages = [ shadow-wrapped ]; };
}
