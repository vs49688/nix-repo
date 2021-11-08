{ stdenv
, lib
, fetchurl
, makeWrapper
, autoPatchelfHook
, openjdk11
, makeDesktopItem
, runtimeShell
}:
let
  pname   = "fiji";
  version = "20201104-1356";

  desktopItem = let
    niceName = "Fiji Is Just ImageJ";
  in makeDesktopItem {
    name        = "fiji";
    exec        = "fiji %F";
    icon        = "fiji";
    mimeType    = "image/*;";
    comment     = "Scientific Image Analysis";
    desktopName = niceName;
    genericName = niceName;
    categories  = "Education;Science;ImageProcessing;";
    terminal    = false;
    startupNotify = true;
    extraEntries = ''
      Version=1.0
      TryExec=fiji
      X-GNOME-FullName=${niceName}
      StartupWMClass=fiji-Main
    '';
  };
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchurl {
    url    = "https://downloads.imagej.net/${pname}/archive/${version}/${pname}-nojre.tar.gz";
    sha256 = "1jv4wjjkpid5spr2nk5xlvq3hg687qx1n5zh8zlw48y1y09c4q7a";
  };

  dontBuild = true;

  nativeBuildInputs = [ autoPatchelfHook makeWrapper ];
  buildInputs       = [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,fiji,share/pixmaps}

    cp -R * $out/fiji
    rm -f $out/fiji/jars/imagej-updater-*.jar

    # Disgusting hack to stop a local desktop entry being created
    makeWrapper ${runtimeShell} $out/bin/fiji \
      --prefix PATH : ${lib.makeBinPath [ openjdk11 ]} \
      --set JAVA_HOME ${openjdk11.home} \
      --add-flags "-c 'exec \$($out/fiji/ImageJ-linux64 --dry-run "\$@")'"

    ln $out/fiji/images/icon.png $out/share/pixmaps/fiji.png
    ln -s "${desktopItem}/share/applications" $out/share

    runHook postInstall
  '';

  meta = with lib; {
    homepage    = "https://imagej.net/software/fiji/";
    description = "An image processing package - a “batteries-included” distribution of ImageJ2, bundling a lot of plugins which facilitate scientific image analysis";
    platforms   = [ "x86_64-linux" ];
    license     = with lib.licenses; [
      gpl2Plus gpl3Plus bsd2 publicDomain
    ];
    maintainers = with maintainers; [ zane ];
  };
}