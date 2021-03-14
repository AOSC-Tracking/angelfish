/***************************************************************************
 *                                                                         *
 *   SPDX-FileCopyrightText: 2014-2015 Sebastian Kügler <sebas@kde.org>    *
 *                           2021 Devin Lin <espidev@gmail.com>            *
 *                                                                         *
 *   SPDX-License-Identifier: GPL-2.0-or-later                             *
 *                                                                         *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.0
import QtWebEngine 1.4
import QtQuick.Controls 2.0 as Controls
import QtFeedback 5.0

import org.kde.kirigami 2.5 as Kirigami
import org.kde.mobile.angelfish 1.0

Item {
    id: navigation

    height: expandedHeight

    property bool navigationShown: true

    property int expandedHeight: Kirigami.Units.gridUnit * 3
    property int buttonSize: Kirigami.Units.gridUnit * 2
    property int gestureThreshold: height * 2
    
    property var tabsSheet
    
    signal activateUrlEntry;

    Rectangle { anchors.fill: parent; color: Kirigami.Theme.backgroundColor; }
    
    // left/right gesture icons
    Kirigami.Icon {
        id: leftGestureIcon
        anchors.margins: Kirigami.Units.gridUnit
        anchors.left: navigation.left
        anchors.top: navigation.top
        anchors.bottom: navigation.bottom
        anchors.verticalCenter: navigation.verticalCenter
        implicitWidth: height
        
        opacity: Math.abs(navContainer.x) / gestureThreshold
        source: "arrow-left"
        transform: Scale {
            origin.x: leftGestureIcon.implicitWidth / 2
            origin.y: leftGestureIcon.implicitWidth / 2
            xScale: Math.max(0, navContainer.x / gestureThreshold)
            yScale: Math.max(0, navContainer.x / gestureThreshold)
        }
    }
    Kirigami.Icon {
        id: rightGestureIcon
        anchors.margins: Kirigami.Units.gridUnit
        anchors.right: navigation.right
        anchors.top: navigation.top
        anchors.bottom: navigation.bottom
        anchors.verticalCenter: navigation.verticalCenter
        implicitWidth: height
        
        opacity: Math.abs(navContainer.x) / gestureThreshold
        source: "arrow-right"
        transform: Scale {
            origin.x: rightGestureIcon.implicitWidth / 2
            origin.y: rightGestureIcon.implicitWidth / 2
            xScale: Math.max(0, -navContainer.x / gestureThreshold)
            yScale: Math.max(0, -navContainer.x / gestureThreshold)
        }
    }
    
    Item {
        id: navContainer
        width: navigation.width
        height: navigation.height
        anchors.bottom: parent.bottom
        
        opacity: 1 - (Math.abs(navContainer.x) / (gestureThreshold * 2))
        
        // left/right gestures
        HapticsEffect {
            id: vibrate
            intensity: 0.5
            duration: Kirigami.Units.shortDuration
        }
        DragHandler {
            id: dragHandler
            target: parent
            yAxis.enabled: false
            xAxis.enabled: true
            xAxis.minimum: currentWebView.canGoForward ? -gestureThreshold : 0
            xAxis.maximum: currentWebView.canGoBack ? gestureThreshold : 0
            onActiveChanged: {
                xAnimator.restart(); // go back to center
                
                if (parent.x >= gestureThreshold && currentWebView.canGoBack) {
                    currentWebView.goBack()
                } else if (parent.x <= -gestureThreshold && currentWebView.canGoForward) {
                    currentWebView.goForward()
                }
            }
        }
        NumberAnimation on x {
            id: xAnimator
            running: !dragHandler.active
            duration: Kirigami.Units.longDuration
            easing.type: Easing.InOutQuad
            to: 0
        }
        onXChanged: {
            if ((x >= gestureThreshold && currentWebView.canGoBack) || (x <= -gestureThreshold && currentWebView.canGoForward)) {
                vibrate.start();
            }
        }
        
        RowLayout {
            id: layout
            anchors.fill: parent
            anchors.leftMargin: Kirigami.Units.gridUnit / 2
            anchors.rightMargin: Kirigami.Units.gridUnit / 2

            spacing: Kirigami.Units.smallSpacing
            Kirigami.Theme.inherit: true
            
            Controls.ToolButton {
                id: mainMenuButton
                icon.name: rootPage.privateMode ? "view-private" : "application-menu"
                visible: webBrowser.landscape || Settings.navBarMainMenu

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                Kirigami.Theme.inherit: true

                onClicked: globalDrawer.open()
            }

            Controls.ToolButton {
                visible: webBrowser.landscape || Settings.navBarTabs
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                Rectangle {
                    anchors.centerIn: parent
                    height: Kirigami.Units.gridUnit * 1.25
                    width: Kirigami.Units.gridUnit * 1.25

                    color: "transparent"
                    border.color: Kirigami.Theme.textColor
                    border.width: Kirigami.Units.gridUnit / 10
                    radius: Kirigami.Units.gridUnit / 5

                    Kirigami.Theme.inherit: true

                    Controls.Label {
                        anchors.centerIn: parent
                        height: Kirigami.Units.gridUnit
                        width: Kirigami.Units.gridUnit
                        fontSizeMode: Text.Fit
                        minimumPixelSize: 0
                        minimumPointSize: 0
                        clip: true
                        text: "%1".arg(tabs.count)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                        Kirigami.Theme.inherit: true
                    }
                }

                onClicked: tabsSheet.open()
            }

            Controls.ToolButton {
                id: backButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: currentWebView.canGoBack && Settings.navBarBack
                icon.name: "go-previous"

                Kirigami.Theme.inherit: true

                onClicked: currentWebView.goBack()
                onPressAndHold: {
                    historySheet.backHistory = true;
                    historySheet.open();
                }
            }

            Controls.ToolButton {
                id: forwardButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: currentWebView.canGoForward && Settings.navBarForward
                icon.name: "go-next"

                Kirigami.Theme.inherit: true

                onClicked: currentWebView.goForward()
                onPressAndHold: {
                    historySheet.backHistory = false;
                    historySheet.open();
                }
            }

            Controls.ToolButton {
                id: labelItem
                Layout.fillWidth: true
                Layout.preferredHeight: buttonSize

                property string scheme: UrlUtils.urlScheme(currentWebView.requestedUrl)

                Controls.ToolButton {
                    id: schemeIcon
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    icon.name: {
                        if (labelItem.scheme === "https") return "lock";
                        if (labelItem.scheme === "http") return "unlock";
                        return "";
                    }
                    visible: icon.name
                    height: buttonSize * 0.75
                    width: visible ? buttonSize * 0.75 : 0
                    Kirigami.Theme.inherit: true
                    background: Rectangle {
                        implicitWidth: schemeIcon.width
                        implicitHeight: schemeIcon.height
                        color: "transparent"
                    }
                    onClicked: activateUrlEntry()
                }

                Controls.Label {
                    anchors.left: schemeIcon.right
                    anchors.right: parent.right
                    anchors.top: parent.top
                    height: parent.height

                    text: {
                        if (labelItem.scheme === "http" || labelItem.scheme === "https") {
                            return UrlUtils.htmlFormattedUrl(currentWebView.requestedUrl)
                        }
                        return currentWebView.requestedUrl;
                    }
                    textFormat: Text.StyledText
                    elide: Text.ElideRight
                    verticalAlignment: Text.AlignVCenter
                    Kirigami.Theme.inherit: true
                }

                onClicked: activateUrlEntry()
            }

            Controls.ToolButton {
                id: reloadButton

                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: Settings.navBarReload
                icon.name: currentWebView.loading ? "process-stop" : "view-refresh"

                Kirigami.Theme.inherit: true

                onClicked: currentWebView.loading ? currentWebView.stopLoading() : currentWebView.reload()

            }

            Controls.ToolButton {
                id: optionsButton

                property string targetState: "overview"

                Layout.fillWidth: false
                Layout.preferredWidth: buttonSize
                Layout.preferredHeight: buttonSize

                visible: webBrowser.landscape || Settings.navBarContextMenu
                icon.name: "overflow-menu"

                Kirigami.Theme.inherit: true

                onClicked: contextDrawer.open()
            }
        }
    }

    states: [
        State {
            name: "shown"
            when: navigationShown
            AnchorChanges {
                target: navigation
                anchors.bottom: navigation.parent.bottom
                anchors.top: undefined
            }
        },
        State {
            name: "hidden"
            when: !navigationShown
            AnchorChanges {
                target: navigation
                anchors.bottom: undefined
                anchors.top: navigation.parent.bottom
            }
        }
    ]
    transitions: Transition {
        AnchorAnimation {
            duration: navigation.visible ? Kirigami.Units.longDuration : 0
        }
    }
}
