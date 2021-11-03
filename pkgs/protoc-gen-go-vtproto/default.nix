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
    rev = "v${version}";
    sha256 = "0kjjpfsiws4vi36ha1gajb97rwcggqw753mv2jqf09kdfszz9p63";
  };

  vendorSha256 = "01lxwlgh3y3gp22gk5qx7r60c1j63pnpi6jnri8gf2lmiiib8fdc";

  # conformance_test.go:55: execution error: fork/exec conformance/conformance-test-runner: no such file or directory
  doCheck = false;

  meta = with lib; {
    description = "A Protocol Buffers compiler that generates optimized marshaling & unmarshaling Go code for ProtoBuf APIv2";
    license = licenses.bsd3;
    maintainers = [ maintainers.zane ];
  };
}
