{ config, lib, pkgs, ... }:

let
  cfg = config.programs.shadow-client;

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ../default.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  # Declare the wrapper with the appropriate configuration
  shadow-wrapped = pkgs.callPackage ../x-session/wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    provideSession = cfg.systemd-session.enable;
    launchArgs = cfg.launchArgs;

    menuOverride = cfg.x-session.additionalMenuEntries;
    customStartScript = cfg.x-session.startScript;
  };
in
{
  imports = [ ./config.nix ];

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
      ExecStartPre = "${config.system.path}/bin/chvt ${cfg.systemd-session.tty}";
      ExecStart =
        "${pkgs.dbus}/bin/dbus-run-session ${shadow-wrapped}/bin/${shadow-wrapped.sessionBinaryName}";
      ExecStopPost =
        lib.mkIf (cfg.systemd-session.onClosingTty != null) "${config.system.path}/bin/chvt ${cfg.systemd-session.onClosingTty}";

      TTYPath = "/dev/tty${cfg.systemd-session.tty}";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      PAMName = "login";
      User = cfg.systemd-session.user;
      WorkingDirectory = "/home/${cfg.systemd-session.user}";
      StandardInput = "tty";
      StandardError = "journal";
      StandardOutput = "journal";
      Restart = "no";
    };
  };
}
