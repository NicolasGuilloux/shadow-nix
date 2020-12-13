{ config, lib, pkgs, ... }:

let
  cfg = config.programs.shadow-client.systemd-session;
in
{
    systemd.services.shadow-tech = lib.mkIf cfg.enable {
        enable = true;
        wants = [ "systemd-machined.service" ];
        after = [
          "rc-local.service"
          "systemd-machined.service"
          "systemd-user-sessions.service"
          "systemd-logind.service"
        ];
        serviceConfig = {
          ExecStartPre = "${config.system.path}/bin/chvt ${sess.tty}";
          ExecStart =
            "${pkgs.dbus}/bin/dbus-run-session ${shadow-wrapped}/bin/${shadow-wrapped.sessionBinaryName}";
          ExecStopPost =
            mkIf (cfg.onClosingTty != null) "${config.system.path}/bin/chvt ${cfg.onClosingTty}";

          TTYPath = "/dev/tty${cfg.tty}";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          PAMName = "login";
          User = sess.user;
          WorkingDirectory = "/home/${cfg.user}";
          StandardInput = "tty";
          StandardError = "journal";
          StandardOutput = "journal";
          Restart = "no";
        };
    };
}