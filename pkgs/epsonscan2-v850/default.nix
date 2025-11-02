{ epsonscan2 }:
epsonscan2.overrideAttrs(final: prev: {
  pname = "${prev.pname}-v850";

  patches = prev.patches ++ [
    ./0005-Fix-crash-no-serial-number.patch
    ./0001-Controller-UsbFinder-add-Perfection-V850-Pro-V800-Ph.patch
  ];
})
