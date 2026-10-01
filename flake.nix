{
  outputs = _: {
    nixosModules = {
      shell = import ./shell;
      sddm = import ./sddm;
    };
  };
}
