{ lib, buildGoModule, fetchFromGitHub }:
let
  pname = "k0sctl";
  version = "0.10.1";
in buildGoModule {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "k0sproject";
    repo = pname;
    rev = "v${version}";
    sha256 = "1g81azccqlv1kdragcxpapshcj0lpp38mgyfsjxvgl7xc5yd8mjm";
  };

  vendorSha256 = "049l9n0aja0xj6qqk2v2y411sim3xddq1w08ywp7sj4sd1jhx9hq";

  buildFlagsArray = ''
    -ldflags=
    -X github.com/k0sproject/k0sctl/version.Environment=production
    -X github.com/k0sproject/k0sctl/version.GitCommit=v${version}
    -X github.com/k0sproject/k0sctl/version.Version=v${version}
  '';

  meta = with lib; {
    description = "A bootstrapping and management tool for k0s clusters";
    homepage = "https://k0sproject.io/";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
