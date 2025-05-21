pragma Singleton

import QtQuick 2.5

ConfigurationBase {
    id: configID
    systemName: "Q.HOME CONTROL"
    appName: "Q.HOME CONTROL"
    appId: "de.qcells.qhomecontrol"

    connectionWizard: "/ui/wizards/ConnectionWizard.qml"

    //////////////////////////////////////////////////////////////////////////////////////
    //Main View
    readonly property string mainMenuThingName: "white"

    //change "Ubuntu" string to set a different font or set "Ubuntu" to have standard font
    property string fontFamily: "NotoSans"

    //Wizard Complete
    property bool isIntroIcon: false
    //////////////////////////////////////////////////////////////////////////////////////
    // Defines the minimal compatible HEMS version
    property string minSysVersion: "1.7.0"

    // Identifier used for branding (e.g. to register for push notifications)
    property string branding: "Q.HOME CONTROL"

    // Identifier used for legal text (e.g. privacy policy)
    property string companyName: "Hanwha Q CELLS GmbH"

    // Branding names visible to the user
    property string appBranding: "Q.HOME CONTROL"
    property string coreBranding: "Q.HOME CONTROL"
    property string deviceName: "Q.HOME CONTROL"

    //Branding contact-email
    property string contactEmail: "meinesolaranlage@q-cells.com"
    property string serviceEmail: "support.components@q-cells.com"
    property string serviceTel: ""

    //Branding company
    property string companyAddress: "Sonnenallee 17 - 21"
    property string companyZip: "06766"
    property string companyLocation: "Bitterfeld-Wolfen"
    property string companyTel: ""

    //////////////////////////////////////////////////////////////////////////////////////
    // Will be shown in About page
    property string githubLink: "https://github.com/ConsolinnoEnergy/nymea-app"
    property string privacyPolicyUrl: "https://consolinno.de/hems-datenschutz/"
    property string termsOfConditionsUrl: "https://consolinno.de/hems-agb/"
    property string downloadMedia: "https://www.q-cells.de/privatkunden/services/downloadbereich#"

    //////////////////////////////////////////////////////////////////////////////////////

    //Styles
    //MainMenuCirlce
    readonly property color mainTimeCircle: "#d7d7d7"
    readonly property color mainTimeCircleDivider: "#ffffff"
    readonly property color mainCircleTimeColor: "gray"

    readonly property color mainTimeNow: "gray"


    readonly property color mainInnerCicleFirst: "#b6b6b6"
    readonly property color mainInnerCicleSecond: "#b6b6b6"

    // Button
    readonly property color iconColor: "#00C6C1"
    readonly property color buttonColor: "#001C77"
    readonly property color secondButtonColor: "#001C77"
    
    readonly property color buttonTextColor: "#ffffff"
    readonly property color highlightForeground: "#ffffff"
    //static things colors
    //producers
    readonly property color rootMeterAcquisitionColor: "#1C3EAA"
    readonly property color rootMeterReturnColor: "#01295F"
    readonly property color inverterColor: "#1AA0DB"

    //other things
    readonly property color epexColor: "#1ACCC8"
    readonly property color epexMainLineColor: "#001C77"
    readonly property color epexAverageColor: "#00C6C1"
    readonly property color epexCurrentTime: "#50B24D"
    
    //other consumers
    readonly property color heatpumpColor: "#4ED6B2"
    readonly property color wallboxColor: "#9DEAC6"
    readonly property color heatingRodColor: "#C2E56C"
    readonly property color consumedColor: "#F4BF65"

    //batteries
    readonly property color batteriesColor: "#93DE8E"
    readonly property color batteryChargeColor: batteriesColor
    readonly property color batteryDischargeColor: "#F4BF65"
    readonly property color batteryIdleColor: "#B5B5B5"

    //etc. colors
    readonly property var totalColors: [consumedColor, inverterColor, rootMeterAcquisitionColor, rootMeterReturnColor, batteryChargeColor, batteryDischargeColor]
    property var consumerColors: ["#677EC6", "#66DDDA", "#437BC4", "#AA5DC2", "#66BFE6"]


    //custom Icons
    readonly property string gridIcon: "QCells/gridQ.svg"
    readonly property string heatpumpIcon: "QCells/heatpumpQ.svg"
    readonly property string heatingRodIcon: "QCells/heatingRodQ.svg"
    readonly property string energyIcon: "QCells/dynamic-tariffQ.svg"
    readonly property string inverterIcon: "QCells/inverterQ.svg"
    readonly property string settingsIcon: "QCells/settingsQ.svg"
    readonly property string evchargerIcon: "QCells/wallboxQ.svg"
    readonly property string batteryIcon: "QCells/batteryQ.svg"
    readonly property string infoIcon: "QCells/infoQ.svg"
    readonly property string menuIcon: "QCells/menuQ.svg"

    property ListModel softwareLinksApp: ListModel {
        ListElement { component: "Suru icons"; url: "https://github.com/snwh/suru-icon-theme" }
        ListElement { component: "Ubuntu font"; url: "https://design.ubuntu.com/font" }
        ListElement { component: "Oswald font"; url: "https://fonts.google.com/specimen/Oswald" }
        ListElement { component: "QTZeroConf"; url: "https://github.com/jbagg/QtZeroConf" }
        ListElement { component: "Android OpenSSL"; url: "https://github.com/KDAB/android_openssl" }
        ListElement { component: "Firebase"; url: "https://github.com/firebase/firebase-cpp-sdk" }
        ListElement { component: "OpenSSl"; url: "https://www.openssl.org/" }
        ListElement { component: "Nymea App"; url: "https://github.com/ConsolinnoEnergy/nymea-app" }
        ListElement { component: "Nymea Remoteproxy"; url: "https://github.com/ConsolinnoEnergy/nymea-remoteproxy" }
        ListElement { component: "Consolinno Overlay"; url: "https://github.com/ConsolinnoEnergy/nymea-app-consolinno-overlay" }
    }

    property ListModel licensesApp: ListModel {
        ListElement { component: "GNU General Public License, Version 3.0"; license: "GPL3" }
        ListElement { component: "GNU Lesser General Public License, Version 3.0"; license: "LGPL3" }
        ListElement { component: "OpenSSL"; license: "OpenSSL" }
        ListElement { component: "Apache License, Version 2.0"; license: "APACHE2" }
        ListElement { component: "Creative Commons Attribution-ShareAlike 3.0 Unported"; license: "CC-BY-SA-3.0" }
        ListElement { component: "SIL Open Font License, Version 1.1"; license: "OFL" }
        ListElement { component: "Ubuntu font licence, Version 1.0"; license: "UFL" }
    }

    //////////////////////////////////////////////////////////////////////////////////////
    //Connection & Settings
    // Default value when manually adding a tunnel proxy
    property string defaultTunnelProxyUrl: "hems-remoteproxy.services.consolinno.de"

    // Hides shutdown button in general settings menu
    property bool hideShutdownButton: true

    // Hides Restart button in general settings menu
    property bool hideRestartButton: true

    // Shows Reboot button in general settings menu
    property bool hideRebootButton: false

    // Shows Developer button in general settings menu
    property bool developerSettingsEnabled: false

    //////////////////////////////////////////////////////////////////////////////////////
    // Additional MainViews
    property var additionalMainViews: ListModel {
        ListElement { name: "consolinno"; source: "ConsolinnoView"; displayName: qsTr("Q CELLS") ; icon: "leaf" }
    }

    // Main views filter: Only those main views are enabled
    //property var mainViewsFilter: ["consolinno"]

    defaultMainView: "consolinno"

    magicEnabled: true
    networkSettingsEnabled: true
    apiSettingsEnabled: true
    mqttSettingsEnabled: true
    webServerSettingsEnabled: true
    zigbeeSettingsEnabled: true
    modbusSettingsEnabled: true
    pluginSettingsEnabled: true



    mainMenuLinks: [
        {
            text: qsTr("Help"),
            iconName: "../images/help.svg",
            page: "info/Help/HelpPage.qml"
        },
    ]

    }
