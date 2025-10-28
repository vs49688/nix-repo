{ stdenvNoCC
, lib
, fetchurl
, p7zip
, cpio
}: stdenvNoCC.mkDerivation(finalAttrs: {
  pname = "apple-sf-compact-font";
  version = "0-unstable-2025-10-28";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Compact.dmg";
    hash = "sha256-CMNP+sL5nshwK0lGBERp+S3YinscCGTi1LVZVl+PuOM=";
  };

  nativeBuildInputs = [
    p7zip
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    7z -so e $src 'SFCompactFonts/SF Compact Fonts.pkg' > tmp.pkg
    7z -so e tmp.pkg 'Payload~' | cpio --quiet -i
    rm tmp.pkg

    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/opentype/apple/sf-compact
    install --mode=644 Library/Fonts/*.otf $out/share/fonts/opentype/apple/sf-compact

    runHook postInstall
  '';

  meta = with lib; {
    description = "Sharing many features with SF Pro, SF Compact features an efficient, compact design that is optimized for small sizes and narrow columns";
    homepage    = "https://developer.apple.com/fonts";
    platforms   = platforms.all;
    license     = licenses.unfree;
  };
})
