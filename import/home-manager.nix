{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;
  utilities = import ../utilities { inherit lib pkgs; };

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ../default.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Drirc file
  drirc = utilities.files.drirc;
in {
  # Import the configuration
  imports = [ ../config.nix ];

  # By default, if you import this file, the Shadow app will be installed
  programs.shadow-client.enable = mkDefault true;

  # Enables
  home = mkIf cfg.enable {
    # Install Shadow wrapper
    packages = with pkgs; [ shadow-package libva-utils libva ];

    # Add GPU fixes
    file.".drirc".source = mkIf (cfg.enableGpuFix) drirc;

    # Force VA Driver
    sessionVariables.LIBVA_DRIVER_NAME = mkIf (cfg.forceDriver != "") [ cfg.forceDriver ];
  };
}
