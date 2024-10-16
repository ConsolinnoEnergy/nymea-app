#!/bin/bash
# check if rsvg-convert is installed
if ! command -v rsvg-convert &> /dev/null; then
    echo "Error: rsvg-convert is not installed. Please install it and try again."
    exit 1
fi
# Check if the correct number of arguments are provided
filenames=("logo.svg" "logo_margin.svg" "logo_bg.svg" "logo_bg_round.svg" "logo_wide.svg" "logo_wide_margin.svg" "logo_wide_margin_bg.svg" "splash.svg")
configuration_files=("config.pri" "Configuration.qml" "overlay.qrc")
root_dir="./nymea-app-consolinno-overlay";
directory="./configuration-files/$WHITELABEL_TARGET/app-icons"

if [[ ! -d "$directory/android/" ]]; then
  echo "Error: The directory $directory/android/ seems to be missing. It should contain the mipmap directories."
  exit 1
fi

# Check for required files
for filename in "${filenames[@]}"; do
    if [[ ! -f "$directory/$filename" ]]; then
        missingFiles+=("$directory/$filename")
    fi
done

for configuration_file in "${configuration_files[@]}"; do
    if [[ ! -f "./configuration-files/$WHITELABEL_TARGET/$configuration_file" ]]; then
        missingFiles+=("./configuration-files/$WHITELABEL_TARGET/$configuration_file")
    fi
done

