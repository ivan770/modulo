{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe'
    mkEnableOption
    mkIf
    mkOption
    types
    ;

  cfg = config.modulo.ssh;
in
{
  options.modulo.ssh = {
    enable = mkEnableOption "SSH client support";

    autoAddToAgent = mkEnableOption "automatic key loading to ssh-agent" // {
      default = true;
    };

    matchBlocks = mkOption {
      type = types.attrs;
      default = { };
      description = ''
        Host-specific SSH configuration.
      '';
    };
  };

  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;

      inherit (cfg) matchBlocks;
    };

    systemd.user.services = {
      ssh-agent = {
        Unit.Description = "SSH authentication agent";

        Service = {
          Type = "exec";
          Environment = [ "SSH_AUTH_SOCK=%t/ssh-agent" ];
          ExecStart = "${getExe' pkgs.openssh "ssh-agent"} -D -a $SSH_AUTH_SOCK";
          ExecStartPost = [ "systemctl --user import-environment SSH_AUTH_SOCK" ];
        };

        Install.WantedBy = [ "default.target" ];
      };

      auto-ssh-add = mkIf cfg.autoAddToAgent {
        Unit = {
          Description = "Automatic key load for SSH agent";
          PartOf = [ "ssh-agent.service" ];
          After = [ "ssh-agent.service" ];
        };

        Service = {
          Type = "oneshot";
          # FIXME: Find a better way to wait for the SSH agent to initialize the socket.
          ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 2";
          ExecStart = getExe' pkgs.openssh "ssh-add";
        };

        Install.WantedBy = [ "ssh-agent.service" ];
      };
    };
  };
}
