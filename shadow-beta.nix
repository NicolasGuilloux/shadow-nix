{ stdenv, lib
, runCommand, yq, fetchurl
, makeWrapper, autoPatchelfHook, wrapGAppsHook, zlib, runtimeShell

, xorg, alsaLib, libbsd, libopus, openssl, libva, pango, cairo
, libuuid, nspr, nss, cups, expat, atk, at-spi2-atk, gtk3, gdk-pixbuf
, libsecret, systemd, pulseaudio, libGL, dbus, libnghttp2, libidn2
, libpsl, libkrb5, openldap, rtmpdump

, desktopLauncher ? true
, sessionCommand ? false
, enableDiagnostics ? false
, xsessionDesktopFile ? false
}:

let
  source = 
   builtins.fromJSON (builtins.readFile (
      runCommand "transform" { buildInputs = [yq]; }
        "cat ${
           builtins.fetchurl "https://storage.googleapis.com/shadow-update/launcher/preprod/linux/ubuntu_18.04/latest-linux.yml"
         } | yq -j . > $out"
  ));

  # This permit to display error that could not be displayed otherwise
  diagTxt = ''
    mv $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow \
      $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/.Shadow-Orig

    echo "#!${runtimeShell}" > $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow

    echo "echo \"\$@\" > /tmp/shadow.current_cmd" >> \
      $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow

    echo "strace $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/.Shadow-Orig \"\$@\" > /tmp/shadow.strace 2>&1" >> \
      $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow

    chmod +x $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow
  '';
in
stdenv.mkDerivation rec {
  pname = "shadow-beta";
  version = source.version;

  src = fetchurl {
    url = "https://update.shadow.tech/launcher/preprod/linux/ubuntu_18.04/ShadowBeta.AppImage";
    hash = "sha512-${source.sha512}";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook
    makeWrapper
  ];

  buildInputs = [
    stdenv.cc.cc.lib

    xorg.libX11 xorg.libxcb xorg.libXrandr xorg.libXcomposite xorg.libXdamage
    xorg.libXScrnSaver xorg.libXcursor xorg.libXfixes xorg.libXi xorg.libXtst

    cairo pango alsaLib libbsd libopus openssl libva zlib libuuid nspr
    nss cups expat atk at-spi2-atk gtk3 gdk-pixbuf libnghttp2 libidn2
    libpsl libkrb5 openldap rtmpdump
  ];

  runtimeDependencies = [
    stdenv.cc.cc.lib
    systemd.lib
    pulseaudio
    libGL
    dbus
    libsecret
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
    mkdir -p $out/share/applications
    rm -r ./squashfs-root/usr/lib
    rm ./squashfs-root/AppRun
    mv ./squashfs-root $out/opt/shadow-beta
  ''
  + lib.optionalString enableDiagnostics diagTxt
  + ''
    wrapProgram $out/opt/shadow-beta/resources/app.asar.unpacked/release/native/Shadow \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}

    makeWrapper $out/opt/shadow-beta/shadow-preprod $out/bin/shadow-beta \
      --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath runtimeDependencies}
  ''
  + lib.optionalString desktopLauncher ''
	  mv $out/opt/shadow-beta/shadow-preprod.desktop $out/share/applications/shadow-preprod.desktop
    substituteInPlace $out/share/applications/shadow-preprod.desktop \
      --replace "Exec=AppRun" "Exec=$out/bin/shadow-beta"
  ''
  + lib.optionalString xsessionDesktopFile ''
    mkdir -p $out/share/xsessions
    cp $out/share/applications/shadow-preprod.desktop $out/share/xsessions/shadow-preprod.desktop
  ''
  + lib.optionalString sessionCommand ''
    echo "#!${runtimeShell}" > $out/bin/shadow-beta-session
    echo "startx $out/bin/shadow-beta" >> $out/bin/shadow-beta-session
    chmod +x $out/bin/shadow-beta-session
  '';

  passthru.providedSessions = [ "shadow-preprod" ];

  meta = with stdenv.lib; {
    description = "Client for the Shadow Cloud Gaming Computer";
    homepage = "https://shadow.tech";
    license = [ licenses.unfree ];
    platforms = platforms.linux;
  };
}
