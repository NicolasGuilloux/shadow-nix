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
in
{
  imports = [ ./cfg.nix ];

  config = mkIf cfg.enable {
    environment.systemPackages = [ shadow-wrapped ];

    services.xserver.displayManager.sessionPackages = mkIf cfg.provideXSession [ shadow-wrapped ];

    environment.etc = mkIf (!cfg.disableAmdFix && (any (s: s == "amdgpu") config.services.xserver.videoDrivers)) {
      "drirc" = {
        text = ''
          <driconf>
            <device driver="radeonsi">
              <application name="Shadow" executable="Shadow">
                <option name="allow_rgb10_configs" value="false" />
                <option name="radeonsi_clear_db_cache_before_clear" value="true" /> 
              </application>
            </device>
          </driconf>
        '';
      };
    };
  };
}
