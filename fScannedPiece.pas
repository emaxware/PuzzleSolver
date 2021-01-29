unit fScannedPiece;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Layouts, FMX.ExtCtrls, FMX.Controls.Presentation
  , System.Generics.Collections
  , uScanPiece
  ;

type
  TfraScanPiece = class(TFrame)
    pnl2: TPanel;
    imgPiece: TImageViewer;
    scrlbrPoints: TScrollBar;
    pnlGraph: TPanel;
    pnlProfile2: TPanel;
    imgProfile2: TImageViewer;
    lblProfile2: TLabel;
    spl3: TSplitter;
    procedure scrlbrPointsChange(Sender: TObject);
    procedure imgPieceDragDrop(Sender: TObject; const Data: TDragObject;
      const Point: TPointF);
    procedure imgPieceDragOver(Sender: TObject; const Data: TDragObject;
      const Point: TPointF; var Operation: TDragOperation);
    procedure imgPieceDragEnter(Sender: TObject; const Data: TDragObject;
      const Point: TPointF);
    procedure lblProfile2DragDrop(Sender: TObject; const Data: TDragObject;
      const Point: TPointF);
  private
    { Private declarations }
    FPieceBitmap:TBitmap;
    FScans:TScanCollection;
    FPiece:TScanPiece;
    FPieceIndex, FLastPointIndex:integer;
    FAngleList:TList<Single>;
    FRedStroke:TStrokeBrush;
    FPieceOrig:TPoint;
  public
    { Public declarations }
    procedure Execute(AScanCollection:TScanCollection; APieceIndex:integer);
  end;

implementation

{$R *.fmx}

uses
  System.Math
  , FMX.ListBox
  , fMain
  , uLib
  ;

procedure TfraScanPiece.Execute(AScanCollection: TScanCollection;
  APieceIndex: integer);
begin
  FScans := AScanCollection;
  FPiece := FScans.Pieces.ToArray[APieceIndex].Value;
  FPieceOrig := FScans.Pieces.ToArray[APieceIndex].Key;
  FPieceIndex := APieceIndex;
//  FPieceBitmap.Free;
  FPieceBitmap := FScans.GetPieceBitmap(FPieceIndex);
  scrlbrPoints.Min := 0;
  scrlbrPoints.Max := FPiece.Points.Count-1;
  FLastPointIndex := -1;
  imgPiece.Bitmap.Assign(FPieceBitmap);
  imgPiece.BitmapScale := Min(imgPiece.Width/FPieceBitmap.Width,imgPiece.Height/FPieceBitmap.Height)
end;

procedure TfraScanPiece.imgPieceDragDrop(Sender: TObject;
  const Data: TDragObject; const Point: TPointF);
var
  i:integer;
  lst:TListBoxItem;
begin
  with (Data.Source as TListBox).parent as TfrmMain do
  begin
    lst := lstPieces.Selected;
    i := lst.Index;
    Execute(ScanCollection
      , Integer(Pointer(lstPieces.Selected.data)));
  end;
end;

procedure TfraScanPiece.imgPieceDragEnter(Sender: TObject;
  const Data: TDragObject; const Point: TPointF);
begin
//
end;

procedure TfraScanPiece.imgPieceDragOver(Sender: TObject;
  const Data: TDragObject; const Point: TPointF; var Operation: TDragOperation);
begin
//
  Operation := TDragOperation.Copy
end;

procedure TfraScanPiece.lblProfile2DragDrop(Sender: TObject;
  const Data: TDragObject; const Point: TPointF);
begin
//
end;

procedure TfraScanPiece.scrlbrPointsChange(Sender: TObject);
var
  ATempPos:TPointf;
begin
  if FLastPointIndex >= 0 then
  begin
    FScans.Pieces.ToArray[FPieceIndex].Value.Points[FLastPointIndex].toPointF.DrawPoint(imgPiece.Bitmap.Canvas, 1);
//    FPointList[FLastScrollPos].toPointF.DrawPoint(imgDetected.Bitmap.Canvas, 1);
//    PointF(FLastScrollPos*2,imgProfile.Bitmap.Height * (1-(pi-FAngleList[FLastScrollPos])/pi)/4).DrawPoint(imgProfile.Bitmap.Canvas, 1);
//    PointF(FLastScrollPos*2,imgProfile2.Bitmap.Height * (1-(FAngleList[FLastScrollPos]-FAngleList[FLastScrollPos-1])/pi)/2).DrawPoint(imgProfile2.Bitmap.Canvas, 1);
  end;
//  FLastScrollPos := Round(scrlbrPoints.Value);
//  FPointList[FLastScrollPos].toPointF.DrawPoint(imgPiece.Bitmap.Canvas, 1, FRedStroke);
//  FPointList[FLastScrollPos].toPointF.DrawPoint(imgDetected.Bitmap.Canvas, 1, FRedStroke);
//  PointF(FLastScrollPos*2,imgProfile.Bitmap.Height * (1-(pi-FAngleList[FLastScrollPos])/pi)/4).DrawPoint(imgProfile.Bitmap.Canvas, 1, FRedStroke);
//  PointF(FLastScrollPos*2,imgProfile2.Bitmap.Height * (1-(FAngleList[FLastScrollPos]-FAngleList[FLastScrollPos-1])/pi)/2).DrawPoint(imgProfile2.Bitmap.Canvas, 1, FRedStroke);
//  lblProfile.Text := Format('a: %.2f'#13#10'a2: %.2f',[
//    FAngleList[FLastScrollPos]/pi*180
//    , (Pi-FAngleList[FLastScrollPos])/pi*180
//    ]);
//  lblProfile2.Text := Format('da: %.2f',[
//    (FAngleList[FLastScrollPos]-FAngleList[FLastScrollPos-1])/pi*180
//    ]);
//  lblCurrPos.Text := Format('n-1: %d,%d'#13#10'n:   %d,%d'#13#10'n+1: %d,%d',[
//    FPointList[FLastScrollPos-1].X
//    , FPointList[FLastScrollPos-1].Y
//    , FPointList[FLastScrollPos].X
//    , FPointList[FLastScrollPos].Y
//    , FPointList[FLastScrollPos+1].X
//    , FPointList[FLastScrollPos+1].Y
//    ])
end;

end.
