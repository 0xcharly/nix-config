{
  mkNoQuarantine = name: {
    inherit name;
    args.no_quarantine = true;
  };
}
