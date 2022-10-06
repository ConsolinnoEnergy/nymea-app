#!/bin/bash
cd nymea-app
rm -rf snap
rm -rf overlay
cp -r ../nymea-app-consolinno-overlay overlay
rm version.txt | ln -s overlay/version.txt version.txt
ln -s overlay/packaging/ubuntu/snap snap
sg lxd -c 'snapcraft --use-lxd'
