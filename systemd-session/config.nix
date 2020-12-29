{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client.systemd-session = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Provides an autonomous systemd session for Shadow.
      '';
    };

    user = mkOption {
      type = types.str;
      default = "";
      example = "myself";
      description = ''
        Select the user with which the session is started
      '';
    };

    tty = mkOption {
      type = types.int;
      default = 8;
      example = 1;
      description = ''
        Select the TTY where to start the systemd session
      '';
    };

    onClosingTty = mkOption {
      type = types.nullOr types.int;
      default = null;
      example = 1;
      description = ''
        Select the TTY to switch to when exiting
      '';
    };
  };
}
