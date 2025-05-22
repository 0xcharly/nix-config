{
  getUserConfig = args:
    if args ? osConfig
    then args.osConfig
    else args.config;
}
