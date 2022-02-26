unit fMain;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, Data.Bind.Components,
  Data.Bind.ObjectScope, FMX.ListView, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.ExtCtrls, FMX.TabControl, FMX.MultiView, Fmx.Bind.GenData,
  Data.Bind.GenData, Data.Bind.EngExt, Fmx.Bind.DBEngExt, System.Rtti,
  System.Bindings.Outputs, Fmx.Bind.Editors, FMX.ListBox, Data.Bind.DBScope,
  System.Actions, FMX.ActnList, FMX.Menus, FMX.TreeView
  , uScanPiece, FMX.ScrollBox, FMX.Memo, fScannedPiece, FMX.Memo.Types,
  cBitmapViewer
  , m3.DebugForm.fmx, FMX.Edit, FMX.EditBox, FMX.NumberBox
  , cFunctionViewer
  , cSlicerViewer
  , cSegmentViewer
  , cPiecesViewer
  ;

type
  TfrmMain = class(TForm)
    sbMain: TStyleBook;
    actlstMain: TActionList;
    actScan: TAction;
    actPreview: TAction;
    actAssemble: TAction;
    tbcMain: TTabControl;
    tabImport: TTabItem;
    tlbImport: TToolBar;
    btnClear: TButton;
    btnSave: TSpeedButton;
    btnRestore: TSpeedButton;
    actClear: TAction;
    actSave: TAction;
    actRestore: TAction;
    lstPieces: TListBox;
    lst1: TListBoxItem;
    lst2: TListBoxItem;
    btnScan: TSpeedButton;
    fraBitmapViewerImport: TfraBitmapViewer;
    actChangeTab: TChangeTabAction;
    actNext: TNextTabAction;
    actPrev: TPreviousTabAction;
    procedure FormShow(Sender: TObject);
    procedure actRestoreExecute(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
    procedure imgOrigPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure actScanExecute(Sender: TObject);
    procedure lstPiecesDblClick(Sender: TObject);
    procedure sliSegmentLengthChange(Sender: TObject);
  private
    { Private declarations }
    fPieceFillBrush, fPieceDrawBrush, fOriginBrush, fNullBrush:TStrokeBrush;
//    fLastPt:TPoint;
    procedure UpdatePieceOverlay;
//    function toBitmapPoint(APoint: TPointF): TPointF;
//    function toControlPoint(APoint, AOrig: TPointF): TPointF; overload;
//    function toControlPoint(APoint: TPointF): TPointF; overload;
//    procedure UpdateStatus;
  protected
    fScan:TScanCollection;
    fSelecting:boolean;
    fSelectStart:TPointF;
    fSelectEnd:TPointF;
    fPieceOverlay:TBitmap;
    fSlicerTab:TTabItem;
    fSlicerFrame:TfraSlicerViewer;
    fSegmentTab:TTabItem;
    fSegmentFrame:TfraSegmentViewer;
    fPiecesTab:TTabItem;
    fPiecesFrame:TfraPiecesViewer;
    procedure AddPiece(APieceIndex:Integer);
  public
    { Public declarations }
    property ScanCollection:TScanCollection read fScan;
  end;

var
  frmMain: TfrmMain;

implementation

{$R *.fmx}
{$R *.Windows.fmx MSWINDOWS}

uses
  FMX.Surfaces
  , System.IOUtils
  , System.JSON
  , System.Generics.Collections
  , System.Math.Vectors
  , System.Math
  , System.SyncObjs
  , uLib
  , m3.consolelog
  , system.UIConsts
  , fmx.InertialMovement
  , m3.imageviewerhelper
  , m3.framehelper.fmx
  , m3.bitmaphelper.fmx
  , m3.pointhelper
//  , fDebug
//  , fmx.Dialogs
//  , m3.log
  ;

const
  PieceCollectionFilename = '..\..\Data\PieceCollection.json';

var
  bFirstShow:boolean = true;

{$REGION 'Form Handler'}
procedure TfrmMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  fScan.Free;
  fNullBrush.free;
  fPieceFillBrush.free
end;

procedure TfrmMain.FormShow(Sender: TObject);
begin
  if bFirstShow then
  begin
    TfrmDebug.Log('Showing..');
    bFirstShow := false;
    tabImport.MakeActive;
    fPieceFillBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Aqua);
    fPieceDrawBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Blue);
    fOriginBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Yellow);
    fNullBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Null);

    fSlicerFrame := tbcMain.AddFrame<TfraSlicerViewer>('Slicer', fSlicerTab);
    fSlicerFrame.Start(
      procedure(AViewer:TfraFunctionViewer)
      begin
        fSlicerTab.MakeActive;
        AViewer.Start(fScan, lstPieces.ItemIndex)
      end);

    fSegmentFrame := tbcMain.AddFrame<TfraSegmentViewer>('Segment', fSegmentTab);
    fSegmentFrame.Start(
      procedure(AViewer:TfraFunctionViewer)
      begin
        fSegmentTab.MakeActive;
        AViewer.Start(fScan, lstPieces.ItemIndex)
      end);

    fPiecesFrame := tbcMain.AddFrame<TfraPiecesViewer>('Pieces', fPiecesTab);
    fPiecesFrame.Start(
      procedure(AViewer:TfraPiecesViewer)
      begin
        tbcMain.SetActiveTabWithTransitionAsync(
          fPiecesTab
          , TTabTransition.Slide
          , TTabTransitionDirection.Normal
          , procedure
          begin
          end
          );
        AViewer.Start(fScan)
      end,
      procedure(AIndex:integer; APiece: TScanPiece)
      begin
        tbcMain.SetActiveTabWithTransitionAsync(
          fSlicerTab
          , TTabTransition.Slide
          , TTabTransitionDirection.Normal
          , procedure
          begin
          end
          );
        fSlicerFrame.Start(fScan, AIndex);
        fSlicerFrame.UpdateOverlay
      end
      );

    actRestore.Execute;
    actScan.Execute
  end;
