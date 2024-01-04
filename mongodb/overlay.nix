final: prev: {
  mongodb_3_6-bin = prev.callPackage ./mongodb-bin.nix {
    version = "3.6.23";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-3.6.23.tgz";
      sha256 = "sha256-woT7k+A5WVyQFwzUuo8ruU/8YVMn9b9QWsWy/j9qW+U=";
    };
  };

  mongodb_4_0-bin = prev.callPackage ./mongodb-bin.nix {
    version = "4.0.28";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.0.28.tgz";
      sha256 = "sha256-vWUeyFwua/tJazIllQcNj9caPESNzVFCBweV3egaKHI=";
    };
  };

  mongodb_4_2-bin = prev.callPackage ./mongodb-bin.nix {
    version = "4.2.25";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.2.25.tgz";
      sha256 = "sha256-4+4H9HRiJGAY+rvlrSIyk7zCYjEKU4HB13TJPgSoYbE=";
    };
  };

  mongodb_4_4-bin = prev.callPackage ./mongodb-bin.nix {
    version = "4.4.27";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-4.4.27.tgz";
      sha256 = "sha256-j/ucnmxHpVNZyrFyJ3ceI/2DKjxEu68eX5x4+DMl2Zk=";
    };
  };

  mongodb_5_0-bin = prev.callPackage ./mongodb-bin.nix {
    version = "5.0.23";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-5.0.23.tgz";
      sha256 = "sha256-UqgY/PO0w++4duMlTJ8v55Hs8HcxrPmIIKNanYJ/icA=";
    };
  };

  mongodb_6_0-bin = prev.callPackage ./mongodb-bin.nix {
    version = "6.0.12";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-6.0.12.tgz";
      sha256 = "sha256-X9EWIdsx3AIK3rORLzf+rvolVdBD2NomKA29EglDoOE=";
    };
  };
}
