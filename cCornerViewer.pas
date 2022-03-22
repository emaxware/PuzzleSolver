unit cCornerViewer;

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
  TfraCornerViewer = class(TfraFunctionViewer)
    grpHeadSize: TGroupBox;
    grpCornerRatio: TGroupBox;
    btnStep: TButton;
    sliHeadLength: TComboTrackBar;
    sliAngleRatio: TComboTrackBar;
    rbNone: TRadioButton;
    grpTrace: TGroupBox;
    rbByPoint: TRadioButton;
    rbBySegment: TRadioButton;
    btnNext: TButton;
    lblPieceIndex: TLabel;
    btnPrev: TButton;
    chkReverse: TCheckBox;
    grpMaxAngle: TGroupBox;
    sliMaxAngle: TComboTrackBar;
    rbShowErrors: TCheckBox;
    rbManual: TRadioButton;
    sliManual: TTrackBar;
    btnAll: TButton;
    procedure btnSlicerClick(Sender: TObject);
    procedure btnStepClick(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnNextClick(Sender: TObject);
    procedure fraBitmapViewerSlicerimgBitmapPaint(Sender: TObject;
      Canvas: TCanvas; const ARect: TRectF);
    procedure fraBitmapViewertckZoomChange(Sender: TObject);
    procedure FrameResized(Sender: TObject);
    procedure sliManualChange(Sender: TObject);
    procedure btnAllClick(Sender: TObject);
  private
    { Private declarations }
    fNextStep:TSimpleEvent;
    fInUpdate:boolean;
    fTestOffset:integer;
    fOverlayRect:TRectF;
    fRepaintOverlay:boolean;
    fPoints:TSegment;
    fManualMove:boolean;
    fManualMoveto:integer;
//    fSegments:TList<TSegment>;
  protected
    procedure Loaded; override;
  public
    { Public declarations }
    procedure AfterConstruction; override;
    destructor Destroy; override;

    procedure Start(AScan:TScanCollection; APieceIndex:integer); override;

    procedure UpdateOverlay; override;
  end;

var
  fraCornerViewer: TfraCornerViewer;

implementation

{$R *.fmx}

uses
  System.Math
  , System.Math.Vectors
  , m3.bitmaphelper.fmx
  , m3.pointhelper
  , m3.imageviewerhelper
  , m3.generics
  ;

{ TfraSlicerViewer }

procedure TfraCornerViewer.AfterConstruction;
begin
  inherited;
  fNextStep := TSimpleEvent.Create(nil, false, False, '')
end;

procedure TfraCornerViewer.btnAllClick(Sender: TObject);
begin
  for var i := 0 to fScan.Count-1 do
  begin
    if (fScan.Pieces[i].Sides = nil) then
    begin
      var sides := fScan.Pieces[i].DetectSides(Round(sliHeadLength.Value), sliAngleRatio.Value, sliMaxAngle.Value);

      if (sides = nil) or (sides.Count <> 4) then
      begin
        sides.free;
        Start(fScan, i);
        continue
      end;

      for var j := 0 to sides.Count-1 do
      begin
        var slices := sides[j].DetectSlices(Round(sliHeadLength.Value), sliAngleRatio.Value);
        if (slices = nil) or (slices.Count = 0) then
        begin
          sides.free;
          slices.free;
          Start(fScan, i);
          continue
        end;
        sides[j].Slices := slices;
      end;

      fScan.Pieces[i].Sides := sides;
    end;
  end;

  Next
end;

procedure TfraCornerViewer.btnNextClick(Sender: TObject);
begin
  if sender = btnNext then
    fPieceIndex := (fPieceIndex + 1) mod fScan.Count
  else
    fPieceIndex := (fPieceIndex + fScan.Count-2) mod fScan.Count;
  Start(fScan, fPieceIndex);
//  UpdateOverlay
end;

procedure TfraCornerViewer.btnSlicerClick(Sender: TObject);
begin
  UpdateOverlay
end;

procedure TfraCornerViewer.btnStepClick(Sender: TObject);
begin
  if not fInUpdate then
  begin
//    if rbNone.IsChecked then
//      rbByPoint.IsChecked := true;
    UpdateOverlay
  end
  else
    fNextStep.SetEvent
end;

procedure TfraCornerViewer.btnTestClick(Sender: TObject);
begin
  if not fInUpdate then
  begin
    rbNone.IsChecked := false;

    UpdateOverlay;
    for var i := 1 to fPiece.Points.Count-1 do
    begin
      fTestOffset := i;
      UpdateOverlay
    end;
  end
  else
    fNextStep.SetEvent
end;

destructor TfraCornerViewer.Destroy;
begin
  fNextStep.SetEvent;
  application.ProcessMessages;
  freeandnil(fNextStep);
  inherited;
end;

procedure TfraCornerViewer.fraBitmapViewerSlicerimgBitmapPaint(Sender: TObject;
  Canvas: TCanvas; const ARect: TRectF);
begin
  if (fOverlay = nil) or (fOverlay.Width = 0) then
    exit;
  Canvas.BeginScene;
  try
    var r := ARect;
    Canvas.DrawBitmap(fOverlay, fOverlay.BoundsF, fOverlayRect, 1)
  finally
    Canvas.EndScene
  end;
end;

procedure TfraCornerViewer.fraBitmapViewertckZoomChange(Sender: TObject);
begin
  fraBitmapViewer.tckZoomChange(sender);
  UpdateOverlay
end;

procedure TfraCornerViewer.FrameResized(Sender: TObject);
begin
  inherited;
  UpdateOverlay
end;

procedure TfraCornerViewer.Loaded;
begin
  inherited;

end;

procedure TfraCornerViewer.sliManualChange(Sender: TObject);
begin
  if sliManual.Value > 0 then
  begin
    fManualMove := true;
    fManualMoveto := round(sliManual.Value);
    fNextStep.SetEvent
  end
end;

procedure TfraCornerViewer.Start(AScan: TScanCollection; APieceIndex: integer);
begin
  inherited;
  fraBitmapViewer.imgBitmap.Bitmap := fBitmap;
  UpdateOverlay;
end;

procedure TfraCornerViewer.UpdateOverlay;
begin
  if (fOverlay = nil) or (fOverlay.Width = 0) then
    exit;

  lblPieceIndex.Text := format('Piece #%d',[fPieceIndex]);
  var topLeftOverlay := fraBitmapViewer.imgBitmap.toControlPoint(PointF(0, 0));
  var bottomRightOverlay := fraBitmapViewer.imgBitmap.toControlPoint(PointF(fBitmap.Width, fBitmap.Height));
  fOverlayRect := RectF(topLeftOverlay.X-1, topLeftOverlay.Y-1, bottomRightOverlay.X+1, bottomRightOverlay.Y+1);
  fOverlay.Resize(Ceil(fOverlayRect.Width), Ceil(fOverlayRect.Height));
  fOverlay.Clear(TAlphaColorRec.null);

  if fInUpdate then
  begin
    fRepaintOverlay := true;
    fNextStep.SetEvent;
    exit;
  end;

  try
    fInUpdate := true;
    pnlLeft.Enabled := false;

    var headsize := round(sliHeadLength.Value);
    var manualUpdate := TSimpleEvent.Create(nil, False, False, '');

    sliManual.Min := 0;
    sliManual.Max := fPiece.Points.Count * 2;
    sliManual.Frequency := 1;
    sliManual.Value := 0;

    if (fPiece.Sides = nil) then
    begin
      var sides := fPiece.DetectSides(
        Round(sliHeadLength.Value)
        , sliAngleRatio.Value
        , sliMaxAngle.Value
        , procedure (
          ALevel: TScanPiece.TTraceLevel;
          AHead : TSegment;
          ASide : TSide;
          ASegments : TSegments<TSide>
        )
        begin
          repeat
            case ALevel of
              TScanPiece.TTraceLevel.tlByError, TScanPiece.TTraceLevel.tlByErrorFixed:
                if not rbShowErrors.IsChecked then
                  exit;
              TScanPiece.TTraceLevel.tlByPoint:
                if not rbByPoint.IsChecked then
                  exit;
              TScanPiece.TTraceLevel.tlBySegment:
                if not rbBySegment.IsChecked then
                  exit;
            end;

            try
              var canvas := fOverlay.Canvas;
              var scale := fraBitmapViewer.imgBitmap.BitmapScale;

              canvas.BeginScene;
              canvas.Clear(0);
              canvas.Stroke.Color := TAlphaColorRec.Blue;
              canvas.Stroke.Thickness := 1;
              canvas.DrawRect(RectF(0, 0, fOverlayRect.Width-1, fOverlayRect.Height-1), 1);
              canvas.SetMatrix(TMatrix.CreateTranslation(2, 2));
              canvas.EndScene
            finally
            end;

            if ALevel = tlByError then
            begin
              mmoProps.Lines.Text := format('Head(5)=%.2f'#13#10'Deleting %d,%d',[
                AHead.HeadRatio(5)
                , AHead[AHead.Count-3].X
                , AHead[AHead.Count-3].y
                ])
            end
            else
            if ALevel = tlByErrorFixed then
            begin
              mmoProps.Lines.add(format('Head(5)=%.2f',[
                AHead.HeadRatio(5)
                ]));

  //            var canvas := fOverlay.Canvas;
              for var i := AHead.Count-5 to AHead.Count-1 do
              try
                var canvas := fOverlay.Canvas;
                var scale := fraBitmapViewer.imgBitmap.BitmapScale;

                canvas.BeginScene;
                var sv := canvas.SaveState;
                canvas.Stroke.Color := TAlphaColorRec.Aqua;
                canvas.SetMatrix(TMatrix.CreateTranslation(2, 2));
                canvas.DrawEllipse(
                  (AHead[i].toPointF * scale)
                  .toRectF(scale, scale), 1);
                canvas.RestoreState(sv);
                canvas.EndScene;
              finally
                fraBitmapViewer.imgBitmap.Repaint;
                Application.processmessages;
                ShowMessage(format('Pt[%d] = %d,%d',[i, AHead[i].X, AHead[i].Y]))
              end;
            end
            else
            begin
              var angle:single := 0;
              if (ASide.Count > 0) and (AHead.Count > 0) then
                angle := AHead[0].DegreesBetween(ASide[0], AHead.Last);
              mmoProps.Lines.Text := format('AHead=%.2f'#13#10'Tail=%.2f'#13#10'Angle=%.2f'#176,
              [
                AHead.HeadRatio
                , ASide.HeadRatio
                , angle
              ]);
            end;

            try
              var canvas := fOverlay.Canvas;
              var scale := fraBitmapViewer.imgBitmap.BitmapScale;

              canvas.BeginScene;
              var sv := canvas.SaveState;
              for var i := 0 to ASegments.Count-1 do
                canvas.Draw(ASegments[i], scale);

              canvas.Draw(ASide, scale);
              canvas.Draw(AHead, scale);

              if (ALevel = tlByError) then
              begin
                canvas.Stroke.Color := TAlphaColorRec.Red;
                var pt := AHead[AHead.count-3].toPointF;
                canvas.DrawEllipse((pt * scale).toRectF(scale, scale), 1)
              end
              else
              if rbManual.IsChecked then
              begin
                canvas.Stroke.Color := TAlphaColorRec.Red;
                var pt := AHead.Last.toPointF;
                canvas.DrawEllipse((pt * scale).toRectF(scale, scale), 1)
              end;
              canvas.RestoreState(sv);
              canvas.EndScene;
            finally
              fraBitmapViewer.imgBitmap.Repaint
            end;

            while fNextStep.WaitFor(100) = TWaitResult.wrTimeout do
              Application.ProcessMessages;

            if fRepaintOverlay then
            begin
              fRepaintOverlay := false;
              continue
            end;

            break
          until false
        end
        , function(var offset:integer):Boolean
        begin
          offset := fManualMoveto;
          if fManualMove then
          begin
            fManualMove := false;
            Result := False;
          end
          else
            result := true
        end
        , rbManual.IsChecked
      );

      fPiece.Sides := sides;
    end;

    try
      mmoProps.Lines.Clear;
      try
        var canvas := fOverlay.Canvas;
        var scale := fraBitmapViewer.imgBitmap.BitmapScale;
        canvas.BeginScene;
        var sv := canvas.SaveState;
        canvas.Clear(0);
        canvas.Stroke.Color := TAlphaColorRec.Blue;
        canvas.Stroke.Thickness := 1;
        canvas.DrawRect(RectF(0, 0, fOverlayRect.Width-1, fOverlayRect.Height-1), 1);
        canvas.SetMatrix(TMatrix.CreateTranslation(2, 2));

        for var i := 0 to fPiece.Sides.Count-1 do
        begin
          canvas.Draw(fPiece.Sides[i], scale);
          mmoProps.Lines.add(format('[%d] pts:%d len:%.2f/%.2f %.2f'#176'/%.2f'#176,
          [
            i
            , fPiece.Sides[i].Count
            , fPiece.Sides[i].length
            , fPiece.Sides[i].LengthRatio
            , fPiece.Sides[i].TailAngle
            , fPiece.Sides[i].HeadAngle
          ]));
        end;

        canvas.RestoreState(sv);
        canvas.EndScene;
      finally
        fraBitmapViewer.imgBitmap.Repaint;
        application.processmessages
      end;

      for var i := 0 to fPiece.Sides.Count-1 do
      begin
        if fPiece.Sides[i].Slices = nil then
        begin
          var slices := fPiece.Sides[i].DetectSlices(
            headsize
//            , 0.96
            , sliAngleRatio.Value
            , procedure(
              ATraceLevel:TSide.TSideTraceLevel;
              AHead : TSlice;
              ASlice : TSlice;
              ASegments : TSegments<TSlice>
            )
            begin
              repeat
                case ATraceLevel of
//                    TSideTraceLevel.tlByError, TScanPiece.TTraceLevel.tlByErrorFixed:
//                      if not rbShowErrors.IsChecked then
//                        exit;
                  TSide.TSideTraceLevel.stlByPoint:
                    if not rbByPoint.IsChecked then
                      exit;
                  TSide.TSideTraceLevel.stlBySegment:
                    if not rbBySegment.IsChecked then
                      exit;
                end;

                var canvas := fOverlay.Canvas;
                var scale := fraBitmapViewer.imgBitmap.BitmapScale;

                canvas.BeginScene;
                var sv := canvas.SaveState;
                try
                  for var i := 0 to ASegments.Count-1 do
                    canvas.Draw(ASegments[i], scale);

                  canvas.Draw(ASlice, scale, TAlphaColorRec.Orange);
                  canvas.Draw(AHead, scale, TAlphaColorRec.White)
                finally
                  canvas.RestoreState(sv);
                  canvas.EndScene;
                  fraBitmapViewer.imgBitmap.Repaint;
                end;

                while fNextStep.WaitFor(100) = TWaitResult.wrTimeout do
                  Application.ProcessMessages;

                if fRepaintOverlay then
                begin
                  fRepaintOverlay := false;
                  continue
                end;

                break
              until false
            end
          );
          fPiece.Sides[i].Slices := slices
        end;

        var canvas := fOverlay.Canvas;
        var scale := fraBitmapViewer.imgBitmap.BitmapScale;

        canvas.BeginScene;
        var sv := canvas.SaveState;
