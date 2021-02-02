#include "bookidxview.h"

BookIdxView::BookIdxView(QWidget *parent) :
    QAbstractItemView(parent),
    _curvesView(0)
{
}

QTransform BookIdxView::_coordToPixelTransform()
{
    QTransform I;
    if ( !_curvesView ) return I;

    QRectF M = _mathRect();

    // Window coords (topleft)
    double u0 = 0.0;
    double v0 = 0.0;

    // Math coords (topleft)
    double x0 = M.topLeft().x();
    double y0 = M.topLeft().y();

    // TODO: if x0=-DBL_MAX and x1=+DBL_MAX etc
    double du = viewport()->rect().width();
    double dv = viewport()->rect().height();
    double dx = M.width();
    double dy = M.height();
    double a = du/dx;
    double b = dv/dy;
    double c = u0-a*x0;
    double d = v0-b*y0;

    QTransform T( a,    0,
                  0,    b,
                  c,    d);

    return T;
}

void BookIdxView::setCurvesView(QAbstractItemView *view)
{
    _curvesView = view;
}

// This window's math rect based on this windows rect(), and the
// plot's window and math rect
QRectF BookIdxView::_mathRect()
{
    if ( !_curvesView ) {
        fprintf(stderr, "koviz [bad scoobs]: BookIdxView::_mathRect() "
                        "called without _curvesView set.\n");
        exit(-1);
    }

    QRectF M = _bookModel()->getPlotMathRect(rootIndex());
    QRect  W = viewport()->rect();
    QRect  V = _curvesView->viewport()->rect();

    if ( W != V ) {

        V.moveTo(_curvesView->viewport()->mapToGlobal(V.topLeft()));
        W.moveTo(viewport()->mapToGlobal(W.topLeft()));
        double pixelWidth  = ( V.width() > 0 )  ? M.width()/V.width()   : 0 ;
        double pixelHeight = ( V.height() > 0 ) ? M.height()/V.height() : 0 ;
        QPointF vw = V.topLeft()-W.topLeft();
        double ox = pixelWidth*vw.x();
        double oy = pixelHeight*vw.y();
        double mw = pixelWidth*W.width();
        double mh = pixelHeight*W.height();
        QPointF pt(M.x()-ox, M.y()-oy);
        M = QRectF(pt.x(),pt.y(), mw, mh);
    }

    return M;
}

QModelIndex BookIdxView::_plotMathRectIdx(const QModelIndex &plotIdx) const
{
    QModelIndex idx;
    if ( !model() ) return idx;
    idx = _bookModel()->getDataIndex(plotIdx, "PlotMathRect", "Plot");
    return idx;
}

void BookIdxView::setModel(QAbstractItemModel *model)
{
    foreach ( QAbstractItemView* view, _childViews ) {
        view->setModel(model);
    }
    QAbstractItemView::setModel(model);
}

void BookIdxView::setRootIndex(const QModelIndex &index)
{
    foreach (QAbstractItemView* view, _childViews ) {
        view->setRootIndex(index);
    }
    QAbstractItemView::setRootIndex(index);
}

void BookIdxView::setCurrentCurveRunID(int runID)
{
    foreach (QAbstractItemView* view, _childViews ) {
        BookIdxView* bookIdxView = dynamic_cast<BookIdxView*>(view);
        if ( bookIdxView ) {
            bookIdxView->setCurrentCurveRunID(runID);
        }
    }
}

// Root index of a page view will be a Page Index of a Book Model
// Noop "template" for a child class
void BookIdxView::dataChanged(const QModelIndex &topLeft,
                              const QModelIndex &bottomRight)
{
    if ( topLeft != rootIndex() || topLeft.parent() != rootIndex() ) return;
    if ( topLeft.column() != 1 ) return;
    if ( topLeft != bottomRight ) return;

    // Code
}

// Noop "template" for a child class
void BookIdxView::rowsInserted(const QModelIndex &pidx, int start, int end)
{
    Q_UNUSED(start);
    Q_UNUSED(end);
    if ( pidx != rootIndex() ) return;

    // Code
}

