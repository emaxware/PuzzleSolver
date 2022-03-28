unit cArrangeViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  cFunctionViewer, FMX.Memo.Types, FMX.ScrollBox, FMX.Memo,
  FMX.Controls.Presentation, cBitmapViewer, FMX.ListBox, FMX.Layouts
  , uScanPiece, FMX.ExtCtrls, cPieceViewer, FMX.Objects, FMX.TabControl
  ;

type
  TfraArrangeViewer = class(TfraFunctionViewer)
    lstPieces: TListBox;
    lbiCorner1: TListBoxItem;
    lbi1: TListBoxItem;
    lstBorders: TListBoxGroupHeader;
    lbhCorners: TListBoxGroupHeader;
    splRight: TSplitter;
    spl2: TSplitter;
    tbcPieces: TTabControl;
    tabPieces: TTabItem;
    tabArrange: TTabItem;
    pbArrange: TPaintBox;
    tlbArrange: TToolBar;
    btnNext: TSpeedButton;
    btnMatch: TSpeedButton;
    lblScore: TLabel;
    btnPrev: TSpeedButton;
    btnSkip: TSpeedButton;
    procedure lstPiecesDblClick(Sender: TObject);
    procedure lbiCorner1Paint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure btnNextClick(Sender: TObject);
    procedure pbArrangePaint(Sender: TObject; Canvas: TCanvas);
    procedure btnMatchClick(Sender: TObject);
    procedure fraBitmapViewerimgBitmapPaint(Sender: TObject; Canvas: TCanvas;
      const ARect: TRectF);
    procedure btnSlicerClick(Sender: TObject);
    procedure fraBitmapViewertckZoomChange(Sender: TObject);
  private
    { Private declarations }
    fRepainting:Boolean;
    fArrCollection:TArrCollection;
//    fCurrPiece:TArrPiece;
    fArrOverlay:TBitmap;
    fCurrSide:TArrSide;
    fMatchSide:TArrSide;
    fMatchSides:TArray<TArrSide>;
    fMatchSidesIndex:integer;
    fTranslationX, fTranslationY:single;
    fArrangementAngle:single;
    fArrScale:single;
    fSkipTargetCount:integer;
//    fLastArrBound, fArrBound:TRectF;
  public
    { Public declarations }

    procedure Start(AScan:TScanCollection); override;
    procedure LoadNextCompatibleSide(inc:integer=1);
    procedure LoadNextTargetSide(ASkipCount:integer);
  end;

var
  fraArrangeViewer: TfraArrangeViewer;

implementation

{$R *.fmx}

uses
  System.Math
  , System.Math.Vectors
  , System.Generics.Collections
  , m3.framehelper.fmx
  , m3.pointhelper
  , m3.consolelog
  , m3.bitmaphelper.fmx
//  , m3.DebugForm
  ;

{ TfraArrangeViewer }

procedure TfraArrangeViewer.btnMatchClick(Sender: TObject);
begin
  if sender = btnMatch then
  begin
    fCurrSide.AddLink(fMatchSide);
    fMatchSide := nil;
    LoadNextTargetSide(0);
  end
  else
  begin
    fMatchSide := nil;
    LoadNextTargetSide(1);
  end;
  fraBitmapViewer.imgBitmap.Repaint;
//  fArrBound := fLastArrBound;
  pbArrange.Repaint
end;

procedure TfraArrangeViewer.btnNextClick(Sender: TObject);
begin
  if sender = btnNext then
    LoadNextCompatibleSide(1)
  else
    LoadNextCompatibleSide(-1);

//  fArrBound := fLastArrBound;
  pbArrange.Repaint
end;

procedure TfraArrangeViewer.btnSlicerClick(Sender: TObject);
begin
  fArrangementAngle := fArrangementAngle + DegToRad(90);
  fraBitmapViewer.imgBitmap.Repaint
end;

procedure TfraArrangeViewer.fraBitmapViewerimgBitmapPaint(Sender: TObject;
  Canvas: TCanvas; const ARect: TRectF);
var
  APaintedPieces : TDictionary<TArrPiece,TMatrix>;
  AArrBound : TRectF;
  canvasM : TMatrix;

  procedure WalkArrangement(ATrans:TMatrix; AAngle:extended; ASide:TArrSide);//; APaintSide: TFunc<Single, TArrSide, Boolean>);
  begin
    if not APaintedPieces.ContainsKey(ASide.Piece) then
