unit PartialSwarmInt;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Samples.Spin, Vcl.Grids,
  PSO_Engine, System.Math;

type
// Инициализация всех компонентов формы
  TPartialSwarm = class(TForm)
    Label1: TLabel;
    cblFunction: TComboBox;
    Label2: TLabel;
    seDimension: TSpinEdit;
    Label3: TLabel;
    seSwarmSize: TSpinEdit;
    Label4: TLabel;
    selteration: TSpinEdit;
    btnRun: TButton;
    btnClear: TButton;
    PaintBox: TPaintBox;
    lblStatus: TLabel;
    MemoBest: TMemo;

    Label6: TLabel;
    edSelfConfidence: TEdit;
    Label7: TLabel;
    edSocialConfidence: TEdit;
    Label8: TLabel;
    edMaxVelocity: TEdit;
    Label9: TLabel;
    edSearchRange: TEdit;
    Label10: TLabel;
    edInertiaWeight: TEdit;
    Label11: TLabel;
    edInertiaStart: TEdit;
    Label12: TLabel;
    edInertiaEnd: TEdit;
    Label13: TLabel;
    edPenaltyRatio: TEdit;
    Label14: TLabel;
    seMaxIterWithoutImprovement: TSpinEdit;
    Label15: TLabel;
    seRuns: TSpinEdit;
    cbAdaptiveWeight: TCheckBox;
    cbMutations: TCheckBox;
    cbPenalty: TCheckBox;
    StringGrid1: TStringGrid;
    Label5: TLabel;
    btnSave: TButton;

    procedure FormCreate(Sender: TObject);
    procedure cbAdaptiveWeightClick(Sender: TObject);
    procedure cbMutationsClick(Sender: TObject);
    procedure cbPenaltyClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnClearClick(Sender: TObject);
    procedure PaintBoxPaint(Sender: TObject);
    procedure cblFunctionChange(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);

  private
    RunsCount: Integer;                          // Количество запусков
    LastResults: array of Double;                // Результаты последнего расчёта
    LastFuncName: string;                        // Имя последней функции
    LastStats: string;                           // Статистика последнего расчёта
    procedure DrawConvergenceGraph;              // Отрисовка графика сходимости
    procedure SetupFunctionParameters(FuncIndex: Integer; var FuncName: string);
    function GetBestPointString: string;         // Строка с координатами лучшей точки
    procedure SaveResultsToFile;                 // Сохранение результатов в файл
  public
    { Public declarations }
  end;

var
  PartialSwarm: TPartialSwarm;

implementation

{$R *.dfm}

// ============================================================
// ФИКСИРОВАННЫЙ РАЗДЕЛИТЕЛЬ ДРОБНОЙ ЧАСТИ
// ============================================================
var
  OldDecimalSeparator: Char;
  OldThousandSeparator: Char;

// Устанавливаем точку как разделитель дробной части
procedure SetDecimalSeparatorToPoint;
begin
  OldDecimalSeparator := FormatSettings.DecimalSeparator;
  OldThousandSeparator := FormatSettings.ThousandSeparator;

  FormatSettings.DecimalSeparator := '.';
  FormatSettings.ThousandSeparator := ',';
end;

// Восстанавливаем исходные разделители
procedure RestoreDecimalSeparator;
begin
  FormatSettings.DecimalSeparator := OldDecimalSeparator;
  FormatSettings.ThousandSeparator := OldThousandSeparator;
end;

// ============================================================
// ЦЕЛЕВЫЕ ФУНКЦИИ (21 штука)
// ============================================================

// 0. Сферическая функция
function Сферическая(x: array of Double): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to Length(x) - 1 do
    Result := Result + x[i] * x[i];
end;

// 1. Функция Розенброка
function Розенброка(x: array of Double): Double;
var
  i: Integer;
begin
  Result := 0;
  if Length(x) >= 2 then
  begin
    for i := 0 to Length(x) - 2 do
      Result := Result + 100 * Sqr(x[i+1] - Sqr(x[i])) + Sqr(1 - x[i]);
  end;
end;

// 2. Функция Растригина
function Растригина(x: array of Double): Double;
var
  i: Integer;
begin
  Result := 10 * Length(x);
  for i := 0 to Length(x) - 1 do
    Result := Result + x[i] * x[i] - 10 * Cos(2 * Pi * x[i]);
end;

// 3. Функция Гриванк
function Гриванк(x: array of Double): Double;
var
  i: Integer;
  Sum: Double;
  Prod: Double;
begin
  Sum := 0;
  Prod := 1;
  for i := 0 to Length(x) - 1 do
  begin
    Sum := Sum + x[i] * x[i];
    Prod := Prod * Cos(x[i] / Sqrt(i + 1));
  end;
  Result := 1 + Sum / 4000 - Prod;
end;

// 4. Функция Экли
function Экли(x: array of Double): Double;
var
  i: Integer;
  Sum1, Sum2: Double;
  n: Integer;
begin
  n := Length(x);
  if n = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Sum1 := 0;
  Sum2 := 0;
  for i := 0 to n - 1 do
  begin
    Sum1 := Sum1 + x[i] * x[i];
    Sum2 := Sum2 + Cos(2 * Pi * x[i]);
  end;
  Result := -20 * Exp(-0.2 * Sqrt(Sum1 / n))
            - Exp(Sum2 / n)
            + 20 + Exp(1);
end;

// 5. Функция Швефеля
function Швефеля(x: array of Double): Double;
var
  i: Integer;
  Sum: Double;
