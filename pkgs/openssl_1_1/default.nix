{
  lib,
  stdenv,
  fetchurl,
  buildPackages,
  perl,
  makeBinaryWrapper,
  withCryptodev ? false,
  cryptodev,
  withZlib ? false,
  zlib,
  enableSSL2 ? false,
  enableSSL3 ? false,
  enableMD2 ? false,
  # path to openssl.cnf file. will be placed in $out/etc/ssl/openssl.cnf to replace the default
  conf ? null,
}:

# OpenSSL 1.1 reached EOL on 2023-09-11. This package exists only for
# legacy binaries (old games, MongoDB 3.6, etc.) that require the 1.1 ABI.
# Do not expect security fixes.

let
  useBinaryWrapper = !(stdenv.hostPlatform.isWindows || stdenv.hostPlatform.isCygwin);
in
stdenv.mkDerivation (finalAttrs: {
  pname = "openssl";
  version = "1.1.1w";

  src = fetchurl {
    url = "https://github.com/openssl/openssl/releases/download/OpenSSL_1_1_1w/openssl-1.1.1w.tar.gz";
    hash = "sha256-zzCYlQy02FOtlcCEHx+cbT3BAtzPys1SHZOSUgi3asg=";
  };

  patches = [
    ./nix-ssl-cert-file.patch

    (
      if stdenv.hostPlatform.isDarwin then
        ./use-etc-ssl-certs-darwin.patch
      else
        ./use-etc-ssl-certs.patch
    )
  ];

  postPatch = ''
    patchShebangs Configure
  ''
  # config is a configure script which is not installed.
  + ''
    substituteInPlace config --replace '/usr/bin/env' '${buildPackages.coreutils}/bin/env'
  ''
  + lib.optionalString stdenv.hostPlatform.isMusl ''
    substituteInPlace crypto/async/arch/async_posix.h \
      --replace '!defined(__ANDROID__) && !defined(__OpenBSD__)' \
                '!defined(__ANDROID__) && !defined(__OpenBSD__) && 0'
  ''
  # This test will fail if the error strings between the build libc and host
  # libc mismatch, e.g. when cross-compiling from glibc to musl
  + lib.optionalString
    (finalAttrs.finalPackage.doCheck && stdenv.hostPlatform.libc != stdenv.buildPlatform.libc)
    ''
      rm test/recipes/02-test_errstr.t
    ''
  + lib.optionalString stdenv.hostPlatform.isCygwin ''
    rm test/recipes/01-test_symbol_presence.t
  ''
  # this test has inconsistent behavior in the freebsd sandbox
  # (binds to only ipv6 and connects on only ipv4)
  + lib.optionalString stdenv.hostPlatform.isFreeBSD ''
    substituteInPlace test/recipes/82-test_ocsp_cert_chain.t \
      --replace-fail '"-accept",' '"-4", "-accept",' \
      --replace-fail '"-connect",' '"-4", "-connect",'
  '';

  outputs = [
    "bin"
    "dev"
    "out"
    "man"
  ];
  setOutputFlags = false;
  separateDebugInfo =
    !stdenv.hostPlatform.isDarwin
    && !stdenv.hostPlatform.isAndroid
    && !(stdenv.hostPlatform.useLLVM or false)
    && stdenv.targetPlatform.libc != "picolibc"
    && stdenv.cc.isGNU;

  nativeBuildInputs = lib.optional useBinaryWrapper makeBinaryWrapper ++ [ perl ];
  buildInputs = lib.optional withCryptodev cryptodev ++ lib.optional withZlib zlib;

  configurePlatforms = [ ];
  configureScript =
    {
      armv5tel-linux = "./Configure linux-armv4 -march=armv5te";
      armv6l-linux = "./Configure linux-armv4 -march=armv6";
      armv7l-linux = "./Configure linux-armv4 -march=armv7-a";
      aarch64-darwin = "./Configure darwin64-arm64-cc";
      x86_64-linux = "./Configure linux-x86_64";
      x86_64-solaris = "./Configure solaris64-x86_64-gcc";
      powerpc-linux = "./Configure linux-ppc";
      powerpc64-linux = "./Configure linux-ppc64";
      riscv32-linux = "./Configure linux-latomic";
      riscv64-linux = "./Configure linux64-riscv64";
    }
    .${stdenv.hostPlatform.system} or (
      if stdenv.hostPlatform == stdenv.buildPlatform then
        "./config"
      else if stdenv.hostPlatform.isBSD then
        if stdenv.hostPlatform.isx86_64 then
          "./Configure BSD-x86_64"
        else if stdenv.hostPlatform.isx86_32 then
          "./Configure BSD-x86" + lib.optionalString stdenv.hostPlatform.isElf "-elf"
        else
          "./Configure BSD-generic${toString stdenv.hostPlatform.parsed.cpu.bits}"
      else if stdenv.hostPlatform.isMinGW then
        "./Configure mingw${
          lib.optionalString (stdenv.hostPlatform.parsed.cpu.bits != 32) (
            toString stdenv.hostPlatform.parsed.cpu.bits
          )
        }"
      else if stdenv.hostPlatform.isLinux then
        if stdenv.hostPlatform.isx86_64 then
          "./Configure linux-x86_64"
        else if stdenv.hostPlatform.isMicroBlaze then
          "./Configure linux-latomic"
        else if stdenv.hostPlatform.isMips32 then
          "./Configure linux-mips32"
        else if stdenv.hostPlatform.isMips64n32 then
          "./Configure linux-mips64"
        else if stdenv.hostPlatform.isMips64n64 then
          "./Configure linux64-mips64"
        else
          "./Configure linux-generic${toString stdenv.hostPlatform.parsed.cpu.bits}"
      else if stdenv.hostPlatform.isiOS then
        "./Configure ios${toString stdenv.hostPlatform.parsed.cpu.bits}-cross"
      else if stdenv.hostPlatform.isCygwin then
        "./Configure Cygwin-${stdenv.hostPlatform.linuxArch}"
      else
        throw "Not sure what configuration to use for ${stdenv.hostPlatform.config}"
    );

  # OpenSSL doesn't like the `--enable-static` / `--disable-shared` flags.
  dontAddStaticConfigureFlags = true;
  configureFlags = [
    "shared" # "shared" builds both shared and static libraries
    "--libdir=lib"
    "--openssldir=etc/ssl"
  ]
  ++ lib.optionals withCryptodev [
    "-DHAVE_CRYPTODEV"
    "-DUSE_CRYPTODEV_DIGESTS"
  ]
  ++ lib.optional enableMD2 "enable-md2"
  ++ lib.optional enableSSL2 "enable-ssl2"
  ++ lib.optional enableSSL3 "enable-ssl3"
  # OpenSSL needs a specific `no-shared` configure flag.
  # See https://wiki.openssl.org/index.php/Compilation_and_Installation#Configure_Options
  # for a comprehensive list of configuration options.
  ++ lib.optional stdenv.hostPlatform.isAarch64 "no-afalgeng"
  ++ lib.optional withZlib "zlib"
  # /dev/crypto support has been dropped in OpenBSD 5.7.
  ++ lib.optional stdenv.hostPlatform.isOpenBSD "no-devcryptoeng"
  ++ lib.optionals (stdenv.hostPlatform.isMips && stdenv.hostPlatform ? gcc.arch) [
    # This is necessary in order to avoid openssl adding -march
    # flags which ultimately conflict with those added by
    # cc-wrapper.  Openssl assumes that it can scan CFLAGS to
    # detect any -march flags, using this perl code:
    #
    #   && !grep { $_ =~ /-m(ips|arch=)/ } (@{$config{CFLAGS}})
    #
    # The following bogus CFLAGS environment variable triggers the
    # the code above, inhibiting `./Configure` from adding the
    # conflicting flags.
    "CFLAGS=-march=${stdenv.hostPlatform.gcc.arch}"
  ]
  # tests are not being installed, it makes no sense
  # to build them if check is disabled, e.g. on cross.
  ++ lib.optional (!finalAttrs.finalPackage.doCheck) "disable-tests";

  makeFlags = [
    "MANDIR=$(man)/share/man"
    # This avoids conflicts between man pages of openssl subcommands (for
    # example 'ts' and 'err') man pages and their equivalent top-level
    # command in other packages (respectively man-pages and moreutils).
    # This is done in ubuntu and archlinux, and possibly many other distros.
    "MANSUFFIX=ssl"
  ];

  enableParallelBuilding = true;

  doCheck = true;
  preCheck = ''
    patchShebangs util
  '';

  __darwinAllowLocalNetworking = true;

  postInstall = ''
    # If we're building dynamic libraries, then don't install static
    # libraries.
    if [ -n "$(echo $out/lib/*.so $out/lib/*.dylib $out/lib/*.dll)" ]; then
        rm "$out/lib/"*.a
    fi

    mkdir -p $bin
    mv $out/bin $bin/bin

  ''
  + lib.optionalString useBinaryWrapper
    # makeWrapper is broken for windows cross (https://github.com/NixOS/nixpkgs/issues/120726)
    ''
      # c_rehash is a legacy perl script with the same functionality
      # as `openssl rehash`
      # this wrapper script is created to maintain backwards compatibility without
      # depending on perl
      makeWrapper $bin/bin/openssl $bin/bin/c_rehash \
        --add-flags "rehash"
    ''
  + ''

    mkdir $dev
    mv $out/include $dev/

    # remove dependency on Perl at runtime
    rm -r $out/etc/ssl/misc

    rmdir $out/etc/ssl/{certs,private}
  ''
  + lib.optionalString (conf != null) ''
    cat ${conf} > $out/etc/ssl/openssl.cnf
  '';

  postFixup = lib.optionalString (!stdenv.hostPlatform.isWindows) ''
    # Check to make sure the main output doesn't depend on perl
    if grep -r '${buildPackages.perl}' $out; then
      echo "Found an erroneous dependency on perl ^^^" >&2
      exit 1
    fi
  '';

  strictDeps = true;
  __structuredAttrs = true;

  meta = {
    homepage = "https://www.openssl.org/";
    changelog = "https://github.com/openssl/openssl/blob/openssl-${finalAttrs.version}/CHANGES.md";
    donationPage = "https://openssl.foundation/donate/ways-to-give";
    description = "Cryptographic library that implements the SSL and TLS protocols";
    license = lib.licenses.openssl;
    mainProgram = "openssl";
    maintainers = with lib.maintainers; [ thillux ];
    teams = [ lib.teams.security-review ];
    pkgConfigModules = [
      "libcrypto"
      "libssl"
      "openssl"
    ];
    platforms = lib.platforms.all;
    identifiers.cpeParts = lib.meta.cpeFullVersionWithVendor "openssl" finalAttrs.version;
  };
})
