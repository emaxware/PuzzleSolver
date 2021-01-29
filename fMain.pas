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
  , uScanPiece, FMX.ScrollBox, FMX.Memo, fScannedPiece
  ;

type
  TfrmMain = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    ilPieces: TImageList;
    proMain: TPrototypeBindSource;
    BindSourceDB1: TBindSourceDB;
    bndngslst1: TBindingsList;
    lnkflcntrltfld1: TLinkFillControlToField;
    sbMain: TStyleBook;
    pmMain: TPopupMenu;
    MenuItem1: TMenuItem;
    MenuItem2: TMenuItem;
    MenuItem3: TMenuItem;
    actlstMain: TActionList;
    actImport: TAction;
    actPreview: TAction;
    actAssemble: TAction;
    actToImport: TChangeTabAction;
    tbcMain: TTabControl;
    tiImport: TTabItem;
    imgOrig: TImageViewer;
    tiPreview: TTabItem;
    tiAssemble: TTabItem;
    actToPreview: TChangeTabAction;
    actToAssemble: TChangeTabAction;
    stat1: TStatusBar;
    statPos: TLabel;
    tiLog: TTabItem;
    mmoLog: TMemo;
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
    fraScanPiece1: TfraScanPiece;
    fraScanPiece2: TfraScanPiece;
    spl3: TSplitter;
    procedure FormShow(Sender: TObject);
    procedure imgOrigMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Single);
    procedure actRestoreExecute(Sender: TObject);
    procedure actClearExecute(Sender: TObject);
    procedure actSaveExecute(Sender: TObject);
  private
    { Private declarations }
    fRedBrush:TStrokeBrush;
  protected
    fScanCollection:TScanCollection;
    fSelecting:boolean;
    fSelectStart:TPointF;
    fSelectEnd:TPointF;
//    fSelectRect:TRectangle;
    procedure AddPiece(APieceIndex:Integer);
  public
    { Public declarations }
    procedure log(const AMsg:string); overload;
    procedure log(const AFmtMsg:string; Args:array of const); overload;

    property ScanCollection:TScanCollection read fScanCollection;
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
  , uLib
  ;

const
  PieceCollectionFilename = 'PieceCollection.json';

var
  bFirstShow:boolean = true;

procedure TfrmMain.actClearExecute(Sender: TObject);
begin
  lstPieces.Clear;
  fScanCollection.Clear;
end;

procedure TfrmMain.actRestoreExecute(Sender: TObject);
var
  APiece:TPair<TPoint,TScanPiece>;
  i:integer;
begin
  actClear.Execute;
  if TFile.Exists(PieceCollectionFilename) then
  begin
    fScanCollection.asJSON := TJSONObject.ParseJSONValue(
      TFile.ReadAllText(PieceCollectionFilename)) as TJSONObject;
    i := 0;
    for APiece in fScanCollection.Pieces.ToArray do
    begin
      AddPiece(i);
      Inc(i);
    end;
    fraScanPiece1.Execute(fScanCollection, 0);
    fraScanPiece2.Execute(fScanCollection, 1);
  end;
end;

procedure TfrmMain.actSaveExecute(Sender: TObject);
begin
  TFile.WriteAllText(PieceCollectionFilename, fScanCollection.asJSON.ToString)
end;

//procedure TfrmMain.AddPiece(AScanPiece: TScanPiece; AScanOrigin:TPoint; ABitmapScale:single);
procedure TfrmMain.AddPiece(APieceIndex:Integer);// ABitmapScale:single);
var
//  bitmapScaledWidth
//    :Single;
  imgPt, ADrawPoint:TPoint;
//  imgSurface:TBitmapSurface;
  ATmpBitmap, AScanBitmap:TBitmap;
  AListItem:TListBoxItem;
  AScanPiece: TScanPiece; AScanOrigin:TPoint;
begin
  with imgOrig do
  try
