{
  isTrue = value: builtins.isBool value && value;
  isFalse = value: builtins.isBool value && !value;
}
