{
  config,
  lib,
  ...
}: let
  inherit (lib) mkIf;

  cfg = config.modulo.filesystem.image;
  version = builtins.toString cfg.version;
in {
  config = mkIf (config.modulo.filesystem.type == "image") {
    fileSystems = {
      "/" = {
        device = "none";
        fsType = "tmpfs";
        options = ["size=${cfg.partitions.root.size}" "mode=755"];
      };

      # Required for UKI updates
      "/efi" = {
        fsType = "vfat";
        device = "/dev/disk/by-partlabel/esp";
        options = ["x-systemd.after=systemd-repart.service"];
        neededForBoot = true;
      };

      "/usr" = {
        fsType = "erofs";
        device = "/dev/disk/by-partlabel/${cfg.name}_${version}";
        options = ["x-systemd.after=systemd-repart.service"];
        neededForBoot = true;
      };

      "/nix/store" = {
        fsType = "none";
        device = "/usr";
        options = ["bind"];
        neededForBoot = true;
      };

      "/data" = {
        fsType = cfg.partitions.data.type;
        label = "data";
        options = ["x-systemd.after=systemd-repart.service"];
        neededForBoot = true;
      };
    };

    boot.initrd.systemd.repart = {
      inherit (cfg) device;

      enable = true;
    };

    systemd.repart.partitions = {
      "10-esp" = {
        Type = "esp";
        Format = "vfat";
        SizeMinBytes = cfg.partitions.esp.size;
        SizeMaxBytes = cfg.partitions.esp.size;
      };

      "20-a-store" = {
        Type = "linux-generic";
        SizeMinBytes = cfg.partitions.store.size;
        SizeMaxBytes = cfg.partitions.store.size;
      };

      "30-b-store" = {
        Type = "linux-generic";
        Label = "_empty";
        SizeMinBytes = cfg.partitions.store.size;
        SizeMaxBytes = cfg.partitions.store.size;
      };

      "40-data" = {
        Type = "linux-generic";
        Label = "data";
        Format = cfg.partitions.data.type;
        FactoryReset = true;
      };
    };

    system.image = {
      inherit version;

      id = cfg.name;
    };

    modulo.impermanence.persistentDirectory = lib.mkDefault "/data";
  };
}
