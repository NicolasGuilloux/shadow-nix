{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client = {
    enable = mkEnableOption ''
      Enable the client to the Shadow Gaming Cloud Computer on NixOS
    '';

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

    provideXSession = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Provides a XSession desktop file for Shadow Launcher.
        Useful if you want to autostart it without any DE/WM.
      '';
    };

    channel = mkOption {
      type = types.enum [ "prod" "preprod" "testing" ];
      default = "prod";
      example = "preprod";
      description = ''
        Choose a channel for the Shadow application.
        `prod` is the stable channel, `preprod` is the beta channel.
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

    forceDriver = mkOption {
      type = types.enum [ "" "iHD" "i965" "radeon" "radeonsi" ];
      default = "";
      example = "iHD";
      description = ''
        Force the VA driver used by Shadow using the LIBVA_DRIVER_NAME environment variable.
      '';
    };

    disableGpuFix = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Disable the GPU fixes for Shadow related to the color bit size.
      '';
    };

    customSessionMenu = mkOption {
      default = null;
      example = ''{ "myProgram" = "myProgramCommand" }'';
      description = ''
        Sets the content of the menu provided in the Openbox bundled standalone session.
      '';
    };

    customSessionStartScript = mkOption {
      type = types.str;
      default = "";
      example = ''
        tint2 &
      '';
      description = ''
        Custom script executed before shadow is launched in the Openbox bundled standalone session.
      '';
    };
  };
}
