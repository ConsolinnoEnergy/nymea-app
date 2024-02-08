import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQml.Models 2.15
import QtQuick.Layouts 1.1
import QtQuick.Controls.Material 2.2
import Qt.labs.settings 1.0
import NymeaApp.Utils 1.0

Item {
    id: root

    property alias model: visualModel.model

    property Component delegate

    signal clicked(real index);

    implicitWidth: 300
    implicitHeight: 400

    Component {
        id: dragDelegate

        Item {
            id: msAreaRoot

            width: root.width
            height: 50

            MouseArea {
                id: itemArea

                property bool held: false

                anchors {
                    left: parent.left
                    right: parent.right
                }

                height: content.height
                drag.axis: Drag.YAxis
                drag.target: held ? content : undefined

                onPressAndHold: {
                    if(view.count > 1 )
                        held = true
                }

                onReleased: held = false

                onClicked: {
                    root.clicked(index)
                }

                Rectangle {
                    id: content

                    Drag.active: itemArea.held
                    Drag.source: itemArea
                    Drag.hotSpot.x: width / 2
                    Drag.hotSpot.y: height / 2
                    width: parent.width
                    height: 50
                    color: itemArea.held ? "#E0E0E0" : "transparent"

                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                        }
                    }

                    Loader {
                        id: contentLoader

                        property int index: model.index
                        property bool held: itemArea.held
                        property var modelProp: model

                        anchors.fill: parent
                        sourceComponent: delegate
                    }

                    states: State {
                        when: itemArea.held

                        ParentChange {
                            target: content
                            parent: root
                        }
                        AnchorChanges {
                            target: content
                            anchors {
                                horizontalCenter: undefined
                                verticalCenter: undefined
                            }
                        }
                    }
                }

                DropArea {
                    anchors {
                        fill: parent
                        margins: 8
                    }

                    onEntered: (drag) => {
                                   visualModel.items.move(
                                       drag.source.parent.DelegateModel.itemsIndex,
                                       itemArea.parent.DelegateModel.itemsIndex)
                               }
                }
            }
        }
    }

    DelegateModel {
        id: visualModel

        delegate: dragDelegate
    }

    ListView {
        id: view

        anchors {
            fill: parent
        }

        model: visualModel

        spacing: 8
        cacheBuffer: 50
        interactive: true

        moveDisplaced: Transition {
            NumberAnimation { property: "y"; duration: 150; easing.type: Easing.InOutQuad }
        }
    }
}
