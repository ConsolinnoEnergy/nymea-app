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
import QtQuick.Layouts
import QtQuick.Window
import Nymea

Dialog {
    id: root
    implicitWidth: Math.max(contentLabel.implicitWidth + app.margins * 2, 400)
    width: Math.min((parent ? parent.width : Screen.width) * .8, implicitWidth)
    x: (parent.width - width) / 2
    y: (parent.height - height) / 2

    property alias headerIcon: headerColorIcon.name
    property alias text: contentLabel.text
    default property alias children: content.children

    standardButtons: Dialog.Ok
    dim: true

    onClosed: root.destroy()

    Overlay.modeless: Rectangle {
        color: "#44000000"
    }

    Overlay.modal: Rectangle {
        color: "#44000000"
    }

    background: Rectangle {
        radius: Style.largeCornerRadius
        color: Style.colors.typography_Background_Default
    }

    header: Item {
        implicitHeight: headerRow.height + 2 * Style.smallMargins
        implicitWidth: parent.width
        visible: root.title.length > 0

        Rectangle {
            id: headerBackground
            anchors.fill: parent
            color: Style.colors.menu_Header_Footer_Background
            topLeftRadius: Style.largeCornerRadius
            topRightRadius: Style.largeCornerRadius
        }

        RowLayout {
            id: headerRow
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
                topMargin: Style.smallMargins
                leftMargin: Style.margins
                rightMargin: Style.margins
            }
            spacing: Style.margins
            ColorIcon {
                id: headerColorIcon
                Layout.preferredHeight: Style.hugeIconSize
                Layout.preferredWidth: height
                color: Style.colors.brand_Basic_Icon_accent
                visible: name.length > 0
            }

            Label {
                id: titleLabel
                Layout.fillWidth: true
                Layout.margins: Style.smallMargins
                wrapMode: Text.WrapAtWordBoundaryOrAnywhere
                text: root.title
                color: Style.colors.typography_Headlines_H2
                font: Style.newH2Font
            }
        }
    }
    contentItem: ColumnLayout {
        id: content

        Label {
            id: contentLabel
            Layout.fillWidth: true
            wrapMode: Text.WrapAtWordBoundaryOrAnywhere
            visible: text.length > 0
            font: Style.newParagraphFont
            color: Style.colors.typography_Basic_Default
        }
    }
}