begin
  Sum := 0;
  for i := 0 to Length(x) - 1 do
    Sum := Sum + x[i] * Sin(Sqrt(Abs(x[i])));
  Result := 418.9829 * Length(x) - Sum;
end;

// 6. Функция Леви
function Леви(x: array of Double): Double;
var
  i: Integer;
  n: Integer;
begin
  n := Length(x);
  if n = 0 then
  begin
    Result := 0;
    Exit;
  end;

  Result := Sqr(Sin(3 * Pi * x[0]));
  for i := 0 to n - 2 do
    Result := Result + Sqr(x[i] - 1) * (1 + Sqr(Sin(3 * Pi * x[i + 1])));
  Result := Result + Sqr(x[n - 1] - 1) * (1 + Sqr(Sin(2 * Pi * x[n - 1])));
end;

// 7. Функция Химмельблау
function Химмельблау(x: array of Double): Double;
begin
  if Length(x) < 2 then
    Result := 1000
  else if Length(x) = 2 then
    Result := Sqr(x[0]*x[0] + x[1] - 11) + Sqr(x[0] + x[1]*x[1] - 7)
  else
    Result := Sqr(x[0]*x[0] + x[1] - 11) + Sqr(x[0] + x[1]*x[1] - 7) +
              (Length(x) - 2) * 1000;
end;

