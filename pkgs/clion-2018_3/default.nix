{ stdenv
, lib
, makeDesktopItem
, makeWrapper
, fetchurl
, patchelf
, unzip
, autoPatchelfHook
, libdbusmenu
, jdk
, coreutils
, gnugrep
, which
, git
}:
let
  pname     = "clion";
  version   = "2018.3.4";
  name      = "${pname}-${version}";

  product    = "CLion";
  loName     = lib.toLower product;
  hiName     = lib.toUpper product;
  execName   = "${pname}-2018-3";

  description     = "C/C++ IDE. New. Intelligent. Cross-platform";
  longDescription = ''
    Enhancing productivity for every C and C++
    developer on Linux, macOS and Windows.
  '';

  desktopItem = makeDesktopItem {
    name          = execName;
    exec          = execName;
    comment       = lib.replaceChars ["\n"] [" "] longDescription;
    desktopName   = "${product} ${version}";
    genericName   = description;
    categories    = "Development;";
    icon          = execName;
    extraEntries = ''
      StartupWMClass=jetbrains-clion
    '';
  };
in stdenv.mkDerivation {
  inherit pname;
  inherit version;

  src = fetchurl {
    url     = "https://download.jetbrains.com/cpp/CLion-${version}.tar.gz";
    sha256  = "1zglpw9vc3ybdmwymi0c2m6anhcmx9jcqi69gnn06n9f4x1v6gwn";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    makeWrapper
    patchelf
    unzip
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libdbusmenu
  ];

  installPhase = let
    binPath = lib.makeBinPath [
      jdk
      coreutils
      gnugrep
      which
      git
    ];
  in ''
    mkdir -p $out/{bin,$name,share/pixmaps,libexec/${name}}
    cp -a . $out/$name
    rm -rf $out/$name/jre64
    ln -s $out/$name/bin/${loName}.png $out/share/pixmaps/${execName}.png
    mv bin/fsnotifier* $out/libexec/${name}/.

    makeWrapper "$out/$name/bin/${loName}.sh" "$out/bin/${execName}" \
      --prefix PATH : "$out/libexec/${name}:${binPath}" \
      --set JDK_HOME "${jdk.home}" \
      --set ${hiName}_JDK "${jdk.home}" \
      --set JAVA_HOME "${jdk.home}"

    ln -s "${desktopItem}/share/applications" $out/share
  '';

  meta = with lib; {
    inherit description longDescription;
    homepage    = "https://www.jetbrains.com/clion/";
    license     = licenses.unfree;
    maintainers = with maintainers; [ zane ];
    platforms   = platforms.linux;
  };
}
