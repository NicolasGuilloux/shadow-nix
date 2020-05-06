{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-package = pkgs.callPackage ./shadow-package.nix {
    shadowChannel = cfg.channel;
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-package = shadow-package;

    shadowChannel = cfg.channel;
    preferredScreens = cfg.preferredScreens;
    xsessionDesktopFile = cfg.provideXSession;
    launchArgs = cfg.launchArgs;
  };

  drirc = (fetchGit {
    url = "https://github.com/NicolasGuilloux/blade-shadow-beta";
    ref = "master";
  } + "/resources/drirc");
in {
  imports = [ ./cfg.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = [ shadow-wrapped ];

    services.xserver.displayManager.sessionPackages = mkIf cfg.provideXSession [ shadow-wrapped ];

    environment.etc = mkIf (!cfg.disableGpuFix) {
      "drirc" = {
        text = drirc;
      };
    };
  };
}
