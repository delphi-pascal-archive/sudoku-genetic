unit uGenetic;

interface
uses Classes, SysUtils, Dialogs;

type TValArr = array [1..9, 1..9] of byte;
type
  TChromosome = class
     private
       function GetSquareFixedCount(iSquare: byte): byte;
      public
       RowGenes: TValArr;
       FitnessValue: real;
       SquareFixedGenes: TValArr;
       // only for elite
       EliteAge: longint;

       ///
       ///  first index is number of square
       ///  second param is elements of this square in sequence
       ///  need for performing mutation and Crossingover
       ///
       SquareGenes: TValArr;

       constructor Create(sampleChromosome: TChromosome);
       destructor Free();

       procedure Generate();
       procedure GenerateSquare(iSquare: byte);


       procedure Mutate(MutateMethod: byte = 0);
       procedure CrossWith(Chrome: TChromosome);
       procedure Cross(MotherChrome, FatherChrome: TChromosome);
       function CalculateFitness(): real;

       //-------cut-----------
       function SqToN(i, j: byte): byte;

       procedure SaveRowGenes(var valArr: TValArr);
       procedure SavetoFile(fName: string);
       procedure LoadfromFile(fName: string);
       procedure LoadRowGenes(valArr: TValArr);

       function isFixed(i, j: byte): boolean;
       // copy Chromosome to destChrome
       procedure CopyChrome(var destChrome: TChromosome);

  end;  { TChromosome }

type
  TPopulation = class
    public
      PopulationCount: byte;

      CurrentPopulation: array [1..30] of TChromosome;
      BestPopulation: array [1..5] of TChromosome;
      logOperation: string;

      constructor Create(PopulationCount: byte);
      destructor Free();



end;

const NINE_FUC = 362880;   // 9! const value


implementation


{ TChromosome }

////
/// returns 0 if Chromosome is the best of the best
/// smaller value >>
function TChromosome.CalculateFitness: real;
var
  n, i, j: integer;
  rowSum,  colSum: integer;
  rowSumAll,  colSumAll: integer;
  rowProd, colProd: integer;
  rowProdAll, colProdAll: real;
  rowMissed, colMissed: integer;
  HasMissed: boolean;
  strMsg: string;
  squareSum, squareSumAll: integer;
begin
  // 1: row and column sum should be equal to 45
    SaveRowGenes(RowGenes);

    RowSumAll := 0;
    rowSum := 0;
    for i := 1 to 9 do
    begin
       rowSum := 0;
       for j := 1 to 9 do
       rowSum := rowSum + RowGenes[i, j];
       rowSumAll := rowSumAll + abs(45 - rowSum);

    end;

    colSum := 0;
    colSumAll := 0;
    for j := 1 to 9 do
    begin
       colSum := 0;
       for i := 1 to 9 do
         colSum := colSum + RowGenes[i, j];
       colSumAll := colSumAll + abs(45 - colSum);
    end;

     // 2: row and column product should be equal to 9!
      rowProd := 1;
      rowProdAll := 0;
    for i := 1 to 9 do
    begin
       rowProd := 1;
       for j := 1 to 9 do
       rowProd := rowProd * RowGenes[i, j];
       rowProd := abs(NINE_FUC - rowProd);
       rowProdAll := rowProdAll + sqrt(rowProd);

    end;

    colProd := 1;
    colProdAll := 0;
    for j := 1 to 9 do
    begin
       colProd := 1;
       for i := 1 to 9 do
         colProd := colProd * RowGenes[i, j];
       colProd := abs(NINE_FUC - colProd);
       colProdAll := colProdAll + sqrt(colProd);
    end;

  // 3:  calculate  the  number of  missing numbers in each row (xi) and column (xj)
   // numbers
   rowMissed := 0;
      for i := 1 to 9 do
      begin
       for n := 1 to 9 do
       begin
         HasMissed := True;
         for j := 1 to 9 do
            if RowGenes[i ,j] = n then
            begin
              HasMissed := false;
              break;
            end;
          if HasMissed then inc(rowMissed);
       end;
    end;

    colMissed := 0;
     for i := 1 to 9 do
      begin
       for n := 1 to 9 do
       begin
         HasMissed := True;
         for j := 1 to 9 do
            if RowGenes[j ,i] = n then
            begin
              HasMissed := false;
              break;
            end;
          if HasMissed then inc(colMissed);

       end;
    end;

    // experimental: square sum
  {  squareSum := 0; squareSumAll := 0;
    for i := 1 to 9 do
    begin
       squareSum := 0;
       for j := 1 to 9 do
         squareSum := squareSum + SquareGenes[i, j];
       squareSumAll := squareSumAll + abs(45 - squareSum);

    end;
   }
       Result := (12* (rowSumAll + colSumAll) +  33 * (rowMissed + colMissed)) / 100
   +      (rowProdAll  + colProdAll) / 1000;
 //   Result := (12* (rowSumAll + colSumAll) +  33 * (rowMissed + colMissed)) / 100;
 //   +      (rowProdAll  + colProdAll) / 1000;
    FitnessValue := Result;
