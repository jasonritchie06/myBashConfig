#!/bin/bash
# Download and import my Gnome settings
wget -O /tmp/saved_settings.dconf https://raw.githubusercontent.com/jasonritchie06/myBashConfig/refs/heads/main/saved_settings.dconf
dconf load -f / < /tmp/saved_settings.dconf
rm -rf /tmp/saved_settings.dconf