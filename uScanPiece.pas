unit uScanPiece;

interface

uses
  System.Types
  , System.SysUtils
  , System.UITypes
  , System.Classes
  , System.Generics.Collections
  , System.JSON
  , FMX.Graphics
  , FMX.Surfaces
  , FMX.ListBox
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
  TPoints = class;

//  TPointsHelper = class helper for TPoints
//  public
//    function TailRatio(ALength:Integer):Extended;
//    function HeadRatio(ALength:Integer):Extended;
//
//    function HeadAngle(ALength:Integer):extended;
//    function TailAngle(ALength:Integer):extended;
//
//    procedure HeadAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
//    procedure TailAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
//  end;

//  TSideDetector = class(TSegmentDetector)
//  public
//  end;
//
//  TSliceDetector = class(TSegmentDetector)
//  public
//  end;

  TPoints = class(TList<TPoint>)
  public
    function asPolygon:TPolygon;
    function Length:extended;
    function LengthRatio:Extended;

    procedure Unknot;

    function TailRatio(ALength:Integer):Extended;
    function HeadRatio(ALength:Integer):Extended;

    function CalcHeadAngle(ALength:Integer):extended;
    function CalcTailAngle(ALength:Integer):extended;

    procedure HeadAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
    procedure TailAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);

    function RotateByRadian(ARotation:Single; ARotationPoint:TPointF; var ABoundingRect:TRectF; AScale:Single = 1):TArray<TPointF>;
  end;

  TSegment = class(TPoints)
  protected
    fHeadSize:integer;
  public
    constructor Create(AHeadSize:Integer);

    function TailRatio:Extended; overload;
    function HeadRatio:Extended; overload;

    function CalcHeadAngle:extended; overload;
    function CalcTailAngle:extended; overload;
  end;

  TSegments<T:TSegment> = class(TList<T>)
  public
    destructor Destroy; override;

    procedure Clear;

//    function FindNextDifference(ASegments:TSegments; var ASegmentIndex:Integer; AOffset:integer = 0):boolean;
  end;

  TScanPiece = class;

  TSegmentOrientation = (soUnknown,soStraight, soLeft, soRight);

  TSlice = class(TSegment)
  protected
    fOrient: TSegmentOrientation;
  public
//    constructor Create(AHeadsize:integer);//APoints:TPoints; AOrientation:TSegmentOrientation);

    procedure Clear;

    property Orientation:TSegmentOrientation read fOrient;
  end;

  TSide = class(TSegment)
  protected
    fSlices: TSegments<TSlice>;
    fHeadAngle, fTailAngle: single;
    procedure SetSlices(const Value: TSegments<TSlice>);
  public
    type
      TSideTraceLevel = (stlPreview, stlByPoint, stlBySegment);

      TOnTraceSide = reference to procedure(
        ATraceLevel:TSideTraceLevel
        ; ASegment:TSlice
        ; ASlice:TSlice
        ; ASlices:TSegments<TSlice>
        );

//    constructor Create(AHeadsize:integer);//APoints:TPoints; AOrientation:TSegmentOrientation);

    function DetectSlices(AHeadsize:integer; AStraightRatio:Single; AOnTrace:TOnTraceSide = nil; bReverse:Boolean = false; AOffset:Integer = 0):TSegments<TSlice>;
    destructor Destroy; override;

    property Slices:TSegments<TSlice> read fSlices write SetSlices;
    property HeadAngle:single read fHeadAngle;
    property TailAngle:single read fTailAngle;
  end;

  TScanPiece = class
  protected
    FPoints:TPoints;
    FWidth: Integer;
    FHeight: Integer;
//    FSlices: TSegments;
    FSides: TSegments<TSide>;
//    FCenter:TPointF;
    function GetSize: TSize;
    function GetAngle(AIndex: Integer): single;
    procedure SetSides(const Value: TSegments<TSide>);
    function GetJSON: TJSONObject;
    procedure SetJSON(const Value: TJSONObject);

    procedure _CalcDimensions;
  public
    type
      TTraceLevel = (tlManual, tlPreview, tlByError, tlByErrorFixed, tlByPoint, tlBySegment);

      TOnTrace = reference to procedure(
        ATraceLevel:TTraceLevel
        ; ASegment:TSegment
        ; ASide:TSide
        ; ASegements:TSegments<TSide>
        );

      TOnManual = reference to function(
        var newoffset:integer
        ):Boolean;

    constructor create;
    destructor Destroy; override;

