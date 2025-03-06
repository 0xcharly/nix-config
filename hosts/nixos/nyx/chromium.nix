{
  nixpkgs.overlays = [
    (final: prev: {
      ungoogled-chromium = prev.ungoogled-chromium.override {
        # Fix hardware acceleration detection by forcing the use of the discrete (AMD) GPU.
        commandLineArgs = [
          "--enable-features=VaapiVideoDecoder,VaapiIgnoreDriverChecks,DefaultANGLEVulkan,VulkanFromANGLE"
          "--gpu-testing-vendor-id=0x1002"
          "--gpu-testing-device-id=0x747e"
        ];
      };
    })
  ];
}
