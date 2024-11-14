# HEMS App Builder
This repo provides build scripts for the Consolinno HEMS App based on nymea-app. It contains two submodules nymea-app-consolinno-overlay and nymea-app.
The nymea-app project is the main Qt project which contains the source code of the stock nymea app and the Qt build instructions. The nymea-app projects support customization using an overlay, which in this case is provided by nymea-app-consolinno-overlay.

# Build
## CI
The CI can build the app for Android, iOS, Linux (AppImage) and Windows. 

## Development build
The build_linux.sh script can be used to build the app locally. Qt 5.15.2 must be installed on your system to a known path and the QT_ROOT variable needs to be defined accordingly.
Optionally you can define the locale which is used to define the language in the app. Currently only de_DE and en_US is supported.
Example build an run of the app:

    QT_ROOT=/home/username/Qt/5.15.2 ./build_linux.sh run de_DE



<br /><br />

# Build process for Whitelabel customers
This documentation will explain how to set up new Whitelabel customers or update existing ones
in the `consolinno-hems-app-builder`.

## General Info
- Whitelabel -> WL
- When a path is mentioned with `./` it refers to the root directory of the `consolinno-hems-app-builder`.

## WL build support
Currently following build processes are supported
- Linx appimage
- Windows unsigned
- android
- ios

## Setup assets
For each WL-customer there needs to be a dedicated configuration-directory.
Those can be found in `./configuration-files/`.

For example there is `./configuration-files/Consolinno-HEMS/`.
In this directory are all assets necessary for building the original Consolinno app.

For better understanding this documentation uses `WL-Example` as example WL customer.
So the configuration folder will be `./configuration-files/WL-Example/`

### OS-Independent assets

#### Main configuration
Independent of the OS there are following configuration files required in `./configuration-files/WL-Example/`:
- `Configuration.qml` -> It contains the main configuration for the app appearance and WL data.
- `config.pri` -> Should be automatically generated in the future but needs to be configured at the moment.
- `overlay.qrc` -> Imports fonts for example to be included by the `Configuration.qml`

#### Main app icons
The app icons can be found in `./configuration-files/WL-Example/app-icons/`.
Following list contains all expected files with their current resolution:
- `logo.svg` -> Main logo of the app | 256x256
- `logo_bg.svg` -> Main logo with a background. If Main logo already has a background this file is still required | 256x256
- `logo_bg_round.svg` -> Main logo with a circular shaped background | 256x256
- `logo_wide.svg` -> Main banner logo of the app | 566x233
- `logo_wide_margin.svg` -> Main banner logo of the app with a slight margin on top and bottom | 1024x500
- `logo_wide_margin_bg.svg` -> Main banner logo of the app with a slight margin on top and bottom and a background color | 1024x500
- `notificationicon.svg` -> | 256x256
- `splash.svg` ->  | 320x480

All files but `logo.svg` and `logo_wide.svg` are suspected to be redundant, but that needs to be investigated more at the time of writing this documentation.

#### Dashboard icons
The dashboard icons can be found in `./configuration-files/WL-Example/images/`.
Those are also included by the `Configuration.qml`.

#### Style directory
The `./configuration-files/WL-Example/style/` directory currently contains following:
- Style.qml -> required for some specific styling adjustments.
- fonts/ -> contains font files which are included in the `./configuration-files/WL-Example/Configuration.qml`.

<br /><br />

### Android configuration
Currently there is no configuration for android besides the app icons.

#### Android app icons
For the Android app icons you can use Android Studio to generate the image assets.
Then you can move the generated `drawable/`, `values/`, `mipmap-*/` directories to the intendet configuration directory `./configuration-files/WL-Example/app-icons/android/`.

After you transferred the directories you need to copy `./configuration-files/WL-Example/app-icons/android/values/ic_launcher_background.xml` into `./configuration-files/WL-Example/app-icons/android/drawable/ic_launcher_background.xml`.

<br /><br />

### iOS configuration

#### <a name="required-ios-github-secrets">Required iOS github secrets</a>
The name of the secrets all end with the WL customers name. In our example this is could be something like `BUILD_CERTIFICATE_BASE64_WL_EXAMPLE`.
Following secrets need to be defined:
- BUILD_CERTIFICATE_BASE64_WL_EXAMPLE       -> The content of the .pm12 file you generated
- BUILD_PROVISION_PROFILE_BASE64_WL_EXAMPLE -> The content of the Provisioning Profile in base64 format
- P12_PASSWORD_WL_EXAMPLE                   -> The Password for the generated pm12 file
- PROVISIONING_PROFILE_ID_WL_EXAMPLE        -> The UUID of the Provisioning Profile

#### <a name="use-ios-secrets">Update code to use iOS secrets</a>
This is only required for adding a new WL-Customer.

After the GitHub secrets are present, the code in the Builder needs to be updated.
The files you need to update are `./.github/workflows/build_ios.yml` and `./build_ios.sh`.

In both of these files you can find occasions where a matrix variable named `$WHITELABEL_TARGET` is checked in a if-block.
In all these checks will be determined which secrets are required for the current `$WHITELABEL_TARGET`.

Append the code on each occasion with an `else-if` to also check for your new WL customer `WL-Example` and use the correct secrets.

In the if-block inside the `./build_ios.sh` you can see hardcoded variables. These should be transferred to GitHub secrets in the future.
Currently there are following variables defined:
- TEAM_ID
- CURRENT_BUNDLE_PREFIX -> `com.example`
- CURRENT_QMAKE_BUNDLE -> `wlcustomer`
    - this will result in a appId called `com.example.wlcustomer`

The values required for these variables can be found in the `Provisioning Profile` of your WL customer.
You need to search for `TeamIdentifier` and `application-identifier`.
You will notice that the appId is prefixed with the teamId, but `CURRENT_BUNDLE_PREFIX` should not contain the teamId. Just the bundle name.


<br /><br />

### Windows configuration
For windows there is only a `.ico` file to adjust.
`./configuration-files/WL-Example/app-icons/windows/logo.ico`.

It is technically the same image as `./configuration-files/WL-Example/app-icons/logo.svg`, but currently the distribution script is not capable to generate a .ico file.

## Building for a customer
When you are ready to build for one or multiple WL customers, you need to update the matrix variable in the `./.github/workflows/build_*.yml` scripts.

For example in `./.github/workflows/build_android.yml` you can find the code:
```yaml
strategy:
  matrix:
    WHITELABEL_TARGET: ["Some-wl-customer", "another-customer"]

```
The array `WHITELABEL_TARGET` needs to contain the names for all WL customers you want to build for.

The name inside this variable needs to be the same you used for the configuration directory of the customer.

So in our example we use `WL-Example` because our configuration directory is `./configuration-files/WL-Example/`.

After you updated the matrix variable you can start your build.

> &#x26a0;&#xfe0f;: **On Windows**: In the `./.github/workflows/build_windows.yml` there are two jobs. It is required to set the **matrix variable** for both of them.

## Other secrets

`GH_TOKEN` must contain a valid personal access token for a user which has Release rights on consolinno-hems-app-builder and consolinno-hems-app. Select "Repo" scope for this.
See https://github.com/settings/tokens
