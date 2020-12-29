{ stdenv, lib, callPackage, shadow-package, symlinkJoin, writeScriptBin
, writeShellScriptBin, makeWrapper, compton

, openbox, feh, pavucontrol, alacritty, xorg
, menuOverride ? null
, customStartScript ? ""

, provideSession ? false, shadowChannel ? "preprod"
, launchArgs ? "" }:

with lib;

let
  sessionCommandWrapperSubCmd =
    writeShellScriptBin "shadow-${shadowChannel}-session-subcmd" ''
      set -o errexit

      # Hook a script
      ${customStartScript}

      # Start VSync
      ${compton}/bin/compton --vsync -b --backend glx

      # Display a beautiful wallpaper
      ${feh}/bin/feh --bg-scale ${../assets/images/background.png}

      exec ${shadow-package}/bin/shadow-${shadowChannel} "$@"
    '';

  sessionCommandWrapper =
    let
      menuFile = (callPackage ./openbox/obmenu.nix {
        menu = (if menuOverride != null then menuOverride else {
          "Shadow" = "${shadow-package}/bin/shadow-${shadowChannel}";
          "Sound" = "${pavucontrol}/bin/pavucontrol";
          "Terminal" = "${alacritty}/bin/alacritty";
        });
      });
      obConfigFile = (callPackage ./openbox/obconfig.nix { inherit menuFile; });
    in writeShellScriptBin "shadow-${shadowChannel}-session" ''
      set -o errexit

      exec ${openbox}/bin/openbox --config-file ${obConfigFile} \
        --startup ${sessionCommandWrapperSubCmd}/bin/shadow-${shadowChannel}-session-subcmd
    '';

  sessionBinaryName = "shadow-${shadowChannel}-standalone-session";

  standaloneSessionCommandWrapper =
    writeShellScriptBin sessionBinaryName ''
      set -o errexit
      exec ${xorg.xinit}/bin/startx ${sessionCommandWrapper}/bin/shadow-${shadowChannel}-session "$@"
    '';
in symlinkJoin {
  inherit sessionBinaryName;

  name = "shadow-${shadowChannel}-${shadow-package.version}";

  paths = [ shadow-package ] ++ (optional provideSession [
    sessionCommandWrapper
    standaloneSessionCommandWrapper
  ]);

  nativeBuildInputs = [ makeWrapper ];

  postBuild = optionalString provideSession ''
    mkdir -p $out/share/xsessions
    substitute ${shadow-package}/opt/shadow-${shadowChannel}/${shadow-package.binaryName}.desktop \
      $out/share/xsessions/${shadow-package.binaryName}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-${shadowChannel}-session"
  '';

  passthru.providedSessions = [ shadow-package.binaryName ];
}
