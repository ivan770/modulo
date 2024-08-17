{
  config,
  lib,
  ...
}: let
  inherit (lib) filterAttrs mapAttrs mapAttrs' nameValuePair;
in {
  config = {
    modulo.secrets.applications = let
      mkUserSecret = user: _:
        nameValuePair "users/${user}/password" {
          neededForUsers = true;
        };
    in
      mapAttrs'
      mkUserSecret
      (filterAttrs (_: opts: opts.isNormalUser) config.users.users);

    users.users =
      mapAttrs
      (user: _: {
        hashedPasswordFile = config.modulo.secrets.values."users/${user}/password";
      })
      config.snowfallorg.users;
  };
}
