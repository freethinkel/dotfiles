// Firefox user.js - Custom preferences
// Place this file in your Firefox profile folder to apply settings
// Profile location: ~/Library/Application Support/Firefox/Profiles/<profile-name>/

// === PRIVACY & SECURITY ===
user_pref("browser.safebrowsing.downloads.enabled", false);
user_pref("browser.safebrowsing.malware.enabled", false);
user_pref("browser.safebrowsing.phishing.enabled", false);
user_pref("dom.security.https_only_mode_ever_enabled", true);

// === UI / APPEARANCE ===
user_pref("browser.tabs.drawInTitlebar", true);
user_pref("browser.toolbars.bookmarks.visibility", "never");
user_pref("browser.theme.toolbar-theme", 0);
user_pref("sidebar.verticalTabs", true);
user_pref("sidebar.revamp", true);
user_pref("sidebar.animation.enabled", false);
user_pref("sidebar.visibility", "hide-sidebar");

// === BEHAVIOR ===
user_pref("browser.ctrlTab.sortByRecentlyUsed", true);
user_pref("browser.warnOnQuitShortcut", false);
user_pref("browser.shell.checkDefaultBrowser", false);
user_pref("browser.download.autohideButton", false);

// === NEW TAB PAGE ===
user_pref("browser.newtabpage.activity-stream.feeds.section.highlights", true);
user_pref("browser.newtabpage.activity-stream.topSitesRows", 2);

// === SEARCH ===
user_pref("browser.urlbar.placeholderName", "Google");

// === LANGUAGE ===
user_pref("intl.accept_languages", "ru,en");

// === PERFORMANCE ===
user_pref("layers.acceleration.force-enabled", true);

// === DEVTOOLS ===
user_pref("devtools.toolbox.selectedTool", "netmonitor");

// === ADVANCED / CUSTOM STYLING ===
user_pref("toolkit.legacyUserProfileCustomizations.stylesheets", true);
user_pref("svg.context-properties.content.enabled", true);
user_pref("mozilla.widget.use-argb-visuals", true);

// === PRIVACY ===
user_pref("privacy.clearOnShutdown_v2.formdata", true);

// === SYNC (optional - remove if you don't want to auto-sync) ===
user_pref("services.sync.engine.addresses", true);
user_pref("services.sync.engine.creditcards", true);

// PIP
user_pref(
  "media.videocontrols.picture-in-picture.enable-when-switching-tabs.enabled",
  true,
);
