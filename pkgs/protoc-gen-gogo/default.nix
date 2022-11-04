{ buildGoModule, fetchFromGitHub, lib }:
buildGoModule rec {
  pname = "protoc-gen-gogo";
  version = "1.3.2";

  src = fetchFromGitHub {
    owner = "gogo";
    repo = "protobuf";
    rev = "v${version}";
    sha256 = "sha256-CoUqgLFnLNCS9OxKFS7XwjE17SlH6iL1Kgv+0uEK2zU=";
  };

  vendorSha256 = "sha256-nOL2Ulo9VlOHAqJgZuHl7fGjz/WFAaWPdemplbQWcak=";

  # FIXME
  doCheck = false;

  excludedPackages = [ "conformance" "mixbench" ];

  meta = with lib; {
    description = "Protocol Buffers for Go with Gadgets";
    homepage = "https://github.com/gogo/protobuf";
    platforms = platforms.all;
    maintainers = [ maintainers.zane ];
  };
}
