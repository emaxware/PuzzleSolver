program PuzzleSolver;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  m3.pointhelper in '..\m3lib\m3.pointhelper.pas',
  uScanPiece in 'uScanPiece.pas',
  fScannedPiece in 'fScannedPiece.pas' {fraScanPiece: TFrame},
  m3.DebugForm.fmx in '..\m3lib\m3.DebugForm.fmx.pas' {frmDebug},
  m3.imageviewerhelper in '..\m3lib\m3.imageviewerhelper.pas',
  cBitmapViewer in 'cBitmapViewer.pas' {fraBitmapViewer: TFrame},
  m3.bitmaphelper.fmx in '..\m3lib\m3.bitmaphelper.fmx.pas',
  cFunctionViewer in 'cFunctionViewer.pas' {fraFunctionViewer: TFrame},
  cSlicerViewer in 'cSlicerViewer.pas' {fraSlicerViewer: TFrame},
  cSegmentViewer in 'cSegmentViewer.pas' {fraSegmentViewer: TFrame},
  cPiecesViewer in 'cPiecesViewer.pas' {fraPiecesViewer: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
