/***************************************************************************
 *                                                                         *
 *   Copyright 2019 Simon Schmeisser <s.schmeisser@gmx.net>                *
 *   Copyright 2019 Jonah Brüchert <jbb@kaidan.im>                         *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   Free Software Foundation, Inc.,                                       *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.7
import QtQuick.Controls 2.2 as Controls
import QtQuick.Layouts 1.2

import org.kde.kirigami 2.5 as Kirigami
import org.kde.mobile.angelfish 1.0

import "regex-weburl.js" as RegexWebUrl

Controls.Drawer {
    id: overlay
    dragMargin: 0
    edge: Qt.BottomEdge
    width: parent.width

    bottomPadding: 0
    topPadding: 0
    rightPadding: 0
    leftPadding: 0

    property int buttonSize: Kirigami.Units.gridUnit * 2
    property int fullHeight: 0.9 * rootPage.height
    property bool openedState: false

    contentHeight: fullHeight - topPadding - bottomPadding
    contentWidth: parent.width - rightPadding - leftPadding
    contentItem: Item {
        width: parent.width
        height: parent.height

        RowLayout {
            id: editRow
            anchors.top: parent.top
            anchors.horizontalCenter: parent.horizontalCenter
            height: Kirigami.Units.gridUnit * 3
            width: parent.width - Kirigami.Units.gridUnit

            Controls.ToolButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                icon.name: "window-minimize"

                Kirigami.Theme.inherit: true

                onClicked: overlay.close()
            }

            Controls.TextField {
                id: urlInput

                Layout.fillWidth: true
                clip: true
                focus: false
                inputMethodHints: rootPage.privateMode ? Qt.ImhNoPredictiveText : Qt.ImhNone
                Kirigami.Theme.inherit: true

                onActiveFocusChanged: if (activeFocus) selectAll()
                onAccepted: applyUrl()
                onDisplayTextChanged: {
                    if (!openedState) return; // avoid filtering
                    if (displayText === "" || displayText.length > 2) {
                        urlFilter.filter = displayText;
                        timer.running = false;
                    }
                    else timer.running = true;
                }
                Keys.onEscapePressed: if (overlay.sheetOpen) overlay.close()

                Timer {
                    id: timer
                    repeat: false
                    interval: Math.max(1000, 3000 - urlInput.displayText.length * 1000)
                    onTriggered: urlFilter.filter = urlInput.displayText
                }

                function applyUrl() {
                    if (text.match(RegexWebUrl.re_weburl)) {
                        currentWebView.url = UrlUtils.urlFromUserInput(text);
                    } else {
                        currentWebView.url = UrlUtils.urlFromUserInput(BrowserManager.searchBaseUrl + text);
                    }
                    overlay.close();
                }
            }

            Controls.ToolButton {
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                icon.name: "go-next"

                Kirigami.Theme.inherit: true

                onClicked: urlInput.applyUrl();
            }
        }

        ListView {
            id: listView

            anchors {
                bottom: parent.bottom
                left: parent.left
                right: parent.right
                top: editRow.bottom
            }

            boundsBehavior: Flickable.StopAtBounds
            clip: true

            delegate: UrlDelegate {
                showRemove: false
                onClicked: overlay.close()
                highlightText: urlFilter.filter
                width: parent.width
            }

            model: BookmarksHistoryModel {
                id: urlFilter
                active: openedState
                bookmarks: true
                history: true
            }
        }
    }

    onOpened: {
        // check if the drawer was just slightly slided
        if (openedState) return;
        urlInput.text = currentWebView.requestedUrl;
        urlInput.forceActiveFocus();
        urlInput.selectAll();
        urlFilter.filter = "";
        openedState = true;
        listView.positionViewAtBeginning();
    }

    onClosed: {
        openedState = false;
        currentWebView.forceActiveFocus();
    }
}
