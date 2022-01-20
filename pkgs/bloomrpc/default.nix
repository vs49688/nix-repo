{ stdenv, lib, fetchurl, dpkg, autoPatchelfHook, wrapGAppsHook
, xorg, alsa-lib, libuuid, nss, pango, atk, cups, dbus, gdk-pixbuf
, gtk3, libudev0-shim }:
stdenv.mkDerivation rec {
  pname = "bloomrpc";
  version = "1.5.3";

  src = fetchurl {
    url = "https://github.com/bloomrpc/bloomrpc/releases/download/${version}/bloomrpc_${version}_amd64.deb";
    sha256 = "013maia2bx85sgssd5wzf1dl2ci85fwya5rgk52qi1hx7xrk4i70";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    wrapGAppsHook
    dpkg
  ];

  buildInputs = [
    xorg.libX11
    xorg.libxcb
    xorg.libXScrnSaver
    xorg.libXcomposite
    xorg.libXcursor
    xorg.libXdamage
    xorg.libXext
    xorg.libXfixes
    xorg.libXi
    xorg.libXrandr
    xorg.libXrender
    xorg.libXtst

    alsa-lib
    libuuid
    nss
    pango
    atk
    cups
    dbus
    gdk-pixbuf
    gtk3
  ];

  unpackCmd = "dpkg-deb -x ${src} source";

  dontConfigure = true;
  dontBuild = true;

  dontWrapGApps = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    cp -R ./opt $out/opt
    cp -R ./usr/share $out/share

    makeWrapper $out/opt/BloomRPC/bloomrpc $out/bin/bloomrpc \
        "''${gappsWrapperArgs[@]}" \
        --prefix XDG_DATA_DIRS : "${gtk3}/share/gsettings-schemas/${gtk3.name}/" \
        --prefix LD_LIBRARY_PATH : ${lib.makeLibraryPath [ libudev0-shim ]}

    substituteInPlace \
      $out/share/applications/bloomrpc.desktop \
      --replace /opt/ $out/opt/

    runHook postInstall
  '';

  meta = with lib; {
    homepage = "https://github.com/bloomrpc/bloomrpc";
    description = "GUI Client for GRPC Services";
    license = licenses.lgpl3Plus;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ zane ];
  };
}
