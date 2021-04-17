/***************************************************************************
 *                                                                         *
 *   SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>           *
 *   SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>          *
 *                                                                         *
 *   SPDX-License-Identifier: GPL-2.0-or-later                             *
 *                                                                         *
 ***************************************************************************/

#include "bookmarkshistorymodel.h"
#include "browsermanager.h"

#include <QDateTime>
#include <QDebug>
#include <QSqlError>
#include <QSqlQuery>

constexpr int QUERY_LIMIT = 1000;

BookmarksHistoryModel::BookmarksHistoryModel(QObject *parent)
    : SqlQueryModel(parent)
{
    connect(BrowserManager::instance(), &BrowserManager::databaseTableChanged, this, &BookmarksHistoryModel::onDatabaseChanged);
}

void BookmarksHistoryModel::setActive(bool a)
{
    if (m_active == a)
        return;
    m_active = a;
    if (m_active)
        setQuery();
    else
        clear();
    emit activeChanged();
}

void BookmarksHistoryModel::setBookmarks(bool b)
{
    if (m_bookmarks == b)
        return;
    m_bookmarks = b;
    setQuery();
    emit bookmarksChanged();
}

void BookmarksHistoryModel::setHistory(bool h)
{
    if (m_history == h)
        return;
    m_history = h;
    setQuery();
    emit historyChanged();
}

void BookmarksHistoryModel::setFilter(const QString &f)
{
    if (m_filter == f)
        return;
    m_filter = f;
    setQuery();
    emit filterChanged();
}

void BookmarksHistoryModel::onDatabaseChanged(const QString &table)
{
    if ((table == QLatin1String("bookmarks") && m_bookmarks) || (table == QLatin1String("history") && m_history))
        setQuery();
}

void BookmarksHistoryModel::setQuery()
{
    if (!m_active)
        return;

    QString command;
    const auto b = QStringLiteral(u"SELECT rowid AS id, url, title, icon, :now - lastVisited AS lastVisitedDelta, %1 AS bookmarked FROM %2 ");
    const QStringView filter = m_filter.isEmpty() ? QStringView() : QStringView(u"WHERE url LIKE '%' || :filter || '%' OR title LIKE '%' || :filter || '%'");
    const bool includeHistory = m_history && !(m_bookmarks && m_filter.isEmpty());

    if (m_bookmarks) {
        command = b.arg(1).arg(QStringView(u"bookmarks"));
        command += filter;
    }

    if (m_bookmarks && includeHistory) {
        command += QStringView(u"\n UNION \n");
    }

    if (includeHistory) {
        command += b.arg(0).arg(QStringView(u"history"));
        command += filter;
    }

    command += QStringView(u"\n ORDER BY bookmarked DESC, lastVisitedDelta ASC");

    if (includeHistory) {
        command += QStringLiteral(u"\n LIMIT %1").arg(QUERY_LIMIT);
    }

    const qint64 ref = QDateTime::currentSecsSinceEpoch();
    QSqlQuery query;
    if (!query.prepare(command)) {
        qWarning() << Q_FUNC_INFO << "Failed to prepare SQL statement";
        qWarning() << query.lastQuery();
        qWarning() << query.lastError();
        return;
    }

    if (!m_filter.isEmpty())
        query.bindValue(QStringLiteral(":filter"), m_filter);

    query.bindValue(QStringLiteral(":now"), ref);

    if (!query.exec()) {
        qWarning() << Q_FUNC_INFO << "Failed to execute SQL statement";
        qWarning() << query.lastQuery();
        qWarning() << query.lastError();
        return;
    }

    SqlQueryModel::setQuery(query);
}
