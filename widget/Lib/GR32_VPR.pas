unit GR32_VPR;

interface

{$I GR32.inc}

uses
  GR32;

type
  PInteger = ^Integer;
  PSingleArray = GR32.PSingleArray;
  TSingleArray = GR32.TSingleArray;

  PValueSpan = ^TValueSpan;
  TValueSpan = record
    X1, X2: Integer;
    Values: PSingleArray;
  end;

  TRenderSpanEvent = procedure(const Span: TValueSpan; DstY: Integer) of object;
  TRenderSpanProc = procedure(Data: Pointer; const Span: TValueSpan; DstY: Integer);

procedure RenderPolyPolygon(const Points: TArrayOfArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanProc; Data: Pointer = nil); overload;
procedure RenderPolygon(const Points: TArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanProc; Data: Pointer = nil); overload;
procedure RenderPolyPolygon(const Points: TArrayOfArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanEvent); overload;
procedure RenderPolygon(const Points: TArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanEvent); overload;

implementation

uses
  Math, GR32_Math, GR32_LowLevel, GR32_VectorUtils;

type
  TArrayOfValueSpan = array of TValueSpan;

  PValueSpanArray = ^TValueSpanArray;
  TValueSpanArray = array [0..0] of TValueSpan;

  PLineSegment = ^TLineSegment;
  TLineSegment = array [0..1] of TFloatPoint;
  TArrayOfLineSegment = array of TLineSegment;

  PLineSegmentArray = ^TLineSegmentArray;
  TLineSegmentArray = array [0..0] of TLineSegment;

  PScanLine = ^TScanLine;
  TScanLine = record
    Segments: PLineSegmentArray;
    Count: Integer;
    Y: Integer;
  end;
  TScanLines = array of TScanLine;
  PScanLineArray = ^TScanLineArray;
  TScanLineArray = array [0..0] of TScanLine;

procedure IntegrateSegment(var P1, P2: TFloatPoint; Values: PSingleArray);
var
  X1, X2, I: Integer;
  Dx, Dy, DyDx, Sx, Y, fracX1, fracX2: TFloat;
begin
  X1 := Round(P1.X);
  X2 := Round(P2.X);
  if X1 = X2 then
  begin
    Values[X1] := Values[X1] + 0.5 * (P2.X - P1.X) * (P1.Y + P2.Y);
  end
  else
  begin
    fracX1 := P1.X - X1;
    fracX2 := P2.X - X2;

    Dx := P2.X - P1.X;
    Dy := P2.Y - P1.Y;
    DyDx := Dy/Dx;

    if X1 < X2 then
    begin
      Sx := 1 - fracX1;
      Y := P1.Y + Sx * DyDx;
      Values[X1] := Values[X1] + 0.5 * (P1.Y + Y) * Sx;
      for I := X1 + 1 to X2 - 1 do
      begin
        Values[I] := Values[I] + (Y + DyDx * 0.5);     
        Y := Y + DyDx;
      end;

      Sx := fracX2;
      Values[X2] := Values[X2] + 0.5 * (Y + P2.Y) * Sx;
    end
    else 
    begin
      Sx := fracX1;
      Y := P1.Y - Sx * DyDx;
      Values[X1] := Values[X1] - 0.5 * (P1.Y + Y) * Sx;
      for I := X1 - 1 downto X2 + 1 do
      begin
        Values[I] := Values[I] - (Y - DyDx * 0.5);    
        Y := Y - DyDx;
      end;
      Sx := 1 - fracX2;
      Values[X2] := Values[X2] - 0.5 * (Y + P2.Y) * Sx;
    end;
  end;
end;

procedure ExtractSingleSpan(const ScanLine: TScanLine; out Span: TValueSpan;
  SpanData: PSingleArray);
var
  I, X: Integer;
  P: PFloatPoint;
  S: PLineSegment;
  fracX: TFloat;
  Points: PFloatPointArray;
  N: Integer;
