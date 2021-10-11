unit uMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, ExtCtrls, Buttons, StdCtrls, uGenetic, TeeProcs, TeEngine, Chart,
  Series, MMSystem, uAbout;

type
  TfrmMain = class(TForm)
    btnSolveSudoku: TSpeedButton;
    Sudobox: TPaintBox;
    lblTitleSh: TLabel;
    lblTitle: TLabel;
    lblTitleSh2: TLabel;
    btnClearTable: TSpeedButton;
    btnStat: TSpeedButton;
    Timer1: TTimer;
    btnTest: TButton;
    btnLoad: TSpeedButton;
    btnSave: TSpeedButton;
    dlgSaveSudoku: TSaveDialog;
    dlgLoadSudoku: TOpenDialog;
    chbTest: TCheckBox;
    lblFitness: TLabel;
    lblFitness2: TLabel;
    lblFitness3: TLabel;
    lblFitness4: TLabel;
    lblFitness5: TLabel;
    lblFitness6: TLabel;
    lblFitness7: TLabel;
    lblFitness8: TLabel;
    Chart1: TChart;
    btnAbout: TSpeedButton;
    btnStop: TSpeedButton;
    procedure SudoboxPaint(Sender: TObject);
    procedure SudoboxMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure FormKeyPress(Sender: TObject; var Key: Char);
    procedure Timer1Timer(Sender: TObject);
    procedure btnTestClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnLoadClick(Sender: TObject);
    procedure btnSolveSudokuClick(Sender: TObject);
    procedure btnStatClick(Sender: TObject);
    procedure btnClearTableClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnAboutClick(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SetTitle(sTitle: string);
    procedure SolveSodoku();
    function CheckChrome(Chrome: TChromosome): bool;
    function Select: byte;
    function Select2(Population: array of TChromosome): byte;
  end;

var
  frmMain: TfrmMain;
  selectedCell: TPoint;
  valArr: TValArr;
  //-----
  dir: boolean = true;
  fontsize: integer = 16;
  effectCount: byte = 0;
  //-----
  SampleChrome: TChromosome;
  testChrome1, testChrome2: TChromosome;

  GenerationCount: longint = 0;
  prevSelect : byte = 0;
  prevSelectNum: byte = 1;
  BestPopulationCount: integer;

  ChromeFound : bool = False;
  Ser: TFastLineSeries;

implementation


{$R *.dfm}

procedure TfrmMain.btnTestClick(Sender: TObject);
var
  c1, c2, c3, c4: TChromosome;
begin
  SampleChrome.LoadRowGenes(valArr);
  SampleChrome.CalculateFitness;
  SudoboxPaint(Sender);
  lblTitle.Caption := 'Fitness is = ' + FloatToStr(SampleChrome.FitnessValue);

  //--- temp
  c1 := TChromosome.Create(nil);
  c2 := TChromosome.Create(nil);
  c3 := TChromosome.Create(nil);
  c4 := TChromosome.Create(nil);
  c1.FitnessValue := 1;
  c2.FitnessValue := 2;
  c3.FitnessValue := 3;
  c4.FitnessValue := 4;
  c1.SquareGenes[1, 1] := 9;
  c2.SquareGenes[1, 1] := 8;

  c4 := c3;
  c3 := c1;

end;

function TfrmMain.CheckChrome(Chrome: TChromosome): bool;
begin
  Result := False;
  Chrome.CalculateFitness();
  if Chrome.FitnessValue = 0 then
  begin
    Result := True;
    SetTitle('Судоку решена в ' + inttoStr(GenerationCount) +  'м поколении!!');
    Chrome.SaveRowGenes(valArr);
    SudoboxPaint(nil);
    PlaySound('sound/sudoku.wav', 0, SND_ASYNC);
  btnClearTable.Show;
  btnSolveSudoku.Show;
 // btnStat.Show;
  btnSave.Show;
  btnLoad.Show;
  chbTest.Show;
  btnStop.Hide;
  lblFitness.Hide;
  lblFitness2.Hide;
  lblFitness3.Hide;
  lblFitness4.Hide;
  lblFitness5.Hide;
  lblFitness6.Hide;
  lblFitness7.Hide;
  lblFitness8.Hide;
  Ser.AddY(0);
  end;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  SampleChrome := TChromosome.Create(nil);
  frmMain.Height :=    frmMain.Height - chart1.Height;
end;

procedure TfrmMain.FormKeyPress(Sender: TObject; var Key: Char);
begin

   if CharInSet(key, ['0'..'9']) then
     valArr[selectedCell.X, selectedCell.Y] := StrtoInt(key);
   if key = #27 then
     valArr[selectedCell.X, selectedCell.Y] := 0;

   if CharInSet(key, ['A', 'a']) then
   if SelectedCell.X > 1 then
     dec(SelectedCell.X);
   if CharInSet(key, ['D', 'd']) then
   if SelectedCell.X < 9 then
     inc(SelectedCell.X);
   if CharInSet(key, ['W', 'w']) then
   if SelectedCell.Y > 1 then
     dec(SelectedCell.Y);

   if CharInSet(key, ['S', 's']) then
   if SelectedCell.Y < 9 then
     inc(SelectedCell.Y);

   SudoboxPaint(Sender);
end;

procedure TfrmMain.btnSaveClick(Sender: TObject);
begin
  SampleChrome.LoadRowGenes(valArr);
  if chbTest.Checked then
    SampleChrome.SavetoFile('samplesudoku.save')
  else
    if dlgSaveSudoku.Execute() then
      SampleChrome.SavetoFile(dlgSaveSudoku.FileName);
  SudoboxPaint(Sender);
  SetTitle('Таблица сохранена в файл!');
end;

//**** test solve
procedure TfrmMain.btnSolveSudokuClick(Sender: TObject);
const
  PopulationCount = 50;
var
  Population: array [1..PopulationCount] of TChromosome;
  BestPopulation: array [1..30] of TChromosome;
  j: Integer;
  i: Integer;
  tempChrome: TChromosome;
  ir, jr: byte;
  tstr: string;
  f: real;
  EliteChange: bool;
  ElitePopulation: array[1..5] of TChromosome;
  lastEliteValues: array [1..5] of real;
  sList: TStringList;
begin

  btnClearTable.Hide;
  //btnStat.Hide;
  btnSave.Hide;
  btnLoad.Hide;
  btnStop.Hide;
  chbTest.Hide;
  btnSolveSudoku.Hide;

  lblFitness.Show;
  lblFitness2.Show;
  lblFitness3.Show;
  lblFitness4.Show;
  lblFitness5.Show;
  lblFitness6.Show;
  lblFitness7.Show;
  lblFitness8.Show;

  lblFitness.Caption := '';
  lblFitness2.Caption := '';
  lblFitness3.Caption := '';
  lblFitness4.Caption := '';
  lblFitness5.Caption := '';
  lblFitness6.Caption := '';
  lblFitness7.Caption := '';
  lblFitness8.Caption := '';

  Randomize();
  GenerationCount := 0;
  ChromeFound := False;
  BestPopulationCount := 20;

  sList := TStringList.Create();

  if SampleChrome = nil then
    SampleChrome := TChromosome.Create(nil);

   EliteChange := false;

  // getting a fixed genes to samplechrome
  SampleChrome.LoadRowGenes(valArr);

  // 1 ШАГ - Генерация НАЧАЛЬНОЙ ПОПУЛЯЦИИ
  //------------------------------------
  inc(GenerationCount);

  for i := 1 to 5 do
  begin
    ElitePopulation[i] := TChromosome.Create(SampleChrome);
  end;

  for i := 1 to PopulationCount do
  begin
    Population[i] := TChromosome.Create(SampleChrome);

    Population[i].Generate();
    f := Population[i].CalculateFitness();
   while f > 30 do                     //!!!!! experimental 2
    begin
       Population[i].Generate();
    f := Population[i].CalculateFitness();
    end;

  end;

  tempChrome := TChromosome.Create(sampleChrome);

  // getting best of the best
  //-------------------------------------

  // sorting by fitness value
  for i := 1 to PopulationCount do
    for j := 1 to PopulationCount - i - 1 do
    if Population[j].FitnessValue > Population[j + 1].FitnessValue then
    begin
      tempChrome.CopyChrome(Population[j]);                // !!can be so?
      Population[j].CopyChrome(Population[j + 1]);
      Population[j + 1].CopyChrome(tempChrome);


    end;

  // отбираем лучших из первой популяции
  for i := 1 to BestPopulationCount do
  begin
    BestPopulation[i] := TChromosome.Create(SampleChrome);
    BestPopulation[i].CopyChrome(Population[i]);
  end;

  // Elite!
  for i := 1 to 5 do
    ElitePopulation[i].CopyChrome(BestPopulation[i]);


  Ser := TFastLineSeries.Create(chart1);
  Ser.ParentChart := chart1;
  Ser.Clear;
  Ser.Pen.Width := 2;
  Ser.AddXY(0, 0);

  // ----------------------------
  //  == main production cycle ==
  // ----------------------------
  while not ChromeFound do
  begin
      inc(GenerationCount);
      if GenerationCount > 20000 then
      begin
        SetTitle('Возможно популяция не удалась :(');
        btnStop.Show;
      end;
      EliteChange := False;

     for i := 1 to BestPopulationCount do
     begin
       BestPopulation[i].CalculateFitness();
       if CheckChrome(BestPopulation[i]) then Exit;
     end;


  // sorting by fitness value
  for i := 1 to BestPopulationCount do
    for j := 1 to BestPopulationCount - i - 1 do
    if BestPopulation[j].FitnessValue > BestPopulation[j + 1].FitnessValue then
    begin
      tempChrome.CopyChrome(BestPopulation[j]);
      BestPopulation[j].CopyChrome(BestPopulation[j + 1]);
      BestPopulation[j + 1].CopyChrome(tempChrome);
    end;

    // ! new Elite
    for i := 1 to 5 do
      if (ElitePopulation[i].FitnessValue < BestPopulation[i].FitnessValue)
        //or (ElitePopulation[i].EliteAge = 0)
         then
       BestPopulation[i].CopyChrome(ElitePopulation[i])
    else
    begin
        inc(ElitePopulation[i].EliteAge);
        EliteChange := True;
    end;

     // crossing BestPopulation to Population
     for i := 1 to BestPopulationCount do
     begin

     if i in [1..10] then
       Population[i].Cross(BestPopulation[Select], BestPopulation[Select]);
    if i in [11..20] then
      //  Population[i].Cross(BestPopulation[Select2(BestPopulation)], BestPopulation[Select2(BestPopulation)]);
      Population[i].Cross(BestPopulation[Select], BestPopulation[Select]);
      Population[i].CalculateFitness;
      Population[i].Mutate();
      if CheckChrome(Population[i]) then Exit;
     end;


      for i := 1 to BestPopulationCount do
      begin
        BestPopulation[i].CopyChrome(Population[i]);
        BestPopulation[i].CalculateFitness();
      end;


      // sorting 2 - only testing
        // sorting by fitness value
  for i := 1 to BestPopulationCount do
    for j := 1 to BestPopulationCount - i - 1 do
    if BestPopulation[j].FitnessValue > BestPopulation[j + 1].FitnessValue then
    begin
      tempChrome.CopyChrome(BestPopulation[j]);
      BestPopulation[j].CopyChrome(BestPopulation[j + 1]);
      BestPopulation[j + 1].CopyChrome(tempChrome);
    end;


   // !new! Elite mode
   for i := 1 to 5 do
     if ElitePopulation[i].FitnessValue > BestPopulation[i].FitnessValue then
       ElitePopulation[i].CopyChrome(BestPopulation[i])
   else
     if not EliteChange then
       inc(ElitePopulation[i].EliteAge);


   // Elite age - new:! 3 may 2009

     for i := 1 to 5 do
       if ElitePopulation[i].EliteAge > 300 then
     begin
       // отправляем старую дряхлую элиту на покой и вливаем свежую кровь ;)

       ElitePopulation[i].CrossWith(BestPopulation[Select]);
         ElitePopulation[i].CalculateFitness();
         if CheckChrome(ElitePopulation[i])   then Exit;
          ElitePopulation[i].Mutate();
          ElitePopulation[i].EliteAge := 0;
          if  ElitePopulation[i].FitnessValue = 1.34066 then ShowmEssage('WARNINGGG!');
          if  ElitePopulation[i].FitnessValue = 1.56 then ShowmEssage('WARNINGGG!');
//          if  ElitePopulation[i].FitnessValue = 1.56 then ShowmEssage('WARNINGGG!');
          for j := 1 to 5 do
          begin
            ElitePopulation[i].CalculateFitness();
            if CheckChrome(ElitePopulation[i])   then Exit;
            if lastEliteValues[i] < ElitePopulation[i].FitnessValue then
            begin
               f := ElitePopulation[i].FitnessValue;
            //   Showmessage('before mutate fitness is: ' + FloatToStr(f));
              ElitePopulation[i].Mutate();  // !!!
           //    Showmessage('after mutate fitness is: ' + FloatToStr(ElitePopulation[i].CalculateFitness));

            end;
            // lastEliteValues[i] := ElitePopulation[i].FitnessValue;
          end;
          lastEliteValues[i] := ElitePopulation[i].FitnessValue;
        if CheckChrome(ElitePopulation[i])   then Exit;
     end;


  if (GenerationCount mod 200) = 0 then
   begin
     Ser.AddXY(GenerationCount, ElitePopulation[1].FitnessValue);
     lblFitness.Caption := FloatToStr(ElitePopulation[1].FitnessValue);
     lblFitness2.Caption := FloatToStr(BestPopulation[2].FitnessValue);
     lblFitness3.Caption := FloatToStr(BestPopulation[3].FitnessValue);
     lblFitness4.Caption := FloatToStr(BestPopulation[4].FitnessValue);
     lblFitness5.Caption := '' + FloatToStr(ElitePopulation[1].EliteAge);
     lblFitness6.Caption := ''  + FloatToStr(ElitePopulation[2].EliteAge);
   {  if TestChrome1 = nil then
       testChrome1 := TChromosome.Create(SampleChrome);
       testChrome1.Generate();
       }
    // BestPopulation[BestPopulationCount].Cross(testChrome1, ElitePopulation[1]);
    //  BestPopulation[BestPopulationCount].CalculateFitness;
     lblFitness7.Caption := FloatToStr(BestPopulation[BestPopulationCount].FitnessValue);
      lblFitness8.Caption := FloatToStr(GenerationCount);
    //  ElitePopulation[1].SaveRowGenes(valArr);
   //   SudoboxPaint(Sender);
     Application.ProcessMessages;
   end;



  end; // while not ChromeFound

  btnClearTable.Show;
//  btnStat.Show;
  btnSave.Show;
  btnLoad.Show;
  chbTest.Show;
  btnSolveSudoku.Show;
  btnStop.Hide;
  btnSolveSudoku.Show;
  lblFitness.Hide;
  lblFitness2.Hide;
  lblFitness3.Hide;
  lblFitness4.Hide;
  lblFitness5.Hide;
  lblFitness6.Hide;
  lblFitness7.Hide;
  lblFitness8.Hide;

  //ElitePopulation[1].SaveRowGenes(valArr);
//  SudoboxPaint(Sender);
 // SetTitle('Пока так получилось...' + IntToStr(GenerationCount));


end;

procedure TfrmMain.btnStatClick(Sender: TObject);
begin
  Chart1.Visible := not Chart1.Visible;
  if Chart1.Visible then
    frmMain.Height :=   frmMain.Height + Chart1.Height
  else
    frmMain.Height :=   frmMain.Height - Chart1.Height;

end;

// selects the chrome
function TfrmMain.Select: byte;
var
  curNum: byte;
begin
  Result := 1;
  curNum := random(100) + 1;
  case curNum of
    1..20: Result := 1;
    21..35: Result := 2;
    36..45: Result := 3;
    46..53: Result := 4;
    54..61: Result := 5;
    63..68: Result := 6;
    69..74: Result := 7;
    75..78: Result := 8;
    79..81: Result := 9;
    82..83: Result := 10;
    84..85: Result := 11;
    86..87: Result := 12;
    88..89: Result := 13;
    90..91: Result := 14;
    92..93: Result := 15;
    94..95: Result := 16;
    96..97: Result := 17;
    98..99: Result := 18;
    100..101: Result := 19;
    102..103: Result := 20;

  end;
  // чтобы не повторялись номера подряд
  if Result = prevSelect then
  begin
    if Result < 10
      then inc(Result)
    else
      dec(Result);
  end;
  prevSelect := Result;

end;

function TfrmMain.Select2(Population: array of TChromosome): byte;
var
  i: byte;
  Ftotal: real;
  P: array of real;
  l: integer;
  proc: byte;
  curNum: byte;

begin
  //
  Result := 0;
  Ftotal := 0;
  Setlength(p, BestPopulationCount);
  curNum := random(100) + 1;

  for i := 1 to BestPopulationCount - 1 do
    Ftotal := Ftotal + (Population[1].FitnessValue - Population[i].FitnessValue);

   if Ftotal = 0 then Ftotal := 1;
  for i := 0 to BestPopulationCount - 1 do
  begin
    P[i] := (Population[1].FitnessValue - Population[i].FitnessValue) / Ftotal * 100;
    P[i] := round(P[i]);
  end;

  for i := 0 to BestPopulationCount - 1 do
  begin

    proc := 0;
    for l := 0 to i do
      proc := proc + round(p[i]);
    if curNum in [integer(round(P[i]))..proc] then
    begin
      result :=  (i + 1);
      Exit;
    end;
  end;

  if (Result = prevSelect) and (prevSelectNum = 2) then
  begin
    if Result < BestPopulationCount
      then inc(Result)
    else
      dec(Result);
  end;
  Inc(prevSelectNum);
  if prevSelectNum > 2 then prevSelectNum := 1;
  prevSelect := Result;

end;

procedure TfrmMain.SetTitle(sTitle: string);
begin
  lblTitle.Caption := sTitle;
  lblTitleSh.Caption := sTitle;
  lblTitleSh2.Caption := sTitle;
  Timer1.Enabled := True;
end;

procedure TfrmMain.SolveSodoku;
var
  i, j: byte;
begin
//

end;

procedure TfrmMain.btnStopClick(Sender: TObject);
begin
  ChromeFound := True;
  SetTitle('Прервано :(');
end;

procedure TfrmMain.btnAboutClick(Sender: TObject);
begin
  frmAbout.ShowModal();
end;

procedure TfrmMain.btnClearTableClick(Sender: TObject);
var i, j: integer;
begin
  for i := 1 to 9 do
  for j := 1 to 9 do
    valArr[i, j] := 0;
  SudoboxPaint(Sender);

  SampleChrome.LoadRowGenes(valArr);

end;

procedure TfrmMain.btnLoadClick(Sender: TObject);
begin
  if chbTest.Checked then
    SampleChrome.LoadfromFile('samplesudoku.save')
  else
    if dlgLoadSudoku.Execute() then
      SampleChrome.LoadfromFile(dlgLoadSudoku.FileName);
  SampleChrome.SaveRowGenes(valArr);
  SudoboxPaint(Sender);
  SetTitle('Таблица загружена из файла!');
end;

procedure TfrmMain.SudoboxMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
    if (Button = mbLeft) then
    begin
        selectedCell.X := X div 50 + 1;
        selectedCell.Y := Y div 50 + 1;
        SudoboxPaint(Sender);
    end;
end;

procedure TfrmMain.SudoboxPaint(Sender: TObject);
const
  COL_BOX_BG = $00D2FFFF;
  COL_CELL_SEL = clYellow;
var
    i, j: integer;
begin
    Sudobox.Canvas.Brush.Color := COL_BOX_BG;
    Sudobox.Canvas.FillRect(SudoBox.Canvas.ClipRect);
    Sudobox.Canvas.Pen.Width := 3;
    Sudobox.Canvas.Font.Color := clRed;

    for i := 1 to 10 do
    begin
       if (((i - 1) mod 3) = 0) or (i = 1) then
           Sudobox.Canvas.Pen.Width := 3
       else
           Sudobox.Canvas.Pen.Width := 1;

       SudoBox.Canvas.MoveTo((i - 1) * 50 + 1, 450);
       Sudobox.Canvas.LineTo((i - 1) * 50 + 1, 0);

       SudoBox.Canvas.MoveTo(450, (i - 1) * 50 + 1);
       Sudobox.Canvas.LineTo(0, (i - 1) * 50 + 1);
    end;

    // painting selected cell
    Sudobox.Canvas.Pen.Width := 0;

     Sudobox.Canvas.Brush.Color := COL_CELL_SEL;
    if  not ((selectedCell.X = 0) and (selectedCell.Y = 0)) then
    begin
        SudoBox.Canvas.Rectangle( (selectedCell.X - 1) * 50 + 1,  (selectedCell.Y - 1) * 50 + 1,
            (selectedCell.X - 1) * 50 + 51, (selectedCell.Y - 1) * 50 + 51) ;
    end;

    Sudobox.Canvas.Brush.Color := COL_BOX_BG;

   // drawing numbers from valArr
   Sudobox.Canvas.Font.Name := 'Verdana';
   Sudobox.Canvas.Font.Size := 18;

    for i := 1 to 9 do
    for j := 1 to 9 do
    begin
        if (valArr[i, j] = 0 ) then continue;
        if ( ( ((selectedCell.X) ) = i) and (((selectedCell.Y) )= j) ) then
        begin
            Sudobox.Canvas.Brush.Color := COL_CELL_SEL;
            SudoBox.Canvas.Font.Size := 20;

        end
        else
        begin
            Sudobox.Canvas.Brush.Color := COL_BOX_BG;
            SudoBox.Canvas.Font.Size := 18;
        end;
        Sudobox.Canvas.TextOut( (i - 1) * 50 + 18 , (j - 1) * 50 + Sudobox.Canvas.Font.Size - 6 ,
            IntToStr(valArr[i, j]));

    end;

end;

// ** just for fun - message effects ~2 sec
procedure TfrmMain.Timer1Timer(Sender: TObject);

begin
  inc(effectCount);
  if dir then
    fontsize := fontsize + 1;
  if not dir then
    fontsize := fontsize - 1;

  if fontsize > 18 then dir := false;
  if fontsize < 15 then dir := true;

  if effectCount > 20 then
  begin
    fontsize := 16;
    timer1.Enabled := False;
    effectCount := 0;
  end;

  lblTitle.Font.Size := fontsize;
  lblTitleSh.Font.Size := fontsize;
  lblTitleSh2.Font.Size := fontsize;

end;


end.


