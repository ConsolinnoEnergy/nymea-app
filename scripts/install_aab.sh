#!/bin/bash
rm -f /tmp/app.apks
java -jar ~/.local/bin/bundletool-all-1.10.0.jar build-apks --bundle=$1 --output=/tmp/app.apks
java -jar ~/.local/bin/bundletool-all-1.10.0.jar  install-apks --apks /tmp/app.apks --adb=/usr/bin/adb
rm -f /tmp/app.apks
