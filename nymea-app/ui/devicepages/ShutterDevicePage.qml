// SPDX-License-Identifier: GPL-3.0-or-later

/* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * *
*
* Copyright (C) 2013 - 2024, nymea GmbH
* Copyright (C) 2024 - 2025, chargebyte austria GmbH
*
* This file is part of nymea-app.
*
* nymea-app is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.
*
* nymea-app is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
* General Public License for more details.
*
* You should have received a copy of the GNU General Public License
* along with nymea-app. If not, see <https://www.gnu.org/licenses/>.
*
* * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * * */

import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import QtQuick.Layouts
import Qt5Compat.GraphicalEffects
import Nymea

import "../components"
import "../customviews"
import "../utils"

ThingPageBase {
    id: root

    readonly property bool landscape: width > height * 1.5
    readonly property bool isExtended: thing.thingClass.interfaces.indexOf("extendedclosable") >= 0
    readonly property bool isVenetian: thing.thingClass.interfaces.indexOf("venetianblind") >= 0

    readonly property StateType angleStateType: isVenetian ? thing.thingClass.stateTypes.findByName("angle") : null

    readonly property State movingState: thing.stateByName("moving")
    readonly property State percentageState: thing.stateByName("percentage")
    readonly property State angleState: isVenetian ? thing.states.getState(angleStateType.id) : null


    readonly property bool moving: movingState ? movingState.value === true : false

//    onMovingChanged: if (!moving) angleMovable.visible = false

    GridLayout {
        anchors.fill: parent
//        columns: root.isVenetian ?
//                     root.landscape ? 3 : 2
//                   : root.landscape ? 2 : 1
        columns: root.landscape ? 2 : 1

        CircleBackground {
            id: background
            Layout.fillHeight: true
            Layout.fillWidth: true
            Layout.margins: Style.hugeMargins

            Item {
                id: blind
                anchors.fill: parent

                Rectangle {
                    anchors.centerIn: parent
                    height: parent.height
                    width: 2
                    color: Style.accentColor
                    visible: root.angleState
                }

                Canvas {
                    id: canvas
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.angleState ? -parent.width / 4 - Style.smallMargins: 0
                    width: background.contentItem.width / (root.angleState ? 2 : 1)
                    height: background.contentItem.height

                    property real progress: root.percentageState ?
                                                percentageDragArea.pressed ? percentageDragArea.draggedProgress : root.percentageState.value  / 100
                                              : .5

                    anchors.verticalCenterOffset: -height * (1 - progress)

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        ctx.fillStyle = Style.tileForegroundColor
                        var segments = 10;
                        var segmentHeight = height / segments
                        var barHeight = segmentHeight - Style.smallMargins
                        for (var i = 0; i < segments; i++) {
                            ctx.fillRect(0, i * segmentHeight + (segmentHeight - barHeight) / 2, width, barHeight)
                        }
                    }
                }

                ActionQueue {
                    id: percentageActionQueue
                    thing: root.thing
                    stateName: "percentage"
                }

                MouseArea {
                    id: percentageDragArea
                    anchors.centerIn: parent
                    anchors.horizontalCenterOffset: root.angleState ? -parent.width / 4 - Style.smallMargins: 0
                    width: background.contentItem.width / (root.angleState ? 2 : 1)
                    height: background.contentItem.height
                    property real draggedProgress: Math.max(0, Math.min(1, mouseY / height))
                    onReleased: percentageActionQueue.sendValue(mouseY / height * 100)
                }

                Canvas {
                    id: angleCanvas
                    anchors.centerIn: parent
                    visible: root.angleState
                    anchors.horizontalCenterOffset: parent.width / 4
                    width: background.contentItem.width / (root.angleState ? 2 : 1)
                    height: background.contentItem.height

                    property real angle: root.angleState ?
                                                angleDragArea.pressed ? angleDragArea.draggedAngle : root.angleState.value
                                              : 0
                    onAngleChanged: requestPaint()

                    property real pendingAngle: angle

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        ctx.fillStyle = Style.tileForegroundColor

                        var segments = 10;
                        var segmentHeight = height / segments
                        var barHeight = Style.smallMargins
                        var barWidth = width / 4
                        ctx.beginPath();
                        for (var i = 0; i < segments; i++) {
                            ctx.save()
                            ctx.translate(barWidth / 2 + Style.smallMargins, i * segmentHeight + (segmentHeight - barHeight) / 2)
                            ctx.rotate(angleCanvas.angle * Math.PI / 180)
                            ctx.fillRect(-barWidth / 2, -barHeight / 2, width / 4, barHeight)
                            ctx.restore()
                        }
                        ctx.closePath()


                        ctx.strokeStyle = Style.accentColor
                        ctx.lineWidth = 2

                        ctx.save()
                        ctx.beginPath();
                        ctx.translate(barWidth / 2 + Style.smallMargins, (height - barHeight) / 2)
                        ctx.rotate(angleCanvas.pendingAngle * Math.PI / 180)
                        ctx.moveTo(-barWidth / 2, 0)
                        ctx.lineTo(width, 0)
                        ctx.stroke();
                        ctx.closePath();
                        ctx.restore()

                        ctx.strokeStyle = Style.tileForegroundColor

                        ctx.save()
                        ctx.beginPath();
                        ctx.translate(barWidth / 2 + Style.smallMargins, (height - barHeight) / 2)
                        ctx.rotate(angleCanvas.angle * Math.PI / 180)
                        ctx.moveTo(-barWidth / 2, 0)
                        ctx.lineTo(width, 0)
                        ctx.stroke();
                        ctx.closePath();
                        ctx.restore()
                    }

                }

                ActionQueue {
                    id: angleActionQueue
                    thing: root.thing
                    stateName: "angle"
                }

                MouseArea {
                    id: angleDragArea
                    visible: root.angleState
                    anchors.fill: angleCanvas
                    property real draggedAngle: root.angleState ? Math.min(root.angleStateType.maxValue,
                                                         Math.max(root.angleStateType.minValue,
                                                                  mouseY / height * (root.angleStateType.maxValue - root.angleStateType.minValue) + root.angleStateType.minValue))
                                                                : 0
                    onReleased: {
                        print("sending angle", draggedAngle)
                        angleCanvas.pendingAngle = draggedAngle
                        angleActionQueue.sendValue(draggedAngle)
                    }
                }

            }

            OpacityMask {
                anchors.fill: parent
                source: ShaderEffectSource {
                    sourceItem: blind
                    sourceRect: background.contentItem.childrenRect
                    hideSource: true
                }
                maskSource: background
            }

        }

        ShutterControls {
            id: shutterControls
            Layout.fillWidth: true
            size: Style.bigIconSize
            backgroundEnabled: true
            thing: root.thing
        }
    }
}
