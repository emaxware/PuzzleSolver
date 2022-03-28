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

  TAlphaColorHelper = record helper for TAlphaColor
    function ScoreDiff(AColor:TAlphaColor):Single;
  end;

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
//  TAlphaColorHelper = record helper for TAlphaColorRec
//    function Diff(AColor:TAlphaColorRec):TAlphaColorRec;
//  end;

  TPoints = class(TList<TPoint>)
  public
    function LengthRatio:Extended;

    procedure Unknot;

    function TailRatio(ALength:Integer):Extended;
    function HeadRatio(ALength:Integer):Extended;

    function CalcHeadAngle(ALength:Integer):extended;
    function CalcTailAngle(ALength:Integer):extended;

    procedure HeadAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
    procedure TailAnglePts(ALength:Integer; var AStartPt, AMidPt, AEndPt:TPoint);
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
  public
    type
      TSideTraceLevel = (stlPreview, stlByPoint, stlBySegment);

      TOnTraceSide = reference to procedure(
        ATraceLevel:TSideTraceLevel
        ; ASegment:TSlice
        ; ASlice:TSlice
        ; ASlices:TSegments<TSlice>
        );
  protected
    fSlices: TSegments<TSlice>;
    fHeadAngle, fTailAngle: single;
    procedure SetSlices(const Value: TSegments<TSlice>);
    function DetectSlices(AHeadsize:integer; AStraightRatio:Single; AOnTrace:TOnTraceSide = nil; bReverse:Boolean = false; AOffset:Integer = 0):TSegments<TSlice>;
  public
//    constructor Create(AHeadsize:integer);//APoints:TPoints; AOrientation:TSegmentOrientation);

    destructor Destroy; override;

//    property Slices:TSegments<TSlice> read fSlices write SetSlices;
    property HeadAngle:single read fHeadAngle;
    property TailAngle:single read fTailAngle;
  end;

  TScanPiece = class
  protected
    fAvgColor: TAlphaColor;
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

//    procedure _CalcDimensions;
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

    property AvgColor:TAlphaColor read fAvgColor;
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

  TArr<T> = class
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
    fGridMove: TPoint;
    fGridMove2: TPoint;
    fGridMove1: TPoint;
    fSide1FromTopIndex, fSide2FromTopIndex:integer;
  public
    constructor Create(ASide1, ASide2:TArrSide);

    function OtherSide(ASide:TArrSide):TArrSide;
    property Side1:TArrSide read fSide1;
    property Side2:TArrSide read fSide2;
    property GridMove1:TPoint read fGridMove1;
    property GridMove2:TPoint read fGridMove2;
  end;

  TPatch = record
    perimeterPts:TArray<TPoint>;
    insidePt:TPoint;
//    score:single;
  end;

//  TPatchScoreArrayHelper = record helper for TArray<TPatchScore>
//    function ToSingleScore:TArray<Single>;
//  end;

  TArrSide = class(TArr<TSide>)
  protected
    fArrSideIndex: integer;
    fIsAfterBorder: Boolean;
    fSideIndex: integer;
    fLink: TArrLink;
    fIsOuty: boolean;
    fIsBeforeBorder: Boolean;
    fPiece: TArrPiece;
    fSideAngle: extended;

    fHypPointChecked:Boolean;

    fLeadingHypLength: single;
    fTrailingHypLength: single;
    fHypPointIndex: integer;
//    fCornersCenter: TPointF;
    fCenter:TPointF;
    function GetCenter: TPointF;
    function GetAngle: extended;
    function GetIsOuty: boolean;
    function GetHypPointIndex: integer;
    function GetLeadingHypLength: single;
    function GetTrailingHypLength: single;