end;

procedure TChromosome.CopyChrome(var destChrome: TChromosome);
var
  i, j: byte;
begin
  //
  for i := 1 to 9 do
    for j := 1 to 9 do
    begin
      SquareGenes[i, j] := destChrome.SquareGenes[i, j];
      SquareFixedGenes[i, j] := destChrome.SquareFixedGenes[i, j];
      RowGenes[i, j] := destChrome.RowGenes[i, j];
    end;

  FitnessValue := destChrome.FitnessValue;
  EliteAge := 0;
end;

constructor TChromosome.Create(sampleChromosome: TChromosome);
var
  i, j: Integer;
begin
//
  FitnessValue := MaxLongint;
  EliteAge := 0;
  for i := 1 to 9 do
    for j := 1 to 9 do
    begin
      SquareGenes[i, j] := 0;
      SquareFixedGenes[i, j] := 0;
      if sampleChromosome <> nil then
      begin
        SquareFixedGenes[i, j] := sampleChromosome.SquareGenes[i, j];
        SquareGenes[i, j] := sampleChromosome.SquareGenes[i, j];
      end;
    end;

end;

procedure TChromosome.Generate;
var i: integer;
begin
//
  for i := 1 to 9 do
    GenerateSquare(i);
    EliteAge := 0;
end;

// generates a 1..9 random sequence in Square with index iSquare
procedure TChromosome.GenerateSquare(iSquare: byte);
var
  i: byte;
  curNum: byte;
  curInd: byte;
  s: string;
  fixArr: array [1..9] of boolean;
begin


  for i := 1 to 9 do fixArr[i] := false;
  // выделяем фиксированные числа в массиве флагов
  for i := 1 to 9 do
    if isFixed(iSquare, i) then
      fixArr[SquareFixedGenes[iSquare, i]] := true;


  for i := 1 to 9 do
  if  isFixed(iSquare, i) then continue
  else
  begin
    curNum := random(9) + 1;
    while fixArr[curNum] do
       curNum := random(9) + 1;
    SquareGenes[iSquare, i] := CurNum;
    fixArr[curNum] := true;
  end;


 // experimental
 {
  for i := 1 to 9 do
    if  not isFixed(iSquare, i) then
      SquareGenes[iSquare, i] := random(9) + 1;
    }
end;

//
//  CROSSINGOVER Chromosome + Chromosome = Love? ^_^
//
procedure TChromosome.Cross(MotherChrome, FatherChrome: TChromosome);
  var
  i, j: byte;
  curNum: byte;
begin
  //
 curNum := random(2) + 1;

