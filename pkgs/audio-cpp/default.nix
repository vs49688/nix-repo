{
  stdenv,
  fetchFromGitHub,
  lib,
  cmake,
  openssl,
  vulkan-headers,
  vulkan-loader,
  vulkan-tools,
  glslang,
  shaderc,
}:
stdenv.mkDerivation(finalAttrs: {
  pname = "audio.cpp";
  version = "0.7.0";

  src = fetchFromGitHub {
    owner = "0xShug0";
    repo = "audio.cpp";
    tag = "v${finalAttrs.version}";
    hash = "sha256-p436ykT5Gj10WSaszHI+hhjGAbFRlYbc79WZ0OS08Kw=";
  };

  nativeBuildInputs = [
    cmake
  ];

  buildInputs = [
    openssl

    vulkan-headers
    vulkan-loader
    vulkan-tools
    glslang
    shaderc
  ];

  cmakeFlags = [
    "-DAUDIOCPP_MODEL_SET=full"
    (lib.cmakeBool "ENGINE_ENABLE_VULKAN" true)
    (lib.cmakeBool "AUDIOCPP_DEPLOYMENT_BUILD" true)
    (lib.cmakeBool "AUDIOCPP_USE_SYSTEM_OPENSSL" true)
    (lib.cmakeBool "AUDIOCPP_BUILD_NATIVE_MODEL_MANAGER" true)
    (lib.cmakeBool "ENGINE_ENABLE_NATIVE_CPU" false)
    (lib.cmakeBool "ENGINE_ENABLE_CPU_ALL_VARIANTS" true)
    (lib.cmakeBool "ENGINE_BUILD_EXAMPLES" false)
    (lib.cmakeBool "ENGINE_BUILD_TESTS" false)
    (lib.cmakeBool "ENGINE_BUILD_MODEL_TESTS" false)
    (lib.cmakeBool "ENGINE_BUILD_WARMBENCH" false)
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin

    cp bin/* $out/bin

    runHook postInstall
  '';

  meta = with lib; {
    description = "A high-performance C++ audio inference framework";
    homepage = "https://github.com/0xShug0/audio.cpp";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "audiocpp_cli";
  };
})