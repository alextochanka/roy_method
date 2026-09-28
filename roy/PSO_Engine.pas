unit PSO_Engine;

interface

uses
  System.SysUtils, System.Math;

const
  MUTATION_AMT = 3;
  MUTATION_LOCAL_RADIUS = 0.5;

type
  TParticle = record
    Position: array of Double;
    Velocity: array of Double;
    BestPosition: array of Double;
    BestFitness: Double;
  end;

  TFitnessFunction = function(x: array of Double): Double;

var
  // ВКЛЮЧЕНИЕ/ОТКЛЮЧЕНИЕ МОДИФИКАЦИЙ
  USE_ADAPTIVE_WEIGHT: Boolean;  // ВКЛЮЧИТЬ адаптивный вес (меняется от InertiaStart до InertiaEnd)
  USE_MUTATIONS: Boolean; // ВКЛЮЧИТЬ мутации (перезапуск частиц при застое)
  USE_PENALTY: Boolean;  // ВКЛЮЧИТЬ штрафы (запрещает вылет за границы)

  // ОСНОВНЫЕ ПАРАМЕТРЫ АЛГОРИТМА
  SwarmSize: Integer;
  Dimension: Integer;
  SelfConfidence: Double;   // c1 — доверие частицы к своему опыту (1.5)
  SocialConfidence: Double;    // c2 — доверие к опыту стаи (1.5)
  MaxVelocity: Double;    // Максимальная скорость частицы
  SearchRange: Double;
  MaxIter: Integer;

  // ПАРАМЕТРЫ ПРИ ВЫБОРЕ USE_MUTATIONS
  MaxIterWithoutImprovement: Integer;

  // ВЕС ИНЕРЦИИ
  InertiaWeight: Double;   // Постоянный вес
  InertiaStart: Double;    // Начальный вес ПРИ ВЫБОРЕ USE_ADAPTIVE_WEIGHT
  InertiaEnd: Double;      // Конечный вес ПРИ ВЫБОРЕ USE_ADAPTIVE_WEIGHT

  // ШТРАФЫ ПРИ ВЫБОРЕ USE_PENALTY
  MinValues: array of Double;
  MaxValues: array of Double;
  PenaltyRatio: Double;

  // РЕЗУЛЬТАТЫ
  GlobalBestPosition: array of Double;
  GlobalBestFitness: Double;

  // ЦЕЛЕВАЯ ФУНКЦИЯ
  FitnessFunction: TFitnessFunction;

  History: array of Double;   // История сходимости (для графика)


// ПРОЦЕДУРЫ
function CalculatePenalty(position: array of Double): Double;
procedure InitializeSwarm;
procedure FindGlobalBest;
procedure ApplyMutation(var MutationCount: Integer);
procedure RunPSO;

implementation

var
  Swarm: array of TParticle;

// ИНИЦИАЛИЗАЦИЯ РОЯ
procedure InitializeSwarm;
var
  i, j: Integer;
begin
  // Проверка, что FitnessFunction назначена
  if not Assigned(FitnessFunction) then
    raise Exception.Create('FitnessFunction не назначена!');

  // Проверка размерности
  if Dimension <= 0 then
    raise Exception.Create('Размерность должна быть больше 0');

  SetLength(Swarm, SwarmSize);

  for i := 0 to SwarmSize - 1 do
  begin
    SetLength(Swarm[i].Position, Dimension);
    SetLength(Swarm[i].Velocity, Dimension);
    SetLength(Swarm[i].BestPosition, Dimension);

    for j := 0 to Dimension - 1 do
    begin
      Swarm[i].Position[j] := -SearchRange + Random * 2 * SearchRange;
      Swarm[i].Velocity[j] := -MaxVelocity + Random * 2 * MaxVelocity;
      Swarm[i].BestPosition[j] := Swarm[i].Position[j];
    end;

    Swarm[i].BestFitness := FitnessFunction(Swarm[i].Position);
  end;
end;

// ПОИСК ГЛОБАЛЬНОГО ЛУЧШЕГО РЕШЕНИЯ
procedure FindGlobalBest;
var
  i, j: Integer;
