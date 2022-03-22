program PuzzleSolverApp;

uses
  System.StartUpCopy,
  FMX.Forms,
  TabbedTemplate in 'TabbedTemplate.pas' {TabbedForm},
  m3.pointhelper in '..\m3lib\m3.pointhelper.pas',
  m3.imageviewerhelper in '..\m3lib\m3.imageviewerhelper.pas',
  m3.DebugForm.fmx in '..\m3lib\m3.DebugForm.fmx.pas' {frmDebug},
  m3.bitmaphelper.fmx in '..\m3lib\m3.bitmaphelper.fmx.pas',
  uScanPiece in 'uScanPiece.pas',
  fScannedPiece in 'fScannedPiece.pas' {fraScanPiece: TFrame},
  fMain in 'fMain.pas' {frmMain},
  cSegmentViewer in 'cSegmentViewer.pas' {fraSegmentViewer: TFrame},
  cPiecesViewer in 'cPiecesViewer.pas' {fraPiecesViewer: TFrame},
  cFunctionViewer in 'cFunctionViewer.pas' {fraFunctionViewer: TFrame},
  cCornerViewer in 'cCornerViewer.pas' {fraCornerViewer: TFrame},
  cBitmapViewer in 'cBitmapViewer.pas' {fraBitmapViewer: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TTabbedForm, TabbedForm);
  Application.CreateForm(TfrmDebug, frmDebug);
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
