{ lib, sloth, ... }:
{
  etc.sslCertificates.enable = lib.mkDefault true;

  bubblewrap = {
    bind = {
      rw = [
        [
          (sloth.mkdir (sloth.concat' sloth.appDir "/tmp"))
          "/tmp"
        ]
      ];

      ro = [
        [
          (sloth.concat' sloth.homeDir' "/.XCompose")
          (sloth.concat' sloth.homeDir "/.XCompose")
        ]
      ];
    };

    bindEntireStore = lib.mkDefault false;
  };
}
