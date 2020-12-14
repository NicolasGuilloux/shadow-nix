{ stdenv, lib, pkgs, runCommand, yq, jq, fetchurl, makeWrapper, autoPatchelfHook
, wrapGAppsHook, zlib, runtimeShell

, xorg, alsaLib, libbsd, libopus, openssl, libva, pango, cairo, libuuid, nspr
, nss, cups, expat, atk, at-spi2-atk, gtk3, gdk-pixbuf, libsecret, systemd
, pulseaudio, libGL, dbus, libnghttp2, libidn2, libpsl, libkrb5, openldap
, rtmpdump, libinput

, enableDiagnostics ? false, extraClientParameters ? []
, shadowChannel ? "prod", desktopLauncher ? true }:

with lib;

let
  # Import tools
  utilities = (import ./utilities { inherit lib pkgs; });
  
  # Latest release information
  info = utilities.shadowApi.getLatestInfo shadowChannel;
in stdenv.mkDerivation rec {
  pname = "shadow-${info.channel}";
  version = info.version;
  src = fetchurl (utilities.shadowApi.getDownloadInfo info);
  binaryName = (if shadowChannel == "prod" then "shadow" else "shadow-${info.channel}");

  # Add all hooks
  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook makeWrapper ];

  # Useful libraries to build the package
  buildInputs = [
    stdenv.cc.cc.lib

    xorg.libX11
    xorg.libxcb
    xorg.libXrandr
    xorg.libXcomposite
    xorg.libXdamage
    xorg.libXScrnSaver
    xorg.libXcursor
    xorg.libXfixes
    xorg.libXi
    xorg.libXtst

    cairo
    pango
    alsaLib
    libbsd
    libopus
    libinput
    openssl
    libva
    zlib
    libuuid
    nspr
    nss
    cups
    expat
    atk
    at-spi2-atk
    gtk3
    gdk-pixbuf
    libnghttp2
    libidn2
    libpsl
    libkrb5
    openldap
    rtmpdump
  ];

  # Mandatory libraries for the runtime
  runtimeDependencies = [
    stdenv.cc.cc.lib
    systemd
    libinput
    pulseaudio
    libGL
    dbus
    libsecret
    xorg.libXinerama
    libva
  ];

  # Unpack the AppImage
  unpackPhase = ''
    cp $src ./Shadow.AppImage
    chmod 777 ./Shadow.AppImage

    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --replace-needed libz.so.1 ${zlib}/lib/libz.so.1 \
      ./Shadow.AppImage

    ./Shadow.AppImage --appimage-extract
    rm ./Shadow.AppImage
  '';

  # Create the package
  installPhase = 
  ''
    mkdir -p $out/opt
    mkdir -p $out/lib

    mv ./squashfs-root/usr/share $out/
    mkdir -p $out/share/applications

    ln -s ${lib.getLib systemd}/lib/libudev.so.1 $out/lib/libudev.so.1
    rm -r ./squashfs-root/usr/lib
    rm ./squashfs-root/AppRun
    mv ./squashfs-root $out/opt/shadow-${info.channel}
  '' + 

  # Add debug wrapper
  optionalString enableDiagnostics (utilities.debug.wrapRenderer info.channel) + 

  # Wrap renderer and launcher
  ''
    wrapProgram $out/opt/shadow-${info.channel}/resources/app.asar.unpacked/release/native/Shadow \
      --prefix LD_LIBRARY_PATH : ${makeLibraryPath runtimeDependencies} ${
        optionalString (extraClientParameters != [ ]) ''
          ${concatMapStrings (x: " --add-flags '" + x + "'")
          extraClientParameters}
        ''
      }

    makeWrapper $out/opt/shadow-${info.channel}/${binaryName} $out/bin/shadow-${shadowChannel} \
      --prefix LD_LIBRARY_PATH : ${makeLibraryPath runtimeDependencies}
  '' + 

  # Add Desktop entry
  optionalString desktopLauncher ''
    substitute $out/opt/shadow-${info.channel}/${binaryName}.desktop \
      $out/share/applications/${binaryName}.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-${shadowChannel}"
  '';

  meta = with stdenv.lib; {
    description = "Client for the Shadow Cloud Gaming Computer";
    homepage = "https://shadow.tech";
    license = [ licenses.unfree ];
    platforms = platforms.linux;
  };
}
