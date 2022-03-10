{ lib, buildGoModule, fetchFromGitHub }:
buildGoModule rec {
  pname = "kafkactl";
  version = "2.2.0";

  src = fetchFromGitHub {
    owner = "deviceinsight";
    repo = "kafkactl";
    rev = "v${version}";
    sha256 = "sha256-og1DnNy3p07bPCNBmVkBSBE5neaCIts6R21hVeKajg0=";
  };

  vendorSha256 = "sha256-BpwzB/zxcpKB/YPayOwGZ6S6JTAABscGpNu8nymIzJc=";

  doCheck = false;

  meta = with lib; {
    description = "Command Line Tool for managing Apache Kafka";
    homepage = "https://github.com/jbvmio/kafkactl";
    license = licenses.asl20;
    platforms = platforms.all;
    maintainers = with maintainers; [ zane ];
  };
}