//    function GetCornersCenter: TPointF;
    function GetHypPoint: TPointF;
    procedure CheckHypPoint; virtual;

    function ScoreMatch(ASide:TArrSide; out AScore:Single):boolean; overload;
    function ScoreMatch(AScore:TArray<TAlphaColor>; ASide:TArrSide; const APositions:array of Single; ARadius:single; out AMatchScore:TArray<Single>):boolean; overload;
  public
    constructor Create(ACollection:TArrCollection; APiece:TArrPiece; ASideIndex:integer; AItem:TSide);

    function CreatePatch(APosition, ARadius:single; out APatch:TPatch):boolean; overload;
    function CreatePatches(const APositions:array of Single; ARadius:single; out APatches:TArray<TPatch>):boolean;

    function ScorePatch(APosition, ARadius:single; out AScore:TAlphaColor):boolean; overload;
    function ScorePatch(APatch:TPatch; out AScore:TAlphaColor):boolean; overload;

    function ScorePatches(const APositions:array of Single; ARadius:single; out AScores:TArray<TAlphaColor>):boolean; overload;
    function ScorePatches(const APatches:array of TPatch; out AScores:TArray<TAlphaColor>):boolean; overload;

    function ScoreMatch(ASide:TArrSide; const APositions:array of Single; ARadius:single; out AMatchScore:TArray<Single>):boolean; overload;
    //    function ScorePatch(APosition, ARadius:single; out AScore:Single):boolean; overload;

    function MatchingSides(const APositions:array of Single; ARadius:integer; ATierCount:Integer = 50):TArray<TArrSide>;

    function AddLink(ASide:TArrSide):TArrLink;

    property Piece:TArrPiece read fPiece;
    property IsAfterBorder:Boolean read fIsAfterBorder;
    property IsBeforeBorder:Boolean read fIsBeforeBorder;
    property Link:TArrLink read fLink;
//    property SideIndex:integer read fSideIndex;
    property ArrSideIndex:integer read fArrSideIndex;
//    property CornersCenter:TPointF read GetCornersCenter;

    property SideCenter:TPointF read GetCenter;
    property Angle:extended read GetAngle;
    property IsOuty:boolean read GetIsOuty;
    property HypPoint:TPointF read GetHypPoint;
    property HypPointIndex:integer read GetHypPointIndex;
    property LeadingHypLength:single read GetLeadingHypLength;
    property TrialingHypLength:single read GetTrailingHypLength;
  end;

  TArrPiece = class(TArr<TScanPiece>)
  private
    fPieceCenter: TPointF;
  protected
    fGridSides: TArray<TArrSide>;
    fGridPos: TPoint;
    fIsCorner: boolean;
    fSides: TList<TArrSide>;
    fIsBorder: boolean;
    fPieceIndex: integer;
    fTopSideIndex: integer;
  public
    constructor Create(ACollection:TArrCollection; APieceIndex:integer; AItem:TScanPiece);
    destructor Destroy; override;

    function SidesLinked:integer;
    function GetBitmap:TBitmap;

    property IsCorner:boolean read fIsCorner;
    property IsBorder:boolean read fIsBorder;
    property Sides:TList<TArrSide> read fSides;
    property PieceIndex:integer read fPieceIndex;
    property GridPos:TPoint read fGridPos;
    property TopSideIndex:integer read fTopSideIndex;
    property GridSides:TArray<TArrSide> read fGridSides;
    property PieceCenter:TPointF read fPieceCenter;
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
    fGrid: TDictionary<TPoint, TArrPiece>;
    fGridPiece: TDictionary<TArrPiece, TPoint>;
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
    property GridPos:TDictionary<TPoint,TArrPiece> read fGrid;
    property GridPiece:TDictionary<TArrPiece, TPoint> read fGridPiece;
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
    type
      TTraceDetection = reference to function(APiece:TScanPiece):Boolean;

    constructor create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadBitmap(const ABitmapfilename:string);
    procedure LoadFrom(const AJSONFilename:string);
    procedure SaveTo(const AJAONFilename:string);

    function GetPieceBitmap(APieceIndex:integer):TBitmap;
//    function DetectPiece(AStartPoint:TPoint; ASpan:integer; var AScanPiece:TScanPiece; var APieceOrigin:TPoint):boolean;
    function DetectPieces(var ABitmapResult:TBitmap; ATracer:TTraceDetection = nil):boolean;
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
      :extended;
    rotatedSide:array[0..3] of TPolygon;
    rotatedCenter:array[0..3] of TPointF;
    rotatedPiece:TPolygon;
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
  , m3.bitmaphelper.fmx
  ;