begin
  N := ScanLine.Count * 2;
  Points := @ScanLine.Segments[0];
  Span.X1 := High(Integer);
  Span.X2 := Low(Integer);

  for I := 0 to N - 1 do
  begin
    P := @Points[I];
    X := Round(P.X);
    if X < Span.X1 then Span.X1 := X;
    if P.Y = 1 then
    begin
      fracX := P.X - X;
      if Odd(I) then
      begin
        SpanData[X] := SpanData[X] + (1 - fracX); Inc(X);
        SpanData[X] := SpanData[X] + fracX;
      end
      else
      begin
        SpanData[X] := SpanData[X] - (1 - fracX); Inc(X);
        SpanData[X] := SpanData[X] - fracX;
      end;
    end;
    if X > Span.X2 then Span.X2 := X;
  end;

  CumSum(@SpanData[Span.X1], Span.X2 - Span.X1 + 1);

  for I := 0 to ScanLine.Count - 1 do
  begin
    S := @ScanLine.Segments[I];
    IntegrateSegment(S[0], S[1], SpanData);
  end;

  Span.Values := @SpanData[Span.X1];
end;

procedure AddSegment(const X1, Y1, X2, Y2: TFloat; var ScanLine: TScanLine); {$IFDEF USEINLINING} inline; {$ENDIF}
var
  S: PLineSegment;
begin
  if (Y1 = 0) and (Y2 = 0) then Exit;  
  with ScanLine do
  begin
    S := @Segments[Count];
    Inc(Count);
  end;

  S[0].X := X1;
  S[0].Y := Y1;
  S[1].X := X2;
  S[1].Y := Y2;
end;

procedure DivideSegment(var P1, P2: TFloatPoint; const ScanLines: PScanLineArray);
var
  Y, Y1, Y2: Integer;
  k, X: TFloat;
begin
  Y1 := Round(P1.Y);
  Y2 := Round(P2.Y);

  if Y1 = Y2 then
  begin
    AddSegment(P1.X, P1.Y - Y1, P2.X, P2.Y - Y1, ScanLines[Y1]);
  end
  else
  begin
    k := (P2.X - P1.X) / (P2.Y - P1.Y);
    if Y1 < Y2 then
    begin
      X := P1.X + (Y1 + 1 - P1.Y) * k;
      AddSegment(P1.X, P1.Y - Y1, X, 1, ScanLines[Y1]);
      for Y := Y1 + 1 to Y2 - 1 do
      begin
        AddSegment(X, 0, X + k, 1, ScanLines[Y]);
        X := X + k;
      end;
      AddSegment(X, 0, P2.X, P2.Y - Y2, ScanLines[Y2]);
    end
    else
    begin
      X := P1.X + (Y1 - P1.Y) * k;
      AddSegment(P1.X, P1.Y - Y1, X, 0, ScanLines[Y1]);
      for Y := Y1 - 1 downto Y2 + 1 do
      begin
        AddSegment(X, 1, X - k, 0, ScanLines[Y]);
        X := X - k
      end;
      AddSegment(X, 1, P2.X, P2.Y - Y2, ScanLines[Y2]);
    end;
  end;
end;

procedure BuildScanLines(const Points: TArrayOfFloatPoint;
  out ScanLines: TScanLines);
var
  I, J, N, J0, J1, Y, YMin, YMax: Integer;
  PScanLines: PScanLineArray;
begin
  N := Length(Points);
  if N <= 2 then Exit;

  YMin := Round(Points[0].Y);
  YMax := YMin;
  for I := 1 to N - 1 do
  begin
    Y := Round(Points[I].Y);
    if YMin > Y then YMin := Y;
    if YMax < Y then YMax := Y;
  end;

  SetLength(ScanLines, YMax - YMin + 2);
  PScanLines := @ScanLines[-YMin];
  
  J0 := Round(Points[0].Y);
  for I := 1 to N - 1 do
  begin
    J1 := J0;
    J0 := Round(Points[I].Y);
    if J0 <= J1 then
    begin
      Inc(PScanLines[J0].Count);
      Dec(PScanLines[J1 + 1].Count);
    end
    else
    begin
      Inc(PScanLines[J1].Count);
      Dec(PScanLines[J0 + 1].Count);
    end;
  end;
  
  J := 0;
  for I := 0 to High(ScanLines) do
  begin
    Inc(J, ScanLines[I].Count);
    GetMem(ScanLines[I].Segments, J * SizeOf(TLineSegment));
    ScanLines[I].Count := 0;
    ScanLines[I].Y := YMin + I;
  end;

  for I := 0 to N - 2 do
  begin
    DivideSegment(Points[I], Points[I + 1], PScanLines);
  end;
end;

procedure MergeScanLines(const Src: TScanLines; var Dst: TScanLines);
var
  Temp: TScanLines;
  I, J, K, SrcCount, DstCount: Integer;