end;
{$ENDREGION}

{$REGION 'Action Handlers'}
procedure TfrmMain.actClearExecute(Sender: TObject);
begin
  lstPieces.Clear;
  if fScan <> nil then
    fScan.Clear;
{$IF DEFINED(ANDROID) OR DEFINED(IOS)}

{$ELSE}

{$ENDIF}
end;

procedure TfrmMain.actRestoreExecute(Sender: TObject);
begin
  actClear.Execute;
  if TFile.Exists(PieceCollectionFilename) then
  begin
    if fScan = nil then
      fScan := TScanCollection.create;
    fScan.LoadFrom(PieceCollectionFilename);
    fraBitmapViewerImport.imgBitmap.Bitmap.Assign(fScan.Bitmap);
    for var i := 0 to fScan.Count-1 do
      AddPiece(i);
    fraBitmapViewerImport.imgBitmap.BitmapScale := 1.22;
    fraBitmapViewerImport.imgBitmap.AniCalculations.ViewportPosition := TPointD.create(0, 0);
//    fraScanPiece1.Execute(fScan, 0);
//    fraScanPiece2.Execute(fScan, 1);
  end;
end;

procedure TfrmMain.actSaveExecute(Sender: TObject);
begin
  fScan.SaveTo(PieceCollectionFilename)
end;

procedure TfrmMain.actScanExecute(Sender: TObject);
begin
  var ABitmapResult:TBitmap;
  if fScan.DetectPieces(ABitmapResult) then
  try
//    fraBitmapViewer.imgBitmap.Bitmap.Clear(TAlphaColorRec.Red);
    fraBitmapViewerImport.imgBitmap.Bitmap := ABitmapResult;
    fraBitmapViewerImport.imgBitmap.Repaint;

    lstPieces.Clear;
    for var i := 0 to fScan.Count-1 do
    begin
      AddPiece(i);
//      break
    end;
  finally
    ABitmapResult.free
  end;

  fPiecesFrame.Start
end;
{$ENDREGION}

{$REGION 'Form methods'}
procedure TfrmMain.AddPiece(APieceIndex:Integer);// ABitmapScale:single);
var
//  imgPt, ADrawPoint:TPoint;
  ATmpBitmap, AScanBitmap:TBitmap;
  AListItem:TListBoxItem;
//  AScanPiece: TScanPiece;
//  AScanOrigin:TPoint;
begin
  try
    ATmpBitmap := fScan.GetPieceBitmap(APieceIndex);
    AScanBitmap := ATmpBitmap.CreateThumbnail(
      80, 80
      );
//    TfrmDebug.Instance.AddBitmap(AScanBitmap);
    AListItem := TListBoxItem.Create(lstPieces);
    AListItem.ItemData.Bitmap := AScanBitmap;
    AListItem.Data := Pointer(APieceIndex);// TOPair<TPoint,TScanPiece>.Create(fScan.Pieces.ToArray[APieceIndex]);
    lstPieces.InsertObject(0, AListItem);
//    AListItem.ItemData.Text := 'Scanned';
    AListItem.ItemData.Detail := 'Detail';
    AListItem.DragMode := TDragMode.dmAutomatic;
  finally
//    ATmpBitmap.free
  end;
end;

procedure TfrmMain.UpdatePieceOverlay;
begin
end;
{$ENDREGION}

procedure TfrmMain.imgOrigPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
  if fPieceFillBrush = nil then
    exit;
  if Canvas.BeginScene then
  try
    var saveFill := Canvas.Fill;
    var save := Canvas.SaveState;
    try
      Canvas.Fill := fPieceFillBrush;
      Canvas.Stroke.Assign(fPieceDrawBrush);
      Canvas.Stroke.Thickness := fraBitmapViewerImport.imgBitmap.BitmapScale;
//      Canvas.Stroke.Dash := TStrokeDash.Dot;
//      var pcs := fScan.Pieces.Values.toarray;
//      var origs := fScan.Pieces.Keys.ToArray;
      for var i := 0 to fScan.Count-1 do
      begin
        var poly := fScan.Pieces[i].Points.asPolygon;
        var orig:TPointF := fScan.PieceOrigin[i];
        for var j := Low(poly) to High(poly) do
          poly[j] := fraBitmapViewerImport.imgBitmap.toControlPoint(poly[j], orig);
        Canvas.fill := fOriginBrush;
        var origRect := TRectF.create(fraBitmapViewerImport.imgBitmap.toControlPoint(Orig.toOffset(-5, -5)), fraBitmapViewerImport.imgBitmap.toControlPoint(Orig.toOffset(5, 5)));
        Canvas.FillRect(origRect, 1);
        Canvas.Fill := fPieceFillBrush;
      end;
    finally
      Canvas.RestoreState(save);
      Canvas.fill := saveFill
    end
  finally
    Canvas.EndScene
  end
end;

procedure TfrmMain.lstPiecesDblClick(Sender: TObject);
begin
  if lstPieces.ItemIndex >= 0 then
  begin
//    fSlicerTab.MakeActive;
    fSlicerFrame.Start
//    UpdatePieceOverlay;
  end;
end;

procedure TfrmMain.sliSegmentLengthChange(Sender: TObject);
begin
  UpdatePieceOverlay
end;

end.
