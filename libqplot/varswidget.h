#ifndef VARSWIDGET_H
#define VARSWIDGET_H

#include <QWidget>
#include <QStandardItemModel>
#include <QItemSelectionModel>
#include <QSortFilterProxyModel>
#include <QGridLayout>
#include <QLineEdit>
#include <QListView>
#include "dp.h"
#include "libsnapdata/montemodel.h"
#include "plotbookview.h"
#include "monteinputsview.h"

class VarsWidget : public QWidget
{
    Q_OBJECT
public:
    explicit VarsWidget( QStandardItemModel* varsModel,
                          MonteModel* monteModel,
                          QStandardItemModel* plotModel,
                          QItemSelectionModel*  plotSelectModel,
                          PlotBookView* plotBookView,
                          MonteInputsView* monteInputsView,
                          QWidget *parent = 0);

    void updateSelection(const QModelIndex& pageIdx);
    void clearSelection();


signals:
    
public slots:

private:
    QStandardItemModel* _varsModel;
    MonteModel* _monteModel;
    QStandardItemModel* _plotModel;
    QItemSelectionModel*  _plotSelectModel;
    PlotBookView* _plotBookView;
    MonteInputsView* _monteInputsView;
    QGridLayout* _gridLayout ;
    QLineEdit* _searchBox;
    QListView* _listView ;

    QSortFilterProxyModel* _varsFilterModel;
    QItemSelectionModel* _varsSelectModel;

    int _currQPIdx;
    bool _isSkip; // Hack City :(

    QModelIndex _findSinglePlotPageWithCurve(const QString& curveName);
    QStandardItem* _createQPItem();
    void _addPlotOfVarToPageItem(QStandardItem* pageItem,
                                 const QModelIndex &varIdx);
    void _selectCurrentRunOnPageItem(QStandardItem* pageItem);
    int _currSelectedRun();
    bool _isCurveIdx(const QModelIndex &idx) const;

private slots:
     void _varsSearchBoxTextChanged(const QString& rx);
     void _varsSelectModelSelectionChanged(
                              const QItemSelection& currVarSelection,
                              const QItemSelection& prevVarSelection);
};

#endif // VARSWIDGET_H
