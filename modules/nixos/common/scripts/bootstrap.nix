{
  config,
  lib,
  inputs,
  pkgs,
  ...
}: let
  inherit
    (lib)
    concatMapStrings
    concatStringsSep
    findFirst
    getExe
    head
    length
    isAttrs
    isInt
    optionalString
    splitString
    take
    ;
in {
  system.build.modulo.bootstrap = pkgs.writeShellScript "bootstrap" (let
    # This assumes that all SSH host keys are stored under the same directory.
    hostKeyPath = let
      path = splitString "/" (head config.services.openssh.hostKeys).path;
    in
      concatStringsSep "/" (take (length path - 1) path);

    hostKeyGenerator =
      concatMapStrings (
        {
          bits ? null,
          path,
          type,
          ...
        }: "${pkgs.openssh}/bin/ssh-keygen -q -N \"\" -t ${type} ${optionalString (isInt bits) "-b ${(toString bits)}"} -f /mnt${path}\n"
      )
      config.services.openssh.hostKeys;

    suitableHostKey = let
      key = findFirst ({type, ...}: type == "ed25519") null config.services.openssh.hostKeys;
    in
      optionalString (isAttrs key) ''
        age=$(cat /mnt/${key.path}.pub | ${getExe pkgs.ssh-to-age})
        echo "Found suitable SSH host key. Age key value: $age"
      '';
  in ''
    echo "Running format script..."
    ${config.system.build.formatScript}

    echo "Running mount script..."
    ${config.system.build.mountScript}

    echo "Creating persistent directory..."
    mkdir -p /mnt${config.modulo.impermanence.persistentDirectory}

    read -p "Generate new SSH host keys? " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]
    then
      echo "Generating new SSH host keys..."

      mkdir -p /mnt${hostKeyPath}
      ${hostKeyGenerator}
      ${suitableHostKey}
    fi

    echo "Starting new shell for you to apply new configuration..."
    echo "nixos-install will be invoked as soon as you exit this shell."
    ${getExe pkgs.bashInteractive}

    echo "Running nixos-install..."
    ${getExe config.system.build.nixos-install} \
      --flake ${inputs.self}#${config.networking.hostName} \
      --no-root-passwd
  '');
}
