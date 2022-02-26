unit cSegmentViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  cFunctionViewer, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, cBitmapViewer, FMX.Edit, FMX.EditBox, FMX.NumberBox;

type
  TfraSegmentViewer = class(TfraFunctionViewer)
    grpSegment: TGroupBox;
    edtSegmentLength: TNumberBox;
    sliSegmentLength: TTrackBar;
    grpSegmentOffset: TGroupBox;
    edtSegmentOffset: TNumberBox;
    sliSegmentOffset: TTrackBar;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure UpdateOverlay; override;
  end;

var
  fraSegmentViewer: TfraSegmentViewer;

implementation

{$R *.fmx}

uses
  m3.bitmaphelper.fmx
  ;

{ TfraSegmentViewer }

procedure TfraSegmentViewer.UpdateOverlay;
begin
  var ptsPrev, ptsCurr:TPoint;
  var ptFirst, ptPrev, ptCurr, ptLast:TPoint;
  var totalLen:single := 0;
  var len:single := 0;
  var data:TBitmapData;
  FreeAndNil(fOverlay);
  fOverlay := fBitmap.clone;
  if fOverlay.Map(TMapAccess.ReadWrite, data) then
  try
    for var i := 0 to fPiece.Points.Count-1 do
    begin
      ptsCurr := fPiece.Points[i];
      if i > 0 then
        totallen := totallen + ptsCurr.Distance(ptsPrev);
      ptsPrev := ptsCurr;
    end;

    for var i := 0 to Trunc(sliSegmentLength.Value)-1 do
    begin
      var offset := round(sliSegmentOffset.Value + i) mod fPiece.Points.Count;
      ptCurr := fPiece.Points[offset];
      data.SetPixel(ptCurr.X, ptCurr.Y, TAlphaColorRec.Yellow);
      if i = 0 then
      begin
        ptFirst := ptCurr
      end
      else
      begin
        ptLast := ptCurr;

        len := len + ptPrev.Distance(ptCurr);
      end;
      ptPrev := ptCurr;
    end;
    mmoProps.Lines.Text := format('Perimeter len: %.2f'#13#10'Segment len: %.2f'#13#10'Distance: %.2f'#13#10'Ratio: %.4f',[
      totallen
      , len
      , ptFirst.Distance(ptLast)
      , len / ptFirst.Distance(ptLast)
        ])
  finally
    fOverlay.UnMap(data)
  end;
end;

end.