//        canvas.Clear(0);
//        canvas.Stroke.Color := TAlphaColorRec.Blue;
//        canvas.Stroke.Thickness := 1;
//        canvas.DrawRect(RectF(0, 0, fOverlayRect.Width-1, fOverlayRect.Height-1), 1);
        canvas.SetMatrix(TMatrix.CreateTranslation(2, 2));
        try
          for var j := 0 to fPiece.Sides[i].Slices.Count-1 do
            canvas.draw(fPiece.Sides[i].Slices[j], scale)
        finally
          canvas.RestoreState(sv);
          canvas.EndScene;
          fraBitmapViewer.imgBitmap.Repaint;
          Application.ProcessMessages
        end;
      end
    finally
      fraBitmapViewer.imgBitmap.Repaint
    end;

    mmoProps.Lines.clear;
    for var i := 0 to fPiece.Sides.Count-1 do
    begin
      if fPiece.Sides[i].Slices = nil then
        mmoProps.Lines.add(format('[%d] pts:%d len:%.2f/%.2f slices:none'// %.2f'#176'/%.2f'#176
        , [
          i
          , fPiece.Sides[i].Count
          , fPiece.Sides[i].Length
          , fPiece.Sides[i].LengthRatio
  //        , fPiece.Sides[i].TailAngle
  //        , fPiece.Sides[i].HeadAngle
        ]))
      else
      begin
        mmoProps.Lines.add(format('[%d] pts:%d len:%.2f/%.2f slices:%d'// %.2f'#176'/%.2f'#176
        , [
          i
          , fPiece.Sides[i].Count
          , fPiece.Sides[i].length
          , fPiece.Sides[i].LengthRatio
          , fPiece.Sides[i].Slices.Count
  //        , fPiece.Sides[i].TailAngle
  //        , fPiece.Sides[i].HeadAngle
        ]));
        for var j := 0 to fPiece.Sides[i].Slices.Count-1 do
        with fpiece.Sides[i].Slices[j] do
          mmoProps.Lines.Add(format('  [%d] pts%d len:%.2f/%.2f'
          , [
            j
            , Count
            , Length
            , LengthRatio
            ]))
      end;
    end;

  finally
    fInUpdate := false;
    pnlLeft.Enabled := true;
  end;
end;

end.
