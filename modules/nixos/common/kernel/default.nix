_: {
  boot.kernel.sysctl = {
    # Disable "Magic SysRq key"
    "kernel.sysrq" = 0;
  };

  # Disable hibernation and kexec on a booted system.
  security.protectKernelImage = true;
}
