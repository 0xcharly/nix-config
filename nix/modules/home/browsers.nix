{flake, ...}: {
  imports = [
    flake.modules.home.google-chrome
    flake.modules.home.firefox
  ];

  xdg.mimeApps = {
    defaultApplications = let
      browserList = ["firefox.desktop" "google-chrome.desktop"];
    in {
      "default-web-browser" = browserList;
      "text/html" = browserList;
      "text/xml" = browserList;
      "application/xhtml+xml" = browserList;
      "application/xhtml_xml" = browserList;
      "application/xml" = browserList;
      "x-scheme-handler/http" = browserList;
      "x-scheme-handler/https" = browserList;
      "x-scheme-handler/about" = browserList;
      "x-scheme-handler/unknown" = browserList;
    };
  };
}
