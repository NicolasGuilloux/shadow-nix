{ lib, pkgs, ... }:

# Use it by adding the following lines
#   let
#     utilities = (import ./utilities { inherit lib pkgs; });
#   in
#   ...
let
  # Import library method
  callLib = path: (import path { inherit lib pkgs; });
in
{
    shadowApi = callLib ./shadow-api.nix;
    debug = callLib ./debug.nix;
    files = callLib ./files.nix;
}