begin
  // Проверка, что рой инициализирован
  if Length(Swarm) = 0 then
    Exit;

  SetLength(GlobalBestPosition, Dimension);
  GlobalBestFitness := Swarm[0].BestFitness;

  for j := 0 to Dimension - 1 do
    GlobalBestPosition[j] := Swarm[0].BestPosition[j];

  for i := 1 to SwarmSize - 1 do
    if Swarm[i].BestFitness < GlobalBestFitness then
    begin
      GlobalBestFitness := Swarm[i].BestFitness;
      for j := 0 to Dimension - 1 do
        GlobalBestPosition[j] := Swarm[i].BestPosition[j];
    end;
end;

// РАСЧЁТ ШТРАФА
function CalculatePenalty(position: array of Double): Double;
var
  TotalPenalty: Double;
  j: Integer;
begin
  // Проверка, что массивы MinValues и MaxValues инициализированы
  if (Length(MinValues) = 0) or (Length(MaxValues) = 0) then
  begin
    Result := 0.0;
    Exit;
  end;

  TotalPenalty := 0.0;
  for j := 0 to Dimension - 1 do
  begin
    // Проверка, что индекс существует в массиве position
    if j < Length(position) then
    begin
      if position[j] < MinValues[j] then
        TotalPenalty := TotalPenalty + PenaltyRatio * (MinValues[j] - position[j]);

      if position[j] > MaxValues[j] then
        TotalPenalty := TotalPenalty + PenaltyRatio * (position[j] - MaxValues[j]);
    end;
  end;
  Result := TotalPenalty;
end;

// ОБНОВЛЕНИЕ ОДНОЙ ЧАСТИЦЫ
procedure UpdateParticle(index: Integer; weight: Double);
var
  r1, r2: Double;
  NewVelocity: Double;
  NewPosition: Double;
  RawFitness: Double;
  TotalFitness: Double;
  Penalty: Double;
  j: Integer;
begin
  r1 := Random;
  r2 := Random;

  // Проверка, что GlobalBestPosition инициализирован
  if Length(GlobalBestPosition) < Dimension then
    Exit;

  // Обновление скорости и позиции по каждой координате
  for j := 0 to Dimension - 1 do
  begin
    NewVelocity := weight * Swarm[index].Velocity[j]
                   + SelfConfidence * r1 * (Swarm[index].BestPosition[j] - Swarm[index].Position[j])
                   + SocialConfidence * r2 * (GlobalBestPosition[j] - Swarm[index].Position[j]);

    // Ограничение скорости
    if NewVelocity < -MaxVelocity then NewVelocity := -MaxVelocity;
    if NewVelocity > MaxVelocity then NewVelocity := MaxVelocity;

    Swarm[index].Velocity[j] := NewVelocity;

    NewPosition := Swarm[index].Position[j] + NewVelocity;
    Swarm[index].Position[j] := NewPosition;
  end;

  // Ограничение позиции (если штрафы выключены)
  if not USE_PENALTY then
  begin
    for j := 0 to Dimension - 1 do
    begin
      if Swarm[index].Position[j] > SearchRange then
        Swarm[index].Position[j] := SearchRange;
      if Swarm[index].Position[j] < -SearchRange then
        Swarm[index].Position[j] := -SearchRange;
    end;
  end;

  // ШТРАФ
  if USE_PENALTY then
    Penalty := CalculatePenalty(Swarm[index].Position)
  else
    Penalty := 0.0;

  RawFitness := FitnessFunction(Swarm[index].Position);
  TotalFitness := RawFitness + Penalty;

  // ОБНОВЛЕНИЕ ЛИЧНОГО РЕКОРДА
  if TotalFitness < Swarm[index].BestFitness then
  begin
    Swarm[index].BestFitness := TotalFitness;
    for j := 0 to Dimension - 1 do
      Swarm[index].BestPosition[j] := Swarm[index].Position[j];
  end;

  // ОБНОВЛЕНИЕ ГЛОБАЛЬНОГО РЕКОРДА (ТОЛЬКО ЕСЛИ НЕТ ШТРАФА)
  if (Penalty = 0) and (TotalFitness < GlobalBestFitness) then
  begin
    GlobalBestFitness := TotalFitness;
    for j := 0 to Dimension - 1 do
      GlobalBestPosition[j] := Swarm[index].Position[j];
  end;
end;

