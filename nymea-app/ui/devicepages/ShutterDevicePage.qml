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

    onMovingChanged: {
        if (!angleCanvas.targetActive) {
            return
        }
        if (moving) {
            angleCanvas.targetMotionObserved = true
        } else if (angleCanvas.targetMotionObserved) {
            angleCanvas.targetActive = false
        }
    }

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

                    property real reportedAngle: root.angleState ? root.angleState.value : 0
                    property real angle: root.angleState
                                                 ? angleDragArea.pressed ? angleDragArea.draggedAngle : reportedAngle
                                                 : 0
                    property real targetAngle: 0
                    property real targetStartAngle: 0
                    property bool targetActive: false
                    property bool targetMovementObserved: false
                    property bool targetMotionObserved: false
                    property real targetOpacity: targetActive ? 1 : 0
                    readonly property real targetTolerance: root.angleStateType && root.angleStateType.stepSize > 0
                                                                    ? Math.max(1, root.angleStateType.stepSize / 2)
                                                                    : 1

                    Behavior on angle {
                        enabled: !angleDragArea.pressed
                        NumberAnimation { duration: Style.slowAnimationDuration; easing.type: Easing.InOutQuad }
                    }
                    Behavior on targetOpacity {
                        NumberAnimation { duration: Style.animationDuration; easing.type: Easing.InOutQuad }
                    }

                    onAngleChanged: {
                        requestPaint()
                        if (targetActive && targetMovementObserved && !angleDragArea.pressed &&
                                Math.abs(angle - targetAngle) <= targetTolerance) {
                            targetActive = false
                        }
                    }
                    onReportedAngleChanged: {
                        if (targetActive && Math.abs(reportedAngle - targetStartAngle) > targetTolerance) {
                            targetMovementObserved = true
                            targetSettleTimer.restart()
                        }
                    }
                    onTargetAngleChanged: requestPaint()
                    onTargetOpacityChanged: requestPaint()
                    onTargetActiveChanged: {
                        requestPaint()
                        if (targetActive) {
                            targetTimeout.restart()
                        } else {
                            targetTimeout.stop()
                            targetSettleTimer.stop()
                        }
                    }

                    Timer {
                        id: targetSettleTimer
                        interval: Style.sleepyAnimationDuration
                        onTriggered: {
                            if (angleCanvas.targetActive && angleCanvas.targetMovementObserved) {
                                angleCanvas.targetActive = false
                            }
                        }
                    }

                    Timer {
                        id: targetTimeout
                        interval: 15000
                        onTriggered: angleCanvas.targetActive = false
                    }

                    onPaint: {
                        var ctx = getContext("2d");
                        ctx.reset();

                        var segments = 10;
                        var segmentHeight = height / segments
                        var barHeight = Style.smallMargins
                        var barWidth = width / 4
                        var pivotX = barWidth / 2 + Style.smallMargins
                        var pivotY = (height - barHeight) / 2
                        var targetRadius = Math.max(0, Math.min(width - pivotX - Style.smallMargins,
                                                               height / 2 - Style.smallMargins))

                        if (targetOpacity > 0 && targetRadius > 0) {
                            var currentRadians = angle * Math.PI / 180
                            var targetRadians = targetAngle * Math.PI / 180

                            ctx.beginPath()
                            ctx.moveTo(pivotX, pivotY)
                            ctx.arc(pivotX, pivotY, targetRadius, currentRadians, targetRadians,
                                    targetRadians < currentRadians)
                            ctx.closePath()
                            ctx.fillStyle = Qt.rgba(Style.accentColor.r, Style.accentColor.g,
                                                    Style.accentColor.b, .2 * targetOpacity)
                            ctx.fill()
                        }

                        ctx.fillStyle = Style.tileForegroundColor
                        ctx.beginPath();
                        for (var i = 0; i < segments; i++) {
                            ctx.save()
                            ctx.translate(pivotX, i * segmentHeight + (segmentHeight - barHeight) / 2)
                            ctx.rotate(angleCanvas.angle * Math.PI / 180)
                            ctx.fillRect(-barWidth / 2, -barHeight / 2, width / 4, barHeight)
                            ctx.restore()
                        }
                        ctx.closePath()

                        ctx.strokeStyle = Style.tileForegroundColor
                        ctx.lineWidth = 2
                        ctx.save()
                        ctx.beginPath();
                        ctx.translate(pivotX, pivotY)
                        ctx.rotate(angleCanvas.angle * Math.PI / 180)
                        ctx.moveTo(-barWidth / 2, 0)
                        ctx.lineTo(width, 0)
                        ctx.stroke();
                        ctx.closePath();
                        ctx.restore()

                        if (targetOpacity > 0) {
                            var markerRadians = targetAngle * Math.PI / 180
                            var markerX = pivotX + Math.cos(markerRadians) * targetRadius
                            var markerY = pivotY + Math.sin(markerRadians) * targetRadius

                            ctx.strokeStyle = Qt.rgba(Style.accentColor.r, Style.accentColor.g,
                                                      Style.accentColor.b, targetOpacity)
                            ctx.fillStyle = ctx.strokeStyle
                            ctx.lineWidth = 2
                            ctx.save()
                            ctx.beginPath()
                            ctx.translate(pivotX, pivotY)
                            ctx.rotate(markerRadians)
                            ctx.moveTo(-barWidth / 2, 0)
                            ctx.lineTo(targetRadius, 0)
                            ctx.stroke()
                            ctx.restore()

                            ctx.beginPath()
                            ctx.arc(markerX, markerY, Math.max(3, Style.smallMargins / 2), 0, Math.PI * 2)
                            ctx.fill()
                        }
                    }

                    ColorIcon {
                        anchors { top: parent.top; right: parent.right; margins: Style.smallMargins }
                        width: Style.iconSize
                        height: width
                        name: "qrc:/icons/up.svg"
                        color: angleDragArea.pressed && angleDragArea.mouseY <= angleDragArea.endpointZoneHeight
                               ? Style.accentColor : Style.iconColor
                        opacity: .6
                    }

                    ColorIcon {
                        anchors { bottom: parent.bottom; right: parent.right; margins: Style.smallMargins }
                        width: Style.iconSize
                        height: width
                        name: "qrc:/icons/down.svg"
                        color: angleDragArea.pressed && angleDragArea.mouseY >= angleDragArea.height - angleDragArea.endpointZoneHeight
                               ? Style.accentColor : Style.iconColor
                        opacity: .6
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
                    readonly property real endpointZoneHeight: Math.min(height / 4, Style.bigIconSize)
                    property point pressPosition: Qt.point(0, 0)

                    onPressed: pressPosition = Qt.point(mouseX, mouseY)
                    onReleased: {
                        var distance = Math.sqrt(Math.pow(mouseX - pressPosition.x, 2) +
                                                 Math.pow(mouseY - pressPosition.y, 2))
                        var targetAngle = draggedAngle
                        if (distance < Qt.styleHints.startDragDistance) {
                            if (pressPosition.y <= endpointZoneHeight) {
                                targetAngle = root.angleStateType.minValue
                            } else if (pressPosition.y >= height - endpointZoneHeight) {
                                targetAngle = root.angleStateType.maxValue
                            }
                        }

                        angleCanvas.targetStartAngle = root.angleState.value
                        angleCanvas.targetMovementObserved = false
                        angleCanvas.targetMotionObserved = root.moving
                        angleCanvas.targetAngle = targetAngle
                        angleCanvas.targetActive = true
                        angleActionQueue.sendValue(targetAngle)
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
