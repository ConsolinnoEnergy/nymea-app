#!/bin/bash

cat > ~/.local/share/applications/consolinno-energy.desktop <<EOF
[Desktop Entry]
Name=Consolinno Hems
Comment=A client application for the Consolinno HEMS system
Icon=consolinno-energy
Terminal=true
Type=Application
Exec=/usr/bin/consolinno-energy %u
Categories=Network;
MimeType=x-scheme-handler/consolinno-energy;
EOF

mv ./Consolinno_HEMS-1-6-0-x86_64.AppImage ./consolinno-energy 

sudo cp ./consolinno-energy /usr/bin/

sudo chmod +x /usr/bin/consolinno-energy

xdg-mime default consolinno-energy.desktop x-scheme-handler/consolinno-energy

sudo update-desktop-database ~/.local/share/applications/
