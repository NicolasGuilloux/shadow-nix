{ config, pkgs, lib, ... }:

let
  # Client configuration
  cfg = config.programs.shadow-client;

  # A set of utilities
  utilities = import ../utilities { inherit lib pkgs; };

  # Declare the package with the appropriate configuration
  shadow-package = channel: pkgs.callPackage ../default.nix {
    shadowChannel = channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Drirc file
  drirc = utilities.files.drirc;
in {
  # Import the configuration
  imports = [ ../config.nix ];

  # By default, if you import this file, the Shadow app will be installed
  programs.shadow-client.enable = lib.mkDefault true;

  # Enables
  home = lib.mkIf cfg.enable {
    # Install Shadow wrapper
    packages = with pkgs; [ 
      (shadow-package cfg.channel)
      libva-utils 
      libva 
    ] ++ lib.forEach cfg.extraChannels shadow-package;


    # Add GPU fixes
    file.".drirc".source = lib.mkIf (cfg.enableGpuFix) drirc;

    # Force VA Driver
    sessionVariables.LIBVA_DRIVER_NAME = cfg.forceDriver;
  };
}