//    ATmpBitmap := TBitmap.Create(AScanPiece.Width, AScanPiece.Height);
//    ATmpBitmap.CopyFromBitmap(Bitmap, Rect(AScanOrigin.X, AScanOrigin.Y, AScanOrigin.X + AScanPiece.Width - 1, AScanOrigin.Y + AScanPiece.Height - 1), 0, 0);
//    if Bitmap.Canvas.BeginScene then
//    try
//      for imgPt in AScanPiece.Points do
//      begin
//        ADrawPoint := imgPt + AScanOrigin;
//        ADrawPoint.toPointF.DrawPoint(Bitmap.Canvas, 1, fRedBrush, 5);
//      end;
//    finally
//      Bitmap.Canvas.EndScene
//    end;
    ATmpBitmap := fScanCollection.GetPieceBitmap(APieceIndex);
    AScanBitmap := ATmpBitmap.CreateThumbnail(
//      Round(AScanPiece.Width * Bitmap.BitmapScale), Round(AScanPiece.Height * Bitmap.BitmapScale)
      80, 80
      );
    AListItem := TListBoxItem.Create(lstPieces);
    AListItem.ItemData.Bitmap := AScanBitmap;
    AListItem.Data := Pointer(APieceIndex);// TOPair<TPoint,TScanPiece>.Create(fScanCollection.Pieces.ToArray[APieceIndex]);
    lstPieces.InsertObject(0, AListItem);
    AListItem.ItemData.Text := 'Scanned';
    AListItem.DragMode := TDragMode.dmAutomatic;
    AListItem.OnDragDrop := self.lst1DragDrop;
    AListItem.OnDragEnd := self.lst1DragEnd;
//    actSave.Execute
  finally
    ATmpBitmap.free
  end;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  APiece:TPair<TPoint,TScanPiece>;
begin
  if bFirstShow then
  begin
    bFirstShow := false;
    lstPieces.Clear;
    fScanCollection := TScanCollection.create(imgOrig.Bitmap);
    fRedBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Red);
    actRestore.Execute
  end;
end;

procedure TfrmMain.imgOrigMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Single);
var
  imgPt:TPointF;
  bitmapScaledSize:TSizeF;
  AScanPiece:TScanPiece;
  AScanOrigin, ADrawPoint:TPoint;
begin
  fSelecting := false;
  imgPt := PointF(x, y);
  log('imgPt.x=%.2f,imgPt.y=%.2f',[imgPt.x,imgPt.y]);
  bitmapScaledSize := TSizeF.Create(imgOrig.Bitmap.Width*imgOrig.BitmapScale,imgOrig.Bitmap.Height*imgOrig.BitmapScale);
  log('bitmapScaledSize.cx=%.2f,bitmapScaledSize.cy=%.2f',[bitmapScaledSize.cx,bitmapScaledSize.cy]);
  imgPt.Offset(imgOrig.ViewportPosition.x, imgOrig.ViewportPosition.y);
  log('imgPt.x=%.2f,imgPt.y=%.2f',[imgPt.x,imgPt.y]);
//  imgOrig.Scene.
  imgPt.Offset((bitmapScaledSize.Width - imgOrig.ContentBounds.Width),(bitmapScaledSize.Height - imgOrig.ContentBounds.Height)/2);
  log('imgPt.x=%.2f,imgPt.y=%.2f',[imgPt.x,imgPt.y]);
  imgPt := imgPt / imgOrig.BitmapScale;
  log('imgPt.x=%.2f,imgPt.y=%.2f',[imgPt.x,imgPt.y]);
  if fScanCollection.DetectPiece(imgPt.toPoint, 5, AScanPiece, AScanOrigin) then
    AddPiece(fScanCollection.Pieces.Count-1);
end;

procedure TfrmMain.log(const AFmtMsg: string; Args: array of const);
begin
  log(Format(AFmtMsg,Args))
end;

procedure TfrmMain.log(const AMsg: string);
begin
  mmoLog.Lines.Insert(0, Format('%s - %s',[DateTimeToStr(now), AMsg]));
end;

end.
