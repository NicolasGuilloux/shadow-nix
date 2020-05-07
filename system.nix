{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ./shadow-package.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Declare the wrapper with the appropriate configuration
  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    preferredScreens = cfg.preferredScreens;
    xsessionDesktopFile = cfg.provideXSession;
    launchArgs = cfg.launchArgs;
  };

  # Drirc file
  drirc = (fetchGit {
    url = "https://github.com/NicolasGuilloux/blade-shadow-beta";
    ref = "master";
  } + "/resources/drirc");
in {
  # Import the configuration
  imports = [ ./cfg.nix ];

  config = mkIf cfg.enable {
    # Install Shadow wrapper
    environment.systemPackages = [ shadow-wrapped ];

    # Add Shadow session
    services.xserver.displayManager.sessionPackages = mkIf cfg.provideXSession [ shadow-wrapped ];

    # Add GPU fixes
    environment.etc."drirc" = mkIf (!cfg.disableGpuFix) { 
      source = drirc; 
    };

    # Force VA Driver
    environment.variables = mkIf (cfg.forceDriver != "") {
      LIBVA_DRIVER_NAME = [cfg.forceDriver];
    };
  };
}
