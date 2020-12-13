{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ./default.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Declare the wrapper with the appropriate configuration
  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    provideSession = cfg.provideXSession || cfg.provideSystemdSession.enable;
    launchArgs = cfg.launchArgs;

    menuOverride = cfg.customSessionMenu;
    customStartScript = cfg.customSessionStartScript;
  };

  # Drirc file
  drirc = (fetchGit {
    url = "https://github.com/NicolasGuilloux/blade-shadow-beta";
    ref = "master";
  } + "/resources/drirc");
in {
  # Import the configuration
  imports = [ ./config.nix ./systemd-session ./x-session];

  config = mkIf cfg.enable {
    # Install Shadow wrapper
    environment.systemPackages = mkIf cfg.enableDesktopLauncher [ shadow-wrapped ];

    # Add Shadow session
    services.xserver.displayManager.sessionPackages =
      mkIf cfg.provideXSession [ shadow-wrapped ];

    # Add GPU fixes
    environment.etc."drirc" = mkIf (!cfg.disableGpuFix) { source = drirc; };

    # Force VA Driver
    environment.variables =
      mkIf (cfg.forceDriver != "") { LIBVA_DRIVER_NAME = [ cfg.forceDriver ]; };
  };
}
