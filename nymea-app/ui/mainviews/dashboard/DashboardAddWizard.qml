/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright 2013 - 2020, nymea GmbH
* Contact: contact@nymea.io
*
* This file is part of nymea.
* This project including source code and documentation is protected by
* copyright law, and remains the property of nymea GmbH. All rights, including
* reproduction, publication, editing and translation, are reserved. The use of
* this project is subject to the terms of a license agreement to be concluded
* with nymea GmbH in accordance with the terms of use of nymea GmbH, available
* under https://nymea.io/license
*
* GNU General Public License Usage
* Alternatively, this project may be redistributed and/or modified under the
* terms of the GNU General Public License as published by the Free Software
* Foundation, GNU version 3. This project is distributed in the hope that it
* will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty
* of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
* Public License for more details.
*
* You should have received a copy of the GNU General Public License along with
* this project. If not, see <https://www.gnu.org/licenses/>.
*
* For any further details and any questions please contact us under
* contact@nymea.io or see our FAQ/Licensing Information on
* https://nymea.io/license/faq
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

import QtQuick 2.8
import QtQuick.Controls 2.1
import QtQuick.Controls.Material 2.1
import QtQuick.Layouts 1.2
import QtCharts 2.2
import Nymea 1.0
import NymeaApp.Utils 1.0
import "../../components"
import "../../delegates"

