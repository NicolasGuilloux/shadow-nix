{ config, lib, pkgs, ... }:

let
  cfg = config.programs.shadow-client.systemd-session;
  sessionCfg = config.programs.shadow-client.x-session;
  packageCfg = config.programs.shadow-client;

  # Declare the package with the appropriate configuration
  shadow-package = pkgs.callPackage ../default.nix {
    shadowChannel = packageCfg.channel;
    enableDiagnostics = packageCfg.enableDiagnostics;
    desktopLauncher = packageCfg.enableDesktopLauncher;
  };

  # Declare the wrapper with the appropriate configuration
  shadow-wrapped = pkgs.callPackage ../x-session/wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = packageCfg.channel;
    provideSession = cfg.enable;
    launchArgs = packageCfg.launchArgs;

    menuOverride = sessionCfg.additionalMenuEntries;
    customStartScript = sessionCfg.startScript;
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
      ExecStartPre = "${config.system.path}/bin/chvt ${toString cfg.tty}";
      ExecStart =
        "${pkgs.dbus}/bin/dbus-run-session ${shadow-wrapped}/bin/${shadow-wrapped.sessionBinaryName}";
      ExecStopPost =
        lib.mkIf
          (cfg.onClosingTty != null)
          "${config.system.path}/bin/chvt ${toString cfg.onClosingTty}";

      TTYPath = "/dev/tty${toString cfg.tty}";
      TTYReset = "yes";
      TTYVHangup = "yes";
      TTYVTDisallocate = "yes";
      PAMName = "login";
      User = cfg.user;
      WorkingDirectory = "/home/${cfg.user}";
      StandardInput = "tty";
      StandardError = "journal";
      StandardOutput = "journal";
      Restart = "no";
    };
  };
}