QModelIndex BookIdxView::indexAt(const QPoint &point) const
{
    Q_UNUSED(point);
    QModelIndex idx;
    return idx;
}

QRect BookIdxView::visualRect(const QModelIndex &index) const
{
    Q_UNUSED(index);

    QRect rect;
    return rect;
}

void BookIdxView::scrollTo(const QModelIndex &index,
                             QAbstractItemView::ScrollHint hint)
{
    Q_UNUSED(index);
    Q_UNUSED(hint);
}

void BookIdxView::mousePressEvent(QMouseEvent *event)
{
    if ( event->button() == Qt::MidButton ){
        event->ignore();
    } else {
        QAbstractItemView::mousePressEvent(event);
    }
}

void BookIdxView::mouseMoveEvent(QMouseEvent *event)
{
    if ( event->buttons() == Qt::MidButton ){
        event->ignore();
    } else {
        QAbstractItemView::mouseMoveEvent(event);
    }
}

void BookIdxView::mouseReleaseEvent(QMouseEvent *event)
{
    if ( event->button() == Qt::MidButton ){
        event->ignore();
    } else {
        QAbstractItemView::mouseReleaseEvent(event);
    }
}

// Need this so that pageView can capture double click event
void BookIdxView::mouseDoubleClickEvent(QMouseEvent *event)
{
    if ( event->button() == Qt::LeftButton ){
        event->ignore();
    } else {
        QAbstractItemView::mouseDoubleClickEvent(event);
    }
}

QModelIndex BookIdxView::moveCursor(
        QAbstractItemView::CursorAction cursorAction,
        Qt::KeyboardModifiers modifiers)
{
    Q_UNUSED(cursorAction);
    Q_UNUSED(modifiers);

    QModelIndex idx;
    return idx;
}

int BookIdxView::horizontalOffset() const
{
    return 0;
}

int BookIdxView::verticalOffset() const
{
    return 0;
}

bool BookIdxView::isIndexHidden(const QModelIndex &index) const
{
    Q_UNUSED(index);
    return false;
}

void BookIdxView::setSelection(const QRect &rect,
                                 QItemSelectionModel::SelectionFlags command)
{
    Q_UNUSED(rect);
    Q_UNUSED(command);
}

QRegion BookIdxView::visualRegionForSelection(
        const QItemSelection &selection) const
{
    Q_UNUSED(selection);
    QRegion region;
    return region;
}

PlotBookModel* BookIdxView::_bookModel() const
{
    PlotBookModel* bookModel = dynamic_cast<PlotBookModel*>(model());

    if ( !bookModel ) {
        fprintf(stderr,"koviz [bad scoobs]: BookIdxView::_bookModel() "
                       "could not cast model() to a PlotBookModel*.\n");
        exit(-1);
    }

    return bookModel;
}

// Note: This can be slow.  It checks every curve.  If all curves have
//       same x unit, it returns x unit for all curves.
QString BookIdxView::_curvesXUnit(const QModelIndex& plotIdx) const
{
    QString curvesXUnit;
    QString dashDash("--");

    bool isCurvesIdx = _bookModel()->isChildIndex(plotIdx, "Plot", "Curves");
    if ( !isCurvesIdx ) return dashDash;
    QModelIndex curvesIdx = _bookModel()->getIndex(plotIdx, "Curves", "Plot");

    bool isCurveIdx = _bookModel()->isChildIndex(curvesIdx, "Curves", "Curve");
    if ( !isCurveIdx ) return dashDash;
    QModelIndexList curveIdxs = _bookModel()->getIndexList(curvesIdx,
                                                           "Curve","Curves");

    foreach ( QModelIndex curveIdx, curveIdxs ) {

        bool isCurveXUnit = _bookModel()->isChildIndex(curveIdx,
                                                       "Curve", "CurveXUnit");
        if ( !isCurveXUnit ) {
            // Since curve has no xunit, bail
            curvesXUnit.clear();
            break;
        }

        QModelIndex curveXUnitIdx = _bookModel()->getDataIndex(curveIdx,
                                                               "CurveXUnit",
                                                               "Curve");
        QString unit = model()->data(curveXUnitIdx).toString();

        if ( curvesXUnit.isEmpty() ) {
            curvesXUnit = unit;
        } else {
            if ( curvesXUnit != unit ) {
                curvesXUnit = dashDash;
                break;
            }
        }
    }

    return curvesXUnit;
}

