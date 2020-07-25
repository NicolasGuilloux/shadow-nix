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
    provideSession = cfg.provideXSession || cfg.provideSystemdSession.enable;
    launchArgs = cfg.launchArgs;

    menuOverride = cfg.customSessionMenu;
    customStartScript = cfg.customSessionStartScript;
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
    environment.systemPackages = mkIf cfg.enableDesktopLauncher [ shadow-wrapped ];

    # Add Shadow session
    services.xserver.displayManager.sessionPackages =
      mkIf cfg.provideXSession [ shadow-wrapped ];

    systemd.services.shadow-tech = 
      let
        sess = cfg.provideSystemdSession;
      in mkIf sess.enable {
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
            mkIf (sess.onClosingTty != null) "${config.system.path}/bin/chvt ${sess.onClosingTty}";

          TTYPath = "/dev/tty${sess.tty}";
          TTYReset = "yes";
          TTYVHangup = "yes";
          TTYVTDisallocate = "yes";
          PAMName = "login";
          User = sess.user;
          WorkingDirectory = "/home/${sess.user}";
          StandardInput = "tty";
          StandardError = "journal";
          StandardOutput = "journal";
          Restart = "no";
        };
      };

    # Add GPU fixes
    environment.etc."drirc" = mkIf (!cfg.disableGpuFix) { source = drirc; };

    # Force VA Driver
    environment.variables =
      mkIf (cfg.forceDriver != "") { LIBVA_DRIVER_NAME = [ cfg.forceDriver ]; };
  };
}
