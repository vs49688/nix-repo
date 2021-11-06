{ stdenv, lib, fetchsvn, ant, jdk, jre ? jdk, makeDesktopItem, makeWrapper }:
let
  jdRevision = "44937";
  appWorkRevision = "3570";

  appWorkHash = "0h0p0j3r7fdg3vjggwsx8lav4w4jm02ci233wld4irzm6qmr5f6i";
  jdownloaderHash = "12nlqi6lmx6lmajr37h3nli56lg6hqi4pnk8lchgi204i5paj0bh";
  jdbrowserHash = "0nsavm4gnq19hgrmak5knpnw1gl8d3m39fq8fm9wv62k05xz9n2r";
  myJDownloaderHash = "19b1h52lwykz4ksljfa1rrvcjr5k1kmlf5d9favmm403sfngm3m4";

  appWorkUtilsSrc = fetchsvn {
    url    = "svn://svn.appwork.org/utils";
    rev    = appWorkRevision;
    sha256 = appWorkHash;
  };

  jdbrowserSrc = fetchsvn {
    url    = "svn://svn.jdownloader.org/jdownloader/browser";
    rev    = jdRevision;
    sha256 = jdbrowserHash;
  };

  myJDownloaderSrc = fetchsvn {
    url    = "svn://svn.jdownloader.org/jdownloader/MyJDownloaderClient";
    rev    = jdRevision;
    sha256 = myJDownloaderHash;
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
in
stdenv.mkDerivation rec {
  pname   = "jdownloader";
  version = "2.${jdRevision}";

  src = fetchsvn {
    url    = "svn://svn.jdownloader.org/jdownloader/trunk";
    rev    = jdRevision;
    sha256 = jdownloaderHash;
  };

  nativeBuildInputs = [ jdk ant makeWrapper ];
  buildInputs = [ jre ];

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
    ln build/newBuild/build_standalone.xml build.xml

    ${ant}/bin/ant \
      -Ddep.awu=./awu \
      -Ddep.browser=${jdbrowserSrc} \
      -Ddep.myjd=${myJDownloaderSrc}
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,jdownloader,share/pixmaps}
    cp -Rv dist/standalone/dist/* $out/jdownloader

    makeWrapper ${jre}/bin/java $out/bin/jdownloader \
      --add-flags "-cp $out/jdownloader/JDownloader.jar org.jdownloader.launcher.JDLauncher"

    ln -s "${src}/artwork/icons/by TRazo/JDownloader/JDownloader.png" $out/share/pixmaps/jdownloader.png
    ln -s "${desktopItem}/share/applications" $out/share

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
