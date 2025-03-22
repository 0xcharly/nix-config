{
  nixpkgs.overlays = [
    (final: prev: let
      overrideCommandLineArgs = pkg:
        pkg.override {
          # Fix hardware acceleration detection by forcing the use of the discrete (AMD) GPU.
          commandLineArgs = [
            "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,DefaultANGLEVulkan,VulkanFromANGLE"
            "--gpu-testing-vendor-id=0x1002"
            "--gpu-testing-device-id=0x747e"
          ];
        };
    in {
      google-chrome = overrideCommandLineArgs prev.google-chrome;
      ungoogled-chromium = overrideCommandLineArgs prev.ungoogled-chromium;
    })
  ];
}