//  curNum := 1; // !!temp

  if MotherChrome = nil then
  ShowMessage('BIG WARNING!!! MotherChrome missed!');
  if FatherChrome = nil then
  ShowMessage('BIG WARNING!!! fatherChrome missed!');

  case curNum of
    1: begin
         // exchanging every second block
         for i := 1 to 9 do
           if (i mod 2) = 0 then
           begin
             for j := 1 to 9 do
               SquareGenes[i, j] := MotherChrome.SquareGenes[i, j];
           end
           else
             for j := 1 to 9 do
              SquareGenes[i, j] := FatherChrome.SquareGenes[i, j];

       end;

    2:  begin
        for i := 1 to 4 do
           for j := 1 to 9 do
              SquareGenes[i, j] := MotherChrome.SquareGenes[i, j];
        for i := 5 to 9 do
           for j := 1 to 9 do
               SquareGenes[i, j] := FatherChrome.SquareGenes[i, j];


      end;
      (*
    3:  begin
             for i := 1 to 4 do
           for j := 1 to 9 do
              SquareGenes[i, j] := FatherChrome.SquareGenes[i, j];
        for i := 5 to 9 do
           for j := 1 to 9 do
               SquareGenes[i, j] := MotherChrome.SquareGenes[i, j];
        end;
        *)

  end;

end;

procedure TChromosome.CrossWith(Chrome: TChromosome);
var
  i, j: byte;
  curNum: byte;
begin
  //
 curNum := random(3) + 1;

//  curNum := 1; // !!temp

  case curNum of
    1: begin
         // exchanging every second block
         for i := 1 to 9 do
           if (i mod 2) = 0 then
           begin
             for j := 1 to 9 do
             if not isFixed(i, j) then
               SquareGenes[i, j] := Chrome.SquareGenes[i, j];
           end;

       end;
    2:  begin
     for i := 1 to 4 do

           begin
             for j := 1 to 9 do
             if not isFixed(i, j) then
               SquareGenes[i, j] := Chrome.SquareGenes[i, j];
           end;

      end;
    3:  begin
              for i := 5 to 9 do

           begin
             for j := 1 to 9 do
             if not isFixed(i, j) then
               SquareGenes[i, j] := Chrome.SquareGenes[i, j];
           end;

     end;
  end;
end;

destructor TChromosome.Free;
begin
  //
end;

// return a number of non-zero genes
function TChromosome.GetSquareFixedCount(iSquare: byte): byte;
var i: integer;
begin
  Result := 0;
  for i := 1 to 9 do
    if isFixed(iSquare, i) then
      inc(Result);
end;

function TChromosome.isFixed(i, j: byte): boolean;
begin
  Result := (SquareFixedGenes[i, j] <> 0) ;
end;

procedure TChromosome.LoadfromFile(fName: string);
var
    i, j: byte;
    f: TextFile;
    ch: char;
begin
    AssignFile(f, fName);
    Reset(F);
    for i := 1 to 9 do
    for j := 1 to 9 do
    begin
        Read(f, ch);
        SquareGenes[i, j] := StrToInt(ch);
        SquareFixedGenes[i, j] := SquareGenes[i, j];
    end;
    CloseFile(f);
  //
  SaveRowGenes(RowGenes);
end;

// loads genes to chromosome from valArray
procedure TChromosome.LoadRowGenes(valArr: TValArr);
var
  i, j, x, m, n: byte;
  tempGenes: array [1..81] of byte;
begin
 for i := 1 to 9 do
  for j := 1 to 9 do
  begin
      tempGenes[ 9 * (i - 1) + j] := ValArr[i, j];
      RowGenes[i, j] := valArr[i, j];
  end;

   begin
   x := 1;
   for i := 1 to 3 do
   for j := 1 to 3 do
   for m := 1 to 3 do
   for n := 1 to 3 do
      begin
        SquareGenes[3 * (i - 1) + m, 3 * (j - 1) + n] := tempGenes[x];
        SquareFixedGenes[3 * (i - 1) + m, 3 * (j - 1) + n] := tempGenes[x];
        inc(x);
      end;
   end;
end;

//
// MUUUUUUUTATE.... Chromosome >> chROMoSOMM_E~
//
procedure TChromosome.Mutate(MutateMethod: byte = 0);
var
 // i, j: byte;
  curNum: byte;
  sqNum: byte;
  indStart: byte;
  IndEnd, IndEnd2: byte;
  iGene: byte;
  tmpGene: byte;
