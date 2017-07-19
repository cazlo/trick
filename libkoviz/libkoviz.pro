#-------------------------------------------------
#
# Project created by QtCreator 2015-11-23T14:52:08
#
#-------------------------------------------------

QT       += core gui
QT       += xml

greaterThan(QT_MAJOR_VERSION, 4): QT += widgets

TARGET = koviz
TEMPLATE = lib

include($$PWD/../koviz.pri)

CONFIG += staticlib

INCLUDEPATH += $$PWD/..

release {
    QMAKE_CXXFLAGS_RELEASE -= -g
}

DESTDIR = $$PWD/../lib
BUILDDIR = $$PWD/../build/libkoviz
OBJECTS_DIR = $$BUILDDIR/obj
MOC_DIR     = $$BUILDDIR/moc
RCC_DIR     = $$BUILDDIR/rcc
UI_DIR      = $$BUILDDIR/ui


SOURCES += bookmodel.cpp \
           bookview_pagetitle.cpp \
           bookview_plot.cpp \
           bookview.cpp \
           bookview_page.cpp \
           bookview_plottitle.cpp \
           bookidxview.cpp \
           bookview_linedruler.cpp \
           bookview_curves.cpp \
           bookview_corner.cpp \
           bookview_labeledruler.cpp \
           bookview_yaxislabel.cpp \
           bookview_xaxislabel.cpp \
           bookview_tablepage.cpp \
           bookview_table.cpp \
           dp.cpp \
           varswidget.cpp \
           dptreewidget.cpp \
           monteinputsview.cpp \
           dpfilterproxymodel.cpp \
           options.cpp \
           frame.cpp \
           job.cpp \
           simobject.cpp \
           sjobexecthreadinfo.cpp \
           snap.cpp \
           thread.cpp \
           utils.cpp \
           unit.cpp \
           versionnumber.cpp \
           csv.cpp \
           monte.cpp \
           montemodel.cpp \
           parameter.cpp \
           runs.cpp \
           snaptable.cpp \
           timeit.cpp \
           timeit_linux.cpp \
           timeit_win32.cpp \
           timestamps.cpp \
           trickcurvemodel.cpp \
           trickmodel.cpp \
           tricktablemodel.cpp \
           plotmainwindow.cpp \
           rangeinput.cpp


HEADERS  += bookmodel.h \
            bookidxview.h \
            bookview.h \
            bookview_corner.h \
            bookview_curves.h \
            bookview_labeledruler.h \
            bookview_linedruler.h \
            bookview_page.h \
            bookview_pagetitle.h \
            bookview_plot.h \
            bookview_plottitle.h \
            bookview_xaxislabel.h \
            bookview_yaxislabel.h \
            bookview_tablepage.h \
            bookview_table.h \
            dp.h \
            varswidget.h \
            dptreewidget.h \
            monteinputsview.h \
            dpfilterproxymodel.h \
            options.h \
            frame.h \
            job.h \
            simobject.h \
            sjobexecthreadinfo.h \
            snap.h \
            thread.h \
            utils.h \
            unit.h \
            versionnumber.h \
            csv.h \
            monte.h \
            montemodel.h \
            numsortitem.h \
            parameter.h \
            role.h \
            roleparam.h \
            roundoff.h \
            runs.h \
            snaptable.h \
            timeit.h \
            timeit_linux.h \
            timeit_win32.h \
            timestamps.h \
            trick_types.h \
            trickcurvemodel.h \
            trickmodel.h \
            tricktablemodel.h \
            plotmainwindow.h \
            rangeinput.h

FLEXSOURCES = product_lexer.l
BISONSOURCES = product_parser.y

flexsource.input = FLEXSOURCES
flexsource.output = ${QMAKE_FILE_BASE}.cpp
flexsource.commands = flex --header-file=${QMAKE_FILE_BASE}.h \
                           -o ${QMAKE_FILE_BASE}.cpp ${QMAKE_FILE_IN}
flexsource.variable_out = SOURCES
flexsource.name = Flex Sources ${QMAKE_FILE_IN}
flexsource.CONFIG += target_predeps
QMAKE_EXTRA_COMPILERS += flexsource

flexheader.input = FLEXSOURCES
flexheader.output = ${QMAKE_FILE_BASE}.h
flexheader.commands = @true
flexheader.variable_out = HEADERS
flexheader.name = Flex Headers ${QMAKE_FILE_IN}
flexheader.CONFIG += target_predeps no_link
QMAKE_EXTRA_COMPILERS += flexheader

bisonsource.input = BISONSOURCES
bisonsource.output = ${QMAKE_FILE_BASE}.cpp
bisonsource.commands = bison -d --defines=${QMAKE_FILE_BASE}.h \
                             -o ${QMAKE_FILE_BASE}.cpp ${QMAKE_FILE_IN}
bisonsource.variable_out = SOURCES
bisonsource.name = Bison Sources ${QMAKE_FILE_IN}
bisonsource.CONFIG += target_predeps
QMAKE_EXTRA_COMPILERS += bisonsource

bisonheader.input = BISONSOURCES
bisonheader.output = ${QMAKE_FILE_BASE}.h
bisonheader.commands = @true
bisonheader.variable_out = HEADERS
bisonheader.name = Bison Headers ${QMAKE_FILE_IN}
bisonheader.CONFIG += target_predeps no_link
QMAKE_EXTRA_COMPILERS += bisonheader

OTHER_FILES += \
    $$FLEXSOURCES \
    $$BISONSOURCES
