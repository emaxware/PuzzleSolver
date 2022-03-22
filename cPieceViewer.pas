unit cPieceViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ExtCtrls
  , uScanPiece, FMX.Objects
  ;

type
  TfraPieceViewer = class(TFrame)
    tlbPieceViewer: TToolBar;
    btnLeft: TSpeedButton;
    btnRight: TSpeedButton;
    btnReset: TSpeedButton;
    boxPaint: TScrollBox;
    pbPaint: TPaintBox;
    procedure btnLeftClick(Sender: TObject);
    procedure boxPaintPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
  protected
    { Private declarations }
    fPiece:TArrPiece;
    fCurrSide:TArrSide;
    fBitmap:TBitmap;
    fFaceAngle: Single;
    fScale: Single;
    procedure SetFaceAngle(const Value: Single);
    procedure SetScale(const Value: Single);
  public
    { Public declarations }
    procedure Start(APiece:TArrPiece);

    property Scale:Single read fScale write SetScale;
    property FaceAngle:Single read fFaceAngle write SetFaceAngle;
  end;

implementation

{$R *.fmx}

uses
  System.math
  ;

{ TfraPieceViewer }

procedure TfraPieceViewer.boxPaintPaint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
begin
//
end;

procedure TfraPieceViewer.btnLeftClick(Sender: TObject);
begin
//  if sender = btnLeft then
//    imgPiece.RotationAngle := imgPiece.RotationAngle - 90// DegToRad(-90)
//  else
//    imgPiece.RotationAngle := imgPiece.RotationAngle + 90// DegToRad(90)
end;

procedure TfraPieceViewer.SetFaceAngle(const Value: Single);
begin
  fFaceAngle := Value;
end;

procedure TfraPieceViewer.SetScale(const Value: Single);
begin
  fScale := Value;
end;

procedure TfraPieceViewer.Start(APiece: TArrPiece);
begin
  fPiece := APiece;
  fCurrSide := fPiece.Sides.First;
  fBitmap := fPiece.Collection.Scan.GetPieceBitmap(fPiece.PieceIndex);
//  imgPiece.RotationAngle := 0;
//  var width := imgPiece.ClientWidth;
//  if imgPiece.ClientHeight > width then
//    width := imgPiece.ClientHeight;
//
//  width := width - 40;
//
//  var bmpWidth := imgPiece.Bitmap.Width;
//  if imgPiece.Bitmap.Height > bmpWidth then
//    bmpWidth := imgPiece.Bitmap.Height;
//
//  imgPiece.BitmapScale := width / bmpWidth
//  imgPiece.BestFit
end;

end.