//    class function DetectSlices(ASegment:TSegment; AHeadsize:integer; AStraightRatio:Single; AOnTrace:TOnTrace = nil; bReverse:Boolean = false; AOffset:Integer = 0):TSegments;
    function DetectSides(AHeadsize:integer; AStraightRatio, AMaxAngle:Single; AOnTrace:TOnTrace = nil; AOnManual:TOnManual = nil; bManualMode:Boolean = false):TSegments<TSide>;

    property Width:Integer read FWidth;
    property Height:Integer read FHeight;
    property Points:TPoints read FPoints;
    property Sides:TSegments<TSide> read FSides write SetSides;
//    property Center:TPointF read fCenter;
  end;

  TScanCollection = class;
  TArrCollection = class;
  TArrPiece = class;
  TArrSide = class;

  TArr<T> = class(TList<T>)
  protected
    fItem:T;
    fCollection:TArrCollection;
  public
    constructor Create(ACollection:TArrCollection; AItem:T);

    property Item:T read fItem;
    property Collection:TArrCollection read fCollection;
  end;

  TArrLink = class
  private
    fSide2: TArrSide;
    fSide1: TArrSide;
  public
    constructor Create(ASide1, ASide2:TArrSide);

    function OtherSide(ASide:TArrSide):TArrSide;
    property Side1:TArrSide read fSide1;
    property Side2:TArrSide read fSide2;
  end;

  TArrSide = class(TArr<TSide>)
  private
    fArrSideIndex: integer;
  protected
    fIsAfterBorder: Boolean;
    fSideIndex: integer;
    fLink: TArrLink;
    fIsOuty: boolean;
    fIsBeforeBorder: Boolean;
    fPiece: TArrPiece;
    fAngle: single;

    fHypPointChecked:Boolean;

    fLeadingHypLength: single;
    fTrailingHypLength: single;
    fHypPointIndex: integer;
//    fCornersCenter: TPointF;
    fCenter:TPointF;
    function GetCenter: TPointF;
    function GetAngle: single;
    function GetIsOuty: boolean;
    function GetHypPointIndex: integer;
    function GetLeadingHypLength: single;
    function GetTrailingHypLength: single;
//    function GetCornersCenter: TPointF;
    function GetHypPoint: TPointF;
    procedure CheckHypPoint; virtual;
  public
    constructor Create(ACollection:TArrCollection; APiece:TArrPiece; ASideIndex:integer; AItem:TSide);

    function ScoreMatch(ASide:TArrSide; out AScore:Single):boolean;
    function AddLink(ASide:TArrSide):TArrLink;

    property Piece:TArrPiece read fPiece;
    property IsAfterBorder:Boolean read fIsAfterBorder;
    property IsBeforeBorder:Boolean read fIsBeforeBorder;
    property Link:TArrLink read fLink;
//    property SideIndex:integer read fSideIndex;
    property ArrSideIndex:integer read fArrSideIndex;
//    property CornersCenter:TPointF read GetCornersCenter;

    property Center:TPointF read GetCenter;
    property Angle:single read GetAngle;
    property IsOuty:boolean read GetIsOuty;
    property HypPoint:TPointF read GetHypPoint;
    property HypPointIndex:integer read GetHypPointIndex;
    property LeadingHypLength:single read GetLeadingHypLength;
    property TrialingHypLength:single read GetTrailingHypLength;
  end;

  TArrPiece = class(TArr<TScanPiece>)
  protected
    fIsCorner: boolean;
    fSides: TList<TArrSide>;
    fIsBorder: boolean;
    fPieceIndex: integer;
  public
    constructor Create(ACollection:TArrCollection; APieceIndex:integer; AItem:TScanPiece);
    destructor Destroy; override;

    function SidesLinked:integer;
    property IsCorner:boolean read fIsCorner;
    property IsBorder:boolean read fIsBorder;
    property Sides:TList<TArrSide> read fSides;
    property PieceIndex:integer read fPieceIndex;
  end;

  TArrCollection = class
  protected
    fLinks: TDictionary<TArrSide, TArrLink>;
    fSides: TList<TArrSide>;
    fPieces: TList<TArrPiece>;
    fAllPieces: TList<TArrPiece>;
    fScan:TScanCollection;
    fCorners: TList<TArrPiece>;
    fBorders: TList<TArrPiece>;
  public
    constructor Create(ACollection:TScanCollection);
    destructor Destroy; override;

    property Scan:TScanCollection read fScan;
    property AllPieces:TList<TArrPiece> read fAllPieces;
    property Pieces:TList<TArrPiece> read fPieces;
    property Sides:TList<TArrSide> read fSides;
    property Corners:TList<TArrPiece> read fCorners;
    property Borders:TList<TArrPiece> read fBorders;
    property Links:TDictionary<TArrSide,TArrLink> read fLinks;
  end;

  TScanCollection = class
  protected
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

  TRotatedSide = record
  public
    direction:byte;
    rotatedPieceBoundary:TRectF;
    rotationAngle
