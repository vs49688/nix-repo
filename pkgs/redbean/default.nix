{ stdenvNoCC
, lib
, fetchurl
}:

# Mostly from https://github.com/NixOS/nixpkgs/pull/278907
stdenvNoCC.mkDerivation(finalAttrs: {
  pname = "redbean";
  version = "2.2";

  src = fetchurl {
    url = "https://redbean.dev/redbean-${finalAttrs.version}.com";
    sha256 = "sha256-24/HzFp3A7fMuDCjZutp5yj8eJL9PswJPAidg3qluRs=";
  };

  dontUnpack = true;
  dontBuild = true;
  dontFixup = true;

  installPhase = ''
    runHook preInstall

    install -D $src $out/bin/redbean.com

    runHook postInstall
  '';

  meta = with lib; {
    description = "A single-file distributable web server";
    license = "free"; # https://github.com/jart/cosmopolitan/blob/master/LICENSE + indirectly uses MIT, BSD-2, BSD-3, zlib
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    homepage = "https://redbean.dev";
    maintainers = with maintainers; [ zane ];
    platforms = [ "i686-linux" "x86_64-linux" "x86_64-windows" "i686-windows" "x86_64-darwin" ];
  };
})
