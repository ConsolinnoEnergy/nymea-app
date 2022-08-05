#!/bin/bash
hash_nymea=$(git submodule status nymea-app | cut -c2-10)
hash_overlay=$(git submodule status nymea-app-consolinno-overlay | cut -c2-10)
version_string=$(cat nymea-app-consolinno-overlay/version.txt | head -n1)
version_code=$(cat nymea-app-consolinno-overlay/version.txt | tail -n1)
echo ${version_string}-ny_${hash_nymea}-co_${hash_overlay} > nymea-app-consolinno-overlay/version.txt
echo ${version_code} >> nymea-app-consolinno-overlay/version.txt

