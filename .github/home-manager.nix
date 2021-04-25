{ pkgs, ... }:

let
  repository = ./..;
in
{
  imports = [
    (repository + "/import/home-manager.nix")
  ];
}