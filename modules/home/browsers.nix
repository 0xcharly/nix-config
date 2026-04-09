{ flake, ... }:
{
  imports = [
    flake.modules.home.browser-google-chrome
  ];

  xdg.mimeApps =
    let
      browserList = [ "google-chrome.desktop" ];

      associations = builtins.listToAttrs (
        map
          (name: {
            inherit name;
            value = browserList;
          })
          [
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
          ]
      );
    in
    {
      enable = true;
      associations.added = associations;
      defaultApplications = associations;
    };
}
