{ stdenv, lib, fetchsvn, ant, jdk8, jre8, makeDesktopItem, desktop-file-utils, imagemagick, makeWrapper }:
let
  appWorkUtilsSrc = fetchsvn {
    url    = "svn://svn.appwork.org/utils";
    rev    = "3570";
    sha256 = "0h0p0j3r7fdg3vjggwsx8lav4w4jm02ci233wld4irzm6qmr5f6i";
  };

  description = "JDownloader is a free, open-source download management tool";

  desktopItem = makeDesktopItem {
    name        = "JDownloader";
    exec        = "jdownloader";
    icon        = "jdownloader";
    comment     = description;
    desktopName = "JDownloader";
    categories  = "Network;FileTransfer;";
  };

  svnRevision = "44937";
in
stdenv.mkDerivation rec {
  pname   = "jdownloader";
  version = "2.${svnRevision}";

  src = fetchsvn {
    url    = "svn://svn.jdownloader.org/jdownloader";
    rev    = svnRevision;
    sha256 = "1h45nc3hnn11lmv6qg51mf0lkxc3f8r7m1fqhmkwvmi7aq7n4w0b";
  };

  nativeBuildInputs = [ ant imagemagick desktop-file-utils makeWrapper ];
  buildInputs = [ jdk8 jre8 ];

  patches = [ ./0001-path-fixes-log-tmp-cfg-pidfile.patch ];

  # We need to also patch the appwork sources
  postPatch = ''
    mkdir -p awu
    cp -R ${appWorkUtilsSrc}/* awu/
    find awu/ -type d -print0 | xargs -0 chmod 0755
    find awu/ -type f -print0 | xargs -0 chmod 0644

    patch --directory=awu -p1 -i ${./0001-Squashed-path-fixes.patch}
  '';

  buildPhase = ''
    cd trunk
    ln build/newBuild/build_standalone.xml build.xml

    ${ant}/bin/ant \
      -Ddep.awu=../awu \
      -Ddep.browser=${src}/browser \
      -Ddep.myjd=${src}/MyJDownloaderClient
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,jdownloader,share/icons/hicolor/256x256/apps}
    cp -Rv dist/standalone/dist/* $out/jdownloader

    makeWrapper ${jre8}/bin/java $out/bin/jdownloader \
      --add-flags "-cp $out/jdownloader/JDownloader.jar org.jdownloader.launcher.JDLauncher"

    convert -resize 256x256 \
      "${src}/trunk/artwork/icons/by TRazo/JDownloader/JDownloader.png" \
      $out/share/icons/hicolor/256x256/apps/jdownloader.png

    ${desktopItem.buildCommand}

    runHook postInstall
  '';

  meta = with lib; {
    inherit description;
    homepage    = "https://jdownloader.org/";
    platforms   = platforms.all;
    license     = licenses.gpl3Only;
    maintainers = with maintainers; [ zane ];
  };
}
