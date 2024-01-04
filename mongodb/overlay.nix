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
    version = "4.2.23";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu1804-4.2.23.tgz";
      sha256 = "sha256-h5Y98F+LUQ7nxl6VkAKxo7H8Vnrb0IbhoKLouayiofo=";
    };
  };

  mongodb_4_4-bin = prev.callPackage ./mongodb-bin.nix {
    version = "4.4.18";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-4.4.18.tgz";
      sha256 = "sha256-iEJJccLiaS9wG26uGzXtS/OxVn6I7kOtluXrx+AHVSY=";
    };
  };

  mongodb_5_0-bin = prev.callPackage ./mongodb-bin.nix {
    version = "5.0.14";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-5.0.14.tgz";
      sha256 = "sha256-Y2v8lo27G8usxyma79sTuIafxeb3AP0OfhDKsm2QSAU=";
    };
  };

  mongodb_6_0-bin = prev.callPackage ./mongodb-bin.nix {
    version = "6.0.3";

    src = prev.fetchurl {
      url = "https://fastdl.mongodb.org/linux/mongodb-linux-x86_64-ubuntu2004-6.0.3.tgz";
      sha256 = "sha256-CpWInJ6EhqDKMLAEZJBv/9X0QhcFgpQYP3J6kZLrD+k=";
    };
  };
}
