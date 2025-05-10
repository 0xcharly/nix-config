{
  nixpkgs.overlays = [
    (final: prev: let
      overrideCommandLineArgs = pkg:
        pkg.override {
          # Fix hardware acceleration detection by forcing the use of the discrete (AMD) GPU.
          # https://nixos.wiki/wiki/Chromium
          commandLineArgs = [
            "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
          ];
        };
    in {
      google-chrome = overrideCommandLineArgs prev.google-chrome;
      ungoogled-chromium = overrideCommandLineArgs prev.ungoogled-chromium;
    })
  ];
}
