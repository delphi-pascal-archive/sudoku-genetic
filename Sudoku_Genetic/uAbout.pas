unit uAbout;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, StdCtrls;

type
  TfrmAbout = class(TForm)
    lblFitness1: TLabel;
    lblFitness2: TLabel;
    lblFitness3: TLabel;
    lblFitness4: TLabel;
    lblFitness5: TLabel;
    lblFitness6: TLabel;
    lblFitness7: TLabel;
    lblFitness8: TLabel;
    lblTitleSh2: TLabel;
    lblTitleSh: TLabel;
    lblTitle: TLabel;
    Timer1: TTimer;
    lblFitness9: TLabel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Button1: TButton;
    procedure Timer1Timer(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;




var
  frmAbout: TfrmAbout;
  effectcount: integer = 0;
  fontsize: integer = 16;
  dir: boolean = true;

implementation
uses uMain;

{$R *.dfm}

procedure TfrmAbout.Button1Click(Sender: TObject);
begin
  Timer1.Enabled := False;
  Close();
end;

procedure TfrmAbout.FormShow(Sender: TObject);
begin
  Timer1.Enabled := True;
end;

procedure TfrmAbout.Timer1Timer(Sender: TObject);
var
  i: byte;
begin
  inc(effectCount);
  if dir then
    fontsize := fontsize + 1;
  if not dir then
    fontsize := fontsize - 1;

  if fontsize > 18 then dir := false;
  if fontsize < 15 then dir := true;

  if effectCount > 40 then
  begin
    fontsize := 16;
    timer1.Enabled := False;

    effectCount := 0;
  end;

  lblTitle.Font.Size := fontsize;
  lblTitleSh.Font.Size := fontsize;
  lblTitleSh2.Font.Size := fontsize;

   for i := 1 to 9 do
     TLabel(FindComponent('lblFitness' + IntToStr(i))).Caption := intToStr(random(9) + 1);


end;

end.
