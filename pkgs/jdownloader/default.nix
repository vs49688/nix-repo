{ stdenv, lib, fetchsvn, writeText, ant, jdk, jre ? jdk
, makeDesktopItem, copyDesktopItems, makeWrapper, ffmpeg }:
let
  appWorkHash = "1ngnxm0n2jh4smdylcxw4pr99mnqccf70cmypnyjqby37hmwqmnx";
  jdownloaderHash = "143cjdbq5bdpy8d598ij1bpry0wwmh94d366n04h65p7apjjs539";
  jdbrowserHash = "1p1b3b99p20g790nyp91wz3pqxmkyv9ckl4sqpf1gcdldgff9ak0";
  myJDownloaderHash = "19b1h52lwykz4ksljfa1rrvcjr5k1kmlf5d9favmm403sfngm3m4";

  description = "JDownloader is a free, open-source download management tool";

  buildJson = lib.importJSON ./build.json;
in
stdenv.mkDerivation rec {
  pname = "jdownloader";
  version = "2.${toString buildJson.JDownloaderRevision}";

  appWorkUtilsSrc = fetchsvn {
    url = "svn://svn.appwork.org/utils";
    rev = buildJson.AppWorkUtilsRevision;
    sha256 = appWorkHash;
  };

  jdbrowserSrc = fetchsvn {
    url = "svn://svn.jdownloader.org/jdownloader/browser";
    rev = buildJson.JDBrowserRevision;
    sha256 = jdbrowserHash;
  };

  myJDownloaderSrc = fetchsvn {
    url = "svn://svn.jdownloader.org/jdownloader/MyJDownloaderClient";
    rev = buildJson.MyJDownloaderClientRevision;
    sha256 = myJDownloaderHash;
  };

  src = fetchsvn {
    url = "svn://svn.jdownloader.org/jdownloader/trunk";
    rev = buildJson.JDownloaderRevision;
    sha256 = jdownloaderHash;
  };

  passthru.updateScript = ./update.sh;

  nativeBuildInputs = [ jdk ant makeWrapper copyDesktopItems ];

  patches = [ ./0001-path-fixes-log-tmp-cfg-pidfile.patch ];

  desktopItems = [
    (makeDesktopItem {
      name = pname;
      exec = pname;
      icon = pname;
      comment = description;
      desktopName = "JDownloader";
      categories = [ "Network" "FileTransfer" ];
    })
  ];

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
    cp -R dist/standalone/dist/* $out/jdownloader

    makeWrapper ${jre}/bin/java $out/bin/jdownloader \
      --add-flags "-cp $out/jdownloader/JDownloader.jar org.jdownloader.launcher.JDLauncher" \
      --prefix PATH : ${lib.makeBinPath [ ffmpeg ]}

    cp "${src}/artwork/icons/by TRazo/JDownloader/JDownloader.png" $out/share/pixmaps/jdownloader.png

    rm -rf $out/jdownloader/tools

    cp ${./build.json} $out/jdownloader/build.json

    runHook postInstall
  '';

  meta = with lib; {
    inherit description;
    homepage = "https://jdownloader.org/";
    platforms = platforms.all;
    license = licenses.gpl3Only;
    maintainers = with maintainers; [ zane ];
  };
}