//      , leftMargin, rightMargin, CenterWidth
      :single;
    rotatedSide:array[0..3] of TArray<TPointF>;
    rotatedCenter:array[0..3] of TPointF;
    rotatedPiece:TArray<TPointF>;
    const DirectionAngles:array[0..3] of Single = (
      0,   //down
      -90, //left
      180, //top
      90   //right
      );

//    var
    constructor Create(ASide:TArrSide; ATargetAngle:Single; AScale:Single = 1); overload;
    constructor Create(ASide:TArrSide; ADirection:byte; AScale:Single = 1); overload;
  end;

  TfrmDebugHelper = class helper for TfrmDebug
    function _AddBitmap(ABitmap:TBitmap):TfraBitmapViewer;
  end;

  TCanvasHelper = class helper for TCanvas
  public
    procedure DrawTail(ASegment:TPoints; ALength:Integer; AColor:TAlphaColor); overload;
    procedure DrawHead(ASegment:TPoints; ALength:Integer; AColor:TAlphaColor); overload;
    procedure Draw(ASegment:TPoints; AColor:TAlphaColor; AScale:Single); overload;

    procedure DrawTail(ASegment:TPoints; ALength:Integer); overload;
    procedure DrawHead(ASegment:TPoints; ALength:Integer); overload;
    procedure Draw(ASegment:TSegment; AScale:Single = 1; AColor:TAlphaColor = 0); overload;

    procedure Draw(const APointFs:array of TPointF; AScale:Single = 1; AColor:TAlphaColor = 0); overload;

//    procedure Draw(
  end;

  TListBoxHelper = class helper for TListBox
  public
    function AddPiece(ACollection:TScanCollection; APieceIndex:Integer; ASize:integer):TListBoxItem;
  end;

implementation

uses
  System.Math
  , System.IOUtils
  , m3.json
  , m3.framehelper.fmx
  , uLib
  , m3.pointhelper
  ;

{ TScanPiece }

procedure TScanPiece._CalcDimensions;
begin
  var lowx := 0;
  var lowy := 0;
  var highx := 0;
  var highy := 0;
//  fCenter := PointF(0, 0);

  for var pt in FPoints do
  begin
//    FCenter := fCenter + pt.toPointF;
    if pt.X > highx then
      highx := pt.x;
    if pt.y > highY then
      highy := pt.y;
    if pt.x < lowx then
      lowx := pt.x;
    if pt.y < lowy then
      lowy := pt.y
  end;

//  FCenter := fCenter / FPoints.Count;

  fWidth := highx - lowx + 1;
  fHeight := highy - lowy + 1;

//  if (lowx > 0) or (lowy > 0) then
//  asm
//    Int 03
//  end;

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

function TSide.DetectSlices;
begin
  var ptIndex := AOffset;
  result := TSegments<TSlice>.create;
    var head := TSlice.Create(AHeadsize);
    var slice := TSlice.Create(AHeadsize);

    repeat
      var offset := ptIndex mod Count;
      var ptCurr := Items[offset];
      if ((Result.Count > 0) or (slice.Count > 0)) and (offset = 0) then
      begin
        if head.Count > 0 then
          slice.AddRange(head);
        result.Add(slice);
        head.Clear;
        break
      end
      else
      begin
        head.Add(ptCurr);

        if bReverse then
          ptIndex := (ptIndex + Count-1) mod Count
        else
          ptIndex := (ptIndex + 1) mod Count;

        if head.Count < AHeadsize then
          continue;
      end;

//      prevIndex := ptIndex;

      if (head.HeadRatio > AStraightRatio) then
        head.fOrient := soStraight
      else
      if (head.CalcTailAngle < 0) then
        head.fOrient := TSegmentOrientation.soLeft
      else
        head.fOrient := TSegmentOrientation.soRight;

      if slice.Count = 0 then
      begin
        slice.AddRange(head);
        slice.fOrient := head.fOrient;
        head.Clear;
        continue
      end;

      if Assigned(AOnTrace) then
        AOnTrace(stlByPoint, head, slice, result);

      case head.fOrient of
        soStraight:
          if slice.fOrient in [soUnknown, soStraight] then
          begin
            slice.fOrient := TSegmentOrientation.soStraight;
            slice.Add(head[0]);
            head.Delete(0);
            continue
          end;

        soLeft:
          if slice.fOrient in [soUnknown, soLeft] then
          begin
            slice.fOrient := TSegmentOrientation.soLeft;
            slice.Add(head[0]);
            head.Delete(0);
            continue
          end;

        soRight:
          if slice.fOrient in [soUnknown, soRight] then
          begin
            slice.fOrient := TSegmentOrientation.soRight;
            slice.Add(head[0]);
            head.Delete(0);
            continue
          end;
      end;

      if Assigned(AOnTrace) then
        AOnTrace(stlBySegment, head, slice, result);

      for var i := 0 to head.Count-2 do
      begin
        slice.Add(head[0]);
        head.Delete(0);
      end;

      result.Add(slice);
      slice := TSlice.Create(AHeadsize);

//      if Assigned(AOnTrace) then
//        AOnTrace(stlBySegment, head, slice, result);
    until ptIndex > Count;

    if Assigned(AOnTrace) then
      AOnTrace(stlBySegment, head, slice, result);

    head.Free
//  end
end;

function TScanPiece.DetectSides;
begin
  var ptInc := 1;
  var ptIndex := 0;
  result := TSegments<TSide>.create;
  var skipSegmentCount := 2;
  var head := TSegment.Create(AHeadsize);
  var side := TSide.Create(AHeadsize);
//  var prevIndex := -1;
//  var firstIndex := ptIndex;

  try
//    var fPoints := TPoints.Create;
//    fPoints.AddRange(Points);
    side.AddRange(Points);

    if not bManualMode and Assigned(AOnTrace) then
      AOnTrace(tlPreview, head, side, result);

    side.Clear;
    ptIndex := 0;
    var lastManualIndex := 0;
    var manualOffsetLeft := 0;

    repeat
      var offset := ptIndex mod fPoints.Count;
      var newside := false;

      var ptCurr := fPoints[offset];
      if (result.Count > 0)
        and (ptCurr = result[0][0])
      then
      begin
        side.AddRange(head);
        var angle := result[0][0].DegreesBetween(side[side.Count-AHeadsize], result[0][AHeadsize-1]);
        side.fHeadAngle := angle;
        Result[0].fTailAngle := angle * -1;
        result.Add(side);
        break
      end
      else
      begin
        head.Add(ptCurr);

        if bManualMode and Assigned(AOnManual) then
        begin
          if manualOffsetLeft > 0 then
            dec(manualOffsetLeft)
          else
          begin
            var newoffset := ptIndex;
            AOnTrace(tlManual, head, side, result);
            if AOnManual(newoffset) then
            begin
              newside := true;
              lastManualIndex := ptIndex;
              manualOffsetLeft := 0
            end
            else
            begin
              if newoffset < ptIndex then
              begin
                head.Clear;
                side.Clear;
                ptIndex := lastManualIndex;
                manualOffsetLeft := abs(newoffset - lastManualIndex) mod fPoints.count;
              end
              else
                manualOffsetLeft := abs(newoffset - ptIndex) mod fPoints.count;
            end
          end;
        end
        else
        // knot detector
        if (head.Count > 4) then
        begin
//          repeat
            var rat := head.HeadRatio(5);
            if (rat > 0) and (rat < 0.6) then
            begin
              if Assigned(AOnTrace) then
                AOnTrace(tlByError, head, side, result);
              var tempHead := TPoints.create;
              try
                for var i := 1 to 5 do
                begin
                  tempHead.insert(0, head[head.Count-1]);
                  head.Delete(head.Count-1);
                end;

                tempHead.Unknot;
                head.AddRange(tempHead)
              finally
                tempHead.free
              end;
              if Assigned(AOnTrace) then
                AOnTrace(tlByErrorFixed, head, side, result)
            end
//            else
//              break
//          until false;
        end;

        ptIndex := (ptIndex + ptInc + fPoints.Count) mod fPoints.Count;

        if head.Count < AHeadsize then
          continue;
      end;

      if side.Count = 0 then
      begin
        side.AddRange(head);
        head.Clear;
        continue
      end;

      var angle := head[0].DegreesBetween(side[0], head.Last);

      if Assigned(AOnTrace) then
        AOnTrace(tlByPoint, head, side, result);

      if
        (
        bManualMode
        and Assigned(AOnManual)
        ) then
      begin
        if not newside then
        begin
          side.Add(head[0]);
          head.Delete(0);
          continue
        end
      end
      else
      if not (
        (head.HeadRatio > AStraightRatio)
        and (side.HeadRatio > AStraightRatio)
        and (abs(angle) > (90 - AMaxAngle))
        and (Abs(angle) < (90 + AMaxAngle))
        )
      then
      begin
        side.Add(head[0]);
        head.Delete(0);
        continue
      end;

      if skipSegmentCount > 0 then
      begin
        if angle < 0 then
        begin
          ptInc := -1;
          result.Clear;
          head.clear;
          side.Clear;
          continue
        end;
        Dec(skipSegmentCount);
        side.clear;
        head.Delete(0)
      end
      else
      begin
        if Assigned(AOnTrace) then
          AOnTrace(tlBySegment, head, side, result);
