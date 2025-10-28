{ stdenvNoCC
, lib
, fetchurl
, p7zip
, cpio
}: stdenvNoCC.mkDerivation(finalAttrs: {
  pname = "apple-sf-mono-font";
  version = "0-unstable-2025-10-28";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Mono.dmg";
    hash = "sha256-bUoLeOOqzQb5E/ZCzq0cfbSvNO1IhW1xcaLgtV2aeUU=";
  };

  nativeBuildInputs = [
    p7zip
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    7z -so e $src 'SFMonoFonts/SF Mono Fonts.pkg' > tmp.pkg
    7z -so e tmp.pkg 'Payload~' | cpio --quiet -i
    rm tmp.pkg

    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/opentype/apple/sf-mono
    install --mode=644 Library/Fonts/*.otf $out/share/fonts/opentype/apple/sf-mono

    runHook postInstall
  '';

  meta = with lib; {
    description = "This monospaced variant of San Francisco enables alignment between rows and columns of text, and is used in coding environments like Xcode";
    homepage    = "https://developer.apple.com/fonts";
    platforms   = platforms.all;
    license     = licenses.unfree;
  };
})
