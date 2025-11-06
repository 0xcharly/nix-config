{flake, ...}: {config, ...}: {
  imports = [
    flake.modules.home.browser-chromium
    flake.modules.home.browser-firefox
    flake.modules.home.browser-zen
  ];

  xdg.mimeApps = let
    chromium = config.programs.chromium.finalPackage.meta.desktopFileName;
    firefox = config.programs.firefox.finalPackage.meta.desktopFileName;
    zen-browser = config.programs.zen-browser.package.meta.desktopFileName;

    browserList = [chromium firefox zen-browser];

    associations = builtins.listToAttrs (map (name: {
        inherit name browserList;
      }) [
        "application/json"
        "application/x-extension-htm"
        "application/x-extension-html"
        "application/x-extension-shtml"
        "application/x-extension-xht"
        "application/x-extension-xhtml"
        "application/xhtml+xml"
        "application/xhtml_xml"
        "application/xml"
        "text/html"
        "text/plain"
        "text/xml"
        "x-scheme-handler/about"
        "x-scheme-handler/chrome"
        "x-scheme-handler/http"
        "x-scheme-handler/https"
        "x-scheme-handler/mailto"
        "x-scheme-handler/unknown"
      ]);
  in {
    associations.added = associations;
    defaultApplications = associations;
  };
}
