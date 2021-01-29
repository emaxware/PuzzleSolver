unit HeaderFooterTemplate;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Graphics, FMX.Controls, FMX.Forms, FMX.Dialogs, FMX.StdCtrls,
  FMX.Objects, FMX.Controls.Presentation, FMX.ListView.Types,
  FMX.ListView.Appearances, FMX.ListView.Adapters.Base, Data.Bind.Components,
  Data.Bind.ObjectScope, FMX.ListView, System.ImageList, FMX.ImgList,
  FMX.Layouts, FMX.ExtCtrls, FMX.TabControl, FMX.MultiView;

type
  THeaderFooterForm = class(TForm)
    Header: TToolBar;
    Footer: TToolBar;
    HeaderLabel: TLabel;
    mvMain: TMultiView;
    tbcMain: TTabControl;
    tiImport: TTabItem;
    ilPieces: TImageList;
    proMain: TPrototypeBindSource;
    BindSourceDB1: TBindSourceDB;
    bndngslst1: TBindingsList;
    lnkflcntrltfld1: TLinkFillControlToField;
    lstPieces: TListBox;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HeaderFooterForm: THeaderFooterForm;

implementation

{$R *.fmx}
{$R *.Windows.fmx MSWINDOWS}

end.