//        for var i := 0 to head.Count-2 do
//        begin
//          side.Add(head[0]);
//          head.Delete(0);
//        end;
        side.fHeadAngle := angle;
        result.Add(side);
        side := TSide.Create(AHeadsize);
        side.AddRange(head);
        side.fTailAngle := angle * -1;
        head.Clear;
        if Assigned(AOnTrace) then
          AOnTrace(tlBySegment, head, result.Last, result);
      end;
    until ptIndex > fPoints.Count*2;
  finally
    head.Free;
//    FPoints.free
  end
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

procedure TScanPiece.SetSides(const Value: TSegments<TSide>);
begin
  freeandnil(fSides);
  FSides := Value
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
                for var d := 1 to 3 do
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

              scanPiece._CalcDimensions;
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

//function TPoints.FindNextDifference;
//var
//  ADiff:integer;
//begin
//  Result := false;
//  for var i := AOffset to count-1 do
//  begin
//    if (i < APoints.Count) and (Items[i] = APoints[i]) then
//      Continue;
//    result := true;
//    APointsIndex := i;
//    break
//  end;
//end;

function TPoints.CalcHeadAngle(ALength: Integer): extended;
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

function TPoints.LengthRatio: Extended;
begin
  result := First.Distance(Last) / length
end;

function TPoints.RotateByRadian(ARotation: Single;
  ARotationPoint: TPointF; var ABoundingRect:TRectF; AScale:Single = 1): TArray<TPointF>;
begin
  var rslt := TList<TPointF>.create;
  for var i := 0 to count-1 do
  begin
    var pt := Items[i].toPointF.RotateByRadian(ARotation, ARotationPoint, AScale);// (Items[i].toPointF - ARotationPoint).Rotate(ARotation) + ARotationPoint;
    if i=0 then
      ABoundingRect := RectF(pt.X, pt.Y, pt.X, pt.Y)
    else
    begin
      if pt.X < ABoundingRect.Left then
        ABoundingRect.Left := pt.X;
      if pt.X > ABoundingRect.Right then
        ABoundingRect.Right := pt.x;
      if pt.Y < ABoundingRect.Top then
        ABoundingRect.Top := pt.Y;
      if pt.Y > ABoundingRect.Bottom then
        ABoundingRect.Bottom := pt.y
    end;
    rslt.Add(pt);
  end;
  result := rslt.ToArray;
  rslt.free
end;

procedure TPoints.UnKnot;
var
  ptTarget:TPointF;
  ptClosest:TPoint;
  ptBucket, ptResult:TPoints;
  beginOffset, endOffset:integer;
  dist, closest:single;
  closestIndex:integer;
begin
  try
    ptBucket := TPoints.Create;
    ptResult := TPoints.Create;
    ptResult.Add(First);
    ptResult.Add(Last);
    for var i := 1 to Count-2 do
      ptBucket.Add(Items[i]);

    beginOffset := 0;
    endOffset := 0;

    while ptBucket.Count > 0 do
    begin
      if beginOffset = endOffset then
        ptTarget := ptResult[beginOffset].toPointF
      else
        ptTarget := ptResult[ptResult.Count-1-endoffset].toPointF;

      for var i := 0 to ptBucket.Count-1 do
      begin
        var pt := ptBucket[i];
        dist := ptTarget.Distance(pt.toPointf);
        if (i = 0) or (dist < closest) then
        begin
          ptClosest := pt;
          closest := dist;
          closestIndex := i
        end;
      end;

      if beginOffset = endOffset then
      begin
        inc(beginOffset);
        ptBucket.Delete(closestIndex);
        ptResult.Insert(beginOffset, ptClosest);
      end
      else
      begin
        inc(endOffset);
        ptBucket.Delete(closestIndex);
        ptResult.Insert(ptResult.Count-endOffset, ptClosest);
      end;
    end;

    var first := ptResult[0];

    for var i := 1 to Count-2 do
      Items[i] := ptResult[i]
  finally
    ptBucket.Free;
    ptResult.free
  end;
end;

function TPoints.CalcTailAngle(ALength: Integer): extended;
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

{ TSegment }

//procedure TSlice.Clear;
//begin
//  inherited clear;
//  fOrient := TSegmentOrientation.soUnknown
//end;

//constructor TSegment.Create(AHeadsize:Integer; APoints: TPoints;
//  AOrientation: TSegmentOrientation);
//begin
//  inherited create;
//  fHeadSize := AHeadsize;
//  AddRange(APoints);
//  fOrient := AOrientation
//end;

constructor TSegment.Create(AHeadSize: Integer);
begin
  inherited create;
  fHeadSize := AHeadsize
end;