QString BookIdxView::_curvesUnit(const QModelIndex &plotIdx, QChar axis) const
{
    if ( axis != 'x' && axis != 'y' ) {
        fprintf(stderr,"koviz [bad scoobs]: BookIdxView::_curvesUnit "
                       "called with bad axis=%c\n", axis.toLatin1());
        exit(-1);
    }

    QString curvesUnit;
    QString dashDash("--");

    bool isCurvesIdx = _bookModel()->isChildIndex(plotIdx, "Plot", "Curves");
    if ( !isCurvesIdx ) return dashDash;
    QModelIndex curvesIdx = _bookModel()->getIndex(plotIdx, "Curves", "Plot");

    bool isCurveIdx = _bookModel()->isChildIndex(curvesIdx, "Curves", "Curve");
    if ( !isCurveIdx ) return dashDash;
    QModelIndexList curveIdxs = _bookModel()->getIndexList(curvesIdx,
                                                           "Curve","Curves");

    foreach ( QModelIndex curveIdx, curveIdxs ) {

        bool isCurveUnit;
        if ( axis == 'x' ) {
            isCurveUnit = _bookModel()->isChildIndex(curveIdx,
                                                     "Curve", "CurveXUnit");
        } else {
            isCurveUnit = _bookModel()->isChildIndex(curveIdx,
                                                     "Curve", "CurveYUnit");
        }
        if ( !isCurveUnit ) {
            // Since curve has no xunit, bail
            curvesUnit.clear();
            break;
        }

        QModelIndex curveUnitIdx;
        if ( axis == 'x' ) {
            curveUnitIdx = _bookModel()->getDataIndex(curveIdx,
                                                      "CurveXUnit", "Curve");
        } else {
            curveUnitIdx = _bookModel()->getDataIndex(curveIdx,
                                                      "CurveYUnit", "Curve");
        }

        QString unit = model()->data(curveUnitIdx).toString();

        if ( curvesUnit.isEmpty() ) {
            curvesUnit = unit;
        } else {
            if ( curvesUnit != unit ) {
                curvesUnit = dashDash;
                break;
            }
        }
    }

    return curvesUnit;
}

void BookIdxView::_paintCurvesLegend(const QRect& R,
                                     const QModelIndex &curvesIdx,
                                     QPainter &painter)
{
    // If all plots on the page have the same legend, PageTitle will show legend
    // (unless explicitly set via -showPlotLegend option)
    QString isShowPlotLegend = _bookModel()->getDataString(QModelIndex(),
                                                         "IsShowPlotLegend","");
    if ( isShowPlotLegend == "no" ) {
        return;
    }
    bool isPlotLegendsSame = _bookModel()->isPlotLegendsSame(
                                         curvesIdx.parent().parent().parent());
    if ( isPlotLegendsSame && isShowPlotLegend != "yes" ) {
        return;
    }

    QString pres = _bookModel()->getDataString(curvesIdx.parent(),
                                               "PlotPresentation","Plot");
    if ( pres == "error" ) {
        return;
    }

    QModelIndex plotIdx = curvesIdx.parent();
    QList<QPen*> pens = _bookModel()->legendPens(plotIdx,
                                                 painter.paintEngine()->type());
    QStringList symbols = _bookModel()->legendSymbols(plotIdx);
    QStringList labels = _bookModel()->legendLabels(plotIdx);

    if ( pres == "error+compare" ) {
        QPen* magentaPen = new QPen(_bookModel()->errorLineColor());
        pens << magentaPen;
        symbols << "none";
        labels << "error";
    }

    __paintCurvesLegend(R,curvesIdx,pens,symbols,labels,painter);

    // Clean up
    foreach ( QPen* pen, pens ) {
        delete pen;
    }
}

