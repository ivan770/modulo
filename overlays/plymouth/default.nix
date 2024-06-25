# FIXME: Remove the entire overlay as soon as a new Plymouth version gets released.
_: _: prev: {
  plymouth = prev.plymouth.overrideAttrs (_: {
    src = prev.fetchFromGitLab {
      domain = "gitlab.freedesktop.org";
      owner = "plymouth";
      repo = "plymouth";
      rev = "3ce6441aa066545f44624025b3d27d691bbda2a9";
      hash = "sha256-iZEPUs2/1KHH4fxavY/ODvkEv9x9jRnvU3Uh11XwaTQ=";
    };
  });
}