function TSegment.CalcHeadAngle: extended;
begin
  result := inherited CalcHeadAngle(fHeadSize)
end;

function TSegment.HeadRatio: Extended;
begin
  result := inherited HeadRatio(fHeadSize)
end;

function TSegment.CalcTailAngle: extended;
begin
  result := inherited CalcTailAngle(fHeadSize)
end;

function TSegment.TailRatio: Extended;
begin
  result := inherited TailRatio(fHeadSize)
end;

//constructor TSegment.CreateBlank(AHeadsize:Integer);
//begin
//  inherited Create;
//  fHeadSize := AHeadsize;
//  fOrient := TSegmentOrientation.soUnknown
//end;

{ TSegments }

//procedure TSegments.Clear;
//begin
//  for var i := 0 to Count-1 do
//    Items[i].free;
//
//  inherited clear
//end;
//
//destructor TSegments.Destroy;
//begin
//  clear;
//  inherited;
//end;
//
//function TSegments.FindNextDifference;
//var
//  ADiff:integer;
//begin
//  result := false;
//  for var i := AOffset to count-1 do
//  begin
//    if (i < ASegments.Count) and (not Items[i].FindNextDifference(ASegments[i], ADiff)) then
//      Continue;
//    result := true;
//    ASegmentIndex := i;
//    break
//  end;
//end;
//
//constructor TSegments.Create;
//begin
//  inherited create;
//end;

{ TSegments<T> }

procedure TSegments<T>.Clear;
begin
  for var i := 0 to count-1 do
    Items[i].free;
  inherited clear
end;

destructor TSegments<T>.Destroy;
begin
  clear;
  inherited;
end;

{ TCanvasHelper }

procedure TCanvasHelper.Draw(ASegment: TPoints; AColor: TAlphaColor; AScale:Single);
begin
  if (ASegment = nil) or (ASegment.Count < 2) then
    exit;

  self.Stroke.Color := AColor;
  for var i := 0 to ASegment.Count-1 do
  begin
    DrawEllipse(
      (ASegment[i].toPointF * AScale)
      .toRectF(AScale, AScale), 1);
  end;
end;

procedure TCanvasHelper.Draw(const APointFs: array of TPointF; AScale: Single;
  AColor: TAlphaColor);
begin
  var ASaveColor := Stroke.Color;
  if AColor <> 0 then
    Stroke.Color := TAlphaColorRec.Aqua;
  for var i := 1 to Length(APointFs)-1 do
    DrawLine(APointFs[i-1] * AScale, APointFs[i] * AScale, 1);
  if AColor <> 0 then
    Stroke.Color := ASaveColor
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

procedure TCanvasHelper.Draw(ASegment:TSegment; AScale:Single; AColor:TAlphaColor);
begin
  if (ASegment = nil) or (ASegment.Count < 2) then
    Exit;
  if AColor <> 0 then
  begin
    Draw(ASegment, AColor, AScale);
    Stroke.Color := TAlphaColorRec.Aqua;
    DrawEllipse((ASegment.First.toPointF * AScale).toRectF(AScale*2, AScale*2), 1)
  end
  else
  if ASegment is TSide then
  begin
    Draw(ASegment, TAlphaColorRec.Hotpink, AScale);
    Stroke.Color := TAlphaColorRec.Aqua;
    DrawEllipse((ASegment.First.toPointF * AScale).toRectF(AScale*2, AScale*2), 1)
  end
  else
  if ASegment is TSlice then
  with ASegment as TSlice do
    case Orientation of
      soStraight:
        Draw(ASegment, TAlphaColorRec.Yellow, AScale);
      soLeft:
        Draw(ASegment, TAlphaColorRec.Blue, AScale);
      soRight:
        Draw(ASegment, TAlphaColorRec.Aqua, AScale);
      else
        Draw(ASegment, TAlphaColorRec.Purple, AScale);

      Stroke.Color := TAlphaColorRec.Aqua;
      DrawEllipse((ASegment.Last.toPointF * AScale).toRectF(AScale*2, AScale*2), 1)
    end
  else
  begin
    Draw(ASegment, TAlphaColorRec.White, AScale);
    Stroke.Color := TAlphaColorRec.Aqua;
    DrawEllipse((ASegment.First.toPointF * AScale).toRectF(AScale*2, AScale*2), 1)
  end;
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

{ TSide }

destructor TSide.Destroy;
begin
  FreeAndNil(fSlices);
  inherited;
end;

procedure TSide.SetSlices(const Value: TSegments<TSlice>);
begin
  FreeAndNil(fSlices);
  fSlices := Value
end;

{ TSlice }

procedure TSlice.Clear;
begin

end;

{ TArr<T> }

