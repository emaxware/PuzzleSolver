unit uScanPiece;

interface

uses
  System.Types
  , System.Classes
  , System.Generics.Collections
  , System.JSON
  , FMX.Graphics
  , FMX.Surfaces
  ;

type
  TScanPiece = class
  private
    FPoints:TList<TPoint>;
    FWidth: Integer;
    FHeight: Integer;
    function GetSize: TSize;
    function GetAngle(AIndex: Integer): single;
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  protected
  public
    constructor create;
    destructor destroy; override;

    class function Detect(ASource:TBitmapSurface; AStartPoint:TPoint; ASpan:integer; var AScanPiece:TScanPiece; var APieceOrigin:TPoint):boolean; overload;
    class function Detect(ASource:TBitmap; AStartPoint:TPoint; ASpan:integer; var AScanPiece:TScanPiece; var APieceOrigin:TPoint):boolean; overload;

    property asJSON:TJSONObject read GetJSON write SetJSON;
    property Angle[AIndex:Integer]:single read GetAngle;

    property Width:Integer read FWidth;
    property Height:Integer read FHeight;

    property Size:TSize read GetSize;
    property Points:TList<TPoint> read FPoints;
  end;

  TScanCollection = class
  private
    FBitmap:TBitmap;
    FPieces: TDictionary<TPoint, TScanPiece>;
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);
  public
    constructor create(ABitmap:TBitmap);
    destructor destroy; override;

    procedure Clear;

    function GetPieceBitmap(APieceIndex:integer):TBitmap;
    function DetectPiece(AStartPoint:TPoint; ASpan:integer; var AScanPiece:TScanPiece; var APieceOrigin:TPoint):boolean;

    property asJSON:TJSONObject read GetJSON write SetJSON;
    property Bitmap:TBitmap read FBitmap;
    property Pieces:TDictionary<TPoint,TScanPiece> read FPieces;
  end;

  TScanProfile = class
  public
    class function GenerateProfiles(ACollection:TScanCollection):TList<TScanProfile>; virtual;

    property Signature:TList<
    property Piece:TScanPiece read GetScanPiece;
    property Index:Integer read FIndex;
    property Origin:TPoint read GetOrigin;
  end;

implementation

uses
  System.UITypes
  , System.SysUtils
  , System.Math
  , uLib
  ;

{ TScanPiece }

constructor TScanPiece.create;
begin
  FPoints := TList<TPoint>.create
end;

const
  APathLimit = 2000;

class function TScanPiece.Detect(ASource: TBitmapSurface; AStartPoint: TPoint; ASpan:integer;
  var AScanPiece: TScanPiece; var APieceOrigin:TPoint): boolean;
var
  currPos, startPos:TPoint;
  currTest, lastTest:TPointF;
  pixelColor:TAlphaColorRec;
  Sin, cosine:double;
  bFound:boolean;
  lastAngle, i:integer;
  bitmapRect:TRectF;
  APieceSize:TPoint;
begin
  AScanPiece := TScanPiece.create;
  result := false;
  try
    bitmapRect := TRectF.Create(0, 0, ASource.Width-1, ASource.Height-1);
    currPos := AStartPoint;
    repeat
      startPos := currPos;
      currPos.Offset(-1,0);
      Assert(currPos.X >= 0);

      pixelColor := TAlphaColorRec.Create(ASource.Pixels[currPos.X, currPos.Y]);
    until pixelColor.A = 0;

    currPos := startPos;
    lastAngle := 0;
    result := False;
    APieceOrigin := startPos;
    APieceSize := startPos;

    repeat
      APieceOrigin.X := Min(APieceOrigin.X, currPos.X);
      APieceOrigin.Y := Min(APieceOrigin.Y, currPos.Y);

      APieceSize.X := Max(APieceSize.X, currPos.X);
      APieceSize.Y := Max(APieceSize.Y, currPos.Y);

      AScanPiece.Points.Add(currPos);
//      lastTestSpot := currPos.toPointF;
      currTest := currPos.toPointF;
      bFound := false;
      for I := 1 to 359 do
      begin
        lastTest := currTest;
        currTest := currPos.toPointF;
        SinCos((i + lastAngle) / 180 * Pi, Sin, cosine);
        currTest.Offset(ASpan * cosine, ASpan * -1.0 * Sin);
        if currTest.EqualsTo(lastTest) then
          continue;
        if not bitmapRect.Contains(currTest) then
          exit;
        with currTest.toPoint do
          pixelColor := TAlphaColorRec.Create(ASource.Pixels[X, Y]);
        if pixelColor.A = 0 then
        begin
//          inc(pathLength);
          currPos := lastTest.toPoint;
          lastAngle := (i + lastAngle + 315) mod 360;
