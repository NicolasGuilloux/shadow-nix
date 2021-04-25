{ pkgs, ... }:

let
  repository = /home/runner/work/shadow-nix/shadow-nix;
in
{
  imports = [
    (repository + "/import/home-manager.nix")
  ];
}