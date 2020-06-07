{ stdenv, lib, ruby, shadow-package, symlinkJoin, writeScriptBin
, writeShellScriptBin, makeWrapper, compton

, writeText, openbox, feh, alacritty

, xsessionDesktopFile ? false, preferredScreens ? [ ], shadowChannel ? "preprod"
, launchArgs ? "" }:

with lib;

let
  # Logic of screen selection with a basic ruby script.
  # (Handling array conparaisons in plain bash are painfull and a waste of time...)
  screenManager = writeScriptBin "set-shadow-screens" ''
    #!${ruby}/bin/ruby
    connected = ARGV[0].split("\n")
    preferred = ARGV[1].split("\n")
    exit if (connected-preferred).count == connected.count
    (connected-preferred).each { |screen| `xrandr --output #{screen} --off` }
  '';

  sessionCommandWrapperSubCmd =
    writeShellScriptBin "shadow-${shadowChannel}-session-subcmd" ''
      set -o errexit

      # Managing connected screens
      CONNECTED_SCREENS=`xrandr | grep -v "disconnected" | grep "connected" | awk '{ print $1 }'`
      PREFERRED_SCREENS=(${builtins.concatStringsSep " " preferredScreens})
      ${screenManager}/bin/set-shadow-screens "$CONNECTED_SCREENS" "$PREFERRED_SCREENS"

      # Start VSync
      ${compton}/bin/compton --vsync -b --backend glx

      # Display a beautiful wallpaper
      ${feh}/bin/feh --bg-scale ${./openbox/background.png}

      exec ${shadow-package}/bin/shadow-${shadowChannel} "$@"
    '';

  sessionCommandWrapper =
    let
      menuFile = writeText "obmenu.xml" (import ./openbox/obmenu.nix {
        shadowCmd = "${shadow-package}/bin/shadow-${shadowChannel}";
        terminalCmd = "${alacritty}/bin/alacritty";
      });
      obConfigFile = writeText "obconfig.xml" (import ./openbox/obconfig.nix { inherit menuFile; });

    in writeShellScriptBin "shadow-${shadowChannel}-session" ''
      set -o errexit

      exec ${openbox}/bin/openbox --config-file ${obConfigFile} \
        --startup ${sessionCommandWrapperSubCmd}/bin/shadow-${shadowChannel}-session-subcmd
    '';

  standaloneSessionCommandWrapper =
    writeShellScriptBin "shadow-${shadowChannel}-standalone-session" ''
      set -o errexit
      exec startx ${sessionCommandWrapper}/bin/shadow-${shadowChannel}-session "$@"
    '';
in symlinkJoin {
  name = "shadow-${shadowChannel}-${shadow-package.version}";

  paths = [ shadow-package ] ++ (optional xsessionDesktopFile [
    sessionCommandWrapper
    standaloneSessionCommandWrapper
  ]);

  nativeBuildInputs = [ makeWrapper ];

  postBuild = optionalString xsessionDesktopFile ''
    mkdir -p $out/share/xsessions
    substitute ${shadow-package}/opt/shadow-${shadowChannel}/${shadow-package.binaryName}.desktop \
      $out/share/xsessions/${shadow-package.binaryName}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-${shadowChannel}-session"
  '';

  passthru.providedSessions = [ shadow-package.binaryName ];
}