// 8. Функция Михалевича
function Михалевича(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
  m: Double;
begin
  n := Length(x);
  // Параметр m — обычно 10, не зависит от размерности
  m := 10;
  Sum := 0;
  for i := 0 to n - 1 do
  begin
    // i+1 — потому что в формуле индекс идёт с 1
    Sum := Sum + Sin(x[i]) * Power(Sin((i + 1) * x[i] * x[i] / Pi), 2 * m);
  end;
  Result := -Sum;
end;

// 9. Функция Шаффера N.2
function ШаффераN2(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
  num, den: Double;
begin
  n := Length(x);
  if n < 2 then
  begin
    Result := 1000;
    Exit;
  end;

  Sum := 0;
  for i := 0 to n - 2 do
  begin
    num := Sqr(Sin(x[i]*x[i] - x[i+1]*x[i+1])) - 0.5;
    den := Sqr(1 + 0.001 * (x[i]*x[i] + x[i+1]*x[i+1]));
    Sum := Sum + 0.5 + num / den;
  end;
  Result := Sum;
end;

// 10. Функция "Падающая волна"
function ПадающаяВолна(x: array of Double): Double;
var
  r2: Double;
begin
  if Length(x) < 2 then
  begin
    Result := 1000;
    Exit;
  end;
  r2 := x[0]*x[0] + x[1]*x[1];
  if r2 = 0 then
    Result := -1
  else
    Result := -(1 + Cos(12 * Sqrt(r2))) / (0.5 * r2 + 2);
end;

// 11. Функция "Альпийская N.1"
function АльпийскаяN1(x: array of Double): Double;
var
  i: Integer;
  Sum: Double;
begin
  Sum := 0;
  for i := 0 to Length(x) - 1 do
    Sum := Sum + Abs(x[i] * Sin(x[i]) + 0.1 * x[i]);
  Result := Sum;
end;

// 12. Функция Брауна
function Брауна(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
begin
  n := Length(x);
  Sum := 0;
  for i := 0 to n - 2 do
  begin
    Sum := Sum + Power(Sqr(x[i]), x[i+1]*x[i+1] + 1) +
                  Power(Sqr(x[i+1]), x[i]*x[i] + 1);
  end;
  Result := Sum;
end;

// 13. Функция Пауэлла
function Пауэлла(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
begin
  n := Length(x);
  Sum := 0;
  i := 0;
  while i <= n - 4 do
  begin
    Sum := Sum + Sqr(x[i] + 10*x[i+1]) +
               5 * Sqr(x[i+2] - x[i+3]) +
               Sqr(x[i+1] - 2*x[i+2]) +
               10 * Sqr(x[i] - x[i+3]);
    Inc(i, 4);
  end;
  Result := Sum;
end;

// 14. Функция Диксона-Прайса
function ДиксонаПрайса(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
begin
  n := Length(x);
  if n < 2 then
  begin
    Result := 1000;
    Exit;
  end;

  Sum := Sqr(x[0] - 1);
  for i := 1 to n - 1 do
    Sum := Sum + (i + 1) * Sqr(2 * x[i]*x[i] - x[i-1]);
  Result := Sum;
end;

// 15. Функция Леви N.13
function ЛевиN13(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
begin
  n := Length(x);
  if n < 2 then
  begin
    Result := 1000;
    Exit;
  end;

  Sum := Sqr(Sin(3 * Pi * x[0]));
  for i := 0 to n - 2 do
    Sum := Sum + Sqr(x[i] - 1) * (1 + Sqr(Sin(3 * Pi * x[i+1])));
  Sum := Sum + Sqr(x[n-1] - 1) * (1 + Sqr(Sin(2 * Pi * x[n-1])));
  Result := 0.1 * Sum;
end;

// 16. Функция Бочачевского N.1
function БочачевскогоН1(x: array of Double): Double;
var
  i, n: Integer;
  Sum: Double;
begin
  n := Length(x);
  if n < 2 then
  begin
    Result := 1000;
    Exit;
  end;

  Sum := 0;
  for i := 0 to n - 2 do
    Sum := Sum + x[i]*x[i] + 2*x[i+1]*x[i+1] -
           0.3 * Cos(3 * Pi * x[i]) - 0.4 * Cos(4 * Pi * x[i+1]) + 0.7;
  Result := Sum;
end;

// 17. Функция "Perm 0, D, Beta"
function Перм0ДБета(x: array of Double): Double;
var
  i, j, n: Integer;
  Sum, innerSum, term: Double;
begin
  n := Length(x);
  Sum := 0;
  for i := 1 to n do
  begin
    innerSum := 0;
    for j := 1 to n do
    begin
      term := Power(j, i) + 0.5;
      innerSum := innerSum + (term * (Power(x[j-1], i) - Power(1.0/j, i)));
    end;
    Sum := Sum + Sqr(innerSum);
  end;
  Result := Sum;
end;

// 18. Вращённый гиперэллипсоид
function ВращённыйГиперэллипсоид(x: array of Double): Double;
var
  i, j, n: Integer;
  Sum, inner: Double;
begin
  n := Length(x);
  Sum := 0;
  for i := 0 to n - 1 do
  begin
    inner := 0;
    for j := 0 to i do
      inner := inner + x[j]*x[j];
    Sum := Sum + inner;
  end;
  Result := Sum;
end;

// 19. Сумма разных степеней
function СуммаРазныхСтепеней(x: array of Double): Double;
var
  i: Integer;
  Sum: Double;
begin
  Sum := 0;
  for i := 0 to Length(x) - 1 do
    Sum := Sum + Power(Abs(x[i]), i + 2);
  Result := Sum;
end;

// 20. Функция Трид
function Трид(x: array of Double): Double;
var
  i: Integer;
  Sum1, Sum2: Double;
begin
  Sum1 := 0;
  Sum2 := 0;
  for i := 0 to Length(x) - 1 do
    Sum1 := Sum1 + Sqr(x[i] - 1);
  for i := 1 to Length(x) - 1 do
    Sum2 := Sum2 + x[i] * x[i-1];
  Result := Sum1 - Sum2;
end;

// ============================================================
// ПОЛУЧЕНИЕ КООРДИНАТ ЛУЧШЕЙ ТОЧКИ
// ============================================================
function TPartialSwarm.GetBestPointString: string;
var
  i: Integer;
begin
  Result := '';
  if Length(GlobalBestPosition) = 0 then
  begin
    Result := 'Нет данных';
    Exit;
  end;

  Result := '(';
  for i := 0 to Length(GlobalBestPosition) - 1 do
  begin
    Result := Result + FloatToStrF(GlobalBestPosition[i], ffFixed, 10, 6);
    if i < Length(GlobalBestPosition) - 1 then
      Result := Result + ', ';
  end;
  Result := Result + ')';
end;

// ============================================================
// НАСТРОЙКА ПАРАМЕТРОВ ФУНКЦИИ
// ============================================================
procedure TPartialSwarm.SetupFunctionParameters(FuncIndex: Integer; var FuncName: string);
var
  i: Integer;
begin
  Dimension := seDimension.Value;
  SwarmSize := seSwarmSize.Value;
  MaxIter := selteration.Value;

  SelfConfidence := StrToFloat(edSelfConfidence.Text);
  SocialConfidence := StrToFloat(edSocialConfidence.Text);
  MaxVelocity := StrToFloat(edMaxVelocity.Text);
  SearchRange := StrToFloat(edSearchRange.Text);
  PenaltyRatio := StrToFloat(edPenaltyRatio.Text);
  MaxIterWithoutImprovement := seMaxIterWithoutImprovement.Value;

  SetLength(MinValues, Dimension);
  SetLength(MaxValues, Dimension);

  // Устанавливаем диапазоны для каждой функции
  case FuncIndex of
    0: begin
         FuncName := 'Сферическая';
         FitnessFunction := Сферическая;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    1: begin
         FuncName := 'Розенброка';
         FitnessFunction := Розенброка;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    2: begin
         FuncName := 'Растригина';
         FitnessFunction := Растригина;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    3: begin
         FuncName := 'Гриванк';
         FitnessFunction := Гриванк;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    4: begin
         FuncName := 'Экли';
         FitnessFunction := Экли;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    5: begin
         FuncName := 'Швефеля';
         FitnessFunction := Швефеля;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -500.0;
           MaxValues[i] := 500.0;
         end;
         MaxVelocity := 100.0;
         SearchRange := 500.0;
       end;
    6: begin
         FuncName := 'Леви';
         FitnessFunction := Леви;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    7: begin
         FuncName := 'Химмельблау';
         FitnessFunction := Химмельблау;
         if Dimension > 2 then
         begin
           ShowMessage('Функция Химмельблау определена только для 2D. Размерность будет установлена в 2.');
           Dimension := 2;
           seDimension.Value := 2;
         end;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -10.0;
           MaxValues[i] := 10.0;
         end;
       end;
    8: begin
         FuncName := 'Михалевича';
         FitnessFunction := Михалевича;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := 0.0;
           MaxValues[i] := Pi;
         end;
       end;
    9: begin
         FuncName := 'Шаффера N.2';
         FitnessFunction := ШаффераN2;
         if Dimension < 2 then
         begin
           Dimension := 2;
           seDimension.Value := 2;
         end;
         for i := 0 to Dimension - 1 do
         begin
           MinValues[i] := -100.0;
           MaxValues[i] := 100.0;
         end;
       end;
    10: begin
          FuncName := 'Падающая волна';
          FitnessFunction := ПадающаяВолна;
          if Dimension > 2 then
          begin
            Dimension := 2;
            seDimension.Value := 2;
          end;
          if Dimension < 2 then
          begin
            Dimension := 2;
            seDimension.Value := 2;
          end;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -5.12;
            MaxValues[i] := 5.12;
          end;
        end;
    11: begin
          FuncName := 'Альпийская N.1';
          FitnessFunction := АльпийскаяN1;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -10.0;
            MaxValues[i] := 10.0;
          end;
        end;
    12: begin
          FuncName := 'Брауна';
          FitnessFunction := Брауна;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -1.0;
            MaxValues[i] := 4.0;
          end;
        end;
    13: begin
          FuncName := 'Пауэлла';
          FitnessFunction := Пауэлла;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -4.0;
            MaxValues[i] := 5.0;
          end;
        end;
    14: begin
          FuncName := 'Диксона-Прайса';
          FitnessFunction := ДиксонаПрайса;
          if Dimension < 2 then
          begin
            Dimension := 2;
            seDimension.Value := 2;
          end;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -10.0;
            MaxValues[i] := 10.0;
          end;
        end;
    15: begin
          FuncName := 'Леви N.13';
          FitnessFunction := ЛевиN13;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -10.0;
            MaxValues[i] := 10.0;
          end;
        end;
    16: begin
          FuncName := 'Бочачевского N.1';
          FitnessFunction := БочачевскогоН1;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -100.0;
            MaxValues[i] := 100.0;
          end;
        end;
    17: begin
          FuncName := 'Перм 0, D, Бета';
          FitnessFunction := Перм0ДБета;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -Dimension;
            MaxValues[i] := Dimension;
          end;
        end;
    18: begin
          FuncName := 'Вращённый гиперэллипсоид';
          FitnessFunction := ВращённыйГиперэллипсоид;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -65.536;
            MaxValues[i] := 65.536;
          end;
        end;
    19: begin
          FuncName := 'Сумма разных степеней';
          FitnessFunction := СуммаРазныхСтепеней;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -1.0;
            MaxValues[i] := 1.0;
          end;
        end;
    20: begin
          FuncName := 'Трид';
          FitnessFunction := Трид;
          for i := 0 to Dimension - 1 do
          begin
            MinValues[i] := -Dimension * Dimension;
            MaxValues[i] := Dimension * Dimension;
          end;
        end;
  end;

  if cbAdaptiveWeight.Checked then
  begin
    InertiaStart := StrToFloat(edInertiaStart.Text);
    InertiaEnd := StrToFloat(edInertiaEnd.Text);
  end
  else
    InertiaWeight := StrToFloat(edInertiaWeight.Text);
end;

// ============================================================
// СОХРАНЕНИЕ РЕЗУЛЬТАТОВ В ФАЙЛ
// ============================================================
procedure TPartialSwarm.SaveResultsToFile;
var
  SaveDialog: TSaveDialog;
  FileName: string;
  i: Integer;
  SL: TStringList;
begin
  if Length(LastResults) = 0 then
  begin
    ShowMessage('Нет данных для сохранения. Сначала выполните расчеты.');
    Exit;
  end;

  SaveDialog := TSaveDialog.Create(Self);
  try
    SaveDialog.Title := 'Сохранить результаты';
    SaveDialog.Filter := 'Текстовые файлы (*.txt)|*.txt|Все файлы (*.*)|*.*';
    SaveDialog.DefaultExt := 'txt';
    SaveDialog.FileName := Format('PSO_Results_%s_%s.txt', [
      LastFuncName,
      FormatDateTime('yyyy-mm-dd_hh-nn-ss', Now)
    ]);

    if SaveDialog.Execute then
    begin
      FileName := SaveDialog.FileName;

      if FileName = '' then
      begin
        ShowMessage('Имя файла не может быть пустым.');
        Exit;
      end;

      SL := TStringList.Create;
      try
        SL.Add('========================================');
        SL.Add('РЕЗУЛЬТАТЫ РОЕВОЙ ОПТИМИЗАЦИИ (PSO)');
        SL.Add('========================================');
        SL.Add('');
        SL.Add('ДАТА И ВРЕМЯ: ' + DateTimeToStr(Now));
        SL.Add('');
        SL.Add('----------------------------------------');
        SL.Add('ПАРАМЕТРЫ АЛГОРИТМА:');
        SL.Add('----------------------------------------');
        SL.Add(Format('Функция: %s', [LastFuncName]));
        SL.Add(Format('Размерность: %d', [seDimension.Value]));
        SL.Add(Format('Размер роя: %d', [seSwarmSize.Value]));
        SL.Add(Format('Макс. итераций: %d', [selteration.Value]));
        SL.Add(Format('Число запусков: %d', [seRuns.Value]));
        SL.Add(Format('c1 (SelfConfidence): %s', [edSelfConfidence.Text]));
        SL.Add(Format('c2 (SocialConfidence): %s', [edSocialConfidence.Text]));
        SL.Add(Format('Макс. скорость: %s', [edMaxVelocity.Text]));
        SL.Add(Format('Диапазон поиска: %s', [edSearchRange.Text]));
        SL.Add(Format('Вес инерции: %s', [edInertiaWeight.Text]));
        SL.Add(Format('Адаптивный вес: %s', [BoolToStr(cbAdaptiveWeight.Checked, True)]));
        SL.Add(Format('Нач. вес: %s', [edInertiaStart.Text]));
        SL.Add(Format('Кон. вес: %s', [edInertiaEnd.Text]));
        SL.Add(Format('Мутации: %s', [BoolToStr(cbMutations.Checked, True)]));
        SL.Add(Format('Итер. без улучш.: %d', [seMaxIterWithoutImprovement.Value]));
        SL.Add(Format('Штрафы: %s', [BoolToStr(cbPenalty.Checked, True)]));
        SL.Add(Format('Коэф. штрафа: %s', [edPenaltyRatio.Text]));
        SL.Add('');
        SL.Add('----------------------------------------');
        SL.Add('РЕЗУЛЬТАТЫ ЗАПУСКОВ:');
        SL.Add('----------------------------------------');
        for i := 0 to Length(LastResults) - 1 do
        begin
          SL.Add(Format('Запуск %d: %.6f', [i + 1, LastResults[i]]));
        end;
        SL.Add('');
        SL.Add('----------------------------------------');
        SL.Add('СТАТИСТИКА:');
        SL.Add('----------------------------------------');
        SL.Add(LastStats);
        SL.Add('');
        SL.Add('========================================');
        SL.Add(Format('Лучшая точка: %s', [GetBestPointString]));
        SL.Add('========================================');

        try
          SL.SaveToFile(FileName);
          ShowMessage(Format('Результаты успешно сохранены в файл:'#13#10#13#10'%s', [FileName]));
        except
          on E: Exception do
          begin
            ShowMessage('Ошибка при сохранении файла:'#13#10 + E.Message);
          end;
        end;

      finally
        SL.Free;
      end;
    end;
  finally
    SaveDialog.Free;
  end;
end;

// ============================================================
// ИНИЦИАЛИЗАЦИЯ ФОРМЫ
// ============================================================
procedure TPartialSwarm.FormCreate(Sender: TObject);
begin
  SetDecimalSeparatorToPoint;

  // Фиксируем размер окна
  Self.BorderStyle := bsSingle;
  Self.BorderIcons := [biSystemMenu, biMinimize];
  Self.Position := poScreenCenter;

  // Цвета подписей
  Label1.Font.Color := clBlack;
  Label2.Font.Color := clBlack;
  Label3.Font.Color := clBlack;
  Label4.Font.Color := clBlack;
  Label5.Font.Color := clBlack;
  Label6.Font.Color := clBlack;
  Label7.Font.Color := clBlack;
  Label8.Font.Color := clBlack;
  Label9.Font.Color := clBlack;
  Label10.Font.Color := clBlack;
  Label11.Font.Color := clBlack;
  Label12.Font.Color := clBlack;
  Label13.Font.Color := clBlack;
  Label14.Font.Color := clBlack;
  Label15.Font.Color := clBlack;

  // Поля ввода — светлая тема
  cblFunction.Color := clWhite;
  cblFunction.Font.Color := clBlack;

  seDimension.Color := clWhite;
  seDimension.Font.Color := clBlack;

  seSwarmSize.Color := clWhite;
  seSwarmSize.Font.Color := clBlack;

  selteration.Color := clWhite;
  selteration.Font.Color := clBlack;

  seMaxIterWithoutImprovement.Color := clWhite;
  seMaxIterWithoutImprovement.Font.Color := clBlack;

  seRuns.Color := clWhite;
  seRuns.Font.Color := clBlack;

  edSelfConfidence.Color := clWhite;
  edSelfConfidence.Font.Color := clBlack;

  edSocialConfidence.Color := clWhite;
  edSocialConfidence.Font.Color := clBlack;

  edMaxVelocity.Color := clWhite;
  edMaxVelocity.Font.Color := clBlack;

  edSearchRange.Color := clWhite;
  edSearchRange.Font.Color := clBlack;

  edInertiaWeight.Color := clWhite;
  edInertiaWeight.Font.Color := clBlack;

  edInertiaStart.Color := clWhite;
  edInertiaStart.Font.Color := clBlack;

  edInertiaEnd.Color := clWhite;
  edInertiaEnd.Font.Color := clBlack;

  edPenaltyRatio.Color := clWhite;
  edPenaltyRatio.Font.Color := clBlack;

  // Кнопки — светлая тема
  btnRun.Font.Color := clWhite;
  btnRun.Font.Style := [fsBold];

  btnClear.Font.Color := clWhite;
  btnClear.Font.Style := [fsBold];

  btnSave.Font.Color := clWhite;
  btnSave.Font.Style := [fsBold];
  btnSave.Caption := 'Сохранить';

  // Флажки
  cbAdaptiveWeight.Font.Color := clBlack;
  cbMutations.Font.Color := clBlack;
  cbPenalty.Font.Color := clBlack;

  // Компоненты вывода — светлая тема
  MemoBest.Color := clWhite;
  MemoBest.Clear;
  MemoBest.Font.Color := clBlack;
  MemoBest.Font.Name := 'Courier New';
  MemoBest.Font.Size := 12;
  MemoBest.ScrollBars := ssVertical;

  StringGrid1.Color := clWhite;
  StringGrid1.Font.Color := clBlack;
  StringGrid1.Font.Name := 'Courier New';
  StringGrid1.Font.Size := 8;
  StringGrid1.FixedColor := clSilver;

  PaintBox.Color := clWhite;

  lblStatus.Font.Color := clNavy;
  lblStatus.Font.Style := [fsBold];

  // Заполнение выпадающего списка (21 функция)
  cblFunction.Items.Clear;
  cblFunction.Items.Add('Сферическая');
  cblFunction.Items.Add('Розенброка');
  cblFunction.Items.Add('Растригина');
  cblFunction.Items.Add('Гриванк');
  cblFunction.Items.Add('Экли');
  cblFunction.Items.Add('Швефеля');
  cblFunction.Items.Add('Леви');
  cblFunction.Items.Add('Химмельблау');
  cblFunction.Items.Add('Михалевича');
  cblFunction.Items.Add('Шаффера N.2');
  cblFunction.Items.Add('Падающая волна');
  cblFunction.Items.Add('Альпийская N.1');
  cblFunction.Items.Add('Брауна');
  cblFunction.Items.Add('Пауэлла');
  cblFunction.Items.Add('Диксона-Прайса');
  cblFunction.Items.Add('Леви N.13');
  cblFunction.Items.Add('Бочачевского N.1');
  cblFunction.Items.Add('Перм 0, D, Бета');
  cblFunction.Items.Add('Вращённый гиперэллипсоид');
  cblFunction.Items.Add('Сумма разных степеней');
  cblFunction.Items.Add('Трид');
  cblFunction.ItemIndex := 0;

  // Настройка таблицы результатов
  StringGrid1.RowCount := 1;
  StringGrid1.ColCount := 2;
  StringGrid1.Cells[0, 0] := 'Запуск';
  StringGrid1.Cells[1, 0] := 'Результат';
  StringGrid1.FixedCols := 0;
  StringGrid1.ColWidths[0] := 60;
  StringGrid1.ColWidths[1] := 120;
  StringGrid1.ScrollBars := ssVertical;
  StringGrid1.Options := [goFixedVertLine, goFixedHorzLine,
                           goVertLine, goHorzLine, goRowSelect];

  // Скрываем зависимые параметры
  edInertiaStart.Visible := False;
  edInertiaEnd.Visible := False;
  seMaxIterWithoutImprovement.Visible := False;
  edPenaltyRatio.Visible := False;

  // Значения по умолчанию
  edSelfConfidence.Text := '1.5';
  edSocialConfidence.Text := '1.5';
  edMaxVelocity.Text := '2.0';
  edSearchRange.Text := '10.0';
  edInertiaWeight.Text := '0.7';
  edInertiaStart.Text := '0.9';
  edInertiaEnd.Text := '0.2';
  edPenaltyRatio.Text := '1000.0';
  seMaxIterWithoutImprovement.Value := 20;
  seRuns.Value := 10;
  seDimension.Value := 2;
  seSwarmSize.Value := 50;
  selteration.Value := 500;

  // Подписи
  Label1.Caption := 'Выберите функцию:';
  Label2.Caption := 'Размерность:';
  Label3.Caption := 'Размер роя:';
  Label4.Caption := 'Макс. итераций:';
  Label5.Caption := 'Статистика:';
  Label6.Caption := 'Коэффициент c1:';
  Label7.Caption := 'Коэффициент c2:';
  Label8.Caption := 'Макс. скорость:';
  Label9.Caption := 'Диапазон поиска:';
  Label10.Caption := 'Вес инерции:';
  Label11.Caption := 'Нач. вес:';
  Label12.Caption := 'Кон. вес:';
  Label13.Caption := 'Коэф. штрафа:';
  Label14.Caption := 'Итер. без улучш.:';
  Label15.Caption := 'Число запусков:';

  cbAdaptiveWeight.Caption := 'Адаптивный вес';
  cbMutations.Caption := 'Мутации';
  cbPenalty.Caption := 'Штрафы';

  btnRun.Caption := 'Запустить';
  btnClear.Caption := 'Очистить';

  lblStatus.Caption := 'Готов к работе';

  // Инициализация массивов
  SetLength(LastResults, 0);
  LastFuncName := '';
  LastStats := '';
end;

// ============================================================
// ВЫБОР ФУНКЦИИ
// ============================================================
procedure TPartialSwarm.cblFunctionChange(Sender: TObject);
begin
  lblStatus.Caption := 'Выбрана функция: ' + cblFunction.Items[cblFunction.ItemIndex];

  // 2D-функции: Химмельблау, Падающая волна (индексы 7, 10)
  if cblFunction.ItemIndex in [7, 10] then
  begin
    seDimension.Value := 2;
    seDimension.Enabled := False;
    lblStatus.Caption := lblStatus.Caption + ' (размерность равна 2)';
  end
  else
  begin
    seDimension.Enabled := True;
  end;
end;

// ============================================================
// ОБРАБОТЧИКИ ФЛАЖКОВ
// ============================================================
procedure TPartialSwarm.cbAdaptiveWeightClick(Sender: TObject);
begin
  edInertiaWeight.Visible := not cbAdaptiveWeight.Checked;
  edInertiaStart.Visible := cbAdaptiveWeight.Checked;
  edInertiaEnd.Visible := cbAdaptiveWeight.Checked;

  if cbAdaptiveWeight.Checked then
    lblStatus.Caption := 'Адаптивный вес: ВКЛ'
  else
    lblStatus.Caption := 'Адаптивный вес: ВЫКЛ';
end;

procedure TPartialSwarm.cbMutationsClick(Sender: TObject);
begin
  seMaxIterWithoutImprovement.Visible := cbMutations.Checked;

  if cbMutations.Checked then
    lblStatus.Caption := 'Мутации: ВКЛ'
  else
    lblStatus.Caption := 'Мутации: ВЫКЛ';
end;

procedure TPartialSwarm.cbPenaltyClick(Sender: TObject);
begin
  edPenaltyRatio.Visible := cbPenalty.Checked;

  if cbPenalty.Checked then
    lblStatus.Caption := 'Штрафы: ВКЛ'
  else
    lblStatus.Caption := 'Штрафы: ВЫКЛ';
end;

// ============================================================
// ОТРИСОВКА ГРАФИКА СХОДИМОСТИ
// ============================================================
procedure TPartialSwarm.DrawConvergenceGraph;
var
  i: Integer;
  maxVal, minVal, range: Double;
  x1, y1, x2, y2: Integer;
  graphWidth, graphHeight: Integer;
begin

  PaintBox.Canvas.Brush.Color := clWhite;
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  if Length(History) < 2 then
  begin
    PaintBox.Canvas.Font.Color := clBlack;
    PaintBox.Canvas.Font.Size := 10;
    PaintBox.Canvas.TextOut(10, 10, '');
    Exit;
  end;

  minVal := History[0];
  maxVal := History[0];
  for i := 1 to Length(History) - 1 do
  begin
    if History[i] < minVal then minVal := History[i];
    if History[i] > maxVal then maxVal := History[i];
  end;

  if maxVal = minVal then
  begin
    range := 1;
    minVal := minVal - 0.5;
    maxVal := maxVal + 0.5;
  end
  else
    range := maxVal - minVal;

  graphWidth := PaintBox.Width - 20;
  graphHeight := PaintBox.Height - 20;

  // Сетка
  PaintBox.Canvas.Pen.Color := clSilver;
  PaintBox.Canvas.Pen.Width := 1;

  for i := 0 to 5 do
  begin
    y1 := 10 + Round((i / 5) * graphHeight);
    PaintBox.Canvas.MoveTo(10, y1);
    PaintBox.Canvas.LineTo(PaintBox.Width - 10, y1);
  end;

  for i := 0 to 5 do
  begin
    x1 := 10 + Round((i / 5) * graphWidth);
    PaintBox.Canvas.MoveTo(x1, 10);
    PaintBox.Canvas.LineTo(x1, PaintBox.Height - 10);
  end;

  // Линия сходимости
  PaintBox.Canvas.Pen.Color := clNavy;
  PaintBox.Canvas.Pen.Width := 2;

  for i := 0 to Length(History) - 2 do
  begin
    x1 := 10 + Round((i / (Length(History) - 1)) * graphWidth);
    y1 := 10 + Round((1 - (History[i] - minVal) / range) * graphHeight);

    x2 := 10 + Round(((i + 1) / (Length(History) - 1)) * graphWidth);
    y2 := 10 + Round((1 - (History[i + 1] - minVal) / range) * graphHeight);

    PaintBox.Canvas.MoveTo(x1, y1);
    PaintBox.Canvas.LineTo(x2, y2);
  end;

  // Рамка
  PaintBox.Canvas.Pen.Color := clBlack;
  PaintBox.Canvas.Pen.Width := 1;
  PaintBox.Canvas.Brush.Style := bsClear;
  PaintBox.Canvas.Rectangle(10, 10, PaintBox.Width - 10, PaintBox.Height - 10);

  // Подписи осей
  PaintBox.Canvas.Font.Color := clBlack;
  PaintBox.Canvas.Font.Size := 8;
  PaintBox.Canvas.Brush.Style := bsClear;

  PaintBox.Canvas.TextOut(12, 12, Format('Max: %.6f', [maxVal]));

  PaintBox.Canvas.TextOut(12, PaintBox.Height - 22, Format('Min: %.6f', [minVal]));

  PaintBox.Canvas.Font.Size := 10;
  PaintBox.Canvas.Font.Style := [fsBold];
  PaintBox.Canvas.TextOut((PaintBox.Width - PaintBox.Canvas.TextWidth('График сходимости')) div 2,
                           PaintBox.Height - 22, 'График сходимости');
end;

// ============================================================
// ЗАПУСК АЛГОРИТМА
// ============================================================
procedure TPartialSwarm.btnRunClick(Sender: TObject);
var
  i, run: Integer;
  results: array of Double;
  sum, avg, minVal, maxVal, stdDev: Double;
  funcName: string;
  funcIndex: Integer;
begin
  try
    if cblFunction.ItemIndex = -1 then
    begin
      ShowMessage('Пожалуйста, выберите целевую функцию');
      Exit;
    end;

    // Проверка параметров
    if seSwarmSize.Value < 2 then
    begin
      ShowMessage('Размер роя должен быть не меньше 2');
      Exit;
    end;

    if seDimension.Value < 2 then
    begin
      ShowMessage('Размерность должна быть не меньше 2');
      Exit;
    end;

    // Проверка для 2D-функций (индексы 7, 10)
    if (cblFunction.ItemIndex in [7, 10]) and (seDimension.Value > 2) then
    begin
      ShowMessage('Эта функция определена только для 2D. Размерность будет установлена в 2.');
      seDimension.Value := 2;
    end;

    if StrToFloat(edSelfConfidence.Text) <= 0 then
    begin
      ShowMessage('Коэффициент c1 должен быть больше 0');
      Exit;
    end;

    if StrToFloat(edSocialConfidence.Text) <= 0 then
    begin
      ShowMessage('Коэффициент c2 должен быть больше 0');
      Exit;
    end;

    funcIndex := cblFunction.ItemIndex;
    SetupFunctionParameters(funcIndex, funcName);

    USE_ADAPTIVE_WEIGHT := cbAdaptiveWeight.Checked;
    USE_MUTATIONS := cbMutations.Checked;
    USE_PENALTY := cbPenalty.Checked;

    if MaxIter <= 0 then
    begin
      ShowMessage('Максимальное количество итераций должно быть больше 0');
      Exit;
    end;

    RunsCount := seRuns.Value;

    MemoBest.Clear;
    StringGrid1.RowCount := 1;
    StringGrid1.Cells[0, 0] := 'Запуск';
    StringGrid1.Cells[1, 0] := 'Результат';

    SetLength(results, RunsCount);

    lblStatus.Caption := Format('Запуск: 0 / %d', [RunsCount]);
    Application.ProcessMessages;

    for run := 0 to RunsCount - 1 do
    begin
      Randomize;
      RunPSO;
      results[run] := GlobalBestFitness;

      StringGrid1.RowCount := run + 2;
      StringGrid1.Cells[0, run + 1] := IntToStr(run + 1);
      StringGrid1.Cells[1, run + 1] := FloatToStrF(results[run], ffFixed, 10, 6);

      lblStatus.Caption := Format('Запуск: %d / %d', [run + 1, RunsCount]);
      Application.ProcessMessages;
    end;

    // Статистика
    minVal := results[0];
    maxVal := results[0];
    sum := 0;

    for i := 0 to RunsCount - 1 do
    begin
      if results[i] < minVal then minVal := results[i];
      if results[i] > maxVal then maxVal := results[i];
      sum := sum + results[i];
    end;

    avg := sum / RunsCount;

    stdDev := 0;
    for i := 0 to RunsCount - 1 do
      stdDev := stdDev + Sqr(results[i] - avg);
    stdDev := Sqrt(stdDev / RunsCount);

    SetLength(LastResults, Length(results));
    for i := 0 to Length(results) - 1 do
      LastResults[i] := results[i];

    LastFuncName := funcName;
    LastStats := 'Среднее: ' + FloatToStrF(avg, ffFixed, 10, 6) + #13#10 +
                 'Минимум: ' + FloatToStrF(minVal, ffFixed, 10, 6) + #13#10 +
                 'Максимум: ' + FloatToStrF(maxVal, ffFixed, 10, 6) + #13#10 +
                 'Стд. отклонение: ' + FloatToStrF(stdDev, ffFixed, 10, 6) + #13#10 +
                 'Лучшая точка: ' + GetBestPointString + #13#10 +
                 'Значение: ' + FloatToStrF(minVal, ffFixed, 10, 6);

    // Вывод в Memo
    MemoBest.Lines.Add('========================================');
    MemoBest.Lines.Add('ФУНКЦИЯ: ' + funcName);
    MemoBest.Lines.Add('========================================');
    MemoBest.Lines.Add(Format('Размерность: %d', [Dimension]));
    MemoBest.Lines.Add(Format('Размер роя: %d', [SwarmSize]));
    MemoBest.Lines.Add(Format('Итераций: %d', [MaxIter]));
    MemoBest.Lines.Add(Format('Запусков: %d', [RunsCount]));
    MemoBest.Lines.Add('----------------------------------------');
    MemoBest.Lines.Add(Format('Среднее: %.6f', [avg]));
    MemoBest.Lines.Add(Format('Минимум: %.6f', [minVal]));
    MemoBest.Lines.Add(Format('Максимум: %.6f', [maxVal]));
    MemoBest.Lines.Add(Format('Стд. отклонение: %.6f', [stdDev]));
    MemoBest.Lines.Add('----------------------------------------');
    MemoBest.Lines.Add('ЛУЧШАЯ ТОЧКА:');
    MemoBest.Lines.Add('  Координаты: ' + GetBestPointString);
    MemoBest.Lines.Add(Format('  Значение: %.6f', [minVal]));
    MemoBest.Lines.Add('========================================');

    DrawConvergenceGraph;

    lblStatus.Caption := 'Завершено! Лучший результат: ' + FloatToStrF(minVal, ffFixed, 10, 6) +
                         ' в точке ' + GetBestPointString;

  except
    on E: Exception do
    begin
      ShowMessage('Ошибка: ' + E.Message);
      lblStatus.Caption := 'Ошибка выполнения';
    end;
  end;
end;

// ============================================================
// КНОПКА СОХРАНЕНИЯ
// ============================================================
procedure TPartialSwarm.btnSaveClick(Sender: TObject);
begin
  SaveResultsToFile;
end;

// ============================================================
// ОЧИСТКА ДАННЫХ
// ============================================================
procedure TPartialSwarm.btnClearClick(Sender: TObject);
begin
  MemoBest.Clear;

  StringGrid1.RowCount := 1;
  StringGrid1.Cells[0, 0] := 'Запуск';
  StringGrid1.Cells[1, 0] := 'Результат';

  PaintBox.Canvas.Brush.Color := clWhite;
  PaintBox.Canvas.FillRect(PaintBox.ClientRect);

  SetLength(History, 0);
  SetLength(LastResults, 0);
  LastFuncName := '';
  LastStats := '';

  lblStatus.Caption := 'Данные очищены';
end;

// ============================================================
// ПЕРЕРИСОВКА PAINTBOX
// ============================================================
procedure TPartialSwarm.PaintBoxPaint(Sender: TObject);
begin
  DrawConvergenceGraph;
end;

// ============================================================
// РАЗДЕЛИТЕЛЬ (инициализация/финализация модуля)
// ============================================================
initialization
  SetDecimalSeparatorToPoint;

finalization
  RestoreDecimalSeparator;

end.