constructor TArr<T>.Create(ACollection: TArrCollection; AItem: T);
begin
  inherited create;
  fCollection := ACollection;
  fItem := AItem
end;

{ TArrSide }

function TArrSide.AddLink(ASide: TArrSide): TArrLink;
begin
  TArrLink.Create(Self, ASide)
end;

procedure TArrSide.CheckHypPoint;
begin
  if not fHypPointChecked then
  begin
    fAngle := Item.First.Angle(Item.Last);
    var innyDistance := 0.0;
    var innyIndex := 0;
    var outyDistance := 0.0;
    var outyIndex := 0;
    var firstPt := fItem.First.toPointF;
    var lastPt := fItem.Last.toPointF;
    fCenter := PointF((firstPt.X+lastPt.X)/2,(firstPt.Y+lastPt.Y)/2);
    for var i := 1 to fItem.Count-2 do
    begin
      var distFromSide := fItem[i].toPointF.distFromLine(fItem.First, fItem.Last);
      var angleFromSide := fItem.First.DegreesBetween(fItem.Last, fItem[i]);
      if angleFromSide > 0 then
      begin
        if distFromSide > outyDistance then
        begin
          outyIndex := i;
          outyDistance := distFromSide
        end;
      end
      else
      begin
        if distFromSide > innyDistance then
        begin
          innyIndex := i;
          innyDistance := distFromSide
        end;
      end;
    end;
    if innyDistance > outyDistance then
    begin
      fIsOuty := false;
      fHypPointIndex := innyIndex;
    end
    else
    begin
      fIsOuty := true;
      fHypPointIndex := outyIndex;
    end;
    fLeadingHypLength := fItem.First.Distance(fItem[fHypPointIndex]);
    fTrailingHypLength := fItem.Last.Distance(fItem[fHypPointIndex]);
    fHypPointChecked := true
  end;
end;

constructor TArrSide.Create(ACollection: TArrCollection; APiece: TArrPiece;
  ASideIndex: integer; AItem: TSide);
begin
  inherited Create(ACollection, AItem);
  fPiece := APiece;
  fSideIndex := ASideIndex;
end;

function TArrSide.GetAngle: single;
begin
  CheckHypPoint;
  result := fAngle;
end;

function TArrSide.GetCenter: TPointF;
begin
  CheckHypPoint;
  result := fCenter
end;

function TArrSide.GetHypPoint: TPointF;
begin
  CheckHypPoint;
  result := Item.Items[fHypPointIndex]
end;

function TArrSide.GetHypPointIndex: integer;
begin
  CheckHypPoint;
  result := fHypPointIndex
end;

function TArrSide.GetIsOuty: boolean;
begin
  CheckHypPoint;
  result := fIsOuty
end;

function TArrSide.GetLeadingHypLength: single;
begin
  CheckHypPoint;
  result := fLeadingHypLength
end;

function TArrSide.GetTrailingHypLength: single;
begin
  CheckHypPoint;
  result := fTrailingHypLength
end;

function TArrSide.ScoreMatch(ASide: TArrSide; out AScore: Single): boolean;
begin
  result := false;
  AScore := 0.5;
  while AScore > 0 do
  begin
    if Piece.PieceIndex = ASide.Piece.PieceIndex then
    begin
      AScore := 0;
      break
    end;

    if Piece.IsCorner and ASide.Piece.IsCorner then
    begin
      AScore := 0;
      break
    end;

    if (IsAfterBorder or IsBeforeBorder) //and (ASide.IsAfterBorder or ASide.IsBeforeBorder)
    then
    begin
      if (ASide.IsBeforeBorder = IsAfterBorder) and (ASide.IsAfterBorder = IsBeforeBorder) then
      begin
//        CheckHypPoint;
//        ASide.CheckHypPoint;
        if (ASide.IsOuty <> IsOuty) then
        begin
          result := True;
          break
        end
        else
        begin
          AScore := 0;
          break
        end;
      end
      else
      begin
        AScore := 0;
        break
      end;
    end;
    break
  end;

//  result := AScore > 0
end;

{ TArrPiece }

constructor TArrPiece.Create(ACollection: TArrCollection; APieceIndex: integer;
  AItem: TScanPiece);
begin
  inherited Create(ACollection, AItem);
  fSides := TList<TArrSide>.create;
  fPieceIndex := APieceIndex;

  var borderCount := 0;
  for var i := 0 to fItem.Sides.Count-1 do
  begin
    var nextIndex := (i + 1) mod fItem.Sides.Count;
    var prevIndex := (i + fItem.Sides.Count-1) mod fItem.Sides.Count;
    if fItem.Sides[i].Slices.Count = 1 then
      inc(borderCount)
    else
    begin
      var side := TArrSide.Create(ACollection, self, i, fItem.Sides[i]);
      side.fArrSideIndex := fSides.Count;
      if fItem.Sides[nextIndex].Slices.Count = 1 then
        side.fIsBeforeBorder := true;

      if fItem.Sides[prevIndex].Slices.Count = 1 then
        side.fIsAfterBorder := True;
      fSides.Add(side)
    end;
  end;

  fIsCorner := borderCount = 2;
  fIsBorder := borderCount = 1
