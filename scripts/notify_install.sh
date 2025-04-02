#!/bin/bash

mkdir ~/.config/sounds/
curl https://raw.githubusercontent.com/freethinkel/dotfiles/refs/heads/master/sounds/BitcoinAlert.mp3 --output ~/.config/sounds/BitcoinAlert.mp3

curl https://raw.githubusercontent.com/freethinkel/dotfiles/refs/heads/master/scripts/notify --output /usr/bin/notify
chmod +x /usr/bin/notify
