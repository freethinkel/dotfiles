.PHONY: install bt-trackpad bar-on bar-off

install:
	scripts/install.sh

# macOS: make bt-trackpad, commit scripts/bt-trackpad.key  /  Asahi: sudo make bt-trackpad
bt-trackpad:
	scripts/bt-trackpad.sh

# statusbar on/off until the next login; the agent itself comes from statusbar/build.sh
bar-on:
	launchctl bootstrap gui/$$(id -u) ~/Library/LaunchAgents/dev.freethinkel.statusbar.plist

bar-off:
	launchctl bootout gui/$$(id -u)/dev.freethinkel.statusbar