{ TScanPiece }

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
  sumR, sumG, sumB, sumCnt:Cardinal;
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

      Inc(sumCnt);
      Inc(sumR, colorrec.R);
      Inc(sumG, colorrec.G);
      Inc(sumB, colorrec.B);
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

  procedure BridgeGap(p1, p2:TPoint; AList:TList<TPoint>);
  begin
    if (Abs(p1.X - p2.X) < 2) and (Abs(p1.Y - p2.Y) < 2) then
    else
    begin
      var midPt := p1.toPointF.MidLinePt(p2).Round;
      BridgeGap(p1, midPt, AList);
      var lastadded := AList.Last;
      AList.Add(midPt);
      BridgeGap(midPt, p2, AList);
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
  ABitmapResult := self.Bitmap.Clone;
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
            sumR := 0;
            sumG := 0;
            sumB := 0;
            sumCnt := 0;
            DetectPiece(Point(x, y), 0);

            if APerimeter.Count > 10 then
            begin
              var newPerimeter := TList<TPoint>.create;
              newPerimeter.Add(APerimeter.First);
              var avgColor := TAlphaColorF.Create(sumR/sumCnt, sumG/sumCnt, sumB/sumCnt, 1).ToAlphaColor;

              // assemble points into contiguos perimeter
              APerimeter.Delete(0);
              while APerimeter.Count > 0 do
              begin
                var found := false;
                for var d := 2 to 2 do
                begin
                  for var i := 0 to APerimeter.Count-1 do
                  begin
                    if (abs(APerimeter[i].x-newPerimeter.Last.x) < 2)
                        and (abs(APerimeter[i].y-newPerimeter.Last.y) < 2)
    //                  or
    //                    (abs(APerimeter[i].x-scanPiece.Points.Last.x) = 0)
    //                    and (abs(APerimeter[i].y-scanPiece.Points.Last.y) < 2)
                    then
                    begin
                      found := true;
                      newPerimeter.Add(APerimeter[i]);
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

              // bridge any gaps in perimeter
              APerimeter.Clear;
              for var i := 0 to newPerimeter.Count-2 do
              begin
                APerimeter.Add(newPerimeter[i]);
                BridgeGap(newPerimeter[i], newPerimeter[i+1], APerimeter);
              end;

              APerimeter.Add(newPerimeter.Last);
              BridgeGap(newPerimeter.Last, newPerimeter.First, APerimeter);

              // find perimeter boundary
              var bound := Rect(APerimeter[0], APerimeter[0]);
              for var i := 1 to APerimeter.Count-1 do
              begin
                if bound.left > APerimeter[i].x then
                  bound.left := APerimeter[i].x;
                if bound.top > APerimeter[i].y then
                  bound.top := APerimeter[i].y;

                if bound.right < APerimeter[i].x then
                  bound.right := APerimeter[i].x;
                if bound.bottom < APerimeter[i].y then
                  bound.bottom := APerimeter[i].y;
              end;

              // recenter perimeter from origin
              for var i := 0 to APerimeter.Count-1 do
              begin
                var pt := APerimeter[i];
                pt.x := pt.X - bound.left;
                pt.y := pt.Y - bound.top;
                APerimeter[i] := pt
              end;

              var scanPiece := TScanPiece.create;

              scanPiece.Points.AddRange(APerimeter);
              scanPiece.fAvgColor := avgColor;
              scanPiece.FWidth := bound.Width;
              scanPiece.FHeight := bound.Height;

//              scanPiece._CalcDimensions;
              self.AddPiece(bound.TopLeft, scanPiece);
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
    mask.Clear(0);
    var piece := TBitmap.Create(Value.Width, Value.Height);
    piece.Clear(TAlphaColorRec.white);
    var maskBrush := TBrush.Create(TBrushKind.Solid, TAlphaColorRec.White);
    try
      var rect := Rect(Key.X, Key.Y, Key.X + Value.Width, Key.Y + Value.Height);
      piece.CopyFromBitmap(Bitmap
        , rect
        , 0, 0);

      var poly := Value.Points.ToArray.AsPointFs.asPolygon;

      with mask.Canvas do
      if BeginScene then
      try
        Fill := maskBrush;
        FillPolygon(poly, 1);
      finally
        EndScene
      end;

      result := piece.CloneWithAlphaMask(mask);
      fCachedBitmaps.Add(Key, result)
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

