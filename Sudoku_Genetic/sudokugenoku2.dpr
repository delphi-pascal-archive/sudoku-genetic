program sudokugenoku2;

uses
  Forms,
  uGenetic in 'uGenetic.pas',
  uMain in 'uMain.pas' {frmMain},
  uAbout in 'uAbout.pas' {frmAbout};

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.CreateForm(TfrmAbout, frmAbout);
  Application.Run;
end.
