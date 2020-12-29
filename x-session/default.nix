{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;
  provideSession = cfg.x-session.enable || cfg.systemd-session.enable;

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ../default.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Declare the wrapper with the appropriate configuration
  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    provideSession = provideSession;
    launchArgs = cfg.launchArgs;

    menuOverride = cfg.x-session.additionalMenuEntries;
    customStartScript = cfg.x-session.startScript;
  };
in {
  imports = [ ./config.nix ];

}
