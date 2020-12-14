{ lib, ... }:

rec {
    drirc = builtins.fetchGit {
        url = "https://github.com/NicolasGuilloux/blade-shadow-beta";
        ref = "master";
      } + "/resources/drirc";
}
