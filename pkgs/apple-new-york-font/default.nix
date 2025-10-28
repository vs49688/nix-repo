{ stdenvNoCC
, lib
, fetchurl
, p7zip
, cpio
}: stdenvNoCC.mkDerivation(finalAttrs: {
  pname = "apple-new-york-font";
  version = "0-unstable-2025-10-28";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/NY.dmg";
    hash = "sha256-HC7ttFJswPMm+Lfql49aQzdWR2osjFYHJTdgjtuI+PQ=";
  };

  nativeBuildInputs = [
    p7zip
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    7z -so e $src 'NYFonts/NY Fonts.pkg' > tmp.pkg
    7z -so e tmp.pkg 'Payload~' | cpio --quiet -i
    rm tmp.pkg

    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/opentype/apple/new-york
    install --mode=644 Library/Fonts/*.otf $out/share/fonts/opentype/apple/new-york

    runHook postInstall
  '';

  meta = with lib; {
    description = "This neutral, flexible, sans-serif typeface is the system font for Apple platforms";
    homepage    = "https://developer.apple.com/fonts";
    platforms   = platforms.all;
    license     = licenses.unfree;
  };
})