if [[ ${#missingFiles[@]} -gt 0 ]]; then
    echo "Error: The following files are missing in the '$directory' directory:"
    for missingFile in "${missingFiles[@]}"; do
        echo "- $missingFile"
    done
    exit 1
fi

echo "All files are present... Starting with the icon generation"

# copy adaptive icons to correct location
cp -r $directory/android/* $root_dir/packaging/android/res/

INPUT_SVG="$directory/logo.svg"
BASE_NAME=$(basename "$INPUT_SVG" .svg)

# Define output directories and subdirectories
declare -A CONSOLINNO_DIRS
CONSOLINNO_DIRS=(
    ["android"]="res/drawable-hdpi res/drawable-ldpi res/drawable-mdpi res/drawable-xhdpi res/drawable-xxhdpi res/drawable-xxxhdpi"
    ["ios"]="Assets.xcassets/AppIcon.appiconset Assets.xcassets/LaunchImage.imageset"
    ["linux-common"]="icons/hicolor/16x16/apps icons/hicolor/22x22/apps icons/hicolor/24x24/apps icons/hicolor/32x32/apps icons/hicolor/48x48/apps icons/hicolor/64x64/apps icons/hicolor/256x256/apps"
    ["osx"]="AppIcon.iconset"
)

# Function to create directories and subdirectories if they don't exist
create_directories() {
    for dir in "${!CONSOLINNO_DIRS[@]}"; 
    do
        main_dir=$dir
        sub_dirs=${CONSOLINNO_DIRS[$dir]}
        for sub_dir in $sub_dirs; do
            full_path="${main_dir}/${sub_dir}"
            if [ ! -d "$full_path" ]; then
                mkdir -p "$full_path"
            fi
        done
    done
}

# Generate consolinno overlay icons

IMG_MARGIN="$directory/logo_margin.svg"
IMG_BG="$directory/logo_bg.svg"
IMG_BG_ROUND="$directory/logo_bg_round.svg"
IMG_WIDE="$directory/logo_wide.svg"
IMG_WIDE_MARGIN="$directory/logo_wide_margin.svg"
IMG_WIDE_MARGIN_BG="$directory/logo_wide_margin_bg.svg"
IMG_SPLASH="$directory/splash.svg"

# Theme Icons
rsvg-convert -w 634 -h 150 "$IMG_WIDE" -o "$root_dir/styles/light/logo-wide.svg"
cp $directory/logo_wide.svg $root_dir/styles/light/logo-wide.svg
cp $directory/logo.svg $root_dir/styles/light/logo.svg
# rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/styles/light/logo.svg"

# Android icons
rsvg-convert -w 256 -h 256 "$IMG_MARGIN" -o "$root_dir/packaging/android/appicon.svg"
rsvg-convert -w 256 -h 256 "$IMG_BG_ROUND" -o "$root_dir/packaging/android/appicon-legacy.svg"
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/android/notificationicon.svg"
rsvg-convert -w 634 -h 150 "$IMG_WIDE" -o "$root_dir/packaging/android/splash-dark.svg"
rsvg-convert -w 634 -h 150 "$IMG_WIDE" -o "$root_dir/packaging/android/splash-light.svg"
rsvg-convert -w 1024 -h 500 "$IMG_WIDE_MARGIN_BG" -o "$root_dir/packaging//android/store-feature-graphic.png"
rsvg-convert -w 1024 -h 500 "$IMG_WIDE_MARGIN" -o "$root_dir/packaging//android/store-feature-graphic.svg"
rsvg-convert -w 512 -h 512 "$IMG_BG" -o "$root_dir/packaging//android/store-icon.png"
rsvg-convert -w 256 -h 256 "$IMG_BG" -o "$root_dir/packaging//android/store-icon.svg"

# res/
# ignore drawable icons for now because of probable replacement by adaptive mipmap icons
<<drawable_icons
rsvg-convert -w 72 -h 72 "$INPUT_SVG" -o "$root_dir/packaging//android/res/drawable-hdpi/icon.png"
rsvg-convert -w 32 -h 32 "$INPUT_SVG" -o "$root_dir/packaging//android/res/drawable-ldpi/icon.png"
rsvg-convert -w 48 -h 48 "$INPUT_SVG" -o "$root_dir/packaging//android/res/drawable-mdpi/icon.png"
rsvg-convert -w 96 -h 96 "$INPUT_SVG" -o "$root_dir/packaging/android/res/drawable-xhdpi/icon.png"
rsvg-convert -w 144 -h 144 "$INPUT_SVG" -o "$root_dir/packaging/android/res/drawable-xxhdpi/icon.png"
rsvg-convert -w 192 -h 192 "$INPUT_SVG" -o "$root_dir/packaging/android/res/drawable-xxxhdpi/icon.png"
rsvg-convert -w 192 -h 192 "$INPUT_SVG" -o "$root_dir/packaging/android/res/drawable-xxxhdpi/icon.png"
drawable_icons

# iOS icons
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/ios/AppIcon.svg"
rsvg-convert -w 640 -h 960 "$IMG_SPLASH" -o "$root_dir/packaging/ios/splash-light.svg"
rsvg-convert -w 640 -h 960 "$IMG_SPLASH" -o "$root_dir/packaging/ios/splash-dark.svg"


# Assets.xcassets/AppIcon.appiconset
rsvg-convert -w 20 -h 20 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon20x20.png"
rsvg-convert -w 40 -h 40 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon20x20@2x.png"
rsvg-convert -w 60 -h 60 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon20x20@3x.png"
rsvg-convert -w 29 -h 29 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon29x29.png"
rsvg-convert -w 58 -h 58 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon29x29@2x.png"
rsvg-convert -w 87 -h 87 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon29x29@3x.png"
rsvg-convert -w 40 -h 40 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon40x40.png"
rsvg-convert -w 80 -h 80 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon40x40@2x.png"
rsvg-convert -w 120 -h 120 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon40x40@3x.png"
rsvg-convert -w 120 -h 120 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon60x60@2x.png"
rsvg-convert -w 180 -h 180 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon60x60@3x.png"
rsvg-convert -w 76 -h 76 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon76x76.png"
rsvg-convert -w 152 -h 152 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon76x76@2x.png"
rsvg-convert -w 167 -h 167 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon83.5x83.5@2x.png"
rsvg-convert -w 1024 -h 1024 "$IMG_BG" -o "$root_dir/packaging/ios/Assets.xcassets/AppIcon.appiconset/AppIcon1024x1024.png"

# Assets.xcassets/LaunchImage.imageset
rsvg-convert -w 320 -h 480 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreenD@1x.png"
rsvg-convert -w 640 -h 960 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreenD@2x.png"
rsvg-convert -w 1280 -h 1920 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreenD@3x.png"

rsvg-convert -w 320 -h 480 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreen@1x.png"
rsvg-convert -w 640 -h 960 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreen@2x.png"
rsvg-convert -w 1280 -h 1920 "$IMG_SPLASH" -o "$root_dir/packaging/ios/Assets.xcassets/LaunchImage.imageset/LaunchScreen@3x.png"

# Linux common
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/leaf.svg"

# icons/hicolor
rsvg-convert -w 16 -h 16 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/16x16/apps/consolinno-energy.png"
rsvg-convert -w 22 -h 22 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/22x22/apps/consolinno-energy.png"
rsvg-convert -w 24 -h 24 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/24x24/apps/consolinno-energy.png"
rsvg-convert -w 32 -h 32 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/32x32/apps/consolinno-energy.png"
rsvg-convert -w 48 -h 48 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/48x48/apps/consolinno-energy.png"
rsvg-convert -w 64 -h 64 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/64x64/apps/consolinno-energy.png"
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/linux-common/icons/hicolor/256x256/apps/consolinno-energy.png"

# osx
# TODO: generate .icns file
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.svg"

# AppIcon.iconset/
rsvg-convert -w 16 -h 16 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_16x16.png"
rsvg-convert -w 32 -h 32 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_16x16@2x.png"
rsvg-convert -w 32 -h 32 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_32x32.png"
rsvg-convert -w 64 -h 64 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_32x32@2x.png"
rsvg-convert -w 128 -h 128 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_128x128.png"
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_128x128@2x.png"
rsvg-convert -w 256 -h 256 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_256x256.png"
rsvg-convert -w 512 -h 512 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_256x256@2x.png"
rsvg-convert -w 512 -h 512 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_512x512.png"
rsvg-convert -w 1024 -h 1024 "$INPUT_SVG" -o "$root_dir/packaging/osx/AppIcon.iconset/icon_512x512@2x.png"


# Distribute Config files
cp ./configuration-files/$WHITELABEL_TARGET/Configuration.qml $root_dir/Configuration.qml
cp ./configuration-files/$WHITELABEL_TARGET/overlay.qrc $root_dir/overlay.qrc
cp ./configuration-files/$WHITELABEL_TARGET/config.pri $root_dir/config.pri
cp -r ./configuration-files/$WHITELABEL_TARGET/style/* $root_dir/styles/light

echo "Conversion completed successfully."