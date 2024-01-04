final: prev: {
  mongodb_3_6-bin = prev.callPackage ./mongodb-bin.nix {
    version = "3.6.23";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-3.6.23.tgz";
      sha256 = "sha256-woT7k+A5WVyQFwzUuo8ruU/8YVMn9b9QWsWy/j9qW+U=";
    };
  };
}