begin
  //
   Randomize();
  if MutateMethod = 0 then
    curNum := random(2) + 1
  else
    curNum := MutateMethod;


  //MutateMethod := 1;
  curNum := 1; //!!

  sqNum := random(9) + 1; // choosing block for mutation
//  Showmessage(intToStr(sqNum));

  if GetSquareFixedCount(sqNum) > 7 then
  begin
    Exit;
  end;

//  curnum := 1;
  case curNum of
    1: begin
         // swapping two genes

           IndStart := random(9) + 1;
           while (isFixed (sqNum, IndStart)) do
             IndStart := random(9) + 1;

           // choosing another gene to swap
       {    for iGene := 1 to 9 do
           begin
             if (IndStart <> iGene) and (not isFixed(sqNum, iGene)) then
             begin
               IndEnd := iGene;
               break;
             end;
           end;
           }
           // version 2 - 4 may 2009 2:28 am
            IndEnd := random(9) + 1;
            while (isFixed (sqNum, IndStart)) and (IndEnd = IndStart) do
             IndEnd := random(9) + 1;

           //Showmessage(intToStr(indStart) + '->>' + intToStr(indEnd));
           tmpGene := SquareGenes[sqNum, indStart];
           SquareGenes[sqNum, indStart] := SquareGenes[sqNum, indEnd];
           SquareGenes[sqNum, indEnd] := tmpGene;



       end;
    2:  begin
          if GetSquareFixedCount(sqNum) > 6 then
          begin
            Self.Mutate(1);
            Exit;
          end;

           // * swapping three genes

           IndStart := random(9) + 1;
           while (isFixed (sqNum, IndStart)) do
             IndStart := random(9) + 1;

           // choosing another gene to swap
           for iGene := 1 to 9 do
           begin
             if (IndStart <> iGene) and (not isFixed(sqNum, iGene)) then
             begin
               IndEnd := iGene;
               break;
             end;
           end;

           tmpGene := SquareGenes[sqNum, indStart];
           SquareGenes[sqNum, indStart] := SquareGenes[sqNum, indEnd];
           SquareGenes[sqNum, indEnd] := tmpGene;

               // choosing third gene to swap
           for iGene := 1 to 9 do
           begin
             if (IndStart <> iGene) and (IndEnd2 <> iGene) and
               (not isFixed(sqNum, iGene)) then
             begin
               IndEnd2 := iGene;
              // break;
             end;
           end;

           tmpGene := SquareGenes[sqNum, indEnd];
           SquareGenes[sqNum, indEnd] := SquareGenes[sqNum, indEnd2];
           SquareGenes[sqNum, indEnd2] := tmpGene;

       end;

    3:  begin end;
  end;

end;

procedure TChromosome.SavetoFile(fName: string);
var
    i, j: integer;
    ffile: TextFile;
begin
    AssignFile(ffile, fName);
    Rewrite(ffile);
    for i := 1 to 9 do
    for j := 1 to 9 do
        Write(ffile, SquareGenes[i, j]);

    CloseFile(ffile);
end;


procedure TChromosome.SaveRowGenes(var valArr: TValArr);
var
  i, j, x,  m, n: byte;
  y: integer;
  Genes: array [1..81] of byte;
begin
 for i := 1 to 9 do
     for x := 1 to 3 do
     for y := 1 to 3 do
       Genes[ 9 * (i - 1) + 3 * (x - 1) + y] := SquareGenes[i, 3 * (x-1) + y];
   x := 1;
   for i := 1 to 3 do
   for j := 1 to 3 do
   for m := 1 to 3 do
   for n := 1 to 3 do
      begin
        valArr[3 * (i - 1) + m, 3 * (j - 1) + n] := Genes[x];
        inc(x);
      end;
  //
end;

function TChromosome.SqToN(i, j: byte): byte;
begin
  Result := 9 * (i - 1) + j;
end;

{ TPopulation }
// creating population
constructor TPopulation.Create(PopulationCount: byte);
begin

end;

destructor TPopulation.Free;
begin

end;

end.