function TPoints.LengthRatio: Extended;
begin
  result := First.Distance(Last) / length
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
    fSideAngle := Item.First.Angle(Item.Last);
    fSideAngle := Round(fSideAngle * Pi * 16) / (pi * 16);
    var angleInDeg := RadToDeg(fSideAngle);
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

function TArrSide.GetAngle: extended;
begin
  CheckHypPoint;
  result := fSideAngle;
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

function TArrSide.MatchingSides;
begin
  var rslts := TList<TPair<TArray<single>,TArrSide>>.Create;
  var sortedList := TList<TArrSide>.create;
  var tierList := TList<TPair<integer,TArrSide>>.create;
  var APatchScore:TArray<TAlphaColor>;
  if ScorePatches(APositions, ARadius, APatchScore) then
  try
    var ASingleScore:single;
    var APatchScore2:TArray<single>;

    // score all sides
    for var i := 0 to Collection.Sides.Count-1 do
      if ScoreMatch(Collection.Sides[i], ASingleScore) then
        if ScoreMatch(APatchScore, Collection.Sides[i], APositions, ARadius, APatchScore2)
      then
      begin
        var pair := TPair<TArray<single>,TArrSide>.Create(APatchScore2, Collection.Sides[i]);
        rslts.Add(pair);
      end;

    // tiered scoring
    for var t := 1 to ATierCount do
    begin
      tierList.clear;

      // extract sorted list for tier
      for var n := rslts.Count-1 downto 0 do
      begin
        var pr := TPair<integer,TArrSide>.Create(0, rslts[n].Value);
        for var o := 0 to length(rslts[n].Key)-1 do
        begin
          if (rslts[n].Key[o] > (1-t*0.01)) or (t = ATierCount) then
            inc(pr.Key);
        end;

        // only include in tier if more than 2
        if pr.Key < 3 then
          continue;

        var added := false;
        for var tl := 0 to tierList.Count-1 do
          if pr.Key > tierList[tl].Key then
          begin
            added := true;
            tierList.Insert(tl, pr);
            break
          end;

        if not added then
          tierList.Add(pr);

        // if added to tierlist, remove from scored list
        rslts.Delete(n)
      end;

      // add tierlist to sortedlist
      for var s := 0 to tierList.Count-1 do
        sortedList.Add(tierList[s].Value)
    end
  finally
    Result := sortedList.ToArray;
    tierList.Free;
    sortedList.free;
    rslts.free
  end;
end;

function TArrSide.ScoreMatch(ASide: TArrSide; out AScore: Single): boolean;
begin
  result := false;
  AScore := 0;
  while true do
  begin
    if ASide.Link <> nil then
      break;

    if Piece.PieceIndex = ASide.Piece.PieceIndex then
      break;

    if Piece.IsCorner and ASide.Piece.IsCorner then
      break;

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
          AScore := Self.Piece.Item.fAvgColor.ScoreDiff(ASide.Piece.Item.fAvgColor);
          break
        end
        else
          break
      end
      else
        break
    end
    else
    if not (ASide.IsBeforeBorder or ASide.IsAfterBorder) then
    begin
      if (ASide.IsOuty <> IsOuty) then
      begin
        result := True;
        AScore := Self.Piece.Item.fAvgColor.ScoreDiff(ASide.Piece.Item.fAvgColor);
        break
      end
      else
        break
    end;
    break
  end;

//  result := AScore > 0
end;

//function TArrSide.ScorePatch(APosition, ARadius: single; out AScore:Single): Boolean;
//begin
//  result := ScorePatch(
//end;

function TArrSide.ScoreMatch(ASide: TArrSide; const APositions:array of Single; ARadius:single;
  out AMatchScore: TArray<Single>): boolean;
begin
  setlength(AMatchScore, 0);
  var cnt := Length(APositions);
  var AScores:TArray<TAlphaColor>;
  if ScorePatches(APositions, ARadius, AScores) then
    result := ScoreMatch(AScores, ASide, APositions, ARadius, AMatchScore)
