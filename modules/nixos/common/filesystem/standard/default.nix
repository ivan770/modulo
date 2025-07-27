{
  config,
  inputs,
  lib,
  ...
}:
let
  inherit (lib)
    attrNames
    concatStringsSep
    filterAttrs
    length
    mapAttrs
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optional
    removePrefix
    replaceStrings
    types
    ;

  cfg = config.modulo.filesystem;
in
{
  options.modulo.filesystem = {
    disks = mkOption {
      type = types.attrsOf (
        types.submodule {
          options = {
            boot = {
              enable = mkOption {
                type = types.bool;
                default = true;
                description = ''
                  Determine whether to create a bootable vfat partition.
                '';
              };

              size = mkOption {
                type = types.str;
                default = "512MiB";
                description = ''
                  Bootable partition size.
                '';
              };

              mountpoint = mkOption {
                type = types.str;
                default = config.modulo.boot.systemd-boot.mountpoint;
                description = ''
                  Boot partition mountpoint.
                '';
              };
            };

            encrypted = mkOption {
              type = types.bool;
              default = true;
              description = ''
                Determine whether to encrypt disk using LUKS.
              '';
            };

            partitions = mkOption {
              type = types.attrsOf (
                types.submodule {
                  options = {
                    preset = mkOption {
                      type = types.str;
                      description = ''
                        Partition preset name.
                      '';
                    };

                    args = mkOption {
                      type = types.attrs;
                      default = { };
                      description = ''
                        Preset arguments.
                      '';
                    };
                  };
                }
              );
              description = ''
                LVM pool configuration.
              '';
            };

            ioScheduler = mkOption {
              type = types.str;
              default = "none";
              description = ''
                IO scheduler used for this disk.
              '';
            };
          };
        }
      );
      default = { };
      description = ''
        Activated disks.
      '';
    };

    root = {
      size = mkOption {
        type = types.str;
        default = "6G";
        description = ''
          tmpfs root partition max size.
        '';
      };
    };

    udisks2 = mkEnableOption "udisks2 daemon";
  };

  imports = [
    inputs.disko.nixosModules.disko
  ];

  config =
    let
      mkLUKSName = device: "crypt" + (replaceStrings [ "/" ] [ "-" ] device);
    in
    mkIf (config.modulo.filesystem.type == "standard") {
      boot =
        let
          encryptedDisks = filterAttrs (_: options: options.encrypted) cfg.disks;
        in
        {
          kernelParams =
            optional (length (attrNames encryptedDisks) != 0) "rd.luks.options=timeout=0"
            # Mask to prevent failed mount on /dev/gpt-auto-root
            ++ [ "systemd.gpt_auto=0" ];

          initrd.luks.devices = mapAttrs' (
            device: _:
            nameValuePair (mkLUKSName device) {
              allowDiscards = true;
              bypassWorkqueues = true;
              crypttabExtraOpts = [ "fido2-device=auto" ];
            }
          ) encryptedDisks;
        };

      disko.devices =
        let
          mkVolumeGroupName = device: "vg" + (replaceStrings [ "/" ] [ "-" ] device);

          presets =
            let
              mkFsOptions = options: "-O " + (concatStringsSep "," options);

              ext4 =
                {
                  mountpoint,
                  size ? "100%FREE",
                  encrypted,
                  ...
                }:
                {
                  inherit size;

                  content = {
                    inherit mountpoint;

                    type = "filesystem";
                    format = "ext4";
                    mountOptions = [
                      "noatime"
                      "commit=30"
                    ]
                    ++ optional encrypted "x-systemd.device-timeout=0";
                  };
                };

              f2fs =
                {
                  mountpoint,
                  size ? "100%FREE",
                  encrypted,
                  ...
                }:
                {
                  inherit size;

                  content = {
                    inherit mountpoint;

                    type = "filesystem";
                    format = "f2fs";
                    mountOptions = [
                      "compress_algorithm=zstd:6"
                      "compress_chksum"
                      "atgc"
                      "gc_merge"
                      "lazytime"
                      "noatime"
                    ]
                    ++ optional encrypted "x-systemd.device-timeout=0";
                    extraArgs = [
                      (mkFsOptions [
                        "extra_attr"
                        "inode_checksum"
                        "sb_checksum"
                        "compression"
                      ])
                    ];
                  };
                };
            in
            {
              inherit ext4 f2fs;

              ext4-nix =
                args:
                ext4 (
                  args
                  // {
                    mountpoint = "/nix";
                  }
                );

              f2fs-nix =
                args:
                f2fs (
                  args
                  // {
                    mountpoint = "/nix";
                  }
                );

              swap =
                {
                  size ? "8G",
                  ...
                }:
                {
                  inherit size;

                  content.type = "swap";
                };
            };

          lvm_vg = mapAttrs' (
            device: options:
            nameValuePair (mkVolumeGroupName device) {
              type = "lvm_vg";
              lvs = mapAttrs (
                _: lvOptions:
                presets.${lvOptions.preset} (
                  lvOptions.args
                  // {
                    inherit (options) encrypted;
                  }
                )
              ) options.partitions;
            }
          ) cfg.disks;

          disk = mapAttrs (device: options: {
            inherit device;

            type = "disk";
            content = {
              type = "gpt";
              partitions = {
                ESP = mkIf options.boot.enable {
                  label = "ESP";
                  priority = 1;
                  type = "EF00";
                  start = "1MiB";
                  end = options.boot.size;
                  content = {
                    inherit (options.boot) mountpoint;

                    type = "filesystem";
                    format = "vfat";
                    mountOptions = [ "umask=0077" ];
                  };
                };
                DATA =
                  let
                    wrapLUKS =
                      content:
                      if options.encrypted then
                        {
                          inherit content;

                          type = "luks";
                          name = mkLUKSName device;
                          extraOpenArgs = [ "--allow-discards" ];
                        }
                      else
                        content;
                  in
                  {
                    label = "DATA";
                    size = "100%";
                    content = wrapLUKS {
                      type = "lvm_pv";
                      vg = mkVolumeGroupName device;
                    };
                  };
              };
            };
          }) cfg.disks;
        in
        {
          inherit lvm_vg disk;

          nodev."/" = {
            fsType = "tmpfs";
            mountOptions = [
              "size=${cfg.root.size}"
              "mode=755"
              "nodev"
              "nosuid"
            ];
          };
        };

      services = {
        udev.extraRules =
          let
            rules = mapAttrsToList (
              name:
              { ioScheduler, ... }:
              concatStringsSep ", " [
                ''ACTION=="add|change"''
                ''KERNEL=="${removePrefix "/dev/" name}"''
                ''ATTR{queue/scheduler}="${ioScheduler}"''
              ]
            ) cfg.disks;
          in
          concatStringsSep "\n" rules;

        udisks2.enable = mkIf cfg.udisks2 true;
      };
    };
}
