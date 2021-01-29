unit uLib;

interface

uses
  System.Types
  , System.SysUtils
  , System.UITypes
  , System.JSON
  , System.Generics.Collections
  , FMX.Graphics
  , FMX.Controls
  ;

type
  TPointFHelper = record helper for TPointF
    function asJSON:TJSONObject;
    function toPoint:TPoint;
    function toOffset(dx,dy:Single):TPointF;
    function toRectF(AWidth:Single = 1; AHeight:Single = 1; ACentered:Boolean = false):TRectF;
    procedure DrawPoint(ACanvas:TCanvas; AOpacity:single; AStrokeBrush:TStrokeBrush = nil; ARadius:Single = 2.0);
  end;

  TPointHelper = record helper for TPoint
    function toPointF:TPointF;
    function asJSON:TJSONObject;
  end;

  TOPair<TKey,TValue> = class
  private
    FKey: TKey;
    FValue: TValue;
  public
    constructor Create(fromTPair:TPair<TKey,TValue>);

    property Key:TKey read FKey;
    property Value:TValue read FValue;
  end;

  TDragDropHelper = class helper for TControl
    procedure BeginDrag;
    function MakeScreenshot:TBitmap;
  end;

//  TPairHelper = record helper for TPair<TKey,TValue>
//    function toPair:TOPair<TKey,TValue>;
//  end;

function NormRad(AAngle:single):single;

implementation

{ TPointFHelper }

procedure TPointFHelper.DrawPoint(ACanvas: TCanvas; AOpacity:single; AStrokeBrush:TStrokeBrush = nil; ARadius:Single = 2.0);
begin
  if ACanvas.BeginScene then
  try
    if AStrokeBrush = nil then
      ACanvas.DrawEllipse(self.toRectF(ARadius, ARadius, true), AOpacity)
    else
      ACanvas.DrawEllipse(self.toRectF(ARadius, ARadius, true), AOpacity, AStrokeBrush)
  finally
    ACanvas.EndScene
  end;
end;

function TPointFHelper.asJSON: TJSONObject;
begin
  result := TJSONObject.create
    .AddPair('x', TJSONNumber.Create(self.X))
    .AddPair('y', TJSONNumber.Create(self.Y))
end;

function TPointFHelper.toOffset(dx, dy: Single): TPointF;
begin
  result := self;
  result.Offset(dx,dy)
end;

function TPointFHelper.toPoint: TPoint;
begin
  result := Point(System.Round(Self.X),System.Round(Self.Y))
end;

function TPointFHelper.toRectF(AWidth, AHeight: Single; ACentered:boolean): TRectF;
begin
  result := TREctF.Create(self, AWidth, AHeight);
  if ACentered then
    Result.Offset(AWidth / -2, AHeight / -2);
end;

function TPointHelper.asJSON: TJSONObject;
begin
  result := TJSONObject.create
    .AddPair('x', TJSONNumber.Create(self.X))
    .AddPair('y', TJSONNumber.Create(self.Y))
end;

function TPointHelper.toPointF: TPointF;
begin
  result := PointF(Self.X,Self.Y)
end;

function NormRad(AAngle:single):single;
begin
  while AAngle > pi * 2 do
    AAngle := AAngle - pi * 2;

  while AAngle < 0 do
    AAngle := AAngle + pi * 2;

  result := AAngle
end;

{ TOPair<TKey, TValue> }

{ TOPair<TKey, TValue> }

constructor TOPair<TKey, TValue>.Create(fromTPair: TPair<TKey, TValue>);
begin
  FKey := fromTPair.Key;
  FValue := fromTPair.Value
end;

{ TDragDropHelper }

procedure TDragDropHelper.BeginDrag;
const
  DraggingOpacity = 0.7;
var
  B, S: TBitmap;
  R: TRectF;
begin
  if Root <> nil then
  begin
    S := MakeScreenshot;
    try
      B := nil;
      try
        if (S.Width > 512) or (S.Height > 512) then
        begin
          R := TRectF.Create(0, 0, S.Width, S.Height);
          R.Fit(TRectF.Create(0, 0, 512, 512));
          B := TBitmap.Create(Round(R.Width), Round(R.Height));
          B.Clear(0);
          if B.Canvas.BeginScene then
          try
            B.Canvas.DrawBitmap(S, TRectF.Create(0, 0, S.Width, S.Height), TRectF.Create(0, 0, B.Width, B.Height),
              DraggingOpacity, True);
          finally
            B.Canvas.EndScene;
          end;
        end else
        begin
          B := TBitmap.Create(S.Width, S.Height);
          B.Clear(0);
          if B.Canvas.BeginScene then
          try
            B.Canvas.DrawBitmap(S, TRectF.Create(0, 0, B.Width, B.Height), TRectF.Create(0, 0, B.Width, B.Height),
              DraggingOpacity, True);
          finally
            B.Canvas.EndScene;
          end;
        end;
        Root.BeginInternalDrag(Self, B);
      finally
        B.Free;
      end;
    finally
      S.Free;
    end;
  end;end;

function TDragDropHelper.MakeScreenshot: TBitmap;
var
  SceneScale: Single;
begin
  if Scene <> nil then
    SceneScale := Scene.GetSceneScale
  else
    SceneScale := 1;
  Result := TBitmap.Create(Round(Width * SceneScale), Round(Height * SceneScale));
  Result.BitmapScale := SceneScale;
  Result.Clear(0);
  if Result.Canvas.BeginScene then
  try
    PaintTo(Result.Canvas, TRectF.Create(0, 0, Result.Width / SceneScale, Result.Height / SceneScale));
  finally
    Result.Canvas.EndScene;
  end;
end;

end.
