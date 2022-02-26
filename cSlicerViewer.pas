unit cSlicerViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  cFunctionViewer, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, cBitmapViewer, FMX.Edit, FMX.EditBox, FMX.NumberBox
  , system.SyncObjs, FMX.ComboTrackBar
  , system.Generics.Collections
  , uScanPiece
  ;

type
  TfraSlicerViewer = class(TfraFunctionViewer)
    grpSlicer1: TGroupBox;
    grpSlicer2: TGroupBox;
    grpCornerAngle: TGroupBox;
    btnStep: TButton;
    sliHeadLength: TComboTrackBar;
    sliStraightAngle: TComboTrackBar;
    sliCornerAngle: TComboTrackBar;
    rbNone: TRadioButton;
    grpTrace: TGroupBox;
    rbByPoint: TRadioButton;
    rbBySegment: TRadioButton;
    grpTest: TGroupBox;
    rbTestNoStep: TRadioButton;
    btnTest: TButton;
    rbTestWithStep: TRadioButton;
    rbTestWithSteps: TRadioButton;
    procedure btnSlicerClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
  private
    { Private declarations }
    fNextStep:TSimpleEvent;
    fInUpdate:boolean;
    fTestOffset:integer;
    fSegments:TList<TSegment>;
  protected
  public
    { Public declarations }
    procedure AfterConstruction; override;
    destructor Destroy; override;

    procedure UpdateOverlay; override;
  end;

var
  fraSlicerViewer: TfraSlicerViewer;

implementation

{$R *.fmx}

uses
  m3.bitmaphelper.fmx
  , m3.pointhelper
  ;

type
  TCanvasHelper = class helper for TCanvas
  public
    procedure DrawTail(ASegment:TPoints; ALength:Integer; AColor:TAlphaColor); overload;
    procedure DrawHead(ASegment:TPoints; ALength:Integer; AColor:TAlphaColor); overload;
    procedure Draw(ASegment:TPoints; AColor:TAlphaColor); overload;

    procedure DrawTail(ASegment:TPoints; ALength:Integer); overload;
    procedure DrawHead(ASegment:TPoints; ALength:Integer); overload;
    procedure Draw(ASegment:TSegment); overload;

//    procedure Draw(
  end;

{ TfraSlicerViewer }

procedure TfraSlicerViewer.AfterConstruction;
begin
  inherited;
  fNextStep := TSimpleEvent.Create(nil, false, False, '')
end;

procedure TfraSlicerViewer.btnSlicerClick(Sender: TObject);
begin
  UpdateOverlay
end;

procedure TfraSlicerViewer.btnStepClick(Sender: TObject);
begin
  if not fInUpdate then
  begin
    if rbNone.IsChecked then
      rbByPoint.IsChecked := true;
    UpdateOverlay
  end
  else
    fNextStep.SetEvent
end;

procedure TfraSlicerViewer.btnTestClick(Sender: TObject);
begin
  if not fInUpdate then
  begin
    rbNone.IsChecked := false;

    UpdateOverlay;
    var
    for var i := 1 to fPiece.Points.Count-1 do
    begin
      fTestOffset := i;
      UpdateOverlay
    end;
  end
  else
    fNextStep.SetEvent
end;

destructor TfraSlicerViewer.Destroy;
begin
  fNextStep.SetEvent;
  application.ProcessMessages;
  freeandnil(fNextStep);
  inherited;
end;

procedure TfraSlicerViewer.UpdateOverlay;
var
  canvas:TCanvas;
  head : TPoints;
  headsize:integer;
  segment : TPoints;
  segments : TList<TSegment>;

  procedure DoTrace;
  begin
    mmoProps.Lines.Text := format('Head=%.2f/%.2f°'#13#10'Tail=%.2f/%.2f°',
    [
      head.HeadRatio(headsize)
      , head.HeadAngle(headsize)
      , segment.TailRatio(headsize)
      , segment.TailAngle(headsize)
    ]);

    canvas.BeginScene;
    try
      canvas.Clear(0);
      canvas.DrawBitmap(fBitmap, fBitmap.BoundsF, fBitmap.BoundsF, 1);

      for var i := 0 to segments.Count-1 do
        canvas.Draw(segments[i]);

      canvas.Draw(segment, TAlphaColorRec.white);
      canvas.Draw(head, TAlphaColorRec.Red);
    finally
      canvas.EndScene;
      fraBitmapViewerSlicer.imgBitmap.Bitmap := fOverlay;
    end;

    while fNextStep.WaitFor(100) = TWaitResult.wrTimeout do
      Application.ProcessMessages
  end;

begin
  if fInUpdate then
    exit;
  var ptCurr:TPoint;
  canvas := fOverlay.Canvas;
  try
    fInUpdate := true;
    pnlLeft.Enabled := false;

    headsize := round(sliHeadLength.Value);
    var straightRatio := sliStraightAngle.Value;// 0.9;
    var ptIndex := fTestOffset;
    head := TPoints.create;
    var prevHead := TPoints.Create;
    var prevOrientation:TSegmentOrientation;
    segment := TPoints.create;
    segments := TList<TSegment>.create;
    var skipSegmentCount := 2;
    repeat
      var offset := ptIndex mod fPiece.Points.Count;
      ptCurr := fPiece.Points[offset];
      inc(ptIndex);
      if (segments.Count > 0) and (ptCurr = segments[0][0]) then
      begin
        segment.AddRange(head);
        segments.add(TSegment.create(segment, prevOrientation));
        segment := nil;
        Break;
      end;

      prevHead.Clear;
      prevHead.AddRange(head);
      head.Add(ptCurr);
      if head.Count <= headsize  then
        continue;

      segment.Add(head[0]);
      head.Delete(0);
      var headAngle := head.HeadAngle(headSize);

//      if (Abs(headAngle) > cornerangle) then
//        if (head.HeadRatio(headSize) > straightRatio) then
//        begin
//          var midhead := (headsize-1) div 2 - 1;
//          for var i := 0 to midhead do
//          begin
//            if (segments.Count > 0) or (segment.Count > 0) then
//              segment.Add(head[0]);
//            head.Delete(0)
//          end;
//          if segment.Count > 0 then
//          begin
//            if skipSegmentCount > 0 then
//            begin
//              Dec(skipSegmentCount);
//              segment.clear;
//            end
//            else
//            begin
//              segments.Add(segment);
//              segment := TPoints.Create;
//            end;
//          end;
//          continue
//        end;

      if segment.Count < headsize then
        continue;

      var tailAngle := segment.TailAngle(headSize);

      if rbByPoint.IsChecked then
        DoTrace;

      if ((head.HeadRatio(headSize) > straightRatio) and (segment.TailRatio(headSize) > straightRatio)) then
      begin
        prevOrientation := TSegmentOrientation.soStraight;
        continue
      end
      else
      if (prevHead.HeadRatio(headsize) > straightRatio) and (prevOrientation = TSegmentOrientation.soStraight) then
      begin
        if skipSegmentCount > 0 then
        begin
          Dec(skipSegmentCount);
          segment.clear
        end
        else
        begin
          if rbBySegment.IsChecked then
            DoTrace;
          segment.AddRange(prevHead);
          segments.Add(TSegment.Create(segment, prevOrientation));
          segment.Clear;
          head.Clear;
          head.Add(ptCurr);
          if rbBySegment.IsChecked then
            DoTrace;
        end;
      end
      else
      if ((tailAngle < 0) and (headangle < 0)) then
      begin
        prevOrientation := TSegmentOrientation.soLeft;
        continue
      end
      else
      if ((tailAngle > 0) and (headangle > 0)) then
      begin
        prevOrientation := TSegmentOrientation.soRight;
        Continue
      end
      else
      begin
        if skipSegmentCount > 0 then
        begin
          Dec(skipSegmentCount);
          segment.clear
        end
        else
        begin
          if rbBySegment.IsChecked then
            DoTrace;

          if (segment.tailRatio(headSize) > straightRatio) then
            prevOrientation := TSegmentOrientation.soStraight
          else
          if (tailAngle < 0) then
            prevOrientation := TSegmentOrientation.soLeft
          else
          if (tailAngle > 0) then
            prevOrientation := TSegmentOrientation.soRight;

          segments.Add(TSegment.Create(segment, prevOrientation));
          segment.Clear;
          if rbBySegment.IsChecked then
            DoTrace;
        end;
      end;
    until ptIndex > fPiece.Points.Count*2;

    canvas.BeginScene;
    try
      canvas.Clear(0);
      canvas.DrawBitmap(fBitmap, fBitmap.BoundsF, fBitmap.BoundsF, 1);

      for var i := 0 to segments.Count-1 do
        canvas.Draw(segments[i]);

//      canvas.Draw(segment, TAlphaColorRec.white);
//      canvas.Draw(head, TAlphaColorRec.Red);
    finally
      canvas.EndScene;
      fraBitmapViewerSlicer.imgBitmap.Bitmap := fOverlay;
    end;

    segment.Free;
    head.Free;
    segments.Free;
  finally
    fInUpdate := false;
    pnlLeft.Enabled := true;
  end;
end;

{ TCanvasHelper }

procedure TCanvasHelper.Draw(ASegment: TPoints; AColor: TAlphaColor);
var
  APt1:TPointF;
begin
  if (ASegment = nil) or (ASegment.Count < 2) then
    exit;

  self.Stroke.Color := AColor;
  APt1 := ASegment[0].toPointF;
  for var i := 1 to ASegment.Count-1 do
  begin
    DrawLine(APt1, ASegment[i].toPointF, 1);
    APt1 := ASegment[i].toPointF
  end;
end;

procedure TCanvasHelper.DrawHead(ASegment: TPoints; ALength: Integer);
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  ASegment.HeadAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  DrawLine(AStartPt.toPointF, AMidPt.toPointF, 1);
  DrawLine(AMidPt.toPointF, AEndPt.toPointF, 1)
end;

procedure TCanvasHelper.DrawTail(ASegment: TPoints; ALength: Integer;
  AColor: TAlphaColor);
begin
  self.Stroke.Color := AColor;
  DrawTail(ASegment, ALength)
end;

procedure TCanvasHelper.Draw(ASegment: TSegment);
begin
  case ASegment.Orientation of
    soStraight:
      Draw(ASegment, TAlphaColorRec.Yellow);
    soLeft:
      Draw(ASegment, TAlphaColorRec.Blue);
    soRight:
      Draw(ASegment, TAlphaColorRec.Aqua);
  end;
  Stroke.Color := TAlphaColorRec.Black;
  var startPt := RectF(ASegment[0].X,ASegment[0].Y,ASegment[0].X,ASegment[0].Y);
  startPt.Inflate(2, 2);
  DrawRect(startPt,1)
end;

procedure TCanvasHelper.DrawHead(ASegment: TPoints; ALength: Integer;
  AColor: TAlphaColor);
begin
  self.Stroke.Color := AColor;
  DrawHead(ASegment, ALength)
end;

procedure TCanvasHelper.DrawTail(ASegment: TPoints; ALength: Integer);
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  ASegment.TailAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  DrawLine(AStartPt.toPointF, AMidPt.toPointF, 1);
  DrawLine(AMidPt.toPointF, AEndPt.toPointF, 1)
end;

end.
