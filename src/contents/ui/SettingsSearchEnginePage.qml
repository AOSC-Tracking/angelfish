// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
// SPDX-FileCopyrightText: 2020 Jonah Brüchert  <jbb@kaidan.im>
// SPDX-License-Identifier: GPL-2.0-or-later

import QtQuick 2.3
import QtQuick.Controls 2.4 as Controls
import QtQuick.Layouts 1.11

import org.kde.kirigami 2.7 as Kirigami
import org.kde.kirigamiaddons.labs.mobileform 0.1 as MobileForm

import org.kde.angelfish 1.0

Kirigami.ScrollablePage {
    title: i18n("Search Engine")

    leftPadding: 0
    rightPadding: 0
    topPadding: Kirigami.Units.gridUnit
    bottomPadding: Kirigami.Units.gridUnit

    Kirigami.Theme.colorSet: Kirigami.Theme.Window
    Kirigami.Theme.inherit: false

    property string baseUrl: Settings.searchBaseUrl

    ColumnLayout {
        id: list
        spacing: 0

        property string customName: i18n("Custom")

        MobileForm.FormCard {
            Layout.fillWidth: true

            contentItem: ColumnLayout {
                spacing: 0
                
                Repeater {
                    model: ListModel {
                        id: searchEngines

                        ListElement {
                            title: "Bing"
                            url: "https://www.bing.com/search?q="
                        }

                        ListElement {
                            title: "DuckDuckGo"
                            url: "https://start.duckduckgo.com/?q="
                        }

                        ListElement {
                            title: "Ecosia"
                            url: "https://www.ecosia.org/search?q="
                        }

                        ListElement {
                            title: "Google"
                            url: "https://www.google.com/search?q="
                        }

                        ListElement {
                            title: "Lilo"
                            url: "https://search.lilo.org/searchweb.php?q="
                        }

                        ListElement {
                            title: "Peekier"
                            url: "https://peekier.com/#!"
                        }

                        ListElement {
                            title: "Qwant"
                            url: "https://www.qwant.com/?q="
                        }

                        ListElement {
                            title: "Qwant Junior"
                            url: "https://www.qwantjunior.com/?q="
                        }

                        ListElement {
                            title: "StartPage"
                            url: "https://www.startpage.com/do/dsearch?query="
                        }

                        ListElement {
                            title: "Swisscows"
                            url: "https://swisscows.com/web?query="
                        }

                        ListElement {
                            title: "Wikipedia"
                            url: "https://wikipedia.org/wiki/Special:Search?search="
                        }
                    }

                    delegate: MobileForm.FormRadioDelegate {
                        checked: model.url === baseUrl
                        text: model.title
                        onClicked: {
                            if (model.title !== list.customName)
                                baseUrl = model.url;
                            else {
                                searchEnginePopup.open();
                            }
                            // restore property binding
                            checked = Qt.binding(function() { return (model.url === baseUrl) });
                        }
                    }
                }
            }
        }
        
        // custom search engine input sheet
        InputSheet {
            id: searchEnginePopup
            title: i18n("Search Engine")
            description: i18n("Base URL of your preferred search engine")
            text: Settings.searchCustomUrl
            onAccepted: {
                const url = UrlUtils.urlFromUserInput(searchEnginePopup.text);
                Settings.searchCustomUrl = url;
                baseUrl = url;
                searchEngines.setProperty(searchEngines.count - 1, "url", url);
            }
        }
    }

    onBaseUrlChanged: {
        Settings.searchBaseUrl = UrlUtils.urlFromUserInput(baseUrl);
    }

    Component.onCompleted: {
        searchEngines.append({ "title": list.customName, "url": Settings.searchCustomUrl });
    }
}