begin
  if Length(Src) = 0 then Exit;
  SetLength(Temp, Length(Src) + Length(Dst));

  I := 0;
  J := 0;
  K := 0;
  while (I <= High(Src)) and (J <= High(Dst)) do
  begin
    if Src[I].Y = Dst[J].Y then
    begin
      SrcCount := Src[I].Count;
      DstCount := Dst[J].Count;
      Temp[K].Count := SrcCount + DstCount;
      Temp[K].Y := Src[I].Y;
      GetMem(Temp[K].Segments, Temp[K].Count * SizeOf(TLineSegment));

      Move(Src[I].Segments[0], Temp[K].Segments[0], SrcCount * SizeOf(TLineSegment));
      Move(Dst[J].Segments[0], Temp[K].Segments[SrcCount], DstCount * SizeOf(TLineSegment));
      FreeMem(Src[I].Segments);
      FreeMem(Dst[J].Segments);
      Inc(I);
      Inc(J);
    end
    else if Src[I].Y < Dst[J].Y then
    begin
      Temp[K] := Src[I];
      Inc(I);
    end
    else
    begin
      Temp[K] := Dst[J];
      Inc(J);
    end;
    Inc(K);
  end;
  while I <= High(Src) do
  begin
    Temp[K] := Src[I];
    Inc(I); Inc(K);
  end;
  while J <= High(Dst) do
  begin
    Temp[K] := Dst[J];
    Inc(J); Inc(K);
  end;
  Dst := Copy(Temp, 0, K);
end;

procedure RenderScanline(var ScanLine: TScanLine;
  RenderProc: TRenderSpanProc; Data: Pointer; SpanData: PSingleArray; X1, X2: Integer);
var
  Span: TValueSpan;
begin
  if ScanLine.Count > 0 then
  begin
    ExtractSingleSpan(ScanLine, Span, SpanData);
    if Span.X1 < X1 then Span.X1 := X1;
    if Span.X2 > X2 then Span.X2 := X2;
    if Span.X2 < Span.X1 then Exit;

    RenderProc(Data, Span, ScanLine.Y);
    FillLongWord(SpanData[Span.X1], Span.X2 - Span.X1 + 1, 0);
  end;
end;

procedure RenderPolyPolygon(const Points: TArrayOfArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanProc; Data: Pointer);
var
  ScanLines, Temp: TScanLines;
  I: Integer;
  Poly: TArrayOfFloatPoint;
  SavedRoundMode: TFPURoundingMode;
  CX1, CX2: Integer;
  SpanData: PSingleArray;
begin
  if Length(Points) = 0 then Exit;
  SavedRoundMode := SetRoundMode(rmDown);
  try
    Poly := ClosePolygon(ClipPolygon(Points[0], ClipRect));
    BuildScanLines(Poly, ScanLines);
    for I := 1 to High(Points) do
    begin
      Poly := ClosePolygon(ClipPolygon(Points[I], ClipRect));
      BuildScanLines(Poly, Temp);
      MergeScanLines(Temp, ScanLines);
      Temp := nil;
    end;

    CX1 := Round(ClipRect.Left);
    CX2 := -Round(-ClipRect.Right) - 1;

    I := CX2 - CX1 + 4;
    GetMem(SpanData, I * SizeOf(Single));
    FillLongWord(SpanData^, I, 0);

    for I := 0 to High(ScanLines) do
    begin
      RenderScanline(ScanLines[I], RenderProc, Data, @SpanData[-CX1 + 1], CX1, CX2);
      FreeMem(ScanLines[I].Segments);
    end;
    FreeMem(SpanData);
  finally
    SetRoundMode(SavedRoundMode);
  end;
end;

procedure RenderPolygon(const Points: TArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanProc; Data: Pointer);
begin
  RenderPolyPolygon(PolyPolygon(Points), ClipRect, RenderProc, Data);
end;

procedure RenderPolyPolygon(const Points: TArrayOfArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanEvent);
begin
  with TMethod(RenderProc) do
    RenderPolyPolygon(Points, ClipRect, Code, Data);
end;

procedure RenderPolygon(const Points: TArrayOfFloatPoint;
  const ClipRect: TFloatRect; const RenderProc: TRenderSpanEvent);
begin
  with TMethod(RenderProc) do
    RenderPolygon(Points, ClipRect, Code, Data);
end;

end.
 