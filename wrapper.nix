{ stdenv
, lib
, ruby
, shadow-package
, symlinkJoin
, writeScriptBin
, writeShellScriptBin
, makeWrapper
, compton

, desktopLauncher ? true
, xsessionDesktopFile ? false
, sessionCommand ? false
, preferredScreens ? []
, shadowChannel ? "preprod"
}:

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

  baseWrapper = writeShellScriptBin "shadow-${shadowChannel}" ''
    set -o errexit

    # Managing connected screens
    CONNECTED_SCREENS=`xrandr | grep -v "disconnected" | grep "connected" | awk '{ print $1 }'`
    PREFERRED_SCREENS=(${builtins.concatStringsSep " " preferredScreens})
    ${screenManager}/bin/set-shadow-screens "$CONNECTED_SCREENS" "$PREFERRED_SCREENS" > /tmp/output.txt

    # Enable compositor with Vsync (can help reduce teardown on Xorg)
    ${compton}/bin/compton --vsync -b --backend glx

    exec ${shadow-package}/bin/shadow-${shadowChannel} "$@"
  '';

  sessionCommandWrapper = writeShellScriptBin "shadow-${shadowChannel}-session" ''
    set -o errexit
    exec startx ${baseWrapper}/bin/shadow-${shadowChannel} "$@"
  '';
in symlinkJoin {
  name = "shadow-${shadowChannel}-${shadow-package.version}";

  paths = [ shadow-package ] 
    ++ (optional sessionCommand sessionCommandWrapper)
    ++ (optional sessionCommand baseWrapper);

  nativeBuildInputs = [ makeWrapper ];

  postBuild = lib.optionalString xsessionDesktopFile ''
    mkdir -p $out/share/xsessions
    substitute ${shadow-package}/opt/shadow-${shadowChannel}/${shadow-package.binaryName}.desktop \
      $out/share/xsessions/${shadow-package.binaryName}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-${shadowChannel}"
  ''
  + optionalString desktopLauncher ''
    substitute ${shadow-package}/opt/shadow-${shadowChannel}/${shadow-package.binaryName}.desktop \
      $out/share/applications/${shadow-package.binaryName}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-${shadowChannel}"
  '';

  passthru.providedSessions = [ shadow-package.binaryName ];
}
