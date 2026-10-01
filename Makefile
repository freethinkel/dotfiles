.PHONY: install bt-trackpad

install:
	scripts/install.sh

# macOS: make bt-trackpad, commit scripts/bt-trackpad.key  /  Asahi: sudo make bt-trackpad
bt-trackpad:
	scripts/bt-trackpad.sh
