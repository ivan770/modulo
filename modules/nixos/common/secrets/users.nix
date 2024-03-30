{
  config,
  lib,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs' nameValuePair;
in {
  # FIXME: Automatically assign user passwords
  config.modulo.secrets.applications = let
    mkUserSecret = user: _:
      nameValuePair "users/${user}/password" {
        neededForUsers = true;
      };
  in
    mapAttrs'
    mkUserSecret
    (filterAttrs (_: opts: opts.isNormalUser) config.users.users);
}
