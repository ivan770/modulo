{lib, ...}: final: _: let
  inherit (lib) attrsets mapAttrs splitString substituteDeps;
in {
  substituteDeps = package: attrs:
    package.override (
      mapAttrs (
        name: drv: let
          path = splitString "." name;
        in
          attrsets.attrByPath
          path (
            attrsets.attrByPath
            path (substituteDeps drv attrs)
            final
          )
          attrs
      )
    );
}
