{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client = {
    enable = mkEnableOption ''
      Install the client to use the Shadow Gaming Cloud Computer on NixOS 
    '';

    enableDesktopLauncher = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Provides the desktop file for launching Shadow from current session.
      '';
    };

    provideSessionCommand = mkOption {
      type = types.bool;
      default = true;
      example = false;
      description = ''
        Provides a session with startx arguments to launch it from command line.
      '';
    };

    enableDiagnostics = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        The command used to execute the client will be output in a file in /tmp.
        The client will output its strace in /tmp.
        This is mainly used for diagnostics purposes (when an update breaks something)
      '';
    };

    provideXSession = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Provides a XSession desktop file for Shadow Launcher.
        Usefull if you want to autostart it without any DE/WM.
      '';
    };
  };
}