{ lib
, dag ? import ./dag.nix { inherit lib; }
, gvariant ? import ./gvariant.nix { inherit lib; }
}:

with lib;

let

  typesDag = import ./types-dag.nix { inherit dag lib; };

  gvarLib = gvariant;

in

rec {

  inherit (typesDag) dagOf listOrDagOf;

  selectorFunction = mkOptionType {
    name = "selectorFunction";
    description =
      "Function that takes an attribute set and returns a list"
      + " containing a selection of the values of the input set";
    check = isFunction;
    merge = _loc: defs:
      as: concatMap (select: select as) (getValues defs);
  };

  overlayFunction = mkOptionType {
    name = "overlayFunction";
    description =
      "An overlay function, takes self and super and returns"
      + " an attribute set overriding the desired attributes.";
    check = isFunction;
    merge = _loc: defs:
      self: super:
        foldl' (res: def: mergeAttrs res (def.value self super)) {} defs;
  };

  fontType = types.submodule {
    options = {
      package = mkOption {
        type = types.nullOr types.package;
        default = null;
        example = literalExample "pkgs.dejavu_fonts";
        description = ''
          Package providing the font. This package will be installed
          to your profile. If <literal>null</literal> then the font
          is assumed to already be available in your profile.
        '';
      };

      name = mkOption {
        type = types.str;
        example = "DejaVu Sans 8";
        description = ''
          The family name and size of the font within the package.
        '';
      };
    };
  };

  gvariant = mkOptionType rec {
    name = "gvariant";
    description = "GVariant value";
    check = v: gvarLib.gvariantOf v != null;
    merge = loc: defs:
      let
        vals = map (d: gvarLib.gvariantOf d.value) defs;
        listType = types.listOf gvariant;
      in
        if all (x: gvarLib.type.isArray x.type && check x) vals
        then listType.merge loc defs
        else mergeOneOption loc defs;
  };

}
