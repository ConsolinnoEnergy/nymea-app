// SPDX-License-Identifier: GPL-3.0-or-later

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

import Nymea
import NymeaApp.Utils
import Nymea.Rfid

import "../components"

SettingsPageBase {
    id: root
    title: qsTr("RFID charging")

    property int pendingRemoveCommandId: -1
    property RfidTagInfo pendingRemovalTag: null

    function userLabel(userInfo) {
        if (!userInfo)
            return ""

        return userInfo.displayName !== "" ? userInfo.displayName + " (" + userInfo.username + ")" : userInfo.username
    }

    function profileMode(profile) {
        return profile && profile.mode ? profile.mode : "Eco"
    }

    function profileSummary(profile) {
        if (!profile || !profile.mode || profile.mode === "Eco")
            return qsTr("Eco")

        var parts = [qsTr("Manual")]
        if (profile.maxChargingCurrent !== undefined)
            parts.push(qsTr("%1 A").arg(profile.maxChargingCurrent))
        if (profile.desiredPhaseCount !== undefined)
            parts.push(qsTr("%1 phases").arg(profile.desiredPhaseCount))
        return parts.join(" | ")
    }

    function buildProfile(mode, maxChargingCurrentText, desiredPhaseCount) {
        if (mode === "Eco")
            return {"mode": "Eco"}

        var profile = {"mode": "Manual"}
        if (maxChargingCurrentText !== "")
            profile.maxChargingCurrent = parseInt(maxChargingCurrentText)
        if (desiredPhaseCount > 0)
            profile.desiredPhaseCount = desiredPhaseCount
        return profile
    }

    function showErrorDialog(text) {
        var popup = errorDialogComponent.createObject(app, {text: text})
        popup.open()
    }

    function showRfidError(error) {
        var text
        switch (error) {
        case RfidManager.RfidErrorDuplicateTag:
            text = qsTr("This RFID tag is already assigned.")
            break
        case RfidManager.RfidErrorInvalidProfile:
            text = qsTr("The selected charging profile is not valid.")
            break
        case RfidManager.RfidErrorUserNotFound:
            text = qsTr("The selected user no longer exists.")
            break
        case RfidManager.RfidErrorTagNotFound:
            text = qsTr("The selected RFID tag no longer exists.")
            break
        case RfidManager.RfidErrorInvalidParameter:
            text = qsTr("The RFID tag data is not valid.")
            break
        default:
            text = qsTr("The RFID tag request could not be completed. (Error code: %1)").arg(error)
            break
        }

        showErrorDialog(text)
    }

    function rebuildUserFilterModel() {
        var currentUsername = ""
        if (userFilterComboBox.currentIndex >= 0 && userFilterComboBox.currentIndex < userFilterModel.count)
            currentUsername = userFilterModel.get(userFilterComboBox.currentIndex).username

        userFilterModel.clear()
        userFilterModel.append({"text": qsTr("All users"), "username": ""})

        for (var i = 0; i < userManager.users.count; ++i) {
            var userInfo = userManager.users.get(i)
            if (!userInfo)
                continue

            userFilterModel.append({"text": root.userLabel(userInfo), "username": userInfo.username})
        }

        var nextIndex = 0
        for (var j = 0; j < userFilterModel.count; ++j) {
            if (userFilterModel.get(j).username === currentUsername) {
                nextIndex = j
                break
            }
        }
        userFilterComboBox.currentIndex = nextIndex
    }

    function tagVisible(username) {
        if (userFilterComboBox.currentIndex < 0 || userFilterComboBox.currentIndex >= userFilterModel.count)
            return true

        var filterUsername = userFilterModel.get(userFilterComboBox.currentIndex).username
        return filterUsername === "" || filterUsername === username
    }

    function selectedUserLabel(username) {
        var userInfo = userManager.users.getUserInfo(username)
        return userInfo ? userLabel(userInfo) : username
    }

    function uuidString(value) {
        if (!value)
            return ""

        return value.toString()
    }

    function chargerThingName(thingId) {
        var chargerThing = _engine.thingManager.things.getThing(thingId)
        return chargerThing ? chargerThing.name : ""
    }

    function extractDetectedCode(eventType, params) {
        if (!eventType || !params || params.length === 0)
            return ""

        var preferredNames = ["code", "tagcode", "tag", "rfid", "content"]
        for (var i = 0; i < eventType.paramTypes.count; ++i) {
            var paramType = eventType.paramTypes.get(i)
            if (!paramType)
                continue

            if (preferredNames.indexOf(paramType.name.toLowerCase()) >= 0 && i < params.length && params[i] !== undefined && params[i] !== null)
                return String(params[i]).trim()
        }

        for (var j = 0; j < params.length; ++j) {
            if (params[j] !== undefined && params[j] !== null && String(params[j]).trim() !== "")
                return String(params[j]).trim()
        }

        return ""
    }

    header: NymeaHeader {
        text: root.title
        onBackPressed: pageStack.pop()

        HeaderButton {
            imageSource: Qt.resolvedUrl("qrc:/icons/add.svg")
            onClicked: pageStack.push(addTagWizardComponent)
        }
    }

    UserManager {
        id: userManager
        engine: _engine
    }

    RfidManager {
        id: rfidManager
        engine: _engine
    }

    ListModel {
        id: userFilterModel
    }

    Component {
        id: errorDialogComponent
        ErrorDialog {}
    }

    Component {
        id: confirmDeleteDialogComponent

        NymeaDialog {
            property RfidTagInfo tagInfo: null

            headerIcon: "qrc:/icons/dialog-warning-symbolic.svg"
            title: qsTr("Remove RFID tag")
            text: qsTr("Are you sure you want to remove \"%1\" for %2?")
                .arg(tagInfo && tagInfo.displayName !== "" ? tagInfo.displayName : (tagInfo ? tagInfo.tagHash : ""))
                .arg(tagInfo ? tagInfo.username : "")
            standardButtons: Dialog.Yes | Dialog.No

            onAccepted: {
                if (!tagInfo)
                    return

                root.busy = true
                root.pendingRemovalTag = tagInfo
                root.pendingRemoveCommandId = rfidManager.removeTag(tagInfo.inventoryItemId)
            }
        }
    }

    Component.onCompleted: rebuildUserFilterModel()

    Connections {
        target: userManager.users
        function onCountChanged() {
            root.rebuildUserFilterModel()
        }
    }

    Connections {
        target: rfidManager

        function onRemoveTagReply(commandId, error) {
            if (commandId !== root.pendingRemoveCommandId)
                return

            root.busy = false
            root.pendingRemoveCommandId = -1
            root.pendingRemovalTag = null

            if (error !== RfidManager.RfidErrorNoError)
                root.showRfidError(error)
        }
    }

    SettingsPageSectionHeader {
        text: qsTr("Filter")
    }

    ComboBox {
        id: userFilterComboBox
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        model: userFilterModel
        textRole: "text"
    }

    SettingsPageSectionHeader {
        text: qsTr("RFID tags")
    }

    Label {
        Layout.fillWidth: true
        Layout.leftMargin: Style.margins
        Layout.rightMargin: Style.margins
        wrapMode: Text.WordWrap
        visible: rfidManager.tags.count === 0
        text: qsTr("No RFID tags configured.")
    }

    Repeater {
        model: rfidManager.tags

        delegate: NymeaSwipeDelegate {
            readonly property bool shown: root.tagVisible(model.username)

            Layout.fillWidth: true
            Layout.leftMargin: Style.margins
            Layout.rightMargin: Style.margins
            Layout.preferredHeight: shown ? implicitHeight : 0
            Layout.maximumHeight: shown ? implicitHeight : 0
            Layout.minimumHeight: 0
            visible: shown
            text: model.displayName !== "" ? model.displayName : model.tagHash
            subText: model.username + " | " + root.profileSummary(model.profile) + (model.enabled ? "" : " | " + qsTr("Disabled"))
            iconName: "qrc:/icons/key.svg"
            canDelete: true
            onClicked: pageStack.push(tagEditorComponent, {tagInfo: rfidManager.tags.get(index), createMode: false})
            onDeleteClicked: {
                var popup = confirmDeleteDialogComponent.createObject(root, {tagInfo: rfidManager.tags.get(index)})
                popup.open()
            }
        }
    }

    Component {
        id: addTagWizardComponent

        WizardPageBase {
            id: wizardRootPage
            title: qsTr("Add RFID tag")
            text: qsTr("Select the user this RFID tag belongs to.")
            nextButtonEnabled: selectedOwnerUsername !== ""

            property string selectedOwnerUsername: ""
            property string selectedAddMethod: ""
            property var selectedChargerThingId: null
            property string scannedOrEnteredCode: ""
            property string newDisplayName: ""
            property bool newEnabled: true
            property var newProfile: ({"mode": "Eco"})

            readonly property string addMethodChargerScan: "chargerScan"
            readonly property string addMethodManual: "manual"
            readonly property string addMethodPhoneNfcFuture: "phoneNfcFuture"
            readonly property string chargerDetectionEventName: "tagDetected"

            function resetScannedCodeState() {
                scannedOrEnteredCode = ""
                selectedChargerThingId = null
            }

            onNext: pageStack.push(addTagMethodComponent)
            onBack: pageStack.pop()

            Component.onDestruction: {
                wizardRootPage.scannedOrEnteredCode = ""
            }

            content: ColumnLayout {
                Layout.fillWidth: true
                Layout.maximumWidth: 500
                Layout.alignment: Qt.AlignHCenter

                Repeater {
                    model: userManager.users

                    delegate: NymeaItemDelegate {
                        Layout.fillWidth: true
                        progressive: false
                        iconName: "qrc:/icons/account.svg"
                        text: root.userLabel(userManager.users.get(index))
                        subText: model.username
                        iconColor: wizardRootPage.selectedOwnerUsername === model.username ? Style.accentColor : Style.iconColor
                        tertiaryIconName: wizardRootPage.selectedOwnerUsername === model.username ? "qrc:/icons/tick.svg" : ""
                        onClicked: wizardRootPage.selectedOwnerUsername = model.username
                    }
                }
            }

            Component {
                id: addTagMethodComponent

                WizardPageBase {
                    title: qsTr("Add RFID tag")
                    text: qsTr("Choose how to read the RFID tag for %1.").arg(root.selectedUserLabel(wizardRootPage.selectedOwnerUsername))
                    showNextButton: false
                    onBack: pageStack.pop()

                    content: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter

                        NymeaItemDelegate {
                            Layout.fillWidth: true
                            iconName: "qrc:/icons/things.svg"
                            text: qsTr("Scan on charger")
                            subText: qsTr("Select a charger and wait for its tagDetected event.")
                            onClicked: {
                                wizardRootPage.selectedAddMethod = wizardRootPage.addMethodChargerScan
                                wizardRootPage.resetScannedCodeState()
                                pageStack.push(chargerSelectionComponent)
                            }
                        }

                        NymeaItemDelegate {
                            Layout.fillWidth: true
                            iconName: "qrc:/icons/edit.svg"
                            text: qsTr("Enter manually")
                            subText: qsTr("Type the RFID code manually.")
                            onClicked: {
                                wizardRootPage.selectedAddMethod = wizardRootPage.addMethodManual
                                wizardRootPage.resetScannedCodeState()
                                pageStack.push(manualCodeEntryComponent)
                            }
                        }

                        NymeaItemDelegate {
                            Layout.fillWidth: true
                            enabled: false
                            progressive: false
                            iconName: "qrc:/icons/nfc.svg"
                            text: qsTr("Scan with phone NFC")
                            subText: qsTr("Planned for a future version.")
                        }
                    }
                }
            }

            Component {
                id: chargerSelectionComponent

                WizardPageBase {
                    id: chargerSelectionPage
                    title: qsTr("Scan RFID tag")
                    text: qsTr("Select the charger that should scan the RFID tag.")
                    showNextButton: false
                    onBack: pageStack.pop()

                    content: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter
                        spacing: Style.margins

                        TextField {
                            id: chargerFilterTextField
                            Layout.fillWidth: true
                            placeholderText: qsTr("Find charger")
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            text: qsTr("No charger with RFID scan support is currently available.")
                            visible: chargerThingsProxy.count === 0 && !_engine.thingManager.fetchingData
                            horizontalAlignment: Text.AlignHCenter
                        }

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            visible: _engine.thingManager.fetchingData
                        }

                        ListView {
                            Layout.fillWidth: true
                            Layout.preferredHeight: Math.min(contentHeight, chargerSelectionPage.visibleContentHeight)
                            clip: true
                            model: ThingsProxy {
                                id: chargerThingsProxy
                                engine: _engine
                                shownInterfaces: ["chargers"]
                                requiredEventName: wizardRootPage.chargerDetectionEventName
                                nameFilter: chargerFilterTextField.text
                            }

                            ScrollBar.vertical: ScrollBar {}

                            delegate: NymeaItemDelegate {
                                width: parent.width
                                progressive: false
                                property Thing chargerThing: chargerThingsProxy.get(index)
                                text: chargerThing ? chargerThing.name : model.name
                                subText: qsTr("Wait for %1").arg(wizardRootPage.chargerDetectionEventName)
                                iconName: chargerThing ? app.interfacesToIcon(chargerThing.thingClass.interfaces) : "qrc:/icons/things.svg"
                                onClicked: {
                                    if (!chargerThing)
                                        return

                                    wizardRootPage.selectedChargerThingId = chargerThing.id
                                    pageStack.push(waitForTagComponent)
                                }
                            }
                        }
                    }
                }
            }

            Component {
                id: waitForTagComponent

                WizardPageBase {
                    id: waitForTagPage
                    title: qsTr("Scan RFID tag")
                    text: waitForTagPage.selectedChargerThing
                          ? qsTr("Present the RFID tag to %1 now.").arg(waitForTagPage.selectedChargerThing.name)
                          : qsTr("The selected charger is no longer available.")
                    showNextButton: false
                    showExtraButton: waitForTagPage.selectedChargerThing !== null
                    extraButtonText: qsTr("Select another charger")

                    readonly property Thing selectedChargerThing: _engine.thingManager.things.getThing(wizardRootPage.selectedChargerThingId)
                    readonly property EventType tagDetectedEventType: selectedChargerThing ? selectedChargerThing.thingClass.eventTypes.findByName(wizardRootPage.chargerDetectionEventName) : null
                    property bool completed: false

                    onBack: pageStack.pop()
                    onExtraButtonPressed: pageStack.pop()

                    content: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter
                        Layout.preferredHeight: waitForTagPage.visibleContentHeight

                        Item { Layout.fillHeight: true }

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            visible: waitForTagPage.selectedChargerThing !== null && !waitForTagPage.completed
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            visible: waitForTagPage.selectedChargerThing !== null
                            text: qsTr("Listening for %1 on %2.")
                                .arg(wizardRootPage.chargerDetectionEventName)
                                .arg(waitForTagPage.selectedChargerThing ? waitForTagPage.selectedChargerThing.name : "")
                        }

                        Label {
                            Layout.fillWidth: true
                            wrapMode: Text.WordWrap
                            horizontalAlignment: Text.AlignHCenter
                            visible: waitForTagPage.selectedChargerThing === null
                            text: qsTr("Please go back and select another charger.")
                        }

                        Item { Layout.fillHeight: true }
                    }

                    Connections {
                        target: waitForTagPage.selectedChargerThing

                        function onEventTriggered(eventTypeId, params) {
                            if (waitForTagPage.completed || !waitForTagPage.tagDetectedEventType)
                                return

                            if (root.uuidString(eventTypeId) !== root.uuidString(waitForTagPage.tagDetectedEventType.id))
                                return

                            var detectedCode = root.extractDetectedCode(waitForTagPage.tagDetectedEventType, params)
                            if (detectedCode === "") {
                                root.showErrorDialog(qsTr("The charger reported a tag, but no RFID code could be read."))
                                return
                            }

                            waitForTagPage.completed = true
                            wizardRootPage.scannedOrEnteredCode = detectedCode
                            pageStack.push(addTagFinalizeComponent)
                        }
                    }
                }
            }

            Component {
                id: manualCodeEntryComponent

                WizardPageBase {
                    id: manualCodePage
                    title: qsTr("Enter RFID tag")
                    text: qsTr("Enter the RFID code manually.")
                    nextButtonEnabled: codeTextField.text.trim() !== ""

                    onNext: {
                        wizardRootPage.scannedOrEnteredCode = codeTextField.text.trim()
                        pageStack.push(addTagFinalizeComponent)
                    }

                    onBack: pageStack.pop()

                    content: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter

                        TextField {
                            id: codeTextField
                            Layout.fillWidth: true
                            text: wizardRootPage.scannedOrEnteredCode
                            placeholderText: qsTr("RFID code")
                        }
                    }
                }
            }

            // Placeholder for a future NFC-based add flow. The method is intentionally not reachable yet.
            Component {
                id: phoneNfcPlaceholderComponent

                WizardPageBase {
                    title: qsTr("Scan with phone NFC")
                    text: qsTr("This flow is planned for a future version.")
                    showNextButton: false
                    onBack: pageStack.pop()
                }
            }

            Component {
                id: addTagFinalizeComponent

                WizardPageBase {
                    id: addTagFinalizePage
                    title: qsTr("Finish RFID tag")
                    text: qsTr("Name the RFID tag and configure its charging profile.")
                    nextButtonText: qsTr("Create RFID tag")
                    nextButtonEnabled: addTagFinalizePage.pendingCommandId === -1
                                       && wizardRootPage.scannedOrEnteredCode !== ""
                                       && userManager.users.contains(wizardRootPage.selectedOwnerUsername)
                                       && (modeComboBox.selectedMode !== "Manual"
                                           || maxChargingCurrentField.text === ""
                                           || maxChargingCurrentField.acceptableInput)

                    property int pendingCommandId: -1

                    function updateDraftProfile() {
                        if (!modeComboBox || !maxChargingCurrentField || !phaseCountComboBox)
                            return

                        wizardRootPage.newProfile = root.buildProfile(
                                    modeComboBox.selectedMode,
                                    maxChargingCurrentField.text.trim(),
                                    phaseCountComboBox.currentIndex >= 0 ? phaseCountModel.get(phaseCountComboBox.currentIndex).value : 0)
                    }

                    onNext: {
                        if (pendingCommandId !== -1)
                            return

                        if (!userManager.users.contains(wizardRootPage.selectedOwnerUsername)) {
                            root.showErrorDialog(qsTr("The selected user no longer exists."))
                            return
                        }

                        updateDraftProfile()
                        pendingCommandId = rfidManager.addTag(
                                    wizardRootPage.selectedOwnerUsername,
                                    wizardRootPage.scannedOrEnteredCode,
                                    wizardRootPage.newDisplayName,
                                    wizardRootPage.newEnabled,
                                    wizardRootPage.newProfile)
                    }

                    onBack: pageStack.pop()

                    ListModel {
                        id: phaseCountModel
                        ListElement { text: qsTr("Not set"); value: 0 }
                        ListElement { text: "1"; value: 1 }
                        ListElement { text: "3"; value: 3 }
                    }

                    content: ColumnLayout {
                        Layout.fillWidth: true
                        Layout.maximumWidth: 500
                        Layout.alignment: Qt.AlignHCenter

                        SettingsPageSectionHeader {
                            text: qsTr("Owner")
                        }

                        Label {
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.margins
                            Layout.rightMargin: Style.margins
                            wrapMode: Text.WordWrap
                            text: root.selectedUserLabel(wizardRootPage.selectedOwnerUsername)
                        }

                        SettingsPageSectionHeader {
                            text: qsTr("RFID tag")
                        }

                        NymeaTextField {
                            id: displayNameTextField
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.margins
                            Layout.rightMargin: Style.margins
                            placeholderText: qsTr("Display name")
                            text: wizardRootPage.newDisplayName
                            onTextEdited: wizardRootPage.newDisplayName = text
                        }

                        SwitchDelegate {
                            id: enabledSwitch
                            Layout.fillWidth: true
                            text: qsTr("Enabled")
                            checked: wizardRootPage.newEnabled
                            onToggled: wizardRootPage.newEnabled = checked
                        }

                        SettingsPageSectionHeader {
                            text: qsTr("Charging profile")
                        }

                        ComboBox {
                            id: modeComboBox
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.margins
                            Layout.rightMargin: Style.margins
                            model: [
                                {"text": qsTr("Eco"), "value": "Eco"},
                                {"text": qsTr("Manual"), "value": "Manual"}
                            ]
                            textRole: "text"
                            property string selectedMode: currentIndex >= 0 ? model[currentIndex].value : "Eco"
                            Component.onCompleted: {
                                currentIndex = root.profileMode(wizardRootPage.newProfile) === "Manual" ? 1 : 0
                            }
                            onCurrentIndexChanged: addTagFinalizePage.updateDraftProfile()
                        }

                        TextField {
                            id: maxChargingCurrentField
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.margins
                            Layout.rightMargin: Style.margins
                            visible: modeComboBox.selectedMode === "Manual"
                            placeholderText: qsTr("Max charging current (A)")
                            text: wizardRootPage.newProfile && wizardRootPage.newProfile.maxChargingCurrent !== undefined ? wizardRootPage.newProfile.maxChargingCurrent : ""
                            inputMethodHints: Qt.ImhDigitsOnly
                            validator: IntValidator { bottom: 1; top: 128 }
                            onTextEdited: addTagFinalizePage.updateDraftProfile()
                        }

                        ComboBox {
                            id: phaseCountComboBox
                            Layout.fillWidth: true
                            Layout.leftMargin: Style.margins
                            Layout.rightMargin: Style.margins
                            visible: modeComboBox.selectedMode === "Manual"
                            model: phaseCountModel
                            textRole: "text"

                            Component.onCompleted: {
                                var desiredPhaseCount = wizardRootPage.newProfile && wizardRootPage.newProfile.desiredPhaseCount !== undefined
                                        ? wizardRootPage.newProfile.desiredPhaseCount : 0
                                for (var i = 0; i < phaseCountModel.count; ++i) {
                                    if (phaseCountModel.get(i).value === desiredPhaseCount) {
                                        currentIndex = i
                                        return
                                    }
                                }
                                currentIndex = 0
                            }

                            onCurrentIndexChanged: addTagFinalizePage.updateDraftProfile()
                        }

                        BusyIndicator {
                            Layout.alignment: Qt.AlignHCenter
                            visible: addTagFinalizePage.pendingCommandId !== -1
                        }
                    }

                    Connections {
                        target: rfidManager

                        function onAddTagReply(commandId, error) {
                            if (commandId !== addTagFinalizePage.pendingCommandId)
                                return

                            addTagFinalizePage.pendingCommandId = -1
                            if (error === RfidManager.RfidErrorNoError) {
                                pageStack.pop(root)
                            } else {
                                root.showRfidError(error)
                            }
                        }
                    }
                }
            }
        }
    }

    Component {
        id: tagEditorComponent

        SettingsPageBase {
            id: editorPage
            property bool createMode: false
            property RfidTagInfo tagInfo: null
            property int pendingCommandId: -1
            property int pendingRemoveCommandId: -1
            property string selectedOwnerUsername: ""
            title: createMode ? qsTr("Add RFID tag") : qsTr("Edit RFID tag")

            function currentUserInfo() {
                return createMode && ownerComboBox.currentIndex >= 0 ? userManager.users.get(ownerComboBox.currentIndex) : userManager.users.getUserInfo(tagInfo ? tagInfo.username : "")
            }

            function currentPhaseValue() {
                return phaseCountComboBox.currentIndex >= 0 ? phaseCountModel.get(phaseCountComboBox.currentIndex).value : 0
            }

            function submit() {
                var profile = root.buildProfile(modeComboBox.selectedMode, maxChargingCurrentField.text.trim(), currentPhaseValue())
                busy = true

                if (createMode) {
                    pendingCommandId = rfidManager.addTag(
                        selectedOwnerUsername,
                        codeTextField.text.trim(),
                        displayNameTextField.text,
                        enabledSwitch.checked,
                        profile
                    )
                } else {
                    pendingCommandId = rfidManager.updateTag(
                        tagInfo.inventoryItemId,
                        displayNameTextField.text,
                        enabledSwitch.checked,
                        profile
                    )
                }
            }

            header: NymeaHeader {
                text: editorPage.title
                onBackPressed: pageStack.pop()
            }

            ListModel {
                id: phaseCountModel
                ListElement { text: qsTr("Not set"); value: 0 }
                ListElement { text: "1"; value: 1 }
                ListElement { text: "3"; value: 3 }
            }

            SettingsPageSectionHeader {
                text: qsTr("Owner")
            }

            ComboBox {
                id: ownerComboBox
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: editorPage.createMode
                model: userManager.users
                textRole: "username"
                onCurrentIndexChanged: {
                    var selectedUser = userManager.users.get(currentIndex)
                    editorPage.selectedOwnerUsername = selectedUser ? selectedUser.username : ""
                }
                Component.onCompleted: {
                    var selectedUser = userManager.users.get(currentIndex)
                    editorPage.selectedOwnerUsername = selectedUser ? selectedUser.username : ""
                }
            }

            Label {
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: !editorPage.createMode && editorPage.tagInfo
                text: editorPage.tagInfo ? editorPage.tagInfo.username : ""
                wrapMode: Text.WordWrap
            }

            SettingsPageSectionHeader {
                text: qsTr("RFID tag")
            }

            TextField {
                id: codeTextField
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: editorPage.createMode
                placeholderText: qsTr("RFID code")
            }

            NymeaTextField {
                id: displayNameTextField
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                placeholderText: qsTr("Display name")
                text: editorPage.tagInfo ? editorPage.tagInfo.displayName : ""
            }

            SwitchDelegate {
                id: enabledSwitch
                Layout.fillWidth: true
                text: qsTr("Enabled")
                checked: editorPage.tagInfo ? editorPage.tagInfo.enabled : true
            }

            SettingsPageSectionHeader {
                text: qsTr("Charging profile")
            }

            ComboBox {
                id: modeComboBox
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                model: [
                    {"text": qsTr("Eco"), "value": "Eco"},
                    {"text": qsTr("Manual"), "value": "Manual"}
                ]
                textRole: "text"
                property string selectedMode: currentIndex >= 0 ? model[currentIndex].value : "Eco"
                Component.onCompleted: {
                    currentIndex = root.profileMode(editorPage.tagInfo ? editorPage.tagInfo.profile : {"mode": "Eco"}) === "Manual" ? 1 : 0
                }
            }

            TextField {
                id: maxChargingCurrentField
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: modeComboBox.selectedMode === "Manual"
                placeholderText: qsTr("Max charging current (A)")
                text: editorPage.tagInfo && editorPage.tagInfo.profile.maxChargingCurrent !== undefined ? editorPage.tagInfo.profile.maxChargingCurrent : ""
                inputMethodHints: Qt.ImhDigitsOnly
                validator: IntValidator { bottom: 1; top: 128 }
            }

            ComboBox {
                id: phaseCountComboBox
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: modeComboBox.selectedMode === "Manual"
                model: phaseCountModel
                textRole: "text"

                Component.onCompleted: {
                    var desiredPhaseCount = editorPage.tagInfo && editorPage.tagInfo.profile.desiredPhaseCount !== undefined
                            ? editorPage.tagInfo.profile.desiredPhaseCount : 0
                    for (var i = 0; i < phaseCountModel.count; ++i) {
                        if (phaseCountModel.get(i).value === desiredPhaseCount) {
                            currentIndex = i
                            return
                        }
                    }
                    currentIndex = 0
                }
            }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                text: editorPage.createMode ? qsTr("Create RFID tag") : qsTr("Save")
                enabled: {
                    if (editorPage.createMode) {
                        if (editorPage.selectedOwnerUsername === "")
                            return false
                        if (codeTextField.text.trim() === "")
                            return false
                    }

                    if (modeComboBox.selectedMode === "Manual" && maxChargingCurrentField.text !== "" && !maxChargingCurrentField.acceptableInput)
                        return false

                    return true
                }
                onClicked: {
                    if (editorPage.createMode) {
                        if (!userManager.users.contains(editorPage.selectedOwnerUsername)) {
                            root.showErrorDialog(qsTr("The selected user no longer exists."))
                            return
                        }
                    }

                    editorPage.submit()
                }
            }

            SettingsPageSectionHeader {
                text: qsTr("Technical details")
                visible: !editorPage.createMode && editorPage.tagInfo
            }

            NymeaSwipeDelegate {
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: !editorPage.createMode && editorPage.tagInfo
                progressive: false
                text: qsTr("RFID hash")
                subText: editorPage.tagInfo ? editorPage.tagInfo.tagHash : ""
            }

            SettingsPageSectionHeader {
                text: qsTr("Remove")
                visible: !editorPage.createMode
            }

            Button {
                Layout.fillWidth: true
                Layout.leftMargin: Style.margins
                Layout.rightMargin: Style.margins
                visible: !editorPage.createMode
                text: qsTr("Remove this RFID tag")
                onClicked: {
                    var popup = localConfirmDeleteDialogComponent.createObject(editorPage, {tagInfo: editorPage.tagInfo})
                    popup.open()
                }
            }

            Component {
                id: localConfirmDeleteDialogComponent

                NymeaDialog {
                    property RfidTagInfo tagInfo: null

                    headerIcon: "qrc:/icons/dialog-warning-symbolic.svg"
                    title: qsTr("Remove RFID tag")
                    text: qsTr("Are you sure you want to remove \"%1\" for %2?")
                        .arg(tagInfo && tagInfo.displayName !== "" ? tagInfo.displayName : (tagInfo ? tagInfo.tagHash : ""))
                        .arg(tagInfo ? tagInfo.username : "")
                    standardButtons: Dialog.Yes | Dialog.No

                    onAccepted: {
                        if (!tagInfo)
                            return

                        editorPage.busy = true
                        editorPage.pendingRemoveCommandId = rfidManager.removeTag(tagInfo.inventoryItemId)
                    }
                }
            }

            Connections {
                target: rfidManager

                function onAddTagReply(commandId, error) {
                    if (!editorPage.createMode || commandId !== editorPage.pendingCommandId)
                        return

                    editorPage.busy = false
                    editorPage.pendingCommandId = -1
                    if (error === RfidManager.RfidErrorNoError) {
                        pageStack.pop()
                    } else {
                        root.showRfidError(error)
                    }
                }

                function onUpdateTagReply(commandId, error) {
                    if (editorPage.createMode || commandId !== editorPage.pendingCommandId)
                        return

                    editorPage.busy = false
                    editorPage.pendingCommandId = -1
                    if (error === RfidManager.RfidErrorNoError) {
                        pageStack.pop()
                    } else {
                        root.showRfidError(error)
                    }
                }

                function onRemoveTagReply(commandId, error) {
                    if (commandId !== editorPage.pendingRemoveCommandId)
                        return

                    editorPage.busy = false
                    editorPage.pendingRemoveCommandId = -1
                    if (error === RfidManager.RfidErrorNoError) {
                        pageStack.pop()
                    } else {
                        root.showRfidError(error)
                    }
                }
            }
        }
    }
}
