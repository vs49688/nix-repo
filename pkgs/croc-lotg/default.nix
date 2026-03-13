{ stdenv
, lib
, requireFile
, makeDesktopItem
, copyDesktopItems
, makeBinaryWrapper
, icoutils
, imagemagick_light
, autoPatchelfHook
, SDL2
, sdl3
, glfw3
, openal-soft
, version ? "1.3.0"
, allowSubstitutes ? false
}: let
  requireFile2 = args: (requireFile args).overrideAttrs(old: { inherit allowSubstitutes; });

  versions = {
    "1.2.0" = {
      name = "croc64-1.2.0.tar.xz";
      hash = "sha256-Oi+jtnruf/522x2TYs94Ze3VEcQfoySavYPTaWxOv/M=";

      buildInputs = [
        glfw3
        openal-soft
      ];

      binaryPaths = {};
    };

    "1.3.0" = {
      name = "croc64-1.3.0.tar.xz";
      hash = "sha256-USdhKi4iMXChfKd9qFT0YZicj0elOVilWgnp9vNskrI=";

      buildInputs = [
        glfw3
        openal-soft
      ];

      binaryPaths = {};
    };

    "1.4.0" = {
      name = "croc64-1.4.0.tar";
      hash = "sha256-cCVxuu38ROfCzXZlI1+jLS5AEnvw1pHC1/h+3fZanFQ=";

      buildInputs = [
        SDL2
      ];

      binaryPaths = {};
    };

    "1.5.0" = {
      name = "croc64-1.5.0.tar";
      hash = "sha256-9Ihnlfbl0o/5Rx6Ijk03G3D/HmL/zX3eE9m6FcWd2MA=";

      buildInputs = [
        SDL2
      ];

      binaryPaths = {};
    };

    "1.5.6" = {
      name = "croc64-1.5.6.tar";
      hash = "sha256-8cUtcSd9TWXW5pFPeNFvHunTLkmX/UHI+nvjtxumkJA=";

      buildInputs = [
        sdl3
      ];

      binaryPaths = {};
    };

    "1.5.7" = {
      name = "croc64-1.5.7.tar";
      hash = "sha256-DL9swJHig1EHcE2+nNy1z8fCaksyiB8Qs9uzZSfsczA=";

      buildInputs = [
        sdl3
      ];

      binaryPaths = {
        "aarch64-linux" = {
          main = requireFile2 {
            name = "CrocA64-1.5.7";
            message = "Please prefetch CrocA64-1.5.7 into the Nix store";
            hash = "sha256-UzVkAaLdBIXTDzsVIVTouFIIBbaL6M87DVW0Gh8wZ9c=";
          };

          demo = requireFile2 {
            name = "CrocDemoA64-1.5.7";
            message = "Please prefetch CrocDemoA64-1.5.7 into the Nix store";
            hash = "sha256-VccydVP9lx1TAXBLaxtVX1i52HyInx2W8340pZmo8a0=";
          };
        };
      };
    };
  };

  versionInfo = assert versions ? ${version}; versions.${version};
in
stdenv.mkDerivation(finalAttrs: {
  inherit version;

  pname = "croc64";

  passthru.versions    = versions;
  passthru.versionInfo = versionInfo;

  src = requireFile2 {
    name = versionInfo.name;
    message = "Please prefetch ${versionInfo.name} into the Nix store";
    sha256 = versionInfo.hash;
  };

  dontBuild = true;

  nativeBuildInputs = [
    autoPatchelfHook
    copyDesktopItems
    makeBinaryWrapper
    icoutils
    imagemagick_light
  ];

  buildInputs = versionInfo.buildInputs;

  desktopItems = [
    (makeDesktopItem {
      name = "croc64";
      exec = "Croc64";
      icon = finalAttrs.pname;
      comment = "Croc! Legend of the Gobbos Definitive Edition";
      desktopName = "Croc! Legend of the Gobbos";
      categories = [ "Game" ];
    })
    (makeDesktopItem {
      name = "crocdemo64";
      exec = "CrocDemo64";
      icon = finalAttrs.pname;
      comment = "Croc! Legend of the Gobbos Definitive Edition Demo";
      desktopName = "Croc! Legend of the Gobbos Demo";
      categories = [ "Game" ];
    })
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{croc64-${finalAttrs.version},bin} $out/share/pixmaps
    wrestool -x -t 14 -n 101 Croc64.exe | convert ico:- $out/share/pixmaps/${finalAttrs.pname}.png
    mv * $out/croc64-${finalAttrs.version}
    rm -rf $out/croc64-${finalAttrs.version}/{config,Croc{,Demo}64.exe,{OpenAL64,SDL2,SDL3,libmcfgthread-2}.dll}
  '' + (lib.optionalString (versionInfo.binaryPaths ? ${stdenv.hostPlatform.system}) ''
    rm -f $out/croc64-${finalAttrs.version}/{config,Croc{,Demo}64}

    install -m755 ${versionInfo.binaryPaths.${stdenv.hostPlatform.system}.main} $out/croc64-${finalAttrs.version}/Croc64
    install -m755 ${versionInfo.binaryPaths.${stdenv.hostPlatform.system}.demo} $out/croc64-${finalAttrs.version}/CrocDemo64
  '') + ''
    makeWrapper $out/croc64-${finalAttrs.version}/Croc64 $out/bin/Croc64 \
      --chdir "$out/croc64-${finalAttrs.version}"

    makeWrapper $out/croc64-${finalAttrs.version}/CrocDemo64 $out/bin/CrocDemo64 \
      --chdir "$out/croc64-${finalAttrs.version}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Croc! Legend of the Gobbos Definitive Edition";
    platforms = [
      "x86_64-linux"
    ] ++ (lib.optionals (lib.versionAtLeast finalAttrs.version "1.5.7") [
      "aarch64-linux"
    ]);
    license = licenses.unfree;
    maintainers = with maintainers; [ zane ];
  };
})
