{ lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "kubefwd";
  version = "1.22.0";

  src = fetchFromGitHub {
    owner = "txn2";
    repo = "kubefwd";
    rev = version;
    sha256 = "sha256-210kYLncQQ9gVGiRUsx97wwC5UpZwNF3gDugxugHuCc=";
  };

  vendorSha256 = "sha256-t7gjQRKAXLFArdFcko6HQVz/SVSCTNOf+AJEvBtcc4U=";

  doCheck = false;

  meta = with lib; {
    description = "Bulk port forwarding Kubernetes services for local development";
    homepage = "https://github.com/txn2/kubefwd";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
