{
  hostPlatform,
  runCommand,
}: {
  name,
  version,
  image,
  uki,
}: let
  inherit (hostPlatform) efiArch;
in
  runCommand "update-package" {} ''
    mkdir -p $out
    cd $out

    ln -s "${uki}" "${name}_${version}.efi"
    ln -s "${image}/${name}_${version}.raw" "${name}_${version}.raw"
    ln -s "${image}/${name}_${version}.store-${efiArch}.raw" "${name}_${version}.store-${efiArch}.raw"
    sha256sum * > SHA256SUMS
  ''
