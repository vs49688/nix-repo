{ stdenv, lib, fetchurl, imagemagick, makeDesktopItem, desktop-file-utils, p7zip, jre }:
let
  description = "UNLIMITED FAMILY TREE FREEWARE";

  desktopItem = makeDesktopItem {
    name        = "ancestris";
    exec        = "ancestris";
    icon        = "ancestris";
    comment     = description;
    desktopName = "Ancestris";
    categories  = "Education;Office;";
  };

in stdenv.mkDerivation rec {
  pname   = "ancestris";
  version = "12.0.11055";

  ##
  # * Can't use fetchsvn, as it can't take username and passwords
  #   - http://svn.ancestris.org/trunk, anonymous:password
  # * Can't use fetchzip, as unzip mangles the weirdly-encoded filenames
  ##
  src = fetchurl {
    url    = "https://en.ancestris.org/dl/pub/ancestris/releases/ancestris_11-20210529.zip";
    sha256 = "1m9h5w3asa25ds02w4197zl44mw9c69bkmj5mns3cz2cicgrykdd";
  };

  nativeBuildInputs = [ p7zip imagemagick desktop-file-utils ];
  buildInputs       = [ jre ];

  unpackPhase = ''
    7z x $src > /dev/null
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,share/icons/hicolor/128x128/apps}
    mv ancestris/* $out

    ls -la ancestris
    convert \
      $out/bin/ancestris128.gif \
      $out/share/icons/hicolor/128x128/apps/ancestris.png

    ${desktopItem.buildCommand}

    runHook postInstall
  '';

  meta = with lib; {
    inherit description;
    homepage    = "https://www.ancestris.org/index.html";
    platforms   = platforms.x86;
    license     = licenses.gpl3Only;
    maintainers = with maintainers; [ zane ];
  };
}
