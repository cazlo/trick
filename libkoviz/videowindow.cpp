#include "videowindow.h"

static void wakeup(void *ctx)
{
    VideoWindow *mainwindow = (VideoWindow *)ctx;
    emit mainwindow->mpv_events();
}

VideoWindow::VideoWindow(QWidget *parent) :
    QMainWindow(parent)
{
    std::setlocale(LC_NUMERIC, "C");
    setFocusPolicy(Qt::StrongFocus);
    setWindowTitle("Koviz MPV");
    setMinimumSize(640, 480);

    QMenu *menu = menuBar()->addMenu(tr("&File"));
    QAction *on_open = new QAction(tr("&Open"), this);
    connect(on_open, &QAction::triggered, this, &VideoWindow::on_file_open);
    menu->addAction(on_open);

    statusBar();

    mpv = mpv_create();
    if (!mpv) {
        throw std::runtime_error("can't create mpv instance");
    }

    // Create a video child window. Force Qt to create a native window, and
    // pass the window ID to the mpv wid option. Works on: X11, win32, Cocoa
    // If you have a HWND, use: int64_t wid = (intptr_t)hwnd;
    mpv_container = new QWidget(this);
    setCentralWidget(mpv_container);
    mpv_container->setAttribute(Qt::WA_DontCreateNativeAncestors);
    mpv_container->setAttribute(Qt::WA_NativeWindow);
    int64_t wid = mpv_container->winId();
    mpv_set_option(mpv, "wid", MPV_FORMAT_INT64, &wid);

    mpv_set_option_string(mpv, "input-default-bindings", "yes");
    mpv_set_option_string(mpv, "input-vo-keyboard", "yes");
    mpv_set_option_string(mpv, "keep-open", "always");
    mpv_observe_property(mpv, 0, "time-pos", MPV_FORMAT_DOUBLE);

    connect(this, &VideoWindow::mpv_events,
            this, &VideoWindow::on_mpv_events,
            Qt::QueuedConnection);
    mpv_set_wakeup_callback(mpv, wakeup, this);

    if (mpv_initialize(mpv) < 0) {
        throw std::runtime_error("mpv failed to initialize");
    }
}

void VideoWindow::seek_time(double time) {
    int isIdle;
    int ret = mpv_get_property(mpv,"core-idle",MPV_FORMAT_FLAG,&isIdle);
    if ( ret >= 0 ) {
        if ( isIdle && parentWidget()->isActiveWindow() ) {
            // Koviz is driving time
            QString com = QString("seek %1 absolute").arg(time);
            mpv_command_string(mpv, com.toLocal8Bit().data());
        }
    }
}

void VideoWindow::handle_mpv_event(mpv_event *event)
{
    switch (event->event_id) {
    case MPV_EVENT_PROPERTY_CHANGE: {
        mpv_event_property *prop = (mpv_event_property *)event->data;
        if (strcmp(prop->name, "time-pos") == 0) {
            if (prop->format == MPV_FORMAT_DOUBLE) {
                double time = *(double *)prop->data;
                std::stringstream ss;
                ss << "At: " << time;
                statusBar()->showMessage(QString::fromStdString(ss.str()));
                int isIdle;
                int ret = mpv_get_property(mpv,"core-idle",MPV_FORMAT_FLAG,
                                           &isIdle);
                if ( ret >= 0 ) {
                    if ( !isIdle || isActiveWindow() ) {
                        // If mpv playing, update time
                        // If mpv paused but still active, update time
                        // If mpv paused and koviz active, do not emit signal
                        emit timechangedByMpv(time);
                    }
                }
            } else if (prop->format == MPV_FORMAT_NONE) {
                statusBar()->showMessage("");
            }
        }
        break;
    }
    case MPV_EVENT_SHUTDOWN: {
        mpv_terminate_destroy(mpv);
        mpv = NULL;
        break;
    }
    default: ;
        // Ignore event
    }
}

// This slot is invoked by wakeup() (through the mpv_events signal).
void VideoWindow::on_mpv_events()
{
    // Process all events, until the event queue is empty.
    while (mpv) {
        mpv_event *event = mpv_wait_event(mpv, 0);
        if (event->event_id == MPV_EVENT_NONE) {
            break;
        }
        handle_mpv_event(event);
    }
}

void VideoWindow::on_file_open()
{
    QString filename = QFileDialog::getOpenFileName(this, "Open file");
    if (mpv) {
        const QByteArray c_filename = filename.toUtf8();
        const char *args[] = {"loadfile", c_filename.data(), NULL};
        mpv_command_async(mpv, 0, args);
    }
}

VideoWindow::~VideoWindow()
{
    if (mpv) {
        mpv_terminate_destroy(mpv);
    }
}
