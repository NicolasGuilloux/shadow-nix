{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client = {
    enable = mkEnableOption ''
      Enable the client to the Shadow Gaming Cloud Computer on NixOS
    '';

    channel = mkOption {
      type = types.enum [ "prod" "preprod" "testing" ];
      default = "prod";
      example = "preprod";
      description = ''
        Choose a channel for the Shadow application.
        `prod` is the stable channel, `preprod` is the beta channel. `testing` is the alpha channel.
      '';
    };

    extraChannels = mkOption {
      type = types.listOf (types.enum [ "prod" "preprod" "testing" ]);
      default = [];
      example = [ "preprod" "testing" ];
      description = ''
        Choose extra channels to install aside from the main channel
      '';
    };

    launchArgs = mkOption {
      type = types.str;
      default = "";
      example = "--report";
      description = ''
        Start the launcher with arguments by default
      '';
    };

    enableDesktopLauncher = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Provides the desktop file for launching Shadow from current session (only works with Xorg sessions).
      '';
    };

    enableDiagnostics = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        The command used to execute the client will be output in a file in /tmp.
        The client will output its strace in /tmp.
        This is mainly used for diagnostics purposes (when an update breaks something).
      '';
    };

    forceDriver = mkOption {
      type = types.nullOr (types.enum [ "iHD" "i965" "radeon" "radeonsi" ]);
      default = null;
      example = "iHD";
      description = ''
        Force the VA driver used by Shadow using the LIBVA_DRIVER_NAME environment variable.
      '';
    };

    enableGpuFix = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Disable the GPU fixes for Shadow related to the color bit size.
      '';
    };
  };
}
