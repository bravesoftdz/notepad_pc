unit GR32_Bindings;

interface

{$I GR32.inc}

uses
  Classes, GR32_System;

type
  TFunctionName = type string;
  TFunctionID = type Integer;

  PFunctionInfo = ^TFunctionInfo;
  TFunctionInfo = record
    FunctionID: Integer;
    Proc: Pointer;
    CPUFeatures: TCPUFeatures;
    Flags: Integer;
  end;

  TFunctionPriority = function (Info: PFunctionInfo): Integer;

  PFunctionBinding = ^TFunctionBinding;
  TFunctionBinding = record
    FunctionID: Integer;
    BindVariable: PPointer;
  end;
  
  TFunctionRegistry = class(TPersistent)
  private
    FItems: TList;
    FBindings: TList;
    FName: string;
    procedure SetName(const Value: string);
    function GetItems(Index: Integer): PFunctionInfo;
    procedure SetItems(Index: Integer; const Value: PFunctionInfo);
  public
    constructor Create; virtual;
    destructor Destroy; override;
    procedure Clear;

    procedure Add(FunctionID: Integer; Proc: Pointer; CPUFeatures: TCPUFeatures = []; Flags: Integer = 0);
    
    procedure RegisterBinding(FunctionID: Integer; BindVariable: PPointer);
    procedure RebindAll(PriorityCallback: TFunctionPriority = nil);
    procedure Rebind(FunctionID: Integer; PriorityCallback: TFunctionPriority = nil);

    function FindFunction(FunctionID: Integer; PriorityCallback: TFunctionPriority = nil): Pointer;
    property Items[Index: Integer]: PFunctionInfo read GetItems write SetItems;
  published
    property Name: string read FName write SetName;
  end;

function NewRegistry(const Name: string = ''): TFunctionRegistry;

function DefaultPriorityProc(Info: PFunctionInfo): Integer;

var
  DefaultPriority: TFunctionPriority = DefaultPriorityProc;

const
  INVALID_PRIORITY: Integer = MaxInt;

implementation

uses
  Math;

var
  Registers: TList;

function NewRegistry(const Name: string): TFunctionRegistry;
begin
  if Registers = nil then
    Registers := TList.Create;
  Result := TFunctionRegistry.Create;
  Result.Name := Name;
  Registers.Add(Result);
end;

function DefaultPriorityProc(Info: PFunctionInfo): Integer;
begin
  Result := IfThen(Info^.CPUFeatures <= GR32_System.CPUFeatures, 0, INVALID_PRIORITY);
end;

procedure TFunctionRegistry.Add(FunctionID: Integer; Proc: Pointer;
  CPUFeatures: TCPUFeatures; Flags: Integer);
var
  Info: PFunctionInfo;
begin
  New(Info);
  Info^.FunctionID := FunctionID;
  Info^.Proc := Proc;
  Info^.CPUFeatures := CPUFeatures;
  Info^.Flags := Flags;
  FItems.Add(Info);
end;

procedure TFunctionRegistry.Clear;
var
  I: Integer;
begin
  for I := 0 to FItems.Count - 1 do
    Dispose(PFunctionInfo(FItems[I]));
  FItems.Clear;
  for I := 0 to FBindings.Count - 1 do
    Dispose(PFunctionBinding(FBindings[I]));
  FBindings.Clear;
end;

constructor TFunctionRegistry.Create;
begin
  FItems := TList.Create;
  FBindings := TList.Create;
end;

destructor TFunctionRegistry.Destroy;
begin
  Clear;
  FItems.Free;
  FBindings.Free;
  inherited;
end;

function TFunctionRegistry.FindFunction(FunctionID: Integer;
  PriorityCallback: TFunctionPriority): Pointer;
var
  I, MinPriority, P: Integer;
  Info: PFunctionInfo;
begin
  if not Assigned(PriorityCallback) then PriorityCallback := DefaultPriority;
  Result := nil;
  MinPriority := INVALID_PRIORITY;
  for I := FItems.Count - 1 downto 0 do
  begin
    Info := FItems[I];
    if (Info^.FunctionID = FunctionID) then
    begin
      P := PriorityCallback(Info);
      if P < MinPriority then
      begin
        Result := Info^.Proc;
        MinPriority := P;
      end;
    end;
  end;
end;

function TFunctionRegistry.GetItems(Index: Integer): PFunctionInfo;
begin
  Result := FItems[Index];
end;

procedure TFunctionRegistry.Rebind(FunctionID: Integer;
  PriorityCallback: TFunctionPriority);
var
  P: PFunctionBinding;
  I: Integer;
begin
  for I := 0 to FBindings.Count - 1 do
  begin
    P := PFunctionBinding(FBindings[I]);
    if P^.FunctionID = FunctionID then
      P^.BindVariable^ := FindFunction(FunctionID, PriorityCallback);
  end;
end;

procedure TFunctionRegistry.RebindAll(PriorityCallback: TFunctionPriority);
var
  I: Integer;
  P: PFunctionBinding;
begin
  for I := 0 to FBindings.Count - 1 do
  begin
    P := PFunctionBinding(FBindings[I]);
    P^.BindVariable^ := FindFunction(P^.FunctionID, PriorityCallback);
  end;
end;

procedure TFunctionRegistry.RegisterBinding(FunctionID: Integer;
  BindVariable: PPointer);
var
  Binding: PFunctionBinding;
begin
  New(Binding);
  Binding^.FunctionID := FunctionID;
  Binding^.BindVariable := BindVariable;
  FBindings.Add(Binding);
end;

procedure TFunctionRegistry.SetItems(Index: Integer;
  const Value: PFunctionInfo);
begin
  FItems[Index] := Value;
end;

procedure TFunctionRegistry.SetName(const Value: string);
begin
  FName := Value;
end;

procedure FreeRegisters;
var
  I: Integer;
begin
  if Assigned(Registers) then
  begin
    for I := Registers.Count - 1 downto 0 do
      TFunctionRegistry(Registers[I]).Free;
    Registers.Free;
    Registers := nil;
  end;
end;

initialization

finalization
  FreeRegisters;

end. 
