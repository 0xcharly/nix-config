{
  lib,
  pkgs,
  usrlib,
  ...
} @ args: let
  inherit ((usrlib.hm.getUserConfig args).modules.usrenv) isCorpManaged isLinuxDesktop;
in
  lib.mkIf isLinuxDesktop {
    programs = {
      chromium = {
        enable = !isCorpManaged;
        package = pkgs.google-chrome;
        commandLineArgs = [
          # Enable to automatically spoof the user agent to something the JP tax site accepts.
          # "--user-agent='Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/18.2 Safari/605.1.15'"
          "--enable-features=VaapiVideoDecodeLinuxGL,VaapiVideoEncoder,Vulkan,VulkanFromANGLE,DefaultANGLEVulkan,VaapiIgnoreDriverChecks,VaapiVideoDecoder,PlatformHEVCDecoderSupport,UseMultiPlaneFormatForHardwareVideo"
        ];
        dictionaries = with pkgs; [
          hunspellDictsChromium.en_US
          hunspellDictsChromium.fr_FR
        ];
        extensions = [
          {id = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";} # 1Password
          {id = "cdglnehniifkbagbbombnjghhcihifij";} # Kagi Search
          {id = "ghmbeldphafepmbegfdlkpapadhbakde";} # Proton Pass
          {id = "dhdgffkkebhmkfjojejmpbldmpobfkfo";} # Tampermonkey
          {id = "cjpalhdlnbpafiamejdnhcphjbkeiagm";} # uBlock Origin
        ];
      };
    };

    xdg.mimeApps = lib.mkIf (!isCorpManaged) {
      defaultApplications = {
        "default-web-browser" = ["google-chrome.desktop"];
        "text/html" = ["google-chrome.desktop"];
        "text/xml" = ["google-chrome.desktop"];
        "application/xhtml+xml" = ["google-chrome.desktop"];
        "application/xhtml_xml" = ["google-chrome.desktop"];
        "application/xml" = ["google-chrome.desktop"];
        "x-scheme-handler/http" = ["google-chrome.desktop"];
        "x-scheme-handler/https" = ["google-chrome.desktop"];
        "x-scheme-handler/about" = ["google-chrome.desktop"];
        "x-scheme-handler/unknown" = ["google-chrome.desktop"];
      };
    };
  }