// pens,symbols and labels are ordered/collated foreach legend curve/label
void BookIdxView::__paintCurvesLegend(const QRect& R,
                                      const QModelIndex &curvesIdx,
                                      const QList<QPen *> &pens,
                                      const QStringList &symbols,
                                      const QStringList &labels,
                                      QPainter &painter)
{
    QPen origPen = painter.pen();

    int n = pens.size();

    // Width Of Legend Box
    const int fw = painter.fontMetrics().averageCharWidth();
    const int ml = fw; // marginLeft
    const int mr = fw; // marginRight
    const int s = fw;  // spaceBetweenLineAndLabel
    const int l = 4*fw;  // line width , e.g. ~5 for: *-----* Gravity
    int w = 0;
    foreach (QString label, labels ) {
        int labelWidth = painter.fontMetrics().boundingRect(label).width();
        int ww = ml + l + s + labelWidth + mr;
        if ( ww > w ) {
            w = ww;
        }
    }

    // Height Of Legend Box
    const int ls = painter.fontMetrics().lineSpacing();
    const int fh = painter.fontMetrics().height();
    const int v = ls/8;  // vertical space between legend entries (0 works)
    const int mt = fh/4; // marginTop
    const int mb = fh/4; // marginBot
    int sh = 0;
    foreach (QString label, labels ) {
        sh += painter.fontMetrics().boundingRect(label).height();
    }
    int h = (n-1)*v + mt + mb + sh;

    // Legend box top left point
    const int top = fh/4;   // top margin
    const int right = fw/2; // right margin
    QPoint legendTopLeft(R.right()-w-right,R.top()+top);

    // Legend box
    QRect LegendBox(legendTopLeft,QSize(w,h));

    // Background color
    QModelIndex pageIdx = curvesIdx.parent().parent().parent();
    QColor bg = _bookModel()->pageBackgroundColor(pageIdx);
    bg.setAlpha(190);

    // Draw legend box with semi-transparent background
    painter.setBrush(bg);
    QPen penGray(QColor(120,120,120,255));
    painter.setPen(penGray);
    painter.drawRect(LegendBox);
    painter.setPen(origPen);

    QRect lastBB;
    for ( int i = 0; i < n; ++i ) {

        QString label = labels.at(i);

        // Calc bounding rect (bb) for line and label
        QPoint topLeft;
        if ( i == 0 ) {
            topLeft.setX(legendTopLeft.x()+ml);
            topLeft.setY(legendTopLeft.y()+mt);
        } else {
            topLeft.setX(lastBB.bottomLeft().x());
            topLeft.setY(lastBB.bottomLeft().y()+v);
        }
        QRect bb = painter.fontMetrics().boundingRect(label);
        bb.moveTopLeft(topLeft);
        bb.setWidth(l+s+bb.width());

        // Draw line segment
        QPen* pen = pens.at(i);
        painter.setPen(*pen);
        QPoint p1(bb.left(),bb.center().y());
        QPoint p2(bb.left()+l,bb.center().y());
        painter.drawLine(p1,p2);

        // Draw symbols on line segment endpoints
        QString symbol = symbols.at(i);
        __paintSymbol(p1,symbol,painter);
        __paintSymbol(p2,symbol,painter);

        // Draw label
        QRect labelRect(bb);
        QPoint p(bb.topLeft().x()+l+s, bb.topLeft().y());
        labelRect.moveTopLeft(p);
        painter.drawText(labelRect, Qt::AlignLeft|Qt::AlignVCenter, label);

        lastBB = bb;
    }

    painter.setPen(origPen);
}

