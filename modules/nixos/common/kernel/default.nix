_: {
  boot = {
    kernel.sysctl = {
      # Disable "Magic SysRq key"
      "kernel.sysrq" = 0;

      # Ensure that legacy TIOCSTI is unavailable
      # This prevents some bubblewrap-related attacks with untrusted code.
      "dev.tty.legacy_tiocsti" = false;

      # Common recommendations
      "fs.protected_fifos" = 2;
      "fs.protected_regular" = 2;
      "fs.suid_dumpable" = 0;
      "dev.tty.ldisc_autoload" = false;
      "kernel.kptr_restrict" = 2;
      "kernel.ftrace_enabled" = false;
      "kernel.dmesg_restrict" = true;
      "kernel.perf_event_paranoid" = 3;
      "kernel.unprivileged_bpf_disabled" = 1;
      "kernel.yama.ptrace_scope" = 2;
    };

    kernelParams = [
      # https://bugzilla.redhat.com/show_bug.cgi?id=2055118
      "page_alloc.shuffle=1"
      "randomize_kstack_offset=1"

      # Legacy features
      "vsyscall=none"
      "ia32_emulation=0"

      # Debugfs is unused in this configuration
      "debugfs=off"
    ];
  };

  # Disable hibernation and kexec on a booted system.
  security.protectKernelImage = true;
}
