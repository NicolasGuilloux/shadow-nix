{ pkgs, ... }:

let
  repository = /home/runner;
in
{
  imports = [
    (repository + "/import/home-manager.nix")
  ];
}