#!/bin/bash
find ./nymea-app/ -iname "*.qml" | xargs -L1 sed -i  's/PasswordTextField {/ConsolinnoPasswordTextField {/g'
