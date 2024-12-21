{
  OVMF,
  inputs,
  qemu,
  runCommand,
  util-linux,
}: let
  systemConfig = inputs.self.nixosConfigurations.image-test.config;

  inherit (systemConfig.modulo.filesystem.image) name;
  version = builtins.toString systemConfig.modulo.filesystem.image.version;
  rawImage = "${systemConfig.system.build.image}/${name}_${version}.raw";
in
  runCommand "qemu-image-test" {
    nativeBuildInputs = [qemu util-linux];
  } ''
    fallocate -l 7G boot.raw
    dd if=${rawImage} of=boot.raw conv=notrunc

    qemu-system-x86_64 \
      -bios ${OVMF.fd}/FV/OVMF.fd \
      -smp 4 -m 4G \
      -drive format=raw,file=boot.raw \
      -nographic
  ''
