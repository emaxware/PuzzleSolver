program PuzzleSolver;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  m3.pointhelper in '..\m3lib\m3.pointhelper.pas',
  uScanPiece in 'uScanPiece.pas',
  m3.imageviewerhelper in '..\m3lib\m3.imageviewerhelper.pas',
  cBitmapViewer in 'cBitmapViewer.pas' {fraBitmapViewer: TFrame},
  m3.bitmaphelper.fmx in '..\m3lib\m3.bitmaphelper.fmx.pas',
  cFunctionViewer in 'cFunctionViewer.pas' {fraFunctionViewer: TFrame},
  cCornerViewer in 'cCornerViewer.pas' {fraCornerViewer: TFrame},
  cPiecesViewer in 'cPiecesViewer.pas' {fraPiecesViewer: TFrame},
  cArrangeViewer in 'cArrangeViewer.pas' {fraArrangeViewer: TFrame},
  m3.DebugForm.fmx in '..\m3lib\m3.DebugForm.fmx.pas' {frmDebug};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmDebug, frmDebug);
  Application.Run;
end.
