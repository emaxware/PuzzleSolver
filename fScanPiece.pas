unit fScanPiece;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Forms, FMX.Graphics, FMX.Dialogs, FMX.StdCtrls,
  FMX.Controls.Presentation, FMX.Layouts, FMX.ExtCtrls
  , System.Generics.Collections, fScannedPiece
  ;

type
  TfrmScanPiece = class(TForm)
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmScanPiece: TfrmScanPiece;

implementation

{$R *.fmx}

uses
  uLib
  , System.Math
  , FMX.Surfaces
  ;

const
  APathSegmentLength = 5;

end.