//          currPos.DrawPoint(imgDetected.Bitmap.Canvas, 1);
//          currPos.DrawPoint(imgPiece.Bitmap.Canvas, 1);
//          currRect := TRectF.Create(testPos.toPointF, 2, 2);
////          currRect.Offset(-5,-5);
//          if imgDetected.Bitmap.Canvas.BeginScene then
//          try
//            imgDetected.Bitmap.Canvas.DrawEllipse(currRect, 1, brush);
//          finally
//            imgDetected.Bitmap.Canvas.EndScene
//          end;
//
//          if imgPiece.Bitmap.Canvas.BeginScene then
//          try
//            imgPiece.Bitmap.Canvas.DrawEllipse(currRect, 1, brush);
//          finally
//            imgPiece.Bitmap.Canvas.EndScene
//          end;
          bFound := true;
          break
        end;
      end;
      if not bFound then
      begin
        Abort;
      end;
//      application.ProcessMessages;
    until (startPos.Distance(currPos) < ASpan-1) or (AScanPiece.Points.count > APathLimit);
    result := AScanPiece.Points.count < APathLimit;
    if result then
    begin
      for i := 0 to AScanPiece.Points.Count - 1 do
        AScanPiece.Points[i] := AScanPiece.Points[i] - APieceOrigin;
      APieceSize := APieceSize - APieceOrigin;
      AScanPiece.FWidth := APieceSize.X+1;
      AScanPiece.FHeight := APieceSize.Y+1;
    end;
  finally
    if not result then
      AScanPiece.free
  end;
end;

destructor TScanPiece.destroy;
begin
  FPoints.Clear;
  FreeAndNil(FPoints);
  inherited;
end;

class function TScanPiece.Detect(ASource: TBitmap; AStartPoint: TPoint; ASpan:integer;
  var AScanPiece: TScanPiece; var APieceOrigin:TPoint): boolean;
var
  ABitmapSurface:TBitmapSurface;
begin
  ABitmapSurface := TBitmapSurface.Create;
  try
    ABitmapSurface.Assign(ASource);
    result := TScanPiece.Detect(ABitmapSurface, AStartPoint, ASpan, AScanPiece, APieceOrigin)
  finally
    ABitmapSurface.free
  end;
end;

function TScanPiece.GetAngle(AIndex: Integer): single;
begin
  result := NormRad(NormRad(Points[AIndex].Angle(Points[AIndex+1]))+Pi*2-NormRad(Points[AIndex].Angle(Points[AIndex-1])));
end;

function TScanPiece.GetJSON: TJSONObject;
var
  APoint:TPoint;
begin
  result := TJSONObject.create;
  Result
    .AddPair('width',TJSONNumber.Create(FWidth))
    .AddPair('height',TJSONNumber.Create(FHeight))
    .AddPair('points',TJSONArray.Create);
  for APoint in FPoints do
    with result.GetValue<TJSONArray>('points') do
      Add(APoint.asJSON)
end;

function TScanPiece.GetSize: TSize;
begin
  result := TSize.Create(FWidth, FHeight);
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

procedure TScanCollection.Clear;
var
  APair:TPair<TPoint,TScanPiece>;
begin
  for APair in FPieces.ToArray do
    APair.Value.Free;
  FPieces.Clear
end;

constructor TScanCollection.create(ABitmap: TBitmap);
begin
  FBitmap := ABitmap;
  FPieces := TDictionary<TPoint,TScanPiece>.create
end;

destructor TScanCollection.destroy;
begin
  Clear;
  FreeAndNil(FPieces);
  inherited;
end;

function TScanCollection.DetectPiece(AStartPoint: TPoint; ASpan:integer;
  var AScanPiece: TScanPiece; var APieceOrigin:TPoint): boolean;
begin
  result := TScanPiece.Detect(FBitmap, AStartPoint, ASpan, AScanPiece, APieceOrigin);

  if result then
    FPieces.Add(APieceOrigin,AScanPiece)
end;

function TScanCollection.GetJSON: TJSONObject;
var
  APair:TPair<TPoint,TScanPiece>;
begin
  result := TJSONObject.Create;
  result.AddPair('pieces',TJSONArray.Create);
  for APair in FPieces.ToArray do
  with Result.GetValue<TJSONArray>('pieces') do
  begin
    Add(TJSONObject.Create
      .AddPair('origin', APair.Key.asJSON)
      .AddPair('piece', APair.Value.asJSON))
  end;
end;

function TScanCollection.GetPieceBitmap(APieceIndex: integer): TBitmap;
begin
  with FPieces.ToArray[APieceIndex] do
  try
    result := TBitmap.Create(Value.Width, Value.Height);
    result.CopyFromBitmap(Bitmap, Rect(Key.X, Key.Y, Key.X + Value.Width - 1, Key.Y + Value.Height - 1), 0, 0);
  except
    result.Free;
    raise
  end
end;

procedure TScanCollection.SetJSON(const Value: TJSONObject);
var
  APiece:TScanPiece;
  AJSON:TJSONObject;
  AOrigin:TPoint;
  i:integer;
begin
  Clear;
  for i := 0 to Value.GetValue<TJSONArray>('pieces').Count-1 do
  with Value.GetValue<TJSONArray>('pieces').Items[i] as TJSONObject do
  begin
    APiece := TScanPiece.create;
    AOrigin := Point(GetValue<Integer>('origin.x'), GetValue<Integer>('origin.y'));
    APiece.asJSON := GetValue<TJSONObject>('piece');
    FPieces.Add(
      AOrigin
      , APiece
      );
  end;

end;

end.
