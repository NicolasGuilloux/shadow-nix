{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client.x-session = {
    enable = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        Provides a XSession desktop file for Shadow Launcher.
        Useful if you want to autostart it without any DE/WM.
      '';
    };

    additionalMenuEntries = mkOption {
      default = null;
      example = ''{ "myProgram" = "myProgramCommand" }'';
      description = ''
        Sets the content of the menu provided in the Openbox bundled standalone session.
      '';
    };

    startScript = mkOption {
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