end;

function TArrSide.ScorePatches(const APatches: array of TPatch;
  out AScores: TArray<TAlphaColor>): boolean;
begin
  setlength(AScores, Length(APatches));
  var AScore:TAlphaColor;
  for var i := 0 to Length(APatches)-1 do
  if ScorePatch(APatches[i], AScore) then
  begin
    result := true;
    AScores[i] := AScore
  end
  else
    AScores[i] := 0
end;

//function TArrSide.CreatePatch(APosition, ARadius: single;
//  out APatch: TPatch): boolean;
//begin
//  result := false;
//  var ABitmapData:TBitmapData;
//  var ABitmap := Collection.Scan.GetPieceBitmap(Piece.PieceIndex).Clone;
//  try
//    if ABitmap.Map(TMapAccess.ReadWrite, ABitmapData) then
//    try
////      result := ScorePatch(ABitmapData, APosition, ARadius, AScore,
//    finally
//      ABitmap.Unmap(ABitmapData)
//    end;
//  finally
//    ABitmap.Free
//  end
//end;

function TArrSide.CreatePatch(APosition,
  ARadius: single; out APatch:TPatch): Boolean;
var
  perimeter:TList<TPoint>;
  stop:boolean;
  insidePt:TPoint;
  insidePtCount:integer;

  procedure BridgeSide(p1, p2:TPoint; AList:TList<TPoint>);
  begin
    if (Abs(p1.X - p2.X) < 2) and (Abs(p1.Y - p2.Y) < 2) then
    else
    begin
      var midPt := p1.toPointF.MidLinePt(p2).Round;
      BridgeSide(p1, midPt, AList);
      var lastadded := AList.Last;
      AList.Add(midPt);
      BridgeSide(midPt, p2, AList);
    end;
  end;

  procedure BridgeArc(p1, center, p2:TPoint; AList:TList<TPoint>; ADepth:Integer = 30);
  begin
    if ADepth <= 0 then
      stop := true
    else
    if (Abs(p1.X - p2.X) < 2) and (Abs(p1.Y - p2.Y) < 2) then
    else
    begin
      var midPt2 := p1.toPointF.MidArcPt(p2.toPointF, center).Round;
      if (midPt2 = p1) or (midPt2 = p2) then
        midPt2 := p1.toPointF.MidLinePt(p2.toPointF).Truncate;
      BridgeArc(p1, center, midPt2, AList, ADepth - 1);
      var lastadded2 := AList.Last;
      AList.Add(midPt2);
      insidePt := insidePt + midPt2;
      Inc(insidePtCount);
      BridgeArc(midPt2, center, p2, AList, ADepth - 1);
    end;
  end;

begin
  stop := False;
  result := false;
  var len := Item.Length;
  var currLen := 0.0;
  var positionIndex := -1;

  // find position index
  for var i := 1 to Item.Count-1 do
  begin
    currLen := currLen + Item[i-1].Distance(Item[i]);
    if currLen > len * APosition then
    begin
      positionIndex := i;
      break
    end;
  end;

  if positionIndex = -1 then
    exit;

  // start building perimeter
  perimeter := TList<TPoint>.create;
  try
    // add first pt
    perimeter.Add(Item[positionIndex]);
    var beginIndex := -1;

    // add first diameter half along side
    var j := positionIndex+1;
    while j < Item.Count do
    begin
      var last := perimeter.Last;
      var next := Item[j];
      BridgeSide(last, Item[j], perimeter);

      perimeter.Add(Item[j]);

      if Item[positionIndex].Distance(Item[j]) > ARadius then
      begin
        beginIndex := j;
        break
      end;

      Inc(j);
    end;

    if beginIndex = -1 then
      exit;

    var endIndex := -1;
    j := positionIndex-1;
    var lastDiamHalf := TList<TPoint>.create(Item[j]);
    Dec(j);
    while j >= 0 do
    begin
      var last := perimeter.Last;
      var next := Item[j];
      BridgeSide(lastDiamHalf.Last, Item[j], lastDiamHalf);

      lastDiamHalf.Add(Item[j]);

      if Item[positionIndex].Distance(Item[j]) > ARadius then
      begin
        endIndex := j;
        break
      end;

      dec(j);
    end;

    if endIndex = -1 then
      exit;

    insidePt := Point(0, 0);
    insidePtCount := 0;
    var arc1 := perimeter.Last;
    var arc2 := lastDiamHalf.Last;
    var ctr := Item[positionIndex];
    // add arc
    BridgeArc(arc1, ctr, arc2, perimeter);
    if stop then
      Exit;

    perimeter.AddRange(lastDiamHalf.toReverseArray);
    APatch.perimeterPts := perimeter.ToArray;
    APatch.insidePt := (insidePt.toPointF / insidePtCount).Round;

    result := true;

  finally
    perimeter.free
  end
