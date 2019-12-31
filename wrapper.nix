{ stdenv
, lib
, ruby
, shadow-beta
, symlinkJoin
, writeScriptBin
, writeShellScriptBin
, makeWrapper

, xsessionDesktopFile ? false
, sessionCommand ? false
, preferredScreens ? []
}:

with lib;

let
  # Handling array conparaisons in bash are painfull and a waste of energy...
  # Here is how I handle the logic of screen selection with a basic ruby script.
  screenManager = writeScriptBin "set-shadow-screens" ''
    #!${ruby}/bin/ruby
    connected = ARGV[0].split("\n")
    preferred = ARGV[1].split("\n")
    exit if (connected-preferred).count == connected.count
    (connected-preferred).each { |screen| `xrandr --output #{screen} --off` }
  '';

  baseWrapper = writeShellScriptBin "shadow-beta" ''
    set -o errexit

    # Managing connected screens
    CONNECTED_SCREENS=`xrandr | grep -v "disconnected" | grep "connected" | awk '{ print $1 }'`
    PREFERRED_SCREENS=(${builtins.concatStringsSep " " preferredScreens})

    ${screenManager}/bin/set-shadow-screens "$CONNECTED_SCREENS" "$PREFERRED_SCREENS" > /tmp/output.txt

    exec ${shadow-beta}/bin/shadow-beta "$@"
  '';

  sessionCommandWrapper = writeShellScriptBin "shadow-beta-session" ''
    set -o errexit
    exec startx ${baseWrapper}/bin/shadow-beta "$@"
  '';
in symlinkJoin {
  name = "shadow-beta-${shadow-beta.version}";

  paths = [ baseWrapper shadow-beta ] ++ (optional sessionCommand sessionCommandWrapper);

  nativeBuildInputs = [ makeWrapper ];

  postBuild = lib.optionalString xsessionDesktopFile ''
    mkdir -p $out/share/xsessions
    cp ${shadow-beta}/share/applications/shadow-preprod.desktop $out/share/xsessions/shadow-preprod.desktop
  '';

  passthru.providedSessions = [ "shadow-preprod" ];
}
