{ config, pkgs, lib, ... }:

with lib;

let
  cfg = config.programs.shadow-client;

  shadow-beta = pkgs.callPackage ./shadow-beta.nix {
    enableDiagnostics = cfg.enableDiagnostics;
    desktopLauncher = cfg.enableDesktopLauncher;
  };

  shadow-wrapped = pkgs.callPackage ./wrapper.nix {
    shadow-beta = shadow-beta;
    sessionCommand = cfg.provideSessionCommand;
    preferredScreens = cfg.preferredScreens;
    xsessionDesktopFile = cfg.provideXSession;
  };
in
{
  imports = [ ./cfg.nix ];

  config = {
    environment.systemPackages = [ shadow-wrapped ];
    services.xserver.displayManager.sessionPackages = mkIf cfg.provideXSession [ shadow-wrapped ];
  };
}