// ПРИМЕНЕНИЕ МУТАЦИИ
procedure ApplyMutation(var MutationCount: Integer);
var
  Indices: array of Integer;
  i, j, k, idx, Temp: Integer;
begin
  // Проверка, что GlobalBestPosition инициализирован
  if Length(GlobalBestPosition) < Dimension then
    Exit;

  // Сортировка индексов по качеству частиц (от лучших к худшим)
  SetLength(Indices, SwarmSize);
  for i := 0 to SwarmSize - 1 do
    Indices[i] := i;

  for i := 0 to SwarmSize - 2 do
    for j := i + 1 to SwarmSize - 1 do
      if Swarm[Indices[i]].BestFitness > Swarm[Indices[j]].BestFitness then
      begin
        Temp := Indices[i];
        Indices[i] := Indices[j];
        Indices[j] := Temp;
      end;

  // Перезапуск худшей половины роя
  for k := SwarmSize div 2 to SwarmSize - 1 do
  begin
    idx := Indices[k];

    for j := 0 to Dimension - 1 do
    begin
      if MutationCount = 0 then
        // Первая мутация - локальный поиск вокруг глобального лучшего
        Swarm[idx].Position[j] := GlobalBestPosition[j] + (Random - 0.5) * SearchRange * MUTATION_LOCAL_RADIUS
      else
        // Последующие мутации - полная реинициализация
        Swarm[idx].Position[j] := -SearchRange + Random * 2 * SearchRange;

      // Ограничение позиции
      if Swarm[idx].Position[j] > SearchRange then
        Swarm[idx].Position[j] := SearchRange;
      if Swarm[idx].Position[j] < -SearchRange then
        Swarm[idx].Position[j] := -SearchRange;

      Swarm[idx].Velocity[j] := 0;
      Swarm[idx].BestPosition[j] := Swarm[idx].Position[j];
    end;

    Swarm[idx].BestFitness := FitnessFunction(Swarm[idx].Position);
  end;
end;

// ОСНОВНОЙ ЦИКЛ ОПТИМИЗАЦИИ
procedure RunPSO;
var
  iter: Integer;
  NoImprovement: Integer;
  PreviousBest: Double;
  Weight: Double;
  MutationCount: Integer;
  i: Integer;
begin
  // Проверка параметров
  if MaxIter <= 0 then
    raise Exception.Create('Максимальное количество итераций должно быть больше 0');

  if not Assigned(FitnessFunction) then
    raise Exception.Create('Функция не инициализирована');

  if SwarmSize < 2 then
    raise Exception.Create('Размер роя должен быть не меньше 2');

  // ИНИЦИАЛИЗАЦИЯ
  InitializeSwarm;
  FindGlobalBest;

  SetLength(History, MaxIter + 1);
  History[0] := GlobalBestFitness;

  iter := 0;
  NoImprovement := 0;
  MutationCount := 0;
  PreviousBest := GlobalBestFitness;

  while iter < MaxIter do
  begin
    Inc(iter);

    // Расчет веса инерции
    if USE_ADAPTIVE_WEIGHT then
      Weight := InertiaStart - (iter / MaxIter) * (InertiaStart - InertiaEnd)
    else
      Weight := InertiaWeight;

    // Обновление всех частиц
    for i := 0 to SwarmSize - 1 do
      UpdateParticle(i, Weight);

    History[iter] := GlobalBestFitness;

    // Проверка улучшения
    if GlobalBestFitness < PreviousBest then
    begin
      NoImprovement := 0;
      PreviousBest := GlobalBestFitness;
    end
    else
      NoImprovement := NoImprovement + 1;

    // МУТАЦИЯ при включении
    if USE_MUTATIONS and (NoImprovement >= MaxIterWithoutImprovement) then
    begin
      if MutationCount < MUTATION_AMT then
      begin
        ApplyMutation(MutationCount);
        NoImprovement := 0;
        Inc(MutationCount);
        // Обновление глобального лучшего после мутации
        FindGlobalBest;
        PreviousBest := GlobalBestFitness;
        // Записываем в историю новое значение
        History[iter] := GlobalBestFitness;
      end
      else
      begin
        // Если все мутации не помогли - сбрасываем счетчик и продолжаем
        MutationCount := 0;
        NoImprovement := 0;
      end;
    end;
  end;
end;

end.
