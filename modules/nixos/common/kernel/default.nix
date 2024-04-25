_: {
  boot = {
    kernel.sysctl = {
      # Disable "Magic SysRq key"
      "kernel.sysrq" = 0;

      # Common recommendations
      "fs.suid_dumpable" = 0;
      "kernel.kptr_restrict" = 2;
      "kernel.ftrace_enabled" = false;
      "kernel.dmesg_restrict" = true;
      "kernel.unprivileged_bpf_disabled" = 1;
    };

    kernelParams = [
      # https://bugzilla.redhat.com/show_bug.cgi?id=2055118
      "page_alloc.shuffle=1"

      # Legacy feature
      "vsyscall=none"
    ];
  };

  # Disable hibernation and kexec on a booted system.
  security.protectKernelImage = true;
}
