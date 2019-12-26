{ config, pkgs, lib, ... }:

with lib;

{
  options.programs.shadow-client = {
    enable = mkEnableOption ''
      Install the client to use the Shadow Gaming Cloud Computer on NixOS 
    '';

    enableDiag = mkOption {
      type = types.bool;
      default = false;
      example = true;
      description = ''
        The command used to execute the client will be output in a file in /tmp.
        The client will output its strace in /tmp.
        This is mainly used for diagnostics purposes (when an update breaks something)
      '';
    };
  };
}