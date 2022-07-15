// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#ifndef DBMANAGER_H
#define DBMANAGER_H

#include <QObject>
#include <QString>
#include <QSqlDatabase>

class QSqlQuery;

/**
 * @class DBManager
 * @short Class for database initialization and applying changes in its records
 */
class DBManager : public QObject
{
    Q_OBJECT
public:
    explicit DBManager(QObject *parent = nullptr);

Q_SIGNALS:
    // emitted with the name of the table that has been changed
    void databaseTableChanged(QString table);

public:
    void addBookmark(const QVariantMap &bookmarkdata);
    void removeBookmark(const QString &url);
    bool isBookmarked(const QString &url) const;

    void addToHistory(const QVariantMap &pagedata);
    void removeFromHistory(const QString &url);
    void clearHistory();

    void updateIcon(const QString &url, const QString &iconSource);
    void updateLastVisited(const QString &url);

    inline QSqlDatabase database() {
        return m_database;
    }

private:
    // version of database schema
    int version();
    void setVersion(int v);

    // migration from earlier versions
    bool migrate();
    bool migrateTo1();

    // limit the size of history table
    void trimHistory();
    // drop unused icons
    void trimIcons();

    // execute SQL statement
    bool execute(const QString &command);
    bool execute(QSqlQuery &query);

    // methods for manipulation of bookmarks or history tables
    void addRecord(const QString &table, const QVariantMap &pagedata);
    void removeRecord(const QString &table, const QString &url);
    void removeAllRecords(const QString &table);
    void updateIconRecord(const QString &table, const QString &url, const QString &iconSource);
    void setLastVisitedRecord(const QString &table, const QString &url);
    bool hasRecord(const QString &table, const QString &url) const;

    QSqlDatabase m_database;
};

#endif // DBMANAGER_H