void BookIdxView::__paintSymbol(const QPointF& p,
                               const QString &symbol, QPainter &painter)
{

    QPen origPen = painter.pen();
    QPen pen = painter.pen();
    pen.setStyle(Qt::SolidLine);
    painter.setPen(pen);

    if ( symbol == "circle" ) {
        painter.drawEllipse(p,2,2);
    } else if ( symbol == "thick_circle" ) {
        pen.setWidth(2.0);
        painter.setPen(pen);
        painter.drawEllipse(p,3,3);
    } else if ( symbol == "solid_circle" ) {
        pen.setWidthF(2.0);
        painter.setPen(pen);
        painter.drawEllipse(p,1,1);
    } else if ( symbol == "square" ) {
        double x = p.x()-2.0;
        double y = p.y()-2.0;
        painter.drawRect(QRectF(x,y,4,4));
    } else if ( symbol == "thick_square") {
        pen.setWidthF(2.0);
        painter.setPen(pen);
        double x = p.x()-3.0;
        double y = p.y()-3.0;
        painter.drawRect(QRectF(x,y,6,6));
    } else if ( symbol == "solid_square" ) {
        pen.setWidthF(4.0);
        painter.setPen(pen);
        painter.drawPoint(p); // happens to be a solid square
    } else if ( symbol == "star" ) { // *
        double r = 3.0;
        QPointF a(p.x()+r*cos(18.0*M_PI/180.0),
                  p.y()-r*sin(18.0*M_PI/180.0));
        QPointF b(p.x(),p.y()-r);
        QPointF c(p.x()-r*cos(18.0*M_PI/180.0),
                  p.y()-r*sin(18.0*M_PI/180.0));
        QPointF d(p.x()-r*cos(54.0*M_PI/180.0),
                  p.y()+r*sin(54.0*M_PI/180.0));
        QPointF e(p.x()+r*cos(54.0*M_PI/180.0),
                  p.y()+r*sin(54.0*M_PI/180.0));
        painter.drawLine(p,a);
        painter.drawLine(p,b);
        painter.drawLine(p,c);
        painter.drawLine(p,d);
        painter.drawLine(p,e);
    } else if ( symbol == "xx" ) {
        pen.setWidthF(2.0);
        painter.setPen(pen);
        QPointF a(p.x()+2.0,p.y()+2.0);
        QPointF b(p.x()-2.0,p.y()+2.0);
        QPointF c(p.x()-2.0,p.y()-2.0);
        QPointF d(p.x()+2.0,p.y()-2.0);
        painter.drawLine(p,a);
        painter.drawLine(p,b);
        painter.drawLine(p,c);
        painter.drawLine(p,d);
    } else if ( symbol == "triangle" ) {
        double r = 3.0;
        QPointF a(p.x(),p.y()-r);
        QPointF b(p.x()-r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        QPointF c(p.x()+r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        painter.drawLine(a,b);
        painter.drawLine(b,c);
        painter.drawLine(c,a);
    } else if ( symbol == "thick_triangle" ) {
        pen.setWidthF(2.0);
        painter.setPen(pen);
        double r = 4.0;
        QPointF a(p.x(),p.y()-r);
        QPointF b(p.x()-r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        QPointF c(p.x()+r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        painter.drawLine(a,b);
        painter.drawLine(b,c);
        painter.drawLine(c,a);
    } else if ( symbol == "solid_triangle" ) {
        pen.setWidthF(2.0);
        painter.setPen(pen);
        double r = 3.0;
        QPointF a(p.x(),p.y()-r);
        QPointF b(p.x()-r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        QPointF c(p.x()+r*cos(30.0*M_PI/180.0),
                  p.y()+r*sin(30.0*M_PI/180.0));
        painter.drawLine(a,b);
        painter.drawLine(b,c);
        painter.drawLine(c,a);
    } else if ( symbol.startsWith("number_",Qt::CaseInsensitive) &&
                symbol.size() == 8 ) {

        QFont origFont = painter.font();
        QBrush origBrush = painter.brush();

        // Calculate bbox to draw text in
        QString number = symbol.right(1); // last char is '0'-'9'
        QFont font = painter.font();
        font.setPointSize(7);
        painter.setFont(font);
        QFontMetrics fm = painter.fontMetrics();
        QRectF bbox(fm.tightBoundingRect(number));
        bbox.moveCenter(p);

        // Draw solid circle around number
        QRectF box(bbox);
        double l = 3.0*qMax(box.width(),box.height())/2.0;
        box.setWidth(l);
        box.setHeight(l);
        box.moveCenter(p);
        QBrush brush(pen.color());
        painter.setBrush(brush);
        painter.drawEllipse(box);

        // Draw number in white in middle of circle
        QPen whitePen("white");
        painter.setPen(whitePen);
        painter.drawText(bbox,Qt::AlignCenter,number);

        painter.setFont(origFont);
        painter.setBrush(origBrush);
    }

    painter.setPen(origPen);
}

void BookIdxView::_paintGrid(QPainter &painter, const QModelIndex& plotIdx)
{
    // If Grid DNE or off or math rect is zero, do not paint grid
    bool isGrid = _bookModel()->isChildIndex(plotIdx,"Plot","PlotGrid");
    if ( !isGrid ) {
        return;
    }
    QModelIndex isGridIdx = _bookModel()->getDataIndex(plotIdx,
                                                       "PlotGrid","Plot");
    isGrid = _bookModel()->data(isGridIdx).toBool();
    if ( !isGrid ) {
        return;
    }
    const QRectF M = _mathRect();
    if ( M.width() == 0.0 || M.height() == 0.0 ) {
        return;
    }

    QString plotXScale = _bookModel()->getDataString(plotIdx,
                                                     "PlotXScale","Plot");
    QString plotYScale = _bookModel()->getDataString(plotIdx,
                                                     "PlotYScale","Plot");
    bool isXLogScale = ( plotXScale == "log" ) ? true : false;
    bool isYLogScale = ( plotYScale == "log" ) ? true : false;

    QList<double> xtics = _bookModel()->majorXTics(plotIdx);
    if ( isXLogScale ) {
        xtics.append(_bookModel()->minorXTics(plotIdx));
    }
    QList<double> ytics = _bookModel()->majorYTics(plotIdx);
    if ( isYLogScale ) {
        ytics.append(_bookModel()->minorYTics(plotIdx));
    }

    QVector<QPointF> vLines;
    QVector<QPointF> hLines;

    foreach ( double x, xtics ) {
        vLines << QPointF(x,M.top()) << QPointF(x,M.bottom());
    }
    foreach ( double y, ytics ) {
        hLines << QPointF(M.left(),y) << QPointF(M.right(),y);
    }

    bool isAntiAliasing = (QPainter::Antialiasing & painter.renderHints()) ;

    // Grid Color
    QModelIndex pageIdx = _bookModel()->getIndex(plotIdx,"Page","Plot");
    QColor color = _bookModel()->pageForegroundColor(pageIdx);
    color.setAlpha(40);

    // Pen
    QVector<qreal> dashes;
    qreal space = 4;
    if ( isXLogScale || isYLogScale ) {
        dashes << 1 << 1 ;
    } else {
        dashes << 4 << space ;
    }

    //
    // Draw!
    //
    QPen origPen = painter.pen();
    QPen pen = painter.pen();
    pen.setColor(color);
    painter.save();
    painter.setRenderHint(QPainter::Antialiasing,false);
    pen.setWidthF(0.0);
    pen.setDashPattern(dashes);
    painter.setPen(pen);
    painter.setTransform(_coordToPixelTransform());
    painter.drawLines(hLines);
    painter.drawLines(vLines);
    painter.setPen(origPen);
    if ( isAntiAliasing ) {
        painter.setRenderHint(QPainter::Antialiasing);
    }
    painter.restore();
}
