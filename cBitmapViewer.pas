unit cBitmapViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.Layouts, FMX.ExtCtrls, FMX.Edit,
  FMX.EditBox, FMX.ComboTrackBar
  ;

type
  TfraBitmapViewer = class(TFrame)
    imgBitmap: TImageViewer;
    tlbFooter: TToolBar;
    stat1: TStatusBar;
    lblStatus: TLabel;
    rectColor1: TRectangle;
    tckZoom: TComboTrackBar;
    lblZoom: TLabel;
    procedure imgBitmapResized(Sender: TObject);
    procedure imgBitmapMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Single);
    procedure tckZoomChange(Sender: TObject);
  private
    { Private declarations }
    fLastPt:TPoint;
  protected
    procedure Loaded; override;
  public
    { Public declarations }
    procedure UpdateStatus;
  end;

implementation

uses
  m3.imageviewerhelper
  , m3.pointhelper
  ;

{$R *.fmx}

procedure TfraBitmapViewer.imgBitmapMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Single);
begin
  fLastPt := imgBitmap.toBitmapPoint(PointF(x, y)).toPoint;
  var data:TBitmapData;
  if Rect(0, 0, imgBitmap.Bitmap.Width-1, imgBitmap.Bitmap.Height-1). Contains(fLastPt)
  then
  begin
    if imgBitmap.Bitmap.Map(TMapAccess.Read, data) then
    try
      var color := Data.GetPixel(fLastPt.X, fLastPt.y);
      rectColor1.Fill.Color := color;
      UpdateStatus
    finally
      imgBitmap.Bitmap.UnMap(data)
    end;
  end
  else
    rectColor1.Fill.Color := TAlphaColorRec.Null
end;

procedure TfraBitmapViewer.imgBitmapResized(Sender: TObject);
begin
  UpdateStatus
end;

procedure TfraBitmapViewer.Loaded;
begin
  inherited;
//  tckZoom.va
end;

procedure TfraBitmapViewer.tckZoomChange(Sender: TObject);
begin
  imgBitmap.BeginUpdate;
  imgBitmap.BitmapScale := tckZoom.Value;
  imgBitmap.EndUpdate
end;

procedure TfraBitmapViewer.UpdateStatus;
begin
  lblStatus.Text := format('COLOR:$%8.8X %5d,%5d',[
    rectColor1.fill.Color
    , fLastPt.X
    , fLastPt.Y
    ]);
  tckZoom.BeginUpdate;
  tckZoom.Value := imgBitmap.Bitmapscale;
  tckZoom.EndUpdate
end;

end.
