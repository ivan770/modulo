{ juce, rnnoise-plugin }:
rnnoise-plugin.overrideAttrs (old: {
  cmakeFlags = [
    "-DUSE_SYSTEM_JUCE=ON"
    "-DBUILD_FOR_RELEASE=ON"
    "-DBUILD_VST_PLUGIN=OFF"
    "-DBUILD_VST3_PLUGIN=OFF"
    "-DBUILD_LV2_PLUGIN=OFF"
  ];

  outputs = [ "out" ];

  buildInputs = (old.buildInputs or [ ]) ++ [ juce ];

  # rnnoise README file recommends using target-specific optimizations.
  # These flags are somewhat arbitrary though.
  NIX_CFLAGS_COMPILE = (old.NIX_CFLAGS_COMPILE or [ ]) ++ [
    "-march=znver3"
    "-mtune=znver4"
  ];

  # Default postInstall includes separate outputs for plugins,
  # but since we build one plugin in the first place, just rely on $out.
  postInstall = "";
})
