{ ... }: {
  boot.kernelParams = [
    # Make the function keys function.
    "hid_apple.fnmode=2"
  ];
}