//    with
//      TLog.Instance.ScopeLog([leInfo], 'Walk Piece %d starting %d angle %.2f toward %.2f',[ASide.Piece.PieceIndex, ASide.ArrSideIndex, RadToDeg(ASide.Angle), RadToDeg(AAngle)])
//    do
    begin

//      Canvas.Stroke.Color := TAlphaColorRec.Red;
//      Canvas.Draw([PointF(5, 0), PointF(0, 5), PointF(-5, 0), PointF(5, 0)]);

//      var currM := Canvas.Matrix;
      var rotateToAngle := TRotatedSide.Create(ASide, AAngle, 1);
      var newM:TMatrix;
      with rotateToAngle.rotatedCenter[0] * -1 do
        newm := TMatrix.CreateTranslation(X , Y);
      var rotAngelInDeg := RadToDeg(rotateToAngle.rotationAngle);
      rotateToAngle.rotationAngle := rotateToAngle.rotationAngle * (pi * 16);
      rotateToAngle.rotationAngle := round(rotateToAngle.rotationAngle);
      rotateToAngle.rotationAngle := rotateToAngle.rotationAngle / (pi * 16);
      var rotAngelInDeg2 := RadToDeg(rotateToAngle.rotationAngle);
      newM := newM * TMatrix.CreateRotation(rotateToAngle.rotationAngle);

      newM := newM * ATrans;

      if newM.m31 < AArrBound.Left then
        AArrBound.Left := newM.m31;

      if newM.m31 > AArrBound.Right then
        AArrBound.Right := newM.m31;

      if newM.m32 < AArrBound.Top then
        AArrBound.Top := newM.m32;

      if newM.m32 > AArrBound.Bottom then
        AArrBound.Bottom := newM.m32;

//      newM := newM * canvasM;

      for var i := 0 to ASide.Piece.Sides.Count-1 do
      begin
        var sideIndex := (ASide.ArrSideIndex+i) mod ASide.Piece.Sides.Count;
        var currSide := ASide.Piece.Sides[sideIndex];
//        Canvas.SetMatrix(newM);

        if i = 0 then
        begin
          APaintedPieces.Add(currSide.Piece, newM);
//          if AArrBound = RectF(0, 0, 0, 0) then
//            AArrBound := rotateToAngle.rotatedPieceBoundary + PointF(newM.m31, newM.m32)
//          else
//            AArrBound := AArrBound + (rotateToAngle.rotatedPieceBoundary + PointF(newM.m31, newM.m32));
//          var ABitmap := currSide.Piece.Collection.Scan.GetPieceBitmap(currSide.Piece.PieceIndex);
//          Canvas.DrawBitmap(ABitmap, ABitmap.BoundsF, ABitmap.BoundsF * fArrScale, 0.8);
//          Canvas.FillText(ABitmap.BoundsF * fArrScale, currSide.Piece.PieceIndex.ToString, false, 1, [], TTextAlign.Center, TTextAlign.Center)
        end;

        if (currSide.Link <> nil) then
        begin
//          Canvas.Draw(currSide.Item, fArrScale);
//          Canvas.Stroke.Color := TAlphaColorRec.Green;
//          Canvas.Draw(ScalePoints([PointF(5, 0), PointF(0, 5), PointF(-5, 0), PointF(5, 0)], fArrScale));

          var sideTrans:TMatrix;
          var flipSide := currSide.Link.OtherSide(currSide);

          with rotateToAngle, rotatedCenter[i] - rotatedCenter[0] do
            sideTrans := TMatrix.CreateTranslation(X, Y);

          var flipM := ATrans * sideTrans;
          var flipAngle := AAngle + (-ASide.Angle+currSide.Angle) + Pi;
          WalkArrangement(flipM, flipAngle, flipSide);
        end;
      end;
    end;
  end;

