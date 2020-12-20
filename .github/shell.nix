let pkgs = import <nixpkgs> {};
in pkgs.mkShell {
  buildInputs = [
    (pkgs.callPackage ../default.nix {
      shadowChannel = "prod";
      enableDiagnostics = true;
      desktopLauncher = true;
    })

    (pkgs.callPackage ../default.nix {
      shadowChannel = "preprod";
      enableDiagnostics = true;
      desktopLauncher = true;
    })

    (pkgs.callPackage ../default.nix {
      shadowChannel = "testing";
      enableDiagnostics = true;
      desktopLauncher = true;
    })
  ];
}
