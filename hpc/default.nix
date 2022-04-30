{ lib, pkgs }: rec {
  nimrod-embedded = pkgs.callPackage ./nimrod-embedded {
    nimrun = pkgs.pkgsStatic.callPackage ../pkgs/nimrun {
      cmake = pkgs.cmake;
    };

    installPrefix = "/sw7/RCC/NimrodG";
    modulePath    = "/sw7/Modules/RCC/local";
  };

  nimrod-embedded-usq = nimrod-embedded.override rec {
    moduleName    = "nimrodg";
    modulePath    = "/usr/local/opt/modules";
    installPrefix = "/nonexistant";
    rootDir       = "/usr/local/opt/software/${moduleName}/${nimrod-embedded.version}";
  };
}
