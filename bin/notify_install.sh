#!/bin/bash

mkdir ~/.config/sounds/
curl https://raw.githubusercontent.com/freethinkel/dotfiles/refs/heads/master/sounds/BitcoinAlert.mp3 --output ~/.config/sounds/

curl https://raw.githubusercontent.com/freethinkel/dotfiles/refs/heads/master/bin/notify --output /usr/bin/
chmod +x /usr/bin/notify
