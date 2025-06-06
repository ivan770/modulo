{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;

  cfg = config.modulo.filesystem.image;
in
{
  systemd.sysupdate = mkIf (config.modulo.filesystem.type == "image" && cfg.update.enable) {
    enable = true;

    reboot.enable = cfg.update.reboot;

    transfers = {
      boot = {
        Source = {
          Type = "url-file";
          Path = cfg.update.url;
          MatchPattern = "${cfg.name}_@v.efi";
        };

        Target = {
          Type = "regular-file";
          Path = "/EFI/Linux";
          PathRelativeTo = "esp";
          MatchPattern = "${cfg.name}_@v.efi";
          Mode = "0444";
          InstancesMax = 2;
        };

        # FIXME: UKI verification
        Transfer.Verify = "false";
      };

      store = {
        Source = {
          Type = "url-file";
          Path = cfg.update.url;
          MatchPattern = "${cfg.name}_@v.store-${pkgs.hostPlatform.efiArch}.raw";
        };

        Target = {
          Type = "partition";
          Path = "auto";
          MatchPattern = "${cfg.name}_@v";
          MatchPartitionType = "linux-generic";
        };

        # FIXME: Store image verification
        Transfer.Verify = "false";
      };
    };
  };
}
