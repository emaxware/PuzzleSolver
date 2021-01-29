program PuzzleSolver;

uses
  System.StartUpCopy,
  FMX.Forms,
  fMain in 'fMain.pas' {frmMain},
  uLib in 'uLib.pas',
  uScanPiece in 'uScanPiece.pas',
  fScannedPiece in 'fScannedPiece.pas' {fraScanPiece: TFrame};

{$R *.res}

begin
  Application.Initialize;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