end;

function TArrSide.CreatePatches(const APositions: array of Single; ARadius:Single;
  out APatches: TArray<TPatch>): boolean;
begin
  result := false;
  setlength(APatches, Length(APositions));
  for var i := 0 to length(APositions)-1 do
  begin
    var APatch:TPatch;
    if CreatePatch(APositions[i], ARadius, APatch) then
      APatches[i] := APatch
    else
      exit;
  end;
  result := true
end;

function TArrSide.ScorePatches(const APositions:array of Single; ARadius:single; out AScores:TArray<TAlphaColor>):boolean;
begin
  result := false;
  var APatches:TArray<TPatch>;
  if CreatePatches(APositions, ARadius, APatches) then
    result := ScorePatches(APatches, AScores)
end;

function TArrSide.ScorePatch(APosition, ARadius: single;
  out AScore: TAlphaColor): boolean;
begin
  result := false;
  var APatch:TPatch;
  if CreatePatch(APosition, ARadius, APatch) then
    result := ScorePatch(APatch, AScore)
end;

function TArrSide.ScorePatch(APatch: TPatch; out AScore: TAlphaColor): boolean;
var
  rslt:TAlphaColorF;
  clrCnt:integer;
  Data:TBitmapData;
  perimeterDict:TDictionary<TPoint, Boolean>;

  procedure WalkPatch(APt:TPoint);
  begin
    var clr := Data.GetPixel(APt.X, APt.Y);
    if clr = 0 then
      exit;
    if perimeterDict.ContainsKey(APt) then
      exit;
    rslt := rslt + TAlphaColorF.Create(clr);
    Inc(clrCnt);

    perimeterDict.Add(APt, false);
    WalkPatch(APt + Point(0, -1));
    WalkPatch(APt + Point(-1, 0));
    WalkPatch(APt + Point(0, 1));
    WalkPatch(APt + Point(1, 0))
  end;

begin
  result := false;
  var Bitmap := Piece.GetBitmap.Clone;
  perimeterDict := TDictionary<TPoint, Boolean>.Create;

  var dupe := false;
  for var i := 0 to Length(APatch.perimeterPts)-1 do
    if perimeterDict.ContainsKey(APatch.perimeterPts[i]) then
      dupe := true
    else
      perimeterDict.Add(APatch.perimeterPts[i], false);

  rslt := TAlphaColorF.Create(0);
  clrCnt := 0;

  if Bitmap.Map(TMapAccess.ReadWrite, Data) then
  try
    WalkPatch(APatch.insidePt);
    AScore := TAlphaColorF.create(rslt.R/clrCnt, rslt.G/clrCnt, rslt.B/clrCnt).ToAlphaColor;
    result := true
  finally
    perimeterDict.free;
    Bitmap.Unmap(Data);
    Bitmap.free
  end;
end;

function TArrSide.ScoreMatch(AScore: TArray<TAlphaColor>; ASide: TArrSide;
  const APositions: array of Single; ARadius: single;
  out AMatchScore: TArray<single>): boolean;
begin
  result := false;
  setlength(AMatchScore, 0);
  var cnt := Length(APositions);
  var AScores2:TArray<TAlphaColor>;
  if ASide.ScorePatches(APositions, ARadius, AScores2) then
  begin
    result := True;
    setlength(AMatchScore, cnt);
    for var i := 0 to cnt-1 do
      if (AScore[i] <> 0) and (AScores2[cnt-1-i] <> 0) then
        AMatchScore[i] := AScore[i].ScoreDiff(AScores2[cnt-1-i])
  end;
