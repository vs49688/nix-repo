self: super: {
  crocutils = super.callPackage ./pkgs/crocutils { };

  extract-drs = super.callPackage ./pkgs/extract-drs { };

  extract-glb = super.callPackage ./pkgs/extract-glb { };

  pimidid = super.callPackage ./pkgs/pimidid { };

  jdownloader = super.callPackage ./pkgs/jdownloader {
    ##
    # Needs to be built with max 11:
    #   [javac] error: Source option 6 is no longer supported. Use 7 or later.
    #   [javac] error: Target option 6 is no longer supported. Use 7 or later.
    ##
    jdk = super.jdk11;
  };

  mangostwo-server = super.callPackage ./pkgs/mangostwo-server { };

  mangostwo-database = super.callPackage ./pkgs/mangostwo-database { };

  ancestris = super.callPackage ./pkgs/ancestris { };

  k0sctl = super.callPackage ./pkgs/k0sctl { };

  zane-scripts = super.callPackages ./pkgs/zane-scripts { };

  terraform-bin_1_0 = super.callPackage ./pkgs/terraform-bin_1_0 { };

  terraform-bin = self.terraform-bin_1_0;

  clion-2018_3 = super.callPackage ./pkgs/clion-2018_3 {
    jdk = super.openjdk11;
  };

  jpsxdec = super.callPackage ./pkgs/jpsxdec {
    jdk = super.openjdk8;
  };
}
