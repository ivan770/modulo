{lib, ...}: final: _: {
  mkConfinedApp = let
    inherit (lib) concatStringsSep getExe optionals;
  in
    {
      package,
      bin ? package.meta.mainProgram,
      audio ? false,
      desktop ? false,
      gpu ? false,
      network ? false,
      locale ? true,
      envVariables ? [],
      bindConfig ? [],
      bindData ? [],
    }: let
      requiredEnvVariables =
        envVariables
        ++ (optionals locale [
          "LC_ADDRESS"
          "LC_COLLATE"
          "LC_CTYPE"
          "LC_MEASUREMENT"
          "LC_MESSAGES"
          "LC_MONETARY"
          "LC_NAME"
          "LC_NUMERIC"
          "LC_PAPER"
          "LC_TELEPHONE"
          "LC_TIME"
          "TZDIR"
        ])
        ++ (optionals desktop [
          "NIXOS_OZONE_WL"
          "QT_QPA_PLATFORM"
          "QT_WAYLAND_DISABLE_WINDOWDECORATION"
          "XCURSOR_THEME"
          "XCURSOR_SIZE"
          "WAYLAND_DISPLAY"
        ]);

      envVariablesFlags =
        map
        (var: ''--setenv ${var} "''$${var}"'')
        requiredEnvVariables;

      mkDirectories = from: to: folders:
        map
        (folder: ''--bind "${from}/${folder}" "${to}/${folder}"'')
        folders;

      desktopFlags = optionals desktop [
        "--setenv XCURSOR_PATH /cursorPath"
        ''--ro-bind "$XCURSOR_PATH" /cursorPath''
        ''--ro-bind "$XDG_RUNTIME_DIR/$WAYLAND_DISPLAY" "/runtime/$WAYLAND_DISPLAY"''
        ''--ro-bind "$XDG_CONFIG_HOME/fontconfig" /config/fontconfig''
        "--ro-bind /etc/fonts /etc/fonts"
      ];

      localeFlags = optionals locale [
        "--ro-bind /etc/zoneinfo /etc/zoneinfo"
        "--ro-bind-try /etc/localtime /etc/localtime"
      ];

      audioFlags = optionals audio [
        ''--ro-bind-try "$XDG_RUNTIME_DIR/pipewire-0" /runtime/pipewire-0''
        ''--ro-bind-try "$XDG_RUNTIME_DIR/pulse" /runtime/pulse''
      ];

      gpuFlags = optionals gpu [
        "--dev-bind /dev/dri /dev/dri"
        "--ro-bind /sys/class /sys/class"
        "--ro-bind /sys/dev/char /sys/dev/char"
        # FIXME: Hardcoded value
        "--ro-bind /sys/devices/pci0000:00 /sys/devices/pci0000:00"
        "--ro-bind /run/opengl-driver /run/opengl-driver"
      ];

      networkFlags = optionals network [
        "--share-net"
        "--ro-bind /etc/resolv.conf /etc/resolv.conf"
        "--ro-bind /run/systemd/resolve /run/systemd/resolve"
      ];

      bwrapScript = final.writeShellApplication {
        name = "bwrap-sandbox";

        text = concatStringsSep " " ([
            "exec"
            (lib.getExe final.bubblewrap)
            "--ro-bind /nix/store /nix/store"
            "--unshare-all"
            "--dev /dev"
            "--proc /proc"
            "--tmpfs /tmp"
            "--new-session"
            "--clearenv"

            # Sandboxed ~/.config directory
            "--setenv XDG_CONFIG_HOME /config"
            "--dir /config"

            # Sandboxed ~/.local/share directory
            "--setenv XDG_DATA_HOME /data"
            "--dir /data"

            # Sandboxed /run/user directory
            "--setenv XDG_RUNTIME_DIR /runtime"
            "--dir /runtime"
          ]
          ++ (mkDirectories "$XDG_CONFIG_HOME" "/config" bindConfig)
          ++ (mkDirectories "$XDG_DATA_HOME" "/data" bindData)
          ++ envVariablesFlags
          ++ desktopFlags
          ++ localeFlags
          ++ audioFlags
          ++ gpuFlags
          ++ networkFlags
          ++ [
            "${package}/bin/${bin}"
            ''"$@"''
          ]);
      };
    in
      # Replace the mainProgram binary while preserving other
      # files such as .desktop entries or application resources
      # without rebuilding the application derivation.
      final.symlinkJoin {
        name = "sandboxed-${package.pname or package.name}";
        paths = [package];
        postBuild = ''
          mv $out/bin/${bin} $out/bin/.unsandboxed-${bin}
          ln -s ${getExe bwrapScript} $out/bin/${bin}
        '';
      };
}
