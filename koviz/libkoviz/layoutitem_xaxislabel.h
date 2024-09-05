#ifndef LAYOUTITEM_XAXISLABEL_H
#define LAYOUTITEM_XAXISLABEL_H

#include <QFontMetrics>
#include "layoutitem_paintable.h"
#include "bookmodel.h"

class XAxisLabelLayoutItem : public PaintableLayoutItem
{
public:
    XAxisLabelLayoutItem(const QFontMetrics& fontMetrics,
                         PlotBookModel* bookModel,
                         const QModelIndex& plotIdx);
    ~XAxisLabelLayoutItem();
    virtual Qt::Orientations expandingDirections() const;
    virtual QRect  geometry() const;
    virtual bool  isEmpty() const;
    virtual QSize  maximumSize() const;
    virtual QSize  minimumSize() const;
    virtual void  setGeometry(const QRect &r);
    virtual QSize  sizeHint() const;
    virtual void paint(QPainter* painter,
                       const QRect& R, const QRect& RG,
                       const QRect& C, const QRectF& M);

private:
    QFontMetrics _fontMetrics;
    PlotBookModel* _bookModel;
    QModelIndex _plotIdx;
    QRect _rect;
    QString _xAxisLabelText() const;
};

#endif // LAYOUTITEM_XAXISLABEL_H
