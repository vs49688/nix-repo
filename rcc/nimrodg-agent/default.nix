{ lib
, fetchFromGitHub
, pkg-config
, cmake
, pkgs
}:
let
  ##
  # Use the stdenv of pkgs, so we get the static compiler.
  ##
  stdenv = pkgs.stdenv;

  isStatic = stdenv.hostPlatform.isStatic;

  xlibressl = pkgs.libressl.overrideAttrs(old: rec {
    # Fixes build issues on Windows
    cmakeFlags = lib.remove "-DENABLE_NC=ON" old.cmakeFlags;
    outputs    = lib.remove "nc" old.outputs;
  });

  xcurlFull = (pkgs.curlFull.override {
    openssl        = xlibressl;
    libssh2        = pkgs.libssh2.override { openssl = xlibressl; };
    nghttp2        = pkgs.nghttp2.override { openssl = xlibressl; };

    http2Support   = true;
    idnSupport     = !stdenv.hostPlatform.isWindows;
    zlibSupport    = true;
    opensslSupport = true;
    scpSupport     = true;
    c-aresSupport  = !stdenv.hostPlatform.isWindows;

    ldapSupport    = false;
    gnutlsSupport  = false;
    wolfsslSupport = false;
    gssSupport     = false;
    brotliSupport  = false;
    rtmpSupport    = false;
  }).overrideAttrs(old: rec {
    configureFlags = old.configureFlags ++ [
      "--disable-file"   "--disable-ldap"  "--disable-ldaps"
      "--disable-rtsp"   "--disable-proxy" "--disable-dict"
      "--disable-telnet" "--disable-pop3"  "--disable-imap"
      "--disable-smb"    "--disable-smtp"  "--disable-cookies"
      "--disable-openssl-auto-load-config"
      "--without-ca-bundle" "--without-ca-path"
    ]
    ++ lib.optionals stdenv.hostPlatform.isWindows [
      "--with-winidn"
    ];

    NIX_CFLAGS_COMPILE = lib.optionals isStatic ["-DNGHTTP2_STATICLIB"];
  });

  xuriparser = pkgs.uriparser.overrideDerivation(old: {
    nativeBuildInputs = [ cmake ];

    cmakeFlags = [
      "-DBUILD_SHARED_LIBS=${if isStatic then "OFF" else "ON"}"
      "-DURIPARSER_BUILD_DOCS=OFF"
      "-DURIPARSER_BUILD_TESTS=OFF" # gtest breaks when building statically
      "-DURIPARSER_BUILD_TOOLS=OFF"
      "-DURIPARSER_ENABLE_INSTALL=ON"
    ];
  });
in
stdenv.mkDerivation rec {
  inherit xlibressl;
  inherit xcurlFull;
  inherit xuriparser;
  inherit isStatic;

  pname   = "nimrodg-agent";
  version = "6.0.2";

  src = fetchFromGitHub {
    owner  = "UQ-RCC";
    repo   = pname;
    /* A few commits ahead of 6.0.2, but only build and #include fixes. */
    rev    = "9afdb6f84c2fa4f588f73cd4dd0ef9065fbc8931";
    sha256 = "1373ngaa924l5j123v9xikkkpav34qnzbm35kz6sqqpx04ildv68";
    fetchSubmodules = true;
  };

  nativeBuildInputs = [ pkg-config cmake ];

  patches = [
    ./optional.patch
    ./ssl-refcount.patch
  ];

  buildInputs = [ xlibressl.dev xcurlFull.dev xuriparser ];

  ##
  # Nimrod's always used -pc, not -unknown. I'm not game to change it.
  ##
  platformString = with stdenv.hostPlatform; if parsed.vendor.name == "unknown" then
      "${parsed.cpu.name}-pc-${parsed.kernel.name}-${parsed.abi.name}"
    else
      config;

  cmakeFlags = [
    "-DNIMRODG_PLATFORM_STRING=${platformString}"
    "-DUSE_LTO=ON"
    "-DCMAKE_BUILD_TYPE=MinSizeRel"
    "-DOPENSSL_USE_STATIC_LIBS=${if isStatic then "ON" else "OFF"}"
    "-DLIBUUID_USE_STATIC_LIBS=${if isStatic then "ON" else "OFF"}"
    "-DLIBCURL_USE_STATIC_LIBS=${if isStatic then "ON" else "OFF"}"
    "-DGIT_HASH=${src.rev}"
  ];

  enableParallelBuilding = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    cp bin/agent-* "$out/bin"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Nimrod/G Agent";
    homepage    = "https://rcc.uq.edu.au/nimrod";
    platforms   = platforms.all;
    license     = licenses.asl20;
  };
}