end;

{ TArrPiece }

constructor TArrPiece.Create(ACollection: TArrCollection; APieceIndex: integer;
  AItem: TScanPiece);
begin
  inherited Create(ACollection, AItem);
  fTopSideIndex := -1;
  fSides := TList<TArrSide>.create;
  fPieceIndex := APieceIndex;
  fPieceCenter := PointF(0, 0);

  var borderCount := 0;
  for var i := 0 to fItem.Sides.Count-1 do
  begin
    fPieceCenter := fPieceCenter + fItem.Sides[i].First;
    var nextIndex := (i + 1) mod fItem.Sides.Count;
    var prevIndex := (i + fItem.Sides.Count-1) mod fItem.Sides.Count;
    // TODO : replace slices
//    if fItem.Sides[i]. //.Slices.Count = 1 then
//      inc(borderCount)
//    else
//    begin
//      var side := TArrSide.Create(ACollection, self, i, fItem.Sides[i]);
//      if side.HypPoint then
//
//      side.fArrSideIndex := fSides.Count;
//      if fItem.Sides[nextIndex].Slices.Count = 1 then
//        side.fIsBeforeBorder := true;
//
//      if fItem.Sides[prevIndex].Slices.Count = 1 then
//        side.fIsAfterBorder := True;
//      fSides.Add(side)
//    end;
  end;

  fPieceCenter := fPieceCenter / fItem.Sides.Count;
  fIsCorner := borderCount = 2;
  fIsBorder := borderCount = 1
end;

destructor TArrPiece.Destroy;
begin
  fSides.free;
  inherited;
end;

