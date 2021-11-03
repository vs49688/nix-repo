{ buildGoModule
, fetchFromGitHub
, lib
}:
buildGoModule rec {
  pname = "protoc-gen-go-vtproto";
  version = "0.2.0";

  src = fetchFromGitHub {
    owner = "planetscale";
    repo = "vtprotobuf";
    rev = "${version}";
    sha256 = "0kjjpfsiws4vi36ha1gajb97rwcggqw753mv2jqf09kdfszz9p63";
  };

  vendorSha256 = "0cak3f70pb20m6n9hskxqld0lgk00ffypkil2zxa4fcp9yc787ms";

  runVend = true;

  # conformance_test.go:55: execution error: fork/exec conformance/conformance-test-runner: no such file or directory
  doCheck = false;

  meta = with lib; {
    description = "A Protocol Buffers compiler that generates optimized marshaling & unmarshaling Go code for ProtoBuf APIv2";
    license = licenses.bsd3;
    maintainers = [ maintainers.zane ];
  };
}
