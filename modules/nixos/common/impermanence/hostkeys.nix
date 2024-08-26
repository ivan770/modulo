{config, ...}: let
  cfg = config.modulo.impermanence;
in {
  # sops-nix executes secretsForUsers before impermanence module activation,
  # leading to incorrect user password provision on startup.
  # To fix this behaviour, host keys can be simply moved to persistent directory explicitly.
  config.services.openssh.hostKeys = [
    {
      bits = 4096;
      path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_rsa_key";
      type = "rsa";
    }
    {
      path = "${cfg.persistentDirectory}/etc/ssh/ssh_host_ed25519_key";
      type = "ed25519";
    }
  ];
}
