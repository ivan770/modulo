_: {
  modulo = {
    filesystem = {
      type = "image";
      image = {
        version = 1;
        device = "/dev/sda";
        partitions.store.size = "2G";
      };
    };
    firmware.cpu.vendor = null;
    headless.enable = true;
  };

  boot.kernelParams = [
    "console=tty0"
    "console=ttyS0,9600n8"
    "systemd.log_level=info"
    "systemd.log_target=console"
    "systemd.journald.forward_to_console=1"
  ];

  users.users.root.password = "cleartestpassword";

  system.stateVersion = "24.11";
}
