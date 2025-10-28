{ stdenvNoCC
, lib
, fetchurl
, p7zip
, cpio
}: stdenvNoCC.mkDerivation(finalAttrs: {
  pname = "apple-sf-pro-font";
  version = "0-unstable-2025-10-28";

  src = fetchurl {
    url = "https://devimages-cdn.apple.com/design/resources/download/SF-Pro.dmg";
    hash = "sha256-Lk14U5iLc03BrzO5IdjUwORADqwxKSSg6rS3OlH9aa4=";
  };

  nativeBuildInputs = [
    p7zip
    cpio
  ];

  unpackPhase = ''
    runHook preUnpack

    7z -so e $src 'SFProFonts/SF Pro Fonts.pkg' > tmp.pkg
    7z -so e tmp.pkg 'Payload~' | cpio --quiet -i
    rm tmp.pkg

    runHook postUnpack
  '';

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/share/fonts/opentype/apple/sf-pro
    install --mode=644 Library/Fonts/*.otf $out/share/fonts/opentype/apple/sf-pro

    runHook postInstall
  '';

  meta = with lib; {
    description = "A companion to San Francisco, this serif typeface is based on essential aspects of historical type styles";
    homepage    = "https://developer.apple.com/fonts";
    platforms   = platforms.all;
    license     = licenses.unfree;
  };
})
