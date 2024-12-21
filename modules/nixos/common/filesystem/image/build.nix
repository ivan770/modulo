{
  config,
  lib,
  modulesPath,
  pkgs,
  ...
}: let
  inherit (pkgs.hostPlatform) efiArch;

  cfg = config.modulo.filesystem.image;

  version = builtins.toString cfg.version;
  uki = "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
in {
  imports = ["${modulesPath}/image/repart.nix"];

  config = lib.mkIf (config.modulo.filesystem.type == "image") {
    # FIXME: Add compression
    image.repart = {
      inherit version;
      inherit (cfg) name;

      split = true;

      partitions = {
        "10-esp" = {
          contents = {
            # systemd-boot is not meant to be updated OTA
            "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source = "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
            "/EFI/Linux/${cfg.name}_${version}.efi".source = uki;
          };

          repartConfig = {
            Type = "esp";
            Format = "vfat";

            SizeMinBytes = cfg.partitions.esp.size;
            SizeMaxBytes = cfg.partitions.esp.size;

            # UKI updates are provisioned using EFI files
            SplitName = "-";
          };
        };

        "20-store" = {
          storePaths = [config.system.build.toplevel];
          stripNixStorePrefix = true;
          repartConfig = {
            Type = "linux-generic";
            Label = "${cfg.name}_${version}";
            Format = "erofs";
            Minimize = "best";
            ReadOnly = true;
            SplitName = "store-${efiArch}";
          };
        };
      };
    };

    system.build.updatePackage = let
      inherit (config.system.build) image;
    in
      pkgs.stdenvNoCC.mkDerivation {
        inherit version;

        pname = "update-package";

        buildCommand = ''
          mkdir -p $out
          cd $out

          ln -s "${uki}" "${cfg.name}_${version}.efi"
          ln -s "${image}/${cfg.name}_${version}.raw" "${cfg.name}_${version}.raw"
          ln -s "${image}/${cfg.name}_${version}.store-${efiArch}.raw" "${cfg.name}_${version}.store-${efiArch}.raw"
          sha256sum * > SHA256SUMS
        '';
      };
  };
}