end;

destructor TArrPiece.Destroy;
begin
  fSides.free;
  inherited;
end;

function TArrPiece.SidesLinked: integer;
begin
  result := 0;
  for var i := 0 to sides.Count-1 do
    if sides[i].Link <> nil then
      inc(result)
end;

{ TArrCollection }

constructor TArrCollection.Create(ACollection: TScanCollection);
begin
  inherited create;

  fScan := ACollection;
  fLinks := TDictionary<TArrSide, TArrLink>.create;
  fSides := TList<TArrSide>.create;
  fAllPieces := TList<TArrPiece>.create;
  fPieces := TList<TArrPiece>.create;
  fCorners := TList<TArrPiece>.create;
  fBorders := TList<TArrPiece>.Create;

  for var i := 0 to fScan.Count-1 do
  begin
    var arrPiece := TArrPiece.Create(self, i, fScan.Pieces[i]);
    if arrPiece.IsCorner then
      fCorners.Add(arrPiece)
    else
    if arrPiece.IsBorder then
      fBorders.Add(arrPiece)
    else
      fPieces.Add(arrPiece);
    fAllPieces.Add(arrPiece);
    for var j := 0 to arrPiece.Sides.Count-1 do
      fSides.Add(arrPiece.Sides[j])
  end;
end;

destructor TArrCollection.Destroy;
begin
  fLinks.Free;
  fSides.free;
  fPieces.Free;
  fAllPieces.Free;
  fCorners.free;
  fBorders.free;
  inherited;
end;

{ TListBoxHelper }

function TListBoxHelper.AddPiece;
var
  ATmpBitmap, AScanBitmap:TBitmap;
//  AListItem:TListBoxItem;
begin
  ATmpBitmap := ACollection.GetPieceBitmap(APieceIndex);
  AScanBitmap := ATmpBitmap.CreateThumbnail(ASize, ASize);
  result := TListBoxItem.Create(self);
  result.ItemData.Bitmap := AScanBitmap;
//  result.Data := Pointer(APieceIndex);// TOPair<TPoint,TScanPiece>.Create(fScan.Pieces.ToArray[APieceIndex]);
  self.InsertObject(0, result);
  result.ItemData.Detail := '';
//  result.DragMode := TDragMode.dmAutomatic;
end;

{ TArrLink }

constructor TArrLink.Create(ASide1, ASide2: TArrSide);
begin
  inherited create;
  fSide1 := ASide1;
  fSide2 := ASide2;
  fSide1.fLink := self;
  fSide2.fLink := Self;
  fSide1.Collection.fLinks.Add(fSide1, self);
  fSide2.Collection.fLinks.Add(fSide2, Self);
end;

function TArrLink.OtherSide(ASide: TArrSide): TArrSide;
begin
  if fSide1 = ASide then
    result := fSide2
  else
    result := fSide1
end;

{ TRotatedSide }

constructor TRotatedSide.Create(ASide: TArrSide; ATargetAngle:Single; AScale:Single);
begin
  rotationAngle := ATargetAngle-ASide.Angle;
  for var i := 0 to ASide.Piece.Sides.Count-1 do
  begin
    var sideIndex := (ASide.ArrSideIndex + i) mod ASide.Piece.Sides.Count;
    var boundary:TRectF;
    rotatedSide[i] := ASide.Piece.Sides[sideIndex].Item.RotateByRadian(rotationAngle, ASide.Center, boundary, AScale);
    rotatedCenter[i] := ASide.Piece.Sides[sideIndex].Center.RotateByRadian(rotationAngle, ASide.Center, AScale);
  end;
  rotatedPiece := ASide.Piece.Item.Points.RotateByRadian(rotationAngle, ASide.Center, rotatedPieceBoundary, AScale)
//  leftMargin := rotatedSide[0].X - rotatedBoundary.Left;
//  rightMargin := rotatedBoundary.Right - rotatedSide[Length(rotatedSide)-1].X;
//  centerWidth := rotatedSide[0].Distance(rotatedSide[Length(rotatedSide)-1]);
end;

constructor TRotatedSide.Create(ASide: TArrSide; ADirection: byte; AScale:Single);
begin
  direction := ADirection;
  Create(ASide, DegToRad(DirectionAngles[ADirection]), AScale)
end;

end.
