// SPDX-FileCopyrightText: 2020 Jonah Brüchert <jbb@kaidan.im>
//
// SPDX-License-Identifier: GPL-2.0-or-later

#pragma once

#include <QObject>
#include <QQuickWebEngineProfile>
#include <QWebEngineUrlRequestInterceptor>

class AngelfishWebProfile : public QQuickWebEngineProfile
{
    Q_OBJECT

    Q_PROPERTY(QObject *questionLoader MEMBER m_questionLoader NOTIFY questionLoaderChanged)
    Q_PROPERTY(QWebEngineUrlRequestInterceptor *urlInterceptor WRITE setUrlInterceptor READ urlInterceptor NOTIFY urlInterceptorChanged)

public:
    explicit AngelfishWebProfile(QObject *parent = nullptr);

private:
    void handleDownload(QQuickWebEngineDownloadItem *downloadItem);
    void handleDownloadFinished(QQuickWebEngineDownloadItem *downloadItem);

    QObject *m_questionLoader;
    Q_SIGNAL void questionLoaderChanged();

    // A valid property needs a read function, and there is no getter in QQuickWebEngineProfile
    // so store a pointer ourselves
    QWebEngineUrlRequestInterceptor *m_urlInterceptor;
    QWebEngineUrlRequestInterceptor *urlInterceptor() const;
    void setUrlInterceptor(QWebEngineUrlRequestInterceptor *urlRequestInterceptor);
    Q_SIGNAL void urlInterceptorChanged();
};
