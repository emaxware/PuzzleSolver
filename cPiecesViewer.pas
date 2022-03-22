unit cPiecesViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls
  , uScanPiece, System.Rtti, FMX.Grid.Style, FMX.Grid,
  FMX.Controls.Presentation, FMX.ScrollBox, FMX.Layouts
  ;

type
  TfraPiecesViewer = class(TFrame)
    grdPieces: TGrid;
    img1: TImageColumn;
    procedure grdPiecesCellDblClick(const Column: TColumn; const Row: Integer);
    procedure grdPiecesDrawColumnCell(Sender: TObject; const Canvas: TCanvas;
      const Column: TColumn; const Bounds: TRectF; const Row: Integer;
      const Value: TValue; const State: TGridDrawStates);
    procedure FrameEnter(Sender: TObject);
    procedure FrameResized(Sender: TObject);
  private
    { Private declarations }
  protected
    fScan:TScanCollection;
    fStarter:TProc<TfraPiecesViewer>;
    fOnChoose:TProc<integer, TScanPiece>;
    fStarted:boolean;
    procedure Update; virtual;
  public
    { Public declarations }
    procedure Start; overload; virtual;
    procedure Start(AStarter:TProc<TfraPiecesViewer>; AOnChoose:TProc<integer, TScanPiece>); overload; virtual;
    procedure Start(AScan:TScanCollection); overload; virtual;
  end;

implementation

{$R *.fmx}

uses
  system.Math
  , m3.bitmaphelper.fmx
  ;

{ TfraPiecesViewer }

procedure TfraPiecesViewer.Start;
begin
  fStarted := true;
  fStarter(Self);
  Update
end;

procedure TfraPiecesViewer.Start(AStarter: TProc<TfraPiecesViewer>; AOnChoose:TProc<integer, TScanPiece>);
begin
  fStarter := AStarter;
  fOnChoose := AOnChoose
end;

procedure TfraPiecesViewer.FrameEnter(Sender: TObject);
begin
  Start
end;

procedure TfraPiecesViewer.FrameResized(Sender: TObject);
begin
  update
end;

procedure TfraPiecesViewer.grdPiecesCellDblClick(const Column: TColumn;
  const Row: Integer);
begin
  var pieceIndex := Row * grdPieces.ColumnCount + Column.Index;
  if assigned(fOnChoose) then
    fOnChoose(pieceIndex, fScan.Pieces[pieceIndex])
end;

procedure TfraPiecesViewer.grdPiecesDrawColumnCell(Sender: TObject;
  const Canvas: TCanvas; const Column: TColumn; const Bounds: TRectF;
  const Row: Integer; const Value: TValue; const State: TGridDrawStates);
begin
  var pieceIndex := Row * grdPieces.ColumnCount + Column.Index;
  var save:TCanvasSaveState;
  if (fscan <> nil) and (pieceIndex < fScan.Count) and Canvas.BeginScene then
  try
    save := Canvas.SaveState;
    var bnd := Bounds;
    bnd.Inflate(-5, -5);
    if TGridDrawState.Selected in state then
    begin
      Canvas.Stroke.Color := TAlphaColorRec.Black;
      canvas.DrawRect(bnd, 1)
    end;
    bnd.Inflate(-5, -5);
    var bitmap := fScan.GetPieceBitmap(pieceIndex);
    canvas.DrawBitmap(bitmap, bitmap.BoundsF, bnd, 1);
    Canvas.FillText(bnd, pieceIndex.ToString, false, 1, [], TTextAlign.Center, TTextAlign.Center)
  finally
    Canvas.RestoreState(save);
    Canvas.EndScene
  end;
end;

procedure TfraPiecesViewer.Start(AScan: TScanCollection);
begin
  fScan := AScan;
end;

procedure TfraPiecesViewer.Update;
begin
  grdPieces.BeginUpdate;
  try
    grdPieces.ClearColumns;
    if fScan = nil then
      exit;
    var cellSize := 120;// Max(fScan.MaxPieceWidth, fScan.MaxPieceHeight) + 10;
    var widthLeft := Round(self.Width);
    repeat
      var col := TImageColumn.Create(grdPieces);
      col.Width := cellSize;// fScan.MaxPieceWidth;
      col.parent := grdPieces;
      dec(widthLeft, cellSize);// fScan.MaxPieceWidth);
    until widthLeft < cellSize;// fScan.MaxPieceWidth;

    grdPieces.RowHeight := cellSize;// fScan.MaxPieceHeight
    grdPieces.RowCount := fScan.Count div grdPieces.ColumnCount + 1
  finally
    grdPieces.EndUpdate
  end;
end;

end.
