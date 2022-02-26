unit cFunctionViewer;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants, 
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo, FMX.Controls.Presentation,
  cBitmapViewer
  , uScanPiece
//  , fMain
  ;

type
  TfraFunctionViewer = class(TFrame)
    fraBitmapViewerSlicer: TfraBitmapViewer;
    pnlSlicer: TPanel;
    btnSlicer: TButton;
    mmoProps: TMemo;
    splSlicer: TSplitter;
    pnlLeft: TPanel;
    spl1: TSplitter;
  private
    { Private declarations }
  protected
    fBitmap, fOverlay:TBitmap;
    fPieceIndex:integer;
    fPiece:TScanPiece;
    fScan:TScanCollection;
    fStarter:TProc<TfraFunctionViewer>;
  public
    { Public declarations }
    procedure UpdateOverlay; virtual; abstract;

    procedure Start; overload; virtual;
    procedure Start(AStarter:TProc<TfraFunctionViewer>); overload; virtual;
    procedure Start(AScan:TScanCollection); overload; virtual;
    procedure Start(AScan:TScanCollection; APieceIndex:integer); overload; virtual;
  end;

implementation

{$R *.fmx}

uses
  m3.bitmaphelper.fmx
  ;

{ TfraFunctionViewer }

{ TfraFunctionViewer }

procedure TfraFunctionViewer.Start(AScan: TScanCollection;
  APieceIndex: integer);
begin
  fScan := AScan;
  fPieceIndex := APieceIndex;
  fPiece := fScan.Pieces[APieceIndex];
  fBitmap := fScan.GetPieceBitmap(fPieceIndex);
  fOverlay := fBitmap.Clone
end;

procedure TfraFunctionViewer.Start(AScan: TScanCollection);
begin
  fScan := AScan;
  fPieceIndex := -1;
  fPiece := nil;
  fBitmap := fScan.Bitmap;
  fOverlay := fBitmap.Clone
end;

procedure TfraFunctionViewer.Start(AStarter: TProc<TfraFunctionViewer>);
begin
  fStarter := aStarter
end;

procedure TfraFunctionViewer.Start;
begin
  fStarter(Self)
end;

end.