MeaDialog {
    id: root

    title: qsTr("Add item")
    standardButtons: Dialog.NoButton
    width: Math.min(parent.width, 400)
    closePolicy: Popup.CloseOnEscape

    property DashboardModel dashboardModel: null
    property int index: 0

    padding: Style.margins

    contentItem: StackView {
        id: internalPageStack
        implicitHeight: currentItem.implicitHeight
        clip: true

        initialItem: ColumnLayout {
            id: contentColumn
            implicitHeight: childrenRect.height
            NymeaItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Thing")
                iconName: "things"
                onClicked: {
                    internalPageStack.push(addThingSelectionComponent)
                }
            }
            NymeaItemDelegate {
                Layout.fillWidth: true
                iconName: "folder"
                text: qsTr("Folder")
                onClicked: {
                    internalPageStack.push(addFolderComponent)
                }
            }
            NymeaItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Chart")
                iconName: "chart"
                onClicked: {
                    internalPageStack.push(addGraphSelectThingComponent)
                }
            }
            NymeaItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Scene")
                iconName: "slideshow"
                onClicked: {
                    internalPageStack.push(addSceneComponent)
                }
            }
            NymeaItemDelegate {
                Layout.fillWidth: true
                text: qsTr("Web view")
                iconName: "stock_website"
                onClicked: {
                    internalPageStack.push(addWebViewComponent)
                }
            }
        }


        Component {
            id: addThingSelectionComponent
            ColumnLayout {
                RowLayout {
                    Layout.leftMargin: Style.margins
                    Layout.rightMargin: Style.margins
                    ColorIcon {
                        name: "/ui/images/find.svg"
                    }
                    TextField {
                        id: filterTextField
                        Layout.fillWidth: true

                    }
                }


                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Style.delegateHeight * 6
                    clip: true
                    model: ThingsProxy {
                        id: thingsProxy
                        engine: _engine
                        nameFilter: filterTextField.displayText
                    }

                    ScrollBar.vertical: ScrollBar {}

                    delegate: NymeaItemDelegate {
                        width: parent.width
                        text: model.name
                        iconName: app.interfacesToIcon(thingsProxy.get(index).thingClass.interfaces)
                        progressive: false
                        onClicked: {
                            root.dashboardModel.addThingItem(model.id, root.index)
                            root.close();
                        }
                    }
                }
            }
        }

        Component {
            id: addFolderComponent
            ColumnLayout {
                property bool needsOkButton: true

                TextField {
                    id: folderNameTextField
                    Layout.fillWidth: true
                    placeholderText: qsTr("Name")
                }

                GridView {
                    id: iconsGrid
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Style.bigIconSize * 6
                    model: Object.entries(NymeaUtils.namedIcons)
                    property int columns: width / Style.bigIconSize - 1
                    cellWidth: width / columns
                    cellHeight: cellWidth

                    property string currentIcon: "dashboard"

                    clip: true
                    delegate: MouseArea {
                        width: iconsGrid.cellWidth
                        height: iconsGrid.cellHeight
                        onClicked: {
                            print("clicked", modelData[0])
                            iconsGrid.currentIcon = modelData[0]
                        }

                        ColorIcon {
                            anchors.centerIn: parent
                            name: modelData[1]
                            color: modelData[0] == iconsGrid.currentIcon ? Style.accentColor : Style.iconColor
                            size: Style.bigIconSize
                        }
                    }
                }

                Connections {
                    target: okButton
                    onClicked: {
                        root.dashboardModel.addFolderItem(folderNameTextField.text, iconsGrid.currentIcon, root.index)
                        root.close();
                    }
                }
            }
        }

        Component {
            id: addGraphSelectThingComponent
            ColumnLayout {
                RowLayout {
                    Layout.leftMargin: Style.margins
                    Layout.rightMargin: Style.margins
                    ColorIcon {
                        name: "/ui/images/find.svg"
                    }
                    TextField {
                        id: filterTextField
                        Layout.fillWidth: true
                    }
                }
                ListView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.preferredHeight: Style.delegateHeight * 6
                    clip: true

                    ScrollBar.vertical: ScrollBar {}

                    model: ThingsProxy {
                        id: thingsProxy
                        engine: _engine
                        nameFilter: filterTextField.displayText
                    }
                    delegate: NymeaItemDelegate {
                        text: model.name
                        width: parent ? parent.width : 0 // silence warning on delegate descruction
                        iconName: app.interfacesToIcon(thingsProxy.get(index).thingClass.interfaces)
                        onClicked: {
                            internalPageStack.push(addGraphSelectStateComponent, {thing: thingsProxy.get(index)})
                        }
                    }
                }
            }

        }
        Component {
            id: addGraphSelectStateComponent
            ListView {
                implicitHeight: Style.delegateHeight * 6
                clip: true

                ScrollBar.vertical: ScrollBar {}

                property Thing thing: null
                model: thing.thingClass.stateTypes
                width: parent.width
                delegate: NymeaItemDelegate {
                    width: parent.width
                    text: model.displayName
                    onClicked: {
                        root.dashboardModel.addGraphItem(thing.id, model.id, root.index)
                        root.close()
                    }
                }
            }
        }

        Component {
            id: addSceneComponent
            ListView {
                width: parent.width
                implicitHeight: Style.delegateHeight * 6

                ScrollBar.vertical: ScrollBar {}

                model: RulesFilterModel {
                    rules: engine.ruleManager.rules
                    filterExecutable: true
                }
                delegate: NymeaItemDelegate {
                    width: parent.width
                    text: model.name
                    iconName: iconTag.tag.value
                    iconColor: colorTag.tag.value

                    TagWatcher {
                        id: iconTag
                        tags: engine.tagsManager.tags
                        ruleId: model.id
                        tagId: "icon"
                    }
                    TagWatcher {
                        id: colorTag
                        tags: engine.tagsManager.tags
                        ruleId: model.id
                        tagId: "color"
                    }

                    onClicked: {
                        root.dashboardModel.addSceneItem(model.id, root.index)
                        root.close()
                    }
                }
            }
        }

        Component {
            id: addWebViewComponent
            Flickable {
                property bool needsOkButton: true
                property bool okButtonEnabled: urlTextField.displayText.length > 0
                implicitHeight: webViewColumn.implicitHeight
                contentHeight: webViewColumn.height

                ColumnLayout {
                    id: webViewColumn
                    width: parent.width

                    Connections {
                        target: okButton
                        onClicked: {
                            root.dashboardModel.addWebViewItem(urlTextField.text, columnsTabs.currentValue, rowsTabs.currentValue, interactiveSwitch.checked, root.index)
                            root.close();
                        }
                    }

                    SettingsPageSectionHeader {
                        Layout.fillWidth: true
                        text: qsTr("Location")
                    }

                    TextField {
                        id: urlTextField
                        Layout.fillWidth: true
                        Layout.leftMargin: Style.margins
                        Layout.rightMargin: Style.margins
                        placeholderText: qsTr("Enter a URL")
                        text: "https://"
                        inputMethodHints: Qt.ImhNoAutoUppercase
                    }

                    SettingsPageSectionHeader {
                        Layout.fillWidth: true
                        text: qsTr("Size")
                    }

                    GridLayout {
                        columns: width > 300 ? 2 : 1
                        Layout.fillWidth: true
                        Layout.leftMargin: Style.margins
                        Layout.rightMargin: Style.margins
                        columnSpacing: Style.smallMargins
                        rowSpacing: Style.smallMargins
                        Label {
                            text: qsTr("Columns")
                        }
                        SelectionTabs {
                            id: columnsTabs
                            Layout.fillWidth: true
                            model: [1, 2, 3, 4, 5, 6]
                            currentIndex: root.item.columnSpan - 1
                        }
                        Label {
                            text: qsTr("Rows")
                        }
                        SelectionTabs {
                            id: rowsTabs
                            Layout.fillWidth: true
                            model: [1, 2, 3, 4, 5, 6]
                            currentIndex: root.item.rowSpan - 1
                        }
                    }

                    SettingsPageSectionHeader {
                        Layout.fillWidth: true
                        text: qsTr("Behavior")
                        visible: ["android", "ios"].indexOf(Qt.platform.os) < 0
                    }

                    SwitchDelegate {
                        id: interactiveSwitch
                        Layout.fillWidth: true
                        checked: root.item.interactive
                        text: qsTr("Interactive")
                        visible: ["android", "ios"].indexOf(Qt.platform.os) < 0
                    }
                }
            }

        }
    }

    footer: Item {
        implicitHeight: buttonRow.implicitHeight + Style.margins

        RowLayout {
            id: buttonRow
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Style.margins}
            spacing: Style.smallMargins

            Button {
                text: qsTr("Cancel")
                onClicked: root.close()
            }
            Button {
                text: qsTr("Back")
                visible: internalPageStack.depth > 1
                onClicked: internalPageStack.pop()
            }

            Item {
                Layout.fillWidth: true
            }
            Button {
                id: okButton
                text: qsTr("OK")
                visible: internalPageStack.currentItem.hasOwnProperty("needsOkButton") && internalPageStack.currentItem.needsOkButton === true
                enabled: !internalPageStack.currentItem.hasOwnProperty("okButtonEnabled") || internalPageStack.currentItem.okButtonEnabled
            }
        }
    }
}
