##
# For personal machines.
##
{ config, pkgs, lib, ...}:
{
  imports = [
    ./settings
  ];

  nix.settings = {
    substituters = ["https://nix-gaming.cachix.org"];
    trusted-public-keys = ["nix-gaming.cachix.org-1:nbjlureqMbRAxR1gJ/f3hxemL9svXaZF/Ees8vCUUs4="];
  };

  programs.firefox.package = pkgs.librewolf;

  programs.firefox.policies = {
    SearchBar = "unified";

    HttpsOnlyMode = "force_enabled";
  };

  programs.firefox.preferences = {
    # Force popups to open in a new window/tab.
    "browser.link.open_newwindow.restriction" = 0;

    # Stop sites attempting to register a mail handler.
    # https:#bugzilla.mozilla.org/show_bug.cgi?id=668577
    "network.protocol-handler.external.mailto" = false;

    # Disable Carat Browsing.
    "accessibility.browsewithcaret_shortcut.enabled" = false;

    # Disable search suggestions.
    "browser.search.suggest.enabled" = false;
    "browser.urlbar.suggest.searches" = false;
    "browser.urlbar.showSearchSuggestionsFirst" = false;
    "browser.search.suggest.enabled.private" = false;

    # Stop auto-updating search plugins.
    "browser.search.update" = false;

    # Attempt to kill "activity stream" altogether.
    "browser.newtabpage.activity-stream.enabled" = false;

    # Remove Amazon, Google, etc. from top sites.
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts" = false;
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.havePinned" = "";
    "browser.newtabpage.activity-stream.improvesearch.topSiteSearchShortcuts.searchEngines" = "";

    "browser.newtabpage.activity-stream.showSponsored" = false;

    "browser.newtabpage.activity-stream.discoverystream.enabled" = false;

    # Show Search
    "browser.newtabpage.activity-stream.showSearch" = true;

    # Hide Top Sites
    "browser.newtabpage.activity-stream.feeds.topsites" = false;
    "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;

    # Disable "Recent Activity"
    "browser.newtabpage.activity-stream.feeds.section.highlights" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeBookmarks" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeDownloads" = false;
    "browser.newtabpage.activity-stream.section.highlights.includeVisited" = false;

    # Disable "Snippets"
    "browser.newtabpage.activity-stream.feeds.snippets" = false;

    # Don't suggest anything.
    "browser.urlbar.sponsoredTopSites" = false;
    "browser.urlbar.suggest.quicksuggest.nonsponsored" = false;
    "browser.urlbar.suggest.quicksuggest.sponsored" = false;

    # We're using custom privacy options.
    "privacy.history.custom" = true;
    "places.history.enabled" = false;  # "Remember browsing and download history".
    "browser.formfill.enable" = false; # "Remember search and form history"
    # TODO: configure "Clear history when Firefox closes"
    # privacy.sanitize.sanitizeOnShutdown

    # Don't add the "Import" button to bookmarks.
    "browser.bookmarks.addedImportButton" = true;

    # Don't warn for about:config
    "browser.aboutConfig.showWarning" = false;

    # Remove YT, Facebook, Wikipedia, Reddit, Amazon, and Twitter from the defualt sites.
    "browser.newtabpage.activity-stream.default.sites" = "";

    # Add back the split URL/search bar.
    "browser.search.widget.inNavBar" = true;
  };

  users.users.${config.settings.primaryUser.username} = {
    packages = with pkgs; [

    ] ++ (with zane-scripts; [
      fuckcue
      pdfreduce
      rarfix
      ofxfix
      flalac
      alflac
    ]);
  };

  fonts.packages = with pkgs; [
    ipafont
  ];

  environment.systemPackages = with pkgs; [
    # Internet
    qbittorrent
    transmission_4-qt
    weechat

    # Office
    # gnucash
    # gramps

    # Audio/Video
    picard
    obs-studio

    # CLI Tools
    shntool
    cuetools
    bchunk
    flac
    unrar

    # Misc
    gargoyle

    bitwarden

    metasploit
  ] ++ (lib.optionals hostPlatform.isx86_64 [
    tor-browser

    ##
    # Wine and friends
    ##
    wineWowPackages.stagingFull
    winetricks

    signal-desktop

    # Not licensed to use this for work
    _010editor
  ]);
}
