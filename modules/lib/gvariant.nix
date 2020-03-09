# A partial and basic implementation of GVariant formatted strings.

{ lib }:

with lib;

let

  primitiveOf = t: v: {
    _type = "gvariant";
    type = t;
    value = v;
    __toString = self: "@${self.type} ${toString self.value}";
  };

in rec {

  type = {
    arrayOf = t: "a${t}";
    tupleOf = ts: "(${concatStrings ts})";
    string = "s";
    boolean = "b";
    uchar = "y";
    int16 = "n";
    uint16 = "q";
    int32 = "i";
    uint32 = "u";
    int64 = "x";
    uint64 = "t";
    double = "d";

    isArray = hasPrefix "a";
  };

  # Returns the GVariant type of a given Nix value. If no type can be
  # found for the value then the empty string is returned.
  typeOf = v:
    with type;
    if isBool v then
      boolean
    else if isInt v then
      int32
    else if builtins.isFloat v then
      double
    else if isString v then
      string
    else if isList v then
      let elemType = elemTypeOf v;
      in if elemType == "" then "" else arrayOf elemType
    else if isAttrs v && v ? type then
      v.type
    else
      "";

  elemTypeOf = vs:
    # with type;
    if isList vs then if vs == [ ] then "" else typeOf (head vs) else "";

  # valueOf = v: if isAttrs v && v ? type then v.value else v;

  array = elemType: elems:
    primitiveOf (type.arrayOf elemType) (map gvariantOf elems) // {
      __toString = self:
        "@${self.type} [${concatMapStringsSep "," toString self.value}]";
    };

  emptyArray = elemType: array elemType [ ];

  tuple = elems:
    let
      gvarElems = map gvariantOf elems;
      tupleType = type.tupleOf (map (e: e.type) gvarElems);
    in primitiveOf tupleType gvarElems // {
      __toString = self:
        "@${self.type} (${concatMapStringsSep "," toString self.value})";
    };

  booleanOf = v:
    primitiveOf type.boolean v // {
      __toString = self: if self.value then "true" else "false";
    };

  stringOf = v:
    primitiveOf type.string v // {
      __toString = self: "'${escape [ "'" ] self.value}'";
    };

  ucharOf = primitiveOf type.uchar;

  int16Of = primitiveOf type.int16;

  uint16Of = primitiveOf type.uint16;

  int32Of = v:
    primitiveOf type.int32 v // {
      __toString = self: toString self.value;
    };

  uint32Of = primitiveOf type.uint32;

  int64Of = primitiveOf type.int64;

  uint64Of = primitiveOf type.uint64;

  doubleOf = v:
    primitiveOf type.double v // {
      __toString = self: toString self.value;
    };

  gvariantOf = v:
    if isBool v then
      booleanOf v
    else if isInt v then
      int32Of v
    else if builtins.isFloat v then
      doubleOf v
    else if isString v then
      stringOf v
    else if isList v then
      if v == [ ] then array type.string [ ] else array (elemTypeOf v) v
    else if isAttrs v && (v._type or "") == "gvariant" then
      v
    else
      null;
  # abort "Cannot convert ${generators.toPretty v} to GVariant value";

}
