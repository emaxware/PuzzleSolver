unit uScanPiece;

interface

uses
  System.Types
  , System.UITypes
  , System.Classes
  , System.Generics.Collections
  , System.JSON
  , FMX.Graphics
  , FMX.Surfaces
  , System.Math.Vectors
  , m3.DebugForm.fmx
  , cBitmapViewer
  ;

const
  PieceFillColor = TAlphaColorRec.Aqua;
  PieceDrawColor = TAlphaColorRec.Orange;
  OrigFillColor = TAlphaColorRec.Yellow;
  SearchedColor = TAlphaColorRec.Purple;

type
  TPoints = class(TList<TPoint>)
    function asPolygon:TPolygon;
    function length:extended;

    function TailRatio(ALength:Integer):Extended;
    function HeadRatio(ALength:Integer):Extended;

    function FindNextDifference(APoints:TPoints; var APointsIndex:Integer; AOffset:integer = 0):boolean;

    function HeadAngle(ALength:Integer):extended;
    function TailAngle(ALength:Integer):extended;

    procedure HeadAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
    procedure TailAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
  end;

  TSegmentOrientation = (soStraight, soLeft, soRight);

  TSegment = class(TPoints)
  private
    fOrient: TSegmentOrientation;
  public
    constructor Create(APoints:TPoints; AOrientation:TSegmentOrientation);

    property Orientation:TSegmentOrientation read fOrient;
  end;

  TSegments = class(TList<TSegment>)
  public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    function FindNextDifference(ASegments:TSegments; var ASegmentIndex:Integer; AOffset:integer = 0):boolean;
  end;

  TScanPiece = class
  private
    FPoints:TPoints;
    FWidth: Integer;
    FHeight: Integer;
    function GetSize: TSize;
    function GetAngle(AIndex: Integer): single;
  protected
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);

    procedure CalcDimensions;
  public
    constructor create;
    destructor Destroy; override;

    property Width:Integer read FWidth;
    property Height:Integer read FHeight;

//    property Size:TSize read GetSize;
    property Points:TPoints read FPoints;
  end;

  TScanCollection = class
  private
    FBrush:TStrokeBrush;
    FBitmap:TBitmap;
    FPieces: TDictionary<TPoint, TScanPiece>;
    fCachedBitmaps: TDictionary<TPoint, TBitmap>;
    fFilename: string;
    fMaxPieceWidth: integer;
    fMaxPieceHeight: integer;
    function GetPiece(AIndex: Integer): TScanPiece;
    function GetPieceOrigin(AIndex: Integer): TPoint;
    function GetPieceCount: integer;
  protected
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
//    procedure ResetBitmapData;
  public
    constructor create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadBitmap(const ABitmapfilename:string);
    procedure LoadFrom(const AJSONFilename:string);
    procedure SaveTo(const AJAONFilename:string);

    function GetPieceBitmap(APieceIndex:integer):TBitmap;
//    function DetectPiece(AStartPoint:TPoint; ASpan:integer; var AScanPiece:TScanPiece; var APieceOrigin:TPoint):boolean;
    function DetectPieces(var ABitmapResult:TBitmap):boolean;
    procedure AddPiece(AOrigin:TPoint; APiece:TScanPiece);

    property MaxPieceWidth:integer read fMaxPieceWidth;
    property MaxPieceHeight:integer read fMaxPieceHeight;
    property Bitmap:TBitmap read FBitmap;
    property PieceOrigin[AIndex:Integer]:TPoint read GetPieceOrigin;
    property Pieces[AIndex:Integer]:TScanPiece read GetPiece;
    property Filename:string read fFilename;
    property Count:integer read GetPieceCount;
  end;

  TfrmDebugHelper = class helper for TfrmDebug
    function _AddBitmap(ABitmap:TBitmap):TfraBitmapViewer;
  end;

implementation

uses
  System.SysUtils
  , System.Math
  , System.IOUtils
  , m3.json
  , m3.framehelper.fmx
  , uLib
  , m3.pointhelper
  ;

{ TScanPiece }

procedure TScanPiece.CalcDimensions;
begin
  var lowx := 0;
  var lowy := 0;
  var highx := 0;
  var highy := 0;

  for var pt in FPoints do
  begin
    if pt.X > highx then
      highx := pt.x;
    if pt.y > highY then
      highy := pt.y;
    if pt.x < lowx then
      lowx := pt.x;
    if pt.y < lowy then
      lowy := pt.y
  end;

  fWidth := highx - lowx + 1;
  fHeight := highy - lowy + 1
end;

constructor TScanPiece.create;
begin
  FPoints := TPoints.create
end;

const
  APathLimit = 2000;

destructor TScanPiece.destroy;
begin
  FPoints.Clear;
  FreeAndNil(FPoints);
  inherited;
end;

function TScanPiece.GetAngle(AIndex: Integer): single;
begin
  result := NormRad(NormRad(Points[AIndex].Angle(Points[AIndex+1]))+Pi*2-NormRad(Points[AIndex].Angle(Points[AIndex-1])));
end;

function TScanPiece.GetSize: TSize;
begin
  result := TSize.Create(FWidth, FHeight);
end;

function TScanPiece.GetJSON: TJSONObject;
var
  APoint:TPoint;
begin
  result := TJSONObject.create;
  Result
    .AddPair('width',FWidth)
    .AddPair('height',FHeight)
    .AddPair('points',TJSONArray.Create);
  for APoint in FPoints do
    with result.GetValue<TJSONArray>('points') do
      Add(APoint.asJSON)
end;

procedure TScanPiece.SetJSON(const Value: TJSONObject);
var
  i:integer;
begin
  FPoints.Clear;
  FWidth := Value.GetValue<Integer>('width');
  FHeight := Value.GetValue<Integer>('height');
  for i := 0 to Value.GetValue<TJSONArray>('points').Count-1 do
  with Value.GetValue<TJSONArray>('points').Items[i] as TJSONObject do
    FPoints.Add(Point(GetValue<Integer>('x'), GetValue<Integer>('y')));
end;

{ TScanCollection }

procedure TScanCollection.AddPiece(AOrigin: TPoint; APiece: TScanPiece);
begin
  if fMaxPieceWidth < APiece.Width then
    fMaxPieceWidth := APiece.Width;
  if fMaxPieceHeight < APiece.Height then
    fMaxPieceHeight := APiece.Height;
  FPieces.Add(AOrigin, APiece)
end;

procedure TScanCollection.Clear;
//var
//  APair:TPair<TPoint,TScanPiece>;
begin
  for var APair in FPieces.ToArray do
    APair.Value.Free;
  FPieces.Clear;
  for var APair in FCachedBitmaps.ToArray do
    APair.Value.Free;
  fCachedBitmaps.Clear;
  freeandnil(fBitmap);
  fBitmap := TBitmap.Create;
//  ResetBitmapData
end;

constructor TScanCollection.create;
begin
  inherited create;
  FPieces := TDictionary<TPoint,TScanPiece>.create;
  fCachedBitmaps := TDictionary<TPoint,TBitmap>.Create;
  fBitmap := TBitmap.Create;
  fBrush := TStrokeBrush.Create(TBrushKind.Solid, TAlphaColorRec.Green);
end;

destructor TScanCollection.destroy;
begin
  Clear;
  fPieces.free;
  fCachedBitmaps.free;
  freeandnil(fBitmap);
  FreeAndNil(fBrush);
  inherited;
end;

function TScanCollection.DetectPieces;
var
  data:TBitmapData;
  APerimeter,AFound:TList<TPoint>;
  AReserve:TStack<TPoint>;
  AFoundColor, ASearchedColor, APerimeterColor:TAlphaColor;
  ADeepest:Integer;

  function DetectPiece(AOrigin:TPoint; ADepth:integer):Boolean;
  begin
    if ADepth > ADeepest then
      ADeepest := ADepth;

    result :=
      (AOrigin.x >= 0)
      and (AOrigin.Y >= 0)
      and (AOrigin.X < data.Width)
      and (AOrigin.Y < data.Height);

    if not result then
      exit;

    var color := data.GetPixel(AOrigin.x, AOrigin.y);

    if (color = AFoundColor) or (color = APerimeterColor) then
    begin
      result := True;
      exit
    end;

    if color = ASearchedColor then
    begin
      result := false;
      exit
    end;

    var colorrec := TAlphaColorRec.Create(color);

    if colorrec.A = 0 then
      result := False
    else
    if ADepth > 1000 then
    begin
      AReserve.Push(AOrigin);
      result := true;
    end
    else
    begin
      result := true;

      data.SetPixel(AOrigin.X, AOrigin.Y, AFoundColor);

{$B+}
      if not (
//        DetectPiece(Point(AOrigin.X-1, AOrigin.y-1), ADepth+1) and
        DetectPiece(Point(AOrigin.X, AOrigin.y-1), ADepth+1)
//        and DetectPiece(Point(AOrigin.X+1, AOrigin.y-1), ADepth+1)
        and DetectPiece(Point(AOrigin.X+1, AOrigin.y), ADepth+1)
//        and DetectPiece(Point(AOrigin.X+1, AOrigin.y+1), ADepth+1)
        and DetectPiece(Point(AOrigin.X, AOrigin.y+1), ADepth+1)
//        and DetectPiece(Point(AOrigin.X-1, AOrigin.y+1), ADepth+1)
        and DetectPiece(Point(AOrigin.X-1, AOrigin.y), ADepth+1)
        )
      then
      begin
        APerimeter.Add(AOrigin);
        data.SetPixel(AOrigin.X, AOrigin.Y, APerimeterColor);
      end
      else
        AFound.Add(AOrigin);
{$B-}
      if (ADepth = 0) then
      begin
        while AReserve.Count > 0 do
          DetectPiece(AReserve.Pop, ADepth+1)
      end;
    end;
  end;

begin
  AFoundColor := PieceFillColor;
  ASearchedColor := SearchedColor;
  APerimeterColor := PieceDrawColor;
  ADeepest := 0;
  var AColorRec:TAlphaColorRec;
  APerimeter := TList<TPoint>.create;
  AFound := TList<TPoint>.create;
  AReserve := TStack<TPoint>.create;
  ABitmapResult := TBitmap.create(self.Bitmap.Width, self.Bitmap.Height);
  ABitmapResult.CopyFromBitmap(self.Bitmap);
  try
//    if self.Bitmap.Map(TMapAccess.ReadWrite, data) then
    if ABitmapResult.Map(TMapAccess.ReadWrite, data) then
    try
      for var y := 0 to data.Height-1 do
      begin
        for var x := 0 to data.Width-1 do
        begin
          var APoint := Point(x, y);
          var color := data.GetPixel(x, y);

          if color in [AFoundColor, ASearchedColor, APerimeterColor] then
            Continue;

          AColorRec := TAlphaColorRec.create(color);

          if AColorRec.A = 0 then
          begin
            data.SetPixel(X, Y, ASearchedColor)
          end
          else
          begin
            DetectPiece(Point(x, y), 0);

            if APerimeter.Count > 10 then
            begin
              var orig := APerimeter[0];
              for var i := 1 to APerimeter.Count-1 do
              begin
                if orig.X > APerimeter[i].x then
                  orig.x := APerimeter[i].x;
                if orig.y > APerimeter[i].y then
                  orig.y := APerimeter[i].y;
              end;

              for var i := 0 to APerimeter.Count-1 do
              begin
                var pt := APerimeter[i];
                pt.x := pt.X - orig.X;
                pt.y := pt.Y - orig.Y;
                APerimeter[i] := pt
              end;

              var scanPiece := TScanPiece.create;
              scanPiece.Points.Add(APerimeter[0]);

              APerimeter.Delete(0);
              while APerimeter.Count > 0 do
              begin
                var found := false;
                for var d := 2 to 3 do
                begin
                  for var i := 0 to APerimeter.Count-1 do
                  begin
                    if (abs(APerimeter[i].x-scanPiece.Points.Last.x) < d)
                        and (abs(APerimeter[i].y-scanPiece.Points.Last.y) < d)
    //                  or
    //                    (abs(APerimeter[i].x-scanPiece.Points.Last.x) = 0)
    //                    and (abs(APerimeter[i].y-scanPiece.Points.Last.y) < 2)
                    then
                    begin
                      found := true;
                      scanPiece.Points.Add(APerimeter[i]);
                      APerimeter.delete(i);
                      break
                    end
                  end;
                  if found then
                    break
                end;
                if not found then
                  break
              end;

              scanPiece.CalcDimensions;
              self.AddPiece(orig, scanPiece);
              result := true
            end;

            APerimeter.Clear;
            AFound.Clear;
            AReserve.Clear;
          end
        end;
      end
    finally
      ABitmapResult.Unmap(data);
    end;
  finally
    AReserve.free;
    APerimeter.Free;
    AFound.Free
  end
end;

function TScanCollection.GetJSON: TJSONObject;
var
  APair:TPair<TPoint,TScanPiece>;
begin
  result := TJSONObject.Create
    .AddPair('pieces',TJSONArray.Create)
    .AddPair('filename', ffilename);
  for APair in FPieces.ToArray do
  with Result.GetValue<TJSONArray>('pieces') do
  begin
    Add(TJSONObject.Create
      .AddPair('origin', APair.Key.asJSON)
      .AddPair('piece', APair.Value.getJSON))
  end;
end;

function TScanCollection.GetPiece(AIndex: Integer): TScanPiece;
begin
  result := FPieces.Values.ToArray[AIndex]
end;

function TScanCollection.GetPieceBitmap(APieceIndex: integer): TBitmap;
begin
  result := nil;
  var rslt:TBitmap := nil;
  with FPieces.ToArray[APieceIndex] do
  if fCachedBitmaps.TryGetValue(key, rslt) then
    result := rslt
  else
  try
    var mask := TBitmap.create(Value.Width, Value.Height);
    mask.Clear(TAlphaColorRec.black);
    var piece := TBitmap.Create(Value.Width, Value.Height);
    piece.Clear(TAlphaColorRec.white);
    var maskBrush := TBrush.Create(TBrushKind.Solid, TAlphaColorRec.White);
    try
      var rect := Rect(Key.X, Key.Y, Key.X + Value.Width, Key.Y + Value.Height);
      piece.CopyFromBitmap(Bitmap
        , rect
        , 0, 0);

//      TfrmDebug.Instance.AddBitmap(piece);
      var poly := Value.Points.asPolygon;

      with mask.Canvas do
      if BeginScene then
      try
        Stroke.Assign(maskBrush);
        FillPolygon(poly, 1);
      finally
        EndScene
      end;

//      TfrmDebug.Instance.AddBitmap(mask);

      result := TBitmap.CreateFromBitmapAndMask(piece, mask);
      fCachedBitmaps.Add(Key, result);

//      TfrmDebug.Instance.AddBitmap(result);
    finally
      maskBrush.Free;
      mask.free;
      piece.free
    end
  except
    result.free;
    raise
  end
end;

function TScanCollection.GetPieceCount: integer;
begin
  result := FPieces.Count
end;

function TScanCollection.GetPieceOrigin(AIndex: Integer): TPoint;
begin
  result := FPieces.Keys.ToArray[AIndex]
end;

procedure TScanCollection.LoadBitmap(const ABitmapfilename: string);
begin
  clear;
  fFilename := ABitmapFilename;
  fBitmap.LoadFromFile(fFilename);
end;

procedure TScanCollection.LoadFrom(const AJSONFilename: string);
begin
  var json := TJSONObject.ParseJSONValue(TFile.ReadAllText(AJSONFilename)) as TJSONObject;
  try
    SetJSON(json)
  finally
    json.free
  end;
end;

procedure TScanCollection.SaveTo(const AJAONFilename: string);
begin
  var json := GetJSON;
  try
    TFile.WriteAllText(AJAONFilename, json.ToJSON)
  finally
    json.Free
  end;
end;

procedure TScanCollection.SetJSON(const Value: TJSONObject);
var
  APiece:TScanPiece;
//  AJSON:TJSONObject;
  AOrigin:TPoint;
  i:integer;
begin
  Clear;
  fFilename := Value.GetValue<string>('filename');
  fMaxPieceWidth := 0;
  fMaxPieceHeight := 0;
  for i := 0 to Value.GetValue<TJSONArray>('pieces').Count-1 do
  with Value.GetValue<TJSONArray>('pieces').Items[i] as TJSONObject do
  begin
    APiece := TScanPiece.create;
    AOrigin := Point(GetValue<Integer>('origin.x'), GetValue<Integer>('origin.y'));
    APiece.setJSON(GetValue<TJSONObject>('piece'));
    AddPiece(
      AOrigin
      , APiece
      );
  end;
  LoadBitmap(fFilename)
end;

{ TPoints }

function TPoints.asPolygon: TPolygon;
begin
  SetLength(Result, Count);
  for var i := 0 to count-1 do
  with Items[i] do
  begin
    result[i].x := x;
    Result[i].Y := y
  end;
end;

//function TPoints.DegreesBetween(ABeginPt, AMidPt, AEndPt: Integer): extended;
//begin
//  result := items[AMidPt].DegreesBetween(Items[ABeginPt], Items[AEndPt])
//end;

function TPoints.FindNextDifference;
var
  ADiff:integer;
begin
  Result := false;
  for var i := AOffset to count-1 do
  begin
    if (i < APoints.Count) and (Items[i] = APoints[i]) then
      Continue;
    result := true;
    APointsIndex := i;
    break
  end;
end;

function TPoints.HeadAngle(ALength: Integer): extended;
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  HeadAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  result := AMidPt.DegreesBetween(AStartPt, AEndPt)
end;

procedure TPoints.HeadAnglePts(ALength: Integer; var AStartPt, AMidPt,
  AEndPt: TPoint);
begin
  ALength := Min(Count, ALength);

  if ALength < 3 then
    exit;
  AMidPt := Items[Count - (ALength div 2 + 1)];
  AStartPt := Items[Count - ALength];
  AEndPt := Items[Count-1]
end;

function TPoints.HeadRatio;
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  result := 0;
  ALength := Min(Count, ALength);

  if ALength < 3 then
    exit;
  HeadAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  for var i := Count - ALength + 1 to Count-1 do
    result := result + Items[i-1].Distance(Items[i]);
  result := AStartPt.Distance(AEndPt) / result
end;

function TPoints.length: extended;
begin
  result := 0;
  for var i := 1 to count-1 do
    result := result + Items[i-1].Distance(Items[i])
end;

function TPoints.TailAngle(ALength: Integer): extended;
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  result := 0;
  ALength := Min(Count, ALength);

  if ALength < 3 then
    exit;
  TailAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  result := AMidPt.DegreesBetween(AStartPt, AEndPt)
end;

procedure TPoints.TailAnglePts(ALength: Integer; var AStartPt, AMidPt,
  AEndPt: TPoint);
begin
  ALength := Min(Count, ALength);
  AMidPt := Items[ALength div 2 + 1];
  AStartPt := Items[0];
  AEndPt := Items[ALength-1]
end;

function TPoints.TailRatio;
var
  AStartPt, AMidPt, AEndPt:TPoint;
begin
  result := 0;
  ALength := Min(Count, ALength);

  if ALength < 3 then
    exit;

  TailAnglePts(ALength, AStartPt, AMidPt, AEndPt);
  for var i := 1 to ALength-1 do
    result := result + Items[i-1].Distance(Items[i]);
  result := AStartPt.Distance(AEndPt) / result
end;

{ TfrmDebugHelper }

function TfrmDebugHelper._AddBitmap(ABitmap: TBitmap): TfraBitmapViewer;
begin
  result := tbcImages.AddFrame<TfraBitmapViewer>('Bitmap');
  result.imgBitmap.Bitmap := ABitmap
end;

{ TSegments }

constructor TSegment.Create(APoints: TPoints;
  AOrientation: TSegmentOrientation);
begin
  inherited create;
  AddRange(APoints);
  fOrient := AOrientation
end;

{ TSegments }

procedure TSegments.Clear;
begin
  for var i := 0 to Count-1 do
    Items[i].free;

  inherited clear
end;

destructor TSegments.Destroy;
begin
  clear;
  inherited;
end;

function TSegments.FindNextDifference;
var
  ADiff:integer;
begin
  result := false;
  for var i := AOffset to count-1 do
  begin
    if (i < ASegments.Count) and (not Items[i].FindNextDifference(ASegments[i], ADiff)) then
      Continue;
    result := true;
    ASegmentIndex := i;
    break
  end;
end;

constructor TSegments.Create;
begin
  inherited create;
end;

end.
