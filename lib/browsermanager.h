// SPDX-FileCopyrightText: 2014 Sebastian Kügler <sebas@kde.org>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef BOOKMARKSMANAGER_H
#define BOOKMARKSMANAGER_H

#include <QObject>
#include <QUrl>

#include "dbmanager.h"

class QSettings;

/**
 * @class BookmarksManager
 * @short Access to Bookmarks and History. This is a singleton for
 * administration and access to the various models and browser-internal
 * data.
 */
class BrowserManager : public QObject
{
    Q_OBJECT

    Q_PROPERTY(QUrl initialUrl READ initialUrl WRITE setInitialUrl NOTIFY initialUrlChanged)

public:
    static BrowserManager *instance();

    QUrl initialUrl() const;
    void setInitialUrl(const QUrl &initialUrl);

    bool isBookmarked(const QString &url) const;

Q_SIGNALS:
    void updated();

    void initialUrlChanged();

    void databaseTableChanged(QString table);

public Q_SLOTS:
    void addBookmark(const QVariantMap &bookmarkdata);
    void removeBookmark(const QString &url);

    void addToHistory(const QVariantMap &pagedata);
    void removeFromHistory(const QString &url);
    void clearHistory();

    void updateLastVisited(const QString &url);
    void updateIcon(const QString &url, const QString &iconSource);

private:
    // BrowserManager should only be createdd by calling the instance() function
    BrowserManager(QObject *parent = nullptr);

    DBManager *m_dbmanager;

    QUrl m_initialUrl;

    static BrowserManager *s_instance;
};

#endif // BOOKMARKSMANAGER_H
