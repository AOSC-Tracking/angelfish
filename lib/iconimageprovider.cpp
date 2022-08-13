// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
// SPDX-FileCopyrightText: 2020 Rinigus <rinigus.git@gmail.com>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#include "iconimageprovider.h"

#include <QBuffer>
#include <QByteArray>
#include <QDebug>
#include <QImage>
#include <QPixmap>
#include <QQmlApplicationEngine>
#include <QSqlError>
#include <QSqlQuery>
#include <QString>

#include "browsermanager.h"

// As there is only one instance of the IconImageProvider
// and icons are added into the database using static methods,
// engine has to be accessed via static property
QQmlApplicationEngine *IconImageProvider::s_engine;

IconImageProvider::IconImageProvider(QQmlApplicationEngine *engine)
    : QQuickImageProvider(QQmlImageProviderBase::Image)
{
    s_engine = engine;
}

QString IconImageProvider::providerId()
{
    return QStringLiteral("angelfish-favicon");
}

QString IconImageProvider::storeImage(const QString &iconSource)
{
    if (iconSource.isEmpty()) {
        return {};
    }

    const QLatin1String prefix_favicon = QLatin1String("image://favicon/");
    if (!iconSource.startsWith(prefix_favicon)) {
        // don't know what to do with it, return as it is
        qWarning() << Q_FUNC_INFO << "Don't know how to store image" << iconSource;
        return iconSource;
    }

    // new uri for image
    QString url = QStringLiteral("image://%1/%2").arg(providerId(), iconSource.mid(prefix_favicon.size()));

    // check if we have that image already
    QSqlQuery query_check(BrowserManager::instance()->databaseManager()->database());
    query_check.prepare(QStringLiteral("SELECT 1 FROM icons WHERE url = :url LIMIT 1"));
    query_check.bindValue(QStringLiteral(":url"), url);
    if (!query_check.exec()) {
        qWarning() << Q_FUNC_INFO << "Failed to execute SQL statement";
        qWarning() << query_check.lastQuery();
        qWarning() << query_check.lastError();
        return iconSource; // as something is wrong
    }

    if (query_check.next()) {
        // there is corresponding record in the database already
        // no need to store it again
        return url;
    }
    query_check.finish();

    // Store new icon
    QQuickImageProvider *provider = dynamic_cast<QQuickImageProvider *>(s_engine->imageProvider(QStringLiteral("favicon")));
    if (!provider) {
        qWarning() << Q_FUNC_INFO << "Failed to load image provider" << url;
        return iconSource; // as something is wrong
    }

    QByteArray data;
    QBuffer buffer(&data);
    buffer.open(QIODevice::WriteOnly);

    const QSize szRequested;
    const QString providerIconName = iconSource.mid(prefix_favicon.size());
    switch (provider->imageType()) {
    case QQmlImageProviderBase::Image: {
        const QImage image = provider->requestImage(providerIconName, nullptr, szRequested);
        if (!image.save(&buffer, "PNG")) {
            qWarning() << Q_FUNC_INFO << "Failed to save image" << url;
            return iconSource; // as something is wrong
        }
        break;
    }
    case QQmlImageProviderBase::Pixmap: {
        const QPixmap image = provider->requestPixmap(providerIconName, nullptr, szRequested);
        if (!image.save(&buffer, "PNG")) {
            qWarning() << Q_FUNC_INFO << "Failed to save pixmap" << url;
            return iconSource; // as something is wrong
        }
        break;
    }
    default:
        qWarning() << Q_FUNC_INFO << "Unsupported image provider" << provider->imageType();
        return iconSource; // as something is wrong
    }

    QSqlQuery query_write(BrowserManager::instance()->databaseManager()->database());
    query_write.prepare(QStringLiteral("INSERT INTO icons(url, icon) VALUES (:url, :icon)"));
    query_write.bindValue(QStringLiteral(":url"), url);
    query_write.bindValue(QStringLiteral(":icon"), data);
    if (!query_write.exec()) {
        qWarning() << Q_FUNC_INFO << "Failed to execute SQL statement";
        qWarning() << query_write.lastQuery();
        qWarning() << query_write.lastError();
        return iconSource; // as something is wrong
    }

    return url;
}

QImage IconImageProvider::requestImage(const QString &id, QSize *size, const QSize & /*requestedSize*/)
{
    QSqlQuery query(BrowserManager::instance()->databaseManager()->database());
    query.prepare(QStringLiteral("SELECT icon FROM icons WHERE url LIKE :url LIMIT 1"));
    query.bindValue(QStringLiteral(":url"), QStringLiteral("image://%1/%2%").arg(providerId(), id));
    if (!query.exec()) {
        qWarning() << Q_FUNC_INFO << "Failed to execute SQL statement";
        qWarning() << query.lastQuery();
        qWarning() << query.lastError();
        return {};
    }

    if (query.next()) {
        const QImage image = QImage::fromData(query.value(0).toByteArray());
        if (size) {
            size->setHeight(image.height());
            size->setWidth(image.width());
        }
        return image;
    }

    qWarning() << "Failed to find icon for" << id;
    return {};
}
