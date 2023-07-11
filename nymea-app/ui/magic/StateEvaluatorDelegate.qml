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
import QtQuick.Layouts 1.2
import Nymea 1.0
import "../components"

ItemDelegate {

    id: root
    property StateEvaluator stateEvaluator: null
    readonly property Thing thing: stateEvaluator ? engine.thingManager.things.getThing(stateEvaluator.stateDescriptor.thingId) : null
    readonly property StateType stateType: thing ? thing.thingClass.stateTypes.getStateType(stateEvaluator.stateDescriptor.stateTypeId) : null

    property bool canDelete: true
    signal deleteClicked()

    function editStateDescriptor(interfaceMode) {
        if (interfaceMode === undefined) {
            interfaceMode = false;
        }

        var page = pageStack.push(Qt.resolvedUrl("SelectThingPage.qml"), {selectInterface: interfaceMode, showStates: true});
        page.backPressed.connect(function() {
            pageStack.pop()
        })
        page.thingSelected.connect(function(thing) {
            root.stateEvaluator.stateDescriptor.interfaceName = "";
            root.stateEvaluator.stateDescriptor.thingId = thing.id;
            var statePage = selectStateDescriptorData()
            statePage.done.connect(function() {
                pageStack.pop(StackView.Immediate)
                pageStack.pop()
            })
        });
        page.interfaceSelected.connect(function(interfaceName) {
            root.stateEvaluator.stateDescriptor.thingId = "";
            root.stateEvaluator.stateDescriptor.interfaceName = interfaceName;
            var statePage = selectStateDescriptorData();
            statePage.done.connect(function() {
                pageStack.pop(StackView.Immediate)
                pageStack.pop()
            })
        });
    }
    function editInterfaceStateDescriptor() {
        editStateDescriptor(true)
    }
    function selectStateDescriptorData() {
        var statePage = pageStack.push(Qt.resolvedUrl("SelectStateDescriptorPage.qml"), {text: "Select state", stateDescriptor: root.stateEvaluator.stateDescriptor})
        statePage.backPressed.connect(function() {
            pageStack.pop();
        })
        statePage.done.connect(function() {
            pageStack.pop(statePage, StackView.Immediate);
            pageStack.pop();
//            pageStack.pop();
        })
        return statePage
    }

    contentItem: ColumnLayout {
        SimpleStateEvaluatorDelegate {
            Layout.fillWidth: true
            stateEvaluator: root.stateEvaluator
            swipe.enabled: root.canDelete
            onClicked: {
                print("opening editor:", root.stateEvaluator.stateDescriptor.thingId)
                if (root.stateEvaluator.stateDescriptor.thingId.toString() !== "{00000000-0000-0000-0000-000000000000}") {
                    selectStateDescriptorData()
                } else {
                    var page = pageStack.push(stateQuestionPageComponent);
                }
            }
            onDeleteClicked: {
                root.deleteClicked()
            }
        }

        ComboBox {
            Layout.fillWidth: true
            model: [qsTr("and all of those"), qsTr("or any of those")]
            currentIndex: root.stateEvaluator && root.stateEvaluator.stateOperator === StateEvaluator.StateOperatorAnd ? 0 : 1
            visible: root.stateEvaluator && root.stateEvaluator.childEvaluators.count > 0
            onActivated: {
                root.stateEvaluator.stateOperator = index == 0 ? StateEvaluator.StateOperatorAnd : StateEvaluator.StateOperatorOr
            }
        }

        Repeater {
            model: root.stateEvaluator ? root.stateEvaluator.childEvaluators : null
            delegate: SimpleStateEvaluatorDelegate {
                Layout.fillWidth: true
                stateEvaluator: root.stateEvaluator.childEvaluators.get(index)
                showChilds: true
                onClicked: {
                    pageStack.push(Qt.resolvedUrl("EditStateEvaluatorPage.qml"), {stateEvaluator: stateEvaluator})
                }
                onDeleteClicked: {
                    root.stateEvaluator.childEvaluators.remove(index)
                }
            }
        }

        Button {
            Layout.fillWidth: true
            text: qsTr("Add a condition")
            onClicked: {
                root.stateEvaluator.addChildEvaluator()
            }
        }
    }

    Component {
        id: stateQuestionPageComponent
        Page {
            header: NymeaHeader {
                text: qsTr("Edit condition...")

                onBackPressed: pageStack.pop()
            }

            ColumnLayout {
                anchors.fill: parent

                Repeater {
                    model: ListModel {
                        ListElement {
                            iconName: "../images/state.svg"
                            text: qsTr("When one of my things is in a certain state")
                            method: "editStateDescriptor"

                        }
                        ListElement {
                            iconName: "../images/state-interface.svg"
                            text: qsTr("When a thing of a given type enters a state")
                            method: "editInterfaceStateDescriptor"
                        }
                    }
                    delegate: NymeaSwipeDelegate {
                        Layout.fillWidth: true
                        Layout.preferredHeight: Style.largeDelegateHeight
                        iconName: model.iconName
                        text: model.text
                        progressive: true
                        iconSize: Style.iconSize * 2

                        onClicked: {
                            root[model.method]()
                        }
                    }
                }
            }
        }
    }
}
