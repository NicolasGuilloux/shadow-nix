{ stdenv, lib, runCommand, yq, jq, fetchurl, makeWrapper, autoPatchelfHook
, wrapGAppsHook, zlib, runtimeShell

, xorg, alsaLib, libbsd, libopus, openssl, libva, pango, cairo, libuuid, nspr
, nss, cups, expat, atk, at-spi2-atk, gtk3, gdk-pixbuf, libsecret, systemd
, pulseaudio, libGL, dbus, libnghttp2, libidn2, libpsl, libkrb5, openldap
, rtmpdump, libinput

, enableDiagnostics ? false, extraClientParameters ? [ ]
, shadowChannel ? "preprod", desktopLauncher ? true }:

with lib;

let
  # Reading dynamic versions information from upstream update system
  latestVersion = builtins.fetchurl
    "https://storage.googleapis.com/shadow-update/launcher/${shadowChannel}/linux/ubuntu_18.04/latest-linux.yml";
  latestVersionJson = (runCommand "transform" { buildInputs = [ yq jq ]; }
    "cat ${latestVersion} | yq -j . > $out");
  source = builtins.fromJSON (builtins.readFile latestVersionJson);

  # This permit to display errors that could not be displayed otherwise
  diagTxt = ''
    mv $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow \
      $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/.Shadow-Orig

    echo "#!${runtimeShell}" > $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow

    echo "echo \"\$@\" > /tmp/shadow.current_cmd" >> \
      $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow

    echo "strace $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/.Shadow-Orig \"\$@\" > /tmp/shadow.strace 2>&1" >> \
      $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow

    chmod +x $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow
  '';
in stdenv.mkDerivation rec {
  pname = "shadow-${shadowChannel}";
  version = source.version;

  src = fetchurl {
    url =
      "https://update.shadow.tech/launcher/${shadowChannel}/linux/ubuntu_18.04/${source.path}";
    hash = "sha512-${source.sha512}";
  };

  binaryName =
    (if shadowChannel == "prod" then "shadow" else "shadow-${shadowChannel}");

  nativeBuildInputs = [ autoPatchelfHook wrapGAppsHook makeWrapper ];

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

  unpackPhase = ''
    cp $src ./ShadowBeta.AppImage
    chmod 777 ./ShadowBeta.AppImage

    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --replace-needed libz.so.1 ${zlib}/lib/libz.so.1 \
      ./ShadowBeta.AppImage

    ./ShadowBeta.AppImage --appimage-extract
    rm ./ShadowBeta.AppImage
  '';

  installPhase = ''
    mkdir -p $out/opt
    mv ./squashfs-root/usr/share $out/

    # Libraries
    mkdir -p $out/lib
    ln -s ${lib.getLib systemd}/lib/libudev.so.1 $out/lib/libudev.so.1
    mkdir -p $out/share/applications
    rm -r ./squashfs-root/usr/lib

    # Application
    rm ./squashfs-root/AppRun
    mv ./squashfs-root $out/opt/shadow-${shadowChannel}
  '' + optionalString enableDiagnostics diagTxt + ''

    # Wrap Renderer
    wrapProgram $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow \
      --prefix LD_LIBRARY_PATH : ${makeLibraryPath runtimeDependencies} ${
        optionalString (extraClientParameters != [ ]) ''
          ${concatMapStrings (x: " --add-flags '" + x + "'")
          extraClientParameters}
        ''
      }

    # Wrap Renderer into binary
    makeWrapper \
      $out/opt/shadow-${shadowChannel}/resources/app.asar.unpacked/release/native/Shadow \
      $out/bin/shadow-${shadowChannel}-renderer \
      --prefix LD_LIBRARY_PATH : ${makeLibraryPath runtimeDependencies}

    # Wrap launcher
    makeWrapper $out/opt/shadow-${shadowChannel}/${binaryName} $out/bin/shadow-${shadowChannel} \
      --prefix LD_LIBRARY_PATH : ${makeLibraryPath runtimeDependencies}

    
  '' + optionalString desktopLauncher ''
    substitute $out/opt/shadow-${shadowChannel}/${binaryName}.desktop \
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