begin
  TLog.Instance.Log([leInfo], 'Paint>>');
  try
    Canvas.BeginScene;
    var sv := Canvas.SaveState;
    if (fArrCollection <> nil) and (fArrCollection.Links.Count > 0) then
    try
      var fSide := fArrCollection.Links.Keys.ToArray[0];
      AArrBound := RectF(0, 0, 0, 0);
      APaintedPieces := TDictionary<TArrPiece,TMatrix>.create;

      WalkArrangement(TMatrix.Identity, fArrangementAngle, fSide);

      // calc center
      var center := ARect.CenterPoint;
      canvasM := Canvas.Matrix;
      AArrBound := AArrBound * fArrScale;
      var ACenteredArrBound := AArrBound.CenterAt(ARect);

      // calc Translation
      var transM, transM2:TMatrix;
      with ACenteredArrBound do
        transM := TMatrix.CreateTranslation(left, top);

      // calc Scale
      var scaleM := TMatrix.CreateScaling(fArrScale, fArrScale);

      Canvas.Clear(0);
      Canvas.Fill.Color := TAlphaColorRec.White;
//      Canvas.SetMatrix(transM * canvasM);
//      Canvas.Stroke.Color := TAlphaColorRec.Red;
//      Canvas.DrawRect(RectF(0, 0, AArrBound.Width-1, AArrBound.Height-1), 1);

      with ACenteredArrBound do
        transM2 := TMatrix.CreateTranslation(-AArrBound.Left + left,-AArrBound.Top + top);

      for var kv in APaintedPieces do
      begin
        Canvas.SetMatrix(kv.Value * scaleM * transM2 * canvasM);
        var ABitmap := kv.Key.Collection.Scan.GetPieceBitmap(kv.Key.PieceIndex);
        Canvas.DrawBitmap(ABitmap, ABitmap.BoundsF, ABitmap.BoundsF * 1, 1);
        var pieceText := format('%d',[kv.Key.PieceIndex]);
        if kv.Key.TopSideIndex > -1 then
          pieceText := Format('%s'#13#10'%d,%d',[pieceText, kv.Key.GridPos.x, kv.Key.GridPos.Y]);
        Canvas.FillText(kv.Key.PieceCenter.Inflate(30) * 1, pieceText, false, 1, [], TTextAlign.Center, TTextAlign.Center);
//        for var sd := 0 to 3 do
//        begin
//          var side := kv.Key.GridSides[sd];
//          if side <> nil then
//          begin
//            var sideText := Format('%d',[sd]);
//            var sideCenter := (side.SideCenter - side.Piece.PieceCenter) * 0.8 + side.Piece.PieceCenter;
//            if side.Link <> nil then
//              Canvas.Fill.Color := TAlphaColorRec.Aqua;
//            Canvas.FillText(sideCenter.Inflate(10), sideText, False, 1, [], TTextAlign.Center, TTextAlign.Center);
//            Canvas.Fill.Color := TAlphaColorRec.White;
//          end
//        end
      end;

      for var kv in APaintedPieces do
      begin
        Canvas.SetMatrix(kv.Value * scaleM * transM2 * canvasM);
//        var ABitmap := kv.Key.Collection.Scan.GetPieceBitmap(kv.Key.PieceIndex);
//        Canvas.DrawBitmap(ABitmap, ABitmap.BoundsF, ABitmap.BoundsF * 1, 1);
//        var pieceText := format('%d',[kv.Key.PieceIndex]);
//        if kv.Key.TopSideIndex > -1 then
//          pieceText := Format('%s'#13#10'%d,%d',[pieceText, kv.Key.GridPos.x, kv.Key.GridPos.Y]);
//        Canvas.FillText(kv.Key.PieceCenter.Inflate(30) * 1, pieceText, false, 1, [], TTextAlign.Center, TTextAlign.Center);
        for var sd := 0 to 3 do
        begin
          var side := kv.Key.GridSides[sd];
          if side <> nil then
          begin
            var sideText := Format('%d',[sd]);
            var sideCenter := (side.SideCenter - side.Piece.PieceCenter) * 0.8 + side.Piece.PieceCenter;
            if side.Link <> nil then
              Canvas.Fill.Color := TAlphaColorRec.Aqua;
            Canvas.FillText(sideCenter.Inflate(10), sideText, False, 1, [], TTextAlign.Center, TTextAlign.Center);
            Canvas.Fill.Color := TAlphaColorRec.White;
          end
        end
      end;

      Canvas.SetMatrix(transM * canvasM);
      Canvas.Stroke.Color := TAlphaColorRec.Red;
      Canvas.DrawRect(RectF(0, 0, AArrBound.Width-1, AArrBound.Height-1), 1);

    finally
      Canvas.RestoreState(sv);
      Canvas.EndScene;
      APaintedPieces.free
    end
    else
    try
      Canvas.Clear(0)
    finally
      Canvas.RestoreState(sv);
      Canvas.EndScene
    end
  finally
    TLog.Instance.Log([leInfo], 'Paint<<'#13#10);
  end
end;

procedure TfraArrangeViewer.fraBitmapViewertckZoomChange(Sender: TObject);
begin
  fArrScale := fraBitmapViewer.tckZoom.Value;
  fraBitmapViewer.imgBitmap.Repaint
end;

procedure TfraArrangeViewer.lbiCorner1Paint(Sender: TObject; Canvas: TCanvas;
  const ARect: TRectF);
var
  AListItem:TListBoxItem absolute Sender;
  APiece:TArrPiece;
begin
  APiece := TArrPiece(AListItem.Data);
  Canvas.BeginScene;
  try
    Canvas.FillText(ARect, format('%d/%d',[APiece.SidesLinked, APiece.Sides.Count]), false, 1, [], TTextAlign.Trailing, TTextAlign.Trailing)
  finally
    Canvas.EndScene
  end;
end;

procedure TfraArrangeViewer.LoadNextCompatibleSide;
begin
  if fCurrSide <> nil then
  begin
    if (fMatchSide = nil) and (fCurrSide <> nil) then
    begin
      fMatchSides := fCurrSide.MatchingSides([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9], 10);
      fMatchSidesIndex := 0
    end
    else
      fMatchSidesIndex := (fMatchSidesIndex + Length(fMatchSides) + inc) mod Length(fMatchSides);

    if length(fMatchSides) > 0 then
      fMatchSide := fMatchSides[fMatchSidesIndex]
  end
end;

procedure TfraArrangeViewer.LoadNextTargetSide;
var
  alreadySearched:TList<TArrPiece>;
  foundSide:TArrSide;
  skipCount:integer;

  function FindUnmatchedSideInArrangement(APiece:TArrPiece):boolean;
  begin
    result := not alreadySearched.Contains(APiece);
    if result then
    begin
      result := false;
      alreadySearched.Add(APiece);
      for var i := 0 to APiece.Sides.Count-1 do
      begin
        var testSide := APiece.Sides[i];
//        if not (testSide.IsAfterBorder or testSide.IsBeforeBorder) then
//          Continue;
        if (testSide.Link = nil) then
        begin
          if skipCount = 0 then
          begin
            foundSide := testSide;
            result := true;
            exit
          end;
          Dec(skipCount)
        end
        else
        if FindUnmatchedSideInArrangement(testSide.Link.OtherSide(testSide).Piece) then
        begin
          result := true;
          break
        end
      end;
//      for var i := 0 to APiece.Sides.Count-1 do
//      begin
//        var testSide := APiece.Sides[i];
////        if not (testSide.IsAfterBorder or testSide.IsBeforeBorder) then
////          Continue;
//        if (testSide.Link = nil) then
//        begin
//          foundSide := testSide;
//          result := true;
//          exit
//        end
//        else
//        if FindUnmatchedSideInArrangement(testSide.Link.OtherSide(testSide).Piece) then
//        begin
//          result := true;
//          break
//        end
//      end;
    end;
  end;

begin
  alreadySearched := TList<TArrPiece>.create;
  try
    var found:Boolean;
    if fArrCollection.Links.Count = 0 then
      found := FindUnmatchedSideInArrangement(fCurrSide.Piece)
    else
    begin
      var links := fArrCollection.Links.Keys.ToArray;
//      if ASkipCount = 0 then
//        fSkipTargetCount := 0
//      else
        Inc(fSkipTargetCount, ASkipCount);
      skipCount := fSkipTargetCount mod length(links);
      found := FindUnmatchedSideInArrangement(links[0].Piece);
    end;
    if found then
    begin
      fCurrSide := foundSide;
      LoadNextCompatibleSide
    end
  finally
    alreadySearched.free
  end
end;

procedure TfraArrangeViewer.lstPiecesDblClick(Sender: TObject);
begin
  var item := lstPieces.ItemByIndex(lstPieces.ItemIndex);
  fCurrSide := TArrPiece(item.Data).Sides.First;
  LoadNextCompatibleSide;
  tabArrange.MakeActive;
end;

procedure TfraArrangeViewer.pbArrangePaint(Sender: TObject; Canvas: TCanvas);
begin
  Canvas.BeginScene;
  try
    Canvas.Clear(TAlphaColorRec.Null);
    if (fCurrSide <> nil) then
    begin
      var canvasBound1 := RectF(0, 0, pbArrange.Width-1, pbArrange.Height / 2-1);
      var canvasBound2 := RectF(0, pbArrange.Height / 2, pbArrange.Width-1, pbArrange.Height-1);

      var rotatedSide2 := TRotatedSide.Create(fCurrSide, 2);
      var maxMargin, maxMiddleWidth, maxHeight:single;

      if fMatchSide <> nil then
      begin
        var rotatedSide1 := TRotatedSide.Create(fMatchSide, 2);

        maxMargin := MaxValue([
          rotatedSide1.rotatedSide[0][0].X - rotatedSide1.rotatedPieceBoundary.Left
          , rotatedSide2.rotatedSide[0][0].X - rotatedSide2.rotatedPieceBoundary.Left
          , rotatedSide1.rotatedPieceBoundary.Right - rotatedSide1.rotatedSide[0][length(rotatedSide1.rotatedSide[0])-1].X
          , rotatedSide2.rotatedPieceBoundary.Right - rotatedSide2.rotatedSide[0][length(rotatedSide2.rotatedSide[0])-1].X
          ]);

        maxMiddleWidth := Max(
            rotatedSide1.rotatedSide[0][length(rotatedSide1.rotatedSide[0])-1].X - rotatedSide1.rotatedSide[0][0].X
            , rotatedSide2.rotatedSide[0][length(rotatedSide2.rotatedSide[0])-1].X - rotatedSide2.rotatedSide[0][0].X
          );

        maxHeight := Max(rotatedSide1.rotatedPieceBoundary.Height, rotatedSide2.rotatedPieceBoundary.Height);
      end
      else
      begin
        maxMargin := MaxValue([
          rotatedSide2.rotatedSide[0][0].X - rotatedSide2.rotatedPieceBoundary.Left
          , rotatedSide2.rotatedPieceBoundary.Right - rotatedSide2.rotatedSide[0][length(rotatedSide2.rotatedSide[0])-1].X
          ]);

        maxMiddleWidth := rotatedSide2.rotatedSide[0][length(rotatedSide2.rotatedSide[0])-1].X - rotatedSide2.rotatedSide[0][0].X;

        maxHeight := rotatedSide2.rotatedPieceBoundary.Height;
      end;

      var mergedBounds := RectF(
        0,
        0,
        maxMargin*2
        + maxMiddleWidth
        , maxHeight
        );

      var scale1, scale2, scale:single;
      var fit1 := mergedBounds.FitInto(canvasBound1, scale1);
      var fit2 := mergedBounds.FitInto(canvasBound2, scale2);

      scale := Min(1/scale1, 1/scale2);
//      var patchSet := TList<T

      var drawSide := procedure(ASide:TArrSide; canvasBound:TRectF; fitBounds:TRectF; rotatedSide:TRotatedSide; opacity:single)
        begin
          var bmpOrig := ASide.Collection.Scan.GetPieceBitmap(ASide.Piece.PieceIndex);
          var bmp := bmpOrig.Clone;
          var sv := canvas.SaveState;
          var oldMatrix := canvas.Matrix;
          try
            var bmpRect := RectF(0, 0, bmp.Width-1, bmp.Height-1);
            var pieceRect := RectF(0, 0, bmpRect.Width*scale-1, bmpRect.Height*scale-1);

            var centeredRect := pieceRect;
            var offset := PointF(0, 0);
            offset := PointF(canvasBound.Width / 2, 0);

            if rotatedSide.direction=0 then
              offset.y := canvasBound.Height;

            // set up transformation
            var newMatrix := oldMatrix;
            with ASide.SideCenter * scale do
              newMatrix := TMatrix.CreateTranslation(-X, -Y);
            newMatrix := newMatrix * TMatrix.CreateRotation(rotatedSide.rotationAngle);
            newMatrix := newMatrix * TMatrix.CreateTranslation(oldMatrix.M[2].X, oldMatrix.M[2].Y);
            newMatrix := newMatrix * TMatrix.CreateTranslation(canvasBound.Left + offset.X, canvasBound.Top + offset.y);
            canvas.SetMatrix(newMatrix);

            // draw bitmap
//            canvas.Stroke.Color := TAlphaColorRec.Green;
//            canvas.DrawRect(pieceRect, 1);
            canvas.DrawBitmap(bmp, bmpRect, pieceRect, opacity);
            var pieceText := format('%d',[ASide.Piece.PieceIndex]);
            if ASide.Piece.TopSideIndex > -1 then
              pieceText := Format('%s'#13#10'%d,%d',[pieceText, ASide.Piece.GridPos.x, ASide.Piece.GridPos.Y]);
            Canvas.FillText(pieceRect, pieceText, false, 1, [], TTextAlign.Center, TTextAlign.Center);

            // draw patches
            canvas.Stroke.Color := TAlphaColorRec.White;
            var APatches:TArray<TPatch>;
            if ASide.CreatePatches([0.1, 0.2, 0.3, 0.4, 0.5, 0.6, 0.7, 0.8, 0.9], 10, APatches) then
              for var pos := 0 to length(APatches)-1 do
                Canvas.DrawPolygon(APatches[Pos].perimeterPts.AsPointFs.Scale(scale).AsPolygon, 0.5);

            // draw side
//            Canvas.Draw(ASide.Item, scale);

            // draw outy
//            if ASide.IsOuty then
//              canvas.Stroke.Color := TAlphaColorRec.Aqua
//            else
//              canvas.Stroke.Color := TAlphaColorRec.Orange;
//            canvas.Draw([ASide.Item.First.toPointF * scale, ASide.HypPoint * scale, ASide.Item.Last.toPointF * scale]);

            // draw side center
//            canvas.Stroke.Color := TAlphaColorRec.Red;
//            Canvas.DrawEllipse((ASide.Center * scale).Inflate(5, 10), 1);
          finally
            bmp.Free;
            canvas.RestoreState(sv)
          end;
        end;

      drawSide(fCurrSide, canvasBound2, fit2, rotatedSide2, 1);
      lblScore.Text := 'n/a';

      if fMatchSide <> nil then
      begin
        var rotatedSide1 := TRotatedSide.Create(fMatchSide, 0);
        drawSide(fMatchSide, canvasBound1, fit1, rotatedSide1, 1);
        var scores:TArray<Single>;
        if fCurrSide.ScoreMatch(fMatchSide, [0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9], 10, scores) then
        try
//          lblScore.BeginUpdate;
          var score := format('[%d/%d] ',[fMatchSidesIndex, length(fMatchSides)-1]);
          for var i := 0 to Length(scores)-1 do
            score := format('%s %.2f',[score, scores[i]]);
          TLog.Instance.Log([leInfo],'score = %s',[score]);
          TThread.ForceQueue(nil,
          procedure
          begin
            lblScore.Text := score
          end)
        finally
//          lblScore.EndUpdate;
//          lblScore.Repaint
        end;
      end
      else
    end
  finally
    Canvas.EndScene
  end;
end;

procedure TfraArrangeViewer.Start(AScan: TScanCollection);
begin
  inherited;
  fraBitmapViewer.tckZoom.Value := 0.7;

  fArrCollection := TArrCollection.Create(AScan);
//  fLastArrBound := RectF(0, 0, 0, 0);
//  fArrBound := fLastArrBound;
  lstPieces.Clear;
  lstPieces.DefaultItemStyles.ItemStyle := 'lst2Style1';

  for var i := 0 to fArrCollection.Borders.Count-1 do
    with lstPieces.AddPiece(AScan, fArrCollection.Borders[i].PieceIndex, 80) do
    begin
      Data := fArrCollection.Borders[i];
      OnPaint := self.lbiCorner1Paint
    end;

  for var i := 0 to fArrCollection.Corners.Count-1 do
    with lstPieces.AddPiece(AScan, fArrCollection.Corners[i].PieceIndex, 80) do
    begin
      Data := fArrCollection.Corners[i];
      OnPaint := lbiCorner1Paint
    end;

  tabPieces.MakeActive
end;

end.