function TArrPiece.GetBitmap: TBitmap;
begin
  result := Collection.Scan.GetPieceBitmap(fPieceIndex)
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
  fGrid := TDictionary<TPoint, TArrPiece>.create;
  fGridPiece := TDictionary<TArrPiece,TPoint>.create;

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
  fGrid.free;
  fGridPiece.free;
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
  if fSide1.fLink <> nil then
    raise Exception.Create('Unexpected');

  if fSide2.fLink <> nil then
    raise Exception.Create('Unexpected');

  try
    fSide1.fLink := self;
    fSide2.fLink := Self;
    fSide1.Collection.fLinks.Add(fSide1, self);
    fSide2.Collection.fLinks.Add(fSide2, Self);

    if ASide1.Collection.fGrid.Count = 0 then
    begin
      ASide1.Collection.fGrid.Add(ASide1.Piece.fGridPos, ASide1.Piece);
      ASide1.Collection.fGridPiece.Add(ASide1.Piece, ASide1.Piece.fGridPos);
      SetLength(ASide1.Piece.fGridSides, 4);
      ASide1.Piece.fTopSideIndex := ASide1.fSideIndex;
      for var ts1 := 0 to ASide1.Piece.Sides.Count-1 do
      begin
        var fromIndex := ASide1.Piece.Sides[ts1].fSideIndex;
        var toIndex := (ASide1.Piece.Sides[ts1].fSideIndex - ASide1.Piece.fTopSideIndex + 4) mod 4;
        ASide1.Piece.fGridSides[toIndex] := ASide1.Piece.Sides[ts1];
      end;
    end;

    fSide1FromTopIndex := (ASide1.fSideIndex - ASide1.Piece.fTopSideIndex + 4) mod 4;

    case fSide1FromTopIndex of
      0: fGridMove1 := Point(0, -1);
      1: fGridMove1 := Point(1, 0);
      2: fGridMove1 := Point(0, 1);
      3: fGridMove1 := Point(-1, 0);
      else
        raise Exception.Create('Unexpected');
    end;

    var ASide2GridPoint := ASide1.Piece.fGridPos + fGridMove1;
    if ASide2.Piece.fTopSideIndex = -1 then
    begin
      ASide2.Piece.fTopSideIndex := (ASide2.fSideIndex + 6 - fSide1FromTopIndex) mod 4;
      ASide2.Piece.fGridPos := ASide2GridPoint;
      ASide2.Collection.fGrid.Add(ASide2.Piece.fGridPos, ASide2.Piece);
      ASide2.Collection.fGridPiece.Add(ASide2.Piece, ASide2.Piece.fGridPos);
      SetLength(ASide2.Piece.fGridSides, 4);
      for var ts2 := 0 to ASide2.Piece.Sides.Count-1 do
      begin
        var fromIndex2 := ASide2.Piece.Sides[ts2].fSideIndex;
        var toIndex2 := (ASide2.Piece.Sides[ts2].fSideIndex - ASide2.Piece.fTopSideIndex + 4) mod 4;
        ASide2.Piece.fGridSides[toIndex2] := ASide2.Piece.Sides[ts2];
      end;
    end
    else
    if (ASide2.Piece.fGridPos <> ASide2GridPoint) then
      raise Exception.Create('Unexpected');

    fSide2FromTopIndex := (ASide2.fSideIndex - ASide2.Piece.fTopSideIndex + 4) mod 4;
    case fSide2FromTopIndex of
      0: fGridMove2 := Point(0, -1);
      1: fGridMove2 := Point(1, 0);
      2: fGridMove2 := Point(0, 1);
      3: fGridMove2 := Point(-1, 0);
      else
        raise Exception.Create('Unexpected');
    end;

  except
    fSide1.fLink := nil;
    fSide2.fLink := nil;
    fSide1.Collection.fLinks.Remove(fSide1);
    fSide2.Collection.fLinks.Remove(fSide2);
    raise
  end;

  var found:TArrPiece;
  var mvTest := [Point(0, -1), Point(1, 0), Point(0, 1), Point(-1, 0)];
  for var mvTestIndex := 0 to 3 do
  if (mvTestIndex <> fSide2FromTopIndex) and (ASide2.Piece.GridSides[mvTestIndex] <> nil) and (ASide2.Piece.GridSides[mvTestIndex].Link = nil) then
  begin
    var newSide1 := ASide2.Piece.GridSides[mvTestIndex];
    if ASide2.Collection.GridPos.TryGetValue(ASide2.Piece.GridPos + mvTest[mvTestIndex], found) then
    try
      var newSide2 := found.GridSides[(mvTestIndex + 2) mod 4];
      if (newSide2 <> nil) and (newSide2.Link = nil) then
        newSide1.AddLink(newSide2);
    except

    end
  end
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
    rotatedSide[i] := ASide.Piece.Sides[sideIndex].Item.RotateByRadian(rotationAngle, ASide.SideCenter, boundary, AScale);
    rotatedCenter[i] := ASide.Piece.Sides[sideIndex].SideCenter.RotateByRadian(rotationAngle, ASide.SideCenter, AScale);
  end;
  rotatedPiece := ASide.Piece.Item.Points.RotateByRadian(rotationAngle, ASide.SideCenter, rotatedPieceBoundary, AScale)
//  leftMargin := rotatedSide[0].X - rotatedBoundary.Left;
//  rightMargin := rotatedBoundary.Right - rotatedSide[Length(rotatedSide)-1].X;
//  centerWidth := rotatedSide[0].Distance(rotatedSide[Length(rotatedSide)-1]);
end;

constructor TRotatedSide.Create(ASide: TArrSide; ADirection: byte; AScale:Single);
begin
  direction := ADirection;
  Create(ASide, DegToRad(DirectionAngles[ADirection]), AScale)
end;

  { TPatchScoreArrayHelper }

//function TPatchScoreArrayHelper.ToSingleScore:TArray<Single>;
//begin
////  SetLength(result, length(self.
//end;

{ TAlphaColorHelper }

//function TAlphaColorHelper.Diff(AColor: TAlphaColorF): TAlphaColorF;
//begin
//  Result.R := Abs(R - AColor.R);
//  Result.G := Abs(G - AColor.G);
//  Result.B := Abs(B - AColor.B);
//  Result.A := Abs(A - AColor.A);
//end;

{ TAlphaColorHelper }

function TAlphaColorHelper.ScoreDiff(AColor:TAlphaColor):Single;
begin
  var diff := TAlphaColorF.Create(self) - TAlphaColorF.Create(AColor);
  result := 1 - (abs(diff.R) + abs(diff.G) + abs(diff.b))/3
end;

end.
