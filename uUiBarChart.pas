unit uUiBarChart;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Generics.Collections;

type
  TUiBarChartOrientation = (ubcVertical, ubcHorizontal);

  TUiBarChartSeries = record
    Name: string;
    Values: TArray<Double>;
    Color: TColor;
  end;

  TUiBarChart = class(TCustomControl)
  private
    FLabels: TArray<string>;
    FSeries: TList<TUiBarChartSeries>;
    FOrientation: TUiBarChartOrientation;
    FValueFormat: string;
    FEmptyText: string;
    FMaxZoom: Integer;
    FIntegral: Boolean;
    FViewStart: Integer;
    FViewCount: Integer;
    FHoverIndex: Integer;
    FDragging: Boolean;
    FDragOrigin: Integer;
    FDragStartView: Integer;
    FArea: TRect;
    FPlot: TRect;
    FSlot: Double;
    procedure SetOrientation(const AValue: TUiBarChartOrientation);
    procedure SetValueFormat(const AValue: string);
    procedure SetEmptyText(const AValue: string);
    procedure SetMaxZoom(const AValue: Integer);
    function GetSeries(const AIndex: Integer): TUiBarChartSeries;
    function GetSeriesCount: Integer;
    function ValueAt(const ASeries, AIndex: Integer): Double;
    function FormatValue(const AValue: Double): string;
    function MaxValue(const AFirst, ALast: Integer): Double;
    procedure CalcTicks(const AMax: Double; out AStep, ATop: Double);
    function MinViewCount: Integer;
    procedure ClampView;
    function IsZoomed: Boolean;
    function SlotRect(const AIndex: Integer): TRect;
    function IndexAt(const X, Y: Integer): Integer;
    function HintText(const AIndex: Integer): string;
    procedure SetHover(const AIndex: Integer);
    procedure PaintChart(const ACanvas: TCanvas);
    procedure PaintLegend(const ACanvas: TCanvas; var AArea: TRect);
    procedure PaintVertical(const ACanvas: TCanvas);
    procedure PaintHorizontal(const ACanvas: TCanvas);
    procedure PaintBar(const ACanvas: TCanvas; const ARect: TRect; const AColor: TColor);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure Clear;
    procedure SetLabels(const ALabels: TArray<string>);
    procedure AddSeries(const AName: string; const AValues: TArray<Double>; const AColor: TColor = clDefault);
    procedure ResetZoom;
    property Labels: TArray<string> read FLabels;
    property Series[const AIndex: Integer]: TUiBarChartSeries read GetSeries;
    property SeriesCount: Integer read GetSeriesCount;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Constraints;
    property Enabled;
    property Font;
    property Margins;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property ShowHint;
    property Visible;
    property EmptyText: string read FEmptyText write SetEmptyText;
    property MaxZoom: Integer read FMaxZoom write SetMaxZoom default 20;
    property Orientation: TUiBarChartOrientation read FOrientation write SetOrientation default ubcVertical;
    property ValueFormat: string read FValueFormat write SetValueFormat;
    property OnClick;
    property OnDblClick;
  end;

implementation

uses
  Math, Forms, uUiTheme, uUiPaint, uUiCard;

const
  cPalette: array[0..3] of TColor = (clUiAccent, clUiInfo, clUiSuccess, clUiPurple);
  cZoomStep = 1.5;

procedure DrawTextIn(const ACanvas: TCanvas; const ARect: TRect; const AText: string; const AFlags: Cardinal);
var
  vRect: TRect;
begin
  vRect := ARect;
  ACanvas.Brush.Style := bsClear;
  DrawText(ACanvas.Handle, PChar(AText), -1, vRect, AFlags or DT_SINGLELINE or DT_NOPREFIX or DT_VCENTER);
  ACanvas.Brush.Style := bsSolid;
end;

constructor TUiBarChart.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents, csDoubleClicks];
  FSeries := TList<TUiBarChartSeries>.Create;
  FValueFormat := '#,##0';
  FEmptyText := 'Нет данных';
  FMaxZoom := 20;
  FIntegral := True;
  FHoverIndex := -1;
  ApplyUiFont(Font);
  Font.Size := 9;
  ShowHint := True;
  Width := 400;
  Height := 220;
end;

destructor TUiBarChart.Destroy;
begin
  FreeAndNil(FSeries);
  inherited;
end;

procedure TUiBarChart.Clear;
begin
  FLabels := nil;
  FSeries.Clear;
  FIntegral := True;
  FHoverIndex := -1;
  FDragging := False;
  ResetZoom;
end;

procedure TUiBarChart.SetLabels(const ALabels: TArray<string>);
begin
  FLabels := Copy(ALabels);
  FHoverIndex := -1;
  ResetZoom;
end;

procedure TUiBarChart.AddSeries(const AName: string; const AValues: TArray<Double>; const AColor: TColor);
var
  vSeries: TUiBarChartSeries;
  vValue: Double;
begin
  vSeries.Name := AName;
  vSeries.Values := Copy(AValues);
  if AColor = clDefault then
    vSeries.Color := cPalette[FSeries.Count mod Length(cPalette)]
  else
    vSeries.Color := AColor;
  for vValue in vSeries.Values do
    if Frac(vValue) <> 0 then
      FIntegral := False;
  FSeries.Add(vSeries);
  Invalidate;
end;

procedure TUiBarChart.ResetZoom;
begin
  FViewStart := 0;
  FViewCount := Length(FLabels);
  Invalidate;
end;

procedure TUiBarChart.SetOrientation(const AValue: TUiBarChartOrientation);
begin
  if FOrientation = AValue then
    Exit;
  FOrientation := AValue;
  FHoverIndex := -1;
  ResetZoom;
end;

procedure TUiBarChart.SetValueFormat(const AValue: string);
begin
  FValueFormat := AValue;
  Invalidate;
end;

procedure TUiBarChart.SetEmptyText(const AValue: string);
begin
  FEmptyText := AValue;
  Invalidate;
end;

procedure TUiBarChart.SetMaxZoom(const AValue: Integer);
begin
  FMaxZoom := Max(1, AValue);
  ClampView;
  Invalidate;
end;

function TUiBarChart.GetSeries(const AIndex: Integer): TUiBarChartSeries;
begin
  Result := FSeries[AIndex];
end;

function TUiBarChart.GetSeriesCount: Integer;
begin
  Result := FSeries.Count;
end;

function TUiBarChart.ValueAt(const ASeries, AIndex: Integer): Double;
begin
  if (AIndex >= 0) and (AIndex < Length(FSeries[ASeries].Values)) then
    Result := FSeries[ASeries].Values[AIndex]
  else
    Result := 0;
end;

function TUiBarChart.FormatValue(const AValue: Double): string;
begin
  Result := FormatFloat(FValueFormat, AValue);
end;

function TUiBarChart.MaxValue(const AFirst, ALast: Integer): Double;
var
  I, S: Integer;
begin
  Result := 0;
  for S := 0 to FSeries.Count - 1 do
    for I := AFirst to ALast do
      Result := Max(Result, ValueAt(S, I));
end;

procedure TUiBarChart.CalcTicks(const AMax: Double; out AStep, ATop: Double);
var
  vMax, vRaw, vMagnitude, vNormal: Double;
begin
  vMax := AMax;
  if vMax <= 0 then
    vMax := 1;
  vRaw := vMax / 4;
  vMagnitude := Power(10, Floor(Log10(vRaw)));
  vNormal := vRaw / vMagnitude;
  if vNormal <= 1 then
    vNormal := 1
  else if vNormal <= 2 then
    vNormal := 2
  else if vNormal <= 2.5 then
    vNormal := 2.5
  else if vNormal <= 5 then
    vNormal := 5
  else
    vNormal := 10;
  AStep := vNormal * vMagnitude;
  if FIntegral and (AStep < 1) then
    AStep := 1;
  ATop := Ceil(vMax / AStep - 1E-9) * AStep;
end;

function TUiBarChart.MinViewCount: Integer;
begin
  Result := Max(Min(Length(FLabels), 3), Ceil(Length(FLabels) / FMaxZoom));
end;

procedure TUiBarChart.ClampView;
begin
  FViewCount := EnsureRange(FViewCount, MinViewCount, Length(FLabels));
  FViewStart := EnsureRange(FViewStart, 0, Max(0, Length(FLabels) - FViewCount));
end;

function TUiBarChart.IsZoomed: Boolean;
begin
  Result := (FOrientation = ubcVertical) and (FViewCount < Length(FLabels));
end;

function TUiBarChart.SlotRect(const AIndex: Integer): TRect;
begin
  if FOrientation = ubcVertical then
    Result := Rect(FPlot.Left + Round((AIndex - FViewStart) * FSlot), FPlot.Top,
      FPlot.Left + Round((AIndex - FViewStart + 1) * FSlot), FPlot.Bottom)
  else
    Result := Rect(FArea.Left, FPlot.Top + Round(AIndex * FSlot), FArea.Right,
      FPlot.Top + Round((AIndex + 1) * FSlot));
end;

function TUiBarChart.IndexAt(const X, Y: Integer): Integer;
begin
  Result := -1;
  if (FSlot <= 0) or (Length(FLabels) = 0) or (FSeries.Count = 0) then
    Exit;
  if FOrientation = ubcVertical then
  begin
    if (X < FPlot.Left) or (X >= FPlot.Right) or (Y < FPlot.Top) or (Y >= FArea.Bottom) then
      Exit;
    Result := FViewStart + Trunc((X - FPlot.Left) / FSlot);
    if Result >= FViewStart + FViewCount then
      Result := -1;
  end
  else
  begin
    if (X < FArea.Left) or (X >= FArea.Right) or (Y < FPlot.Top) or (Y >= FPlot.Bottom) then
      Exit;
    Result := Trunc((Y - FPlot.Top) / FSlot);
    if Result >= Length(FLabels) then
      Result := -1;
  end;
end;

function TUiBarChart.HintText(const AIndex: Integer): string;
var
  S: Integer;
  vName: string;
begin
  Result := FLabels[AIndex];
  for S := 0 to FSeries.Count - 1 do
  begin
    vName := FSeries[S].Name;
    if vName = '' then
      Result := Result + sLineBreak + FormatValue(ValueAt(S, AIndex))
    else
      Result := Result + sLineBreak + vName + ': ' + FormatValue(ValueAt(S, AIndex));
  end;
end;

procedure TUiBarChart.SetHover(const AIndex: Integer);
begin
  if FHoverIndex = AIndex then
    Exit;
  FHoverIndex := AIndex;
  Invalidate;
end;

procedure TUiBarChart.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TUiBarChart.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiBarChart.Paint;
var
  vBuffer: TBitmap;
begin
  vBuffer := TBitmap.Create;
  try
    vBuffer.SetSize(ClientWidth, ClientHeight);
    PaintChart(vBuffer.Canvas);
    Canvas.Draw(0, 0, vBuffer);
  finally
    vBuffer.Free;
  end;
end;

procedure TUiBarChart.PaintChart(const ACanvas: TCanvas);
var
  vPad: Integer;
begin
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clUiCard;
  ACanvas.FillRect(Rect(0, 0, ClientWidth, ClientHeight));
  ACanvas.Font.Assign(Font);
  vPad := ScaleValue(14);
  FArea := Rect(vPad, vPad, ClientWidth - vPad, ClientHeight - vPad);
  FSlot := 0;
  if (Length(FLabels) = 0) or (FSeries.Count = 0) then
  begin
    ACanvas.Font.Color := clUiMuted;
    DrawTextIn(ACanvas, FArea, FEmptyText, DT_CENTER);
  end
  else
  begin
    ClampView;
    PaintLegend(ACanvas, FArea);
    if FOrientation = ubcVertical then
      PaintVertical(ACanvas)
    else
      PaintHorizontal(ACanvas);
  end;
  DrawRoundedFrame(ACanvas, Rect(0, 0, ClientWidth, ClientHeight), ScaleValue(12), SurfaceOf(Self), clUiBorder);
end;

procedure TUiBarChart.PaintLegend(const ACanvas: TCanvas; var AArea: TRect);
var
  S, vSwatch, vGap, vTextH, vTotal, vX, vTextW: Integer;
  vNamed: Boolean;
begin
  vNamed := False;
  for S := 0 to FSeries.Count - 1 do
    if FSeries[S].Name <> '' then
      vNamed := True;
  if not vNamed then
    Exit;
  vSwatch := ScaleValue(10);
  vGap := ScaleValue(16);
  vTextH := ACanvas.TextHeight('0');
  vTotal := 0;
  for S := 0 to FSeries.Count - 1 do
    Inc(vTotal, vSwatch + ScaleValue(6) + ACanvas.TextWidth(FSeries[S].Name) + vGap);
  Dec(vTotal, vGap);
  vX := Max(AArea.Left, AArea.Right - vTotal);
  for S := 0 to FSeries.Count - 1 do
  begin
    DrawRounded(ACanvas, Rect(vX, AArea.Top + (vTextH - vSwatch) div 2, vX + vSwatch,
      AArea.Top + (vTextH - vSwatch) div 2 + vSwatch), ScaleValue(3), FSeries[S].Color, FSeries[S].Color);
    Inc(vX, vSwatch + ScaleValue(6));
    vTextW := ACanvas.TextWidth(FSeries[S].Name);
    ACanvas.Font.Color := clUiText;
    DrawTextIn(ACanvas, Rect(vX, AArea.Top, vX + vTextW, AArea.Top + vTextH), FSeries[S].Name, DT_LEFT);
    Inc(vX, vTextW + vGap);
  end;
  Inc(AArea.Top, vTextH + ScaleValue(10));
end;

procedure TUiBarChart.PaintBar(const ACanvas: TCanvas; const ARect: TRect; const AColor: TColor);
var
  vRadius, vSaved: Integer;
  vRect: TRect;
begin
  if (ARect.Right <= ARect.Left) or (ARect.Bottom <= ARect.Top) then
    Exit;
  if FOrientation = ubcVertical then
    vRadius := Min(ScaleValue(3), Min(ARect.Width div 2, ARect.Height))
  else
    vRadius := Min(ScaleValue(3), Min(ARect.Height div 2, ARect.Width));
  if vRadius < 2 then
  begin
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := AColor;
    ACanvas.FillRect(ARect);
    Exit;
  end;
  vRect := ARect;
  if FOrientation = ubcVertical then
    Inc(vRect.Bottom, vRadius)
  else
    Dec(vRect.Left, vRadius);
  vSaved := SaveDC(ACanvas.Handle);
  try
    IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
    DrawRounded(ACanvas, vRect, vRadius, AColor, AColor);
  finally
    RestoreDC(ACanvas.Handle, vSaved);
  end;
end;

procedure TUiBarChart.PaintVertical(const ACanvas: TCanvas);
var
  vFirst, vLast, vTicks, vAxisW, vTextH, vBottom, I, S, vY, vX, vLabelStep, vLabelW, vBarH: Integer;
  vStep, vTop, vGroup, vBarW, vGap, vLeft: Double;
  vText: string;
  vTrack, vThumb, vBar: TRect;
begin
  vFirst := FViewStart;
  vLast := FViewStart + FViewCount - 1;
  CalcTicks(MaxValue(vFirst, vLast), vStep, vTop);
  vTicks := Round(vTop / vStep);
  vTextH := ACanvas.TextHeight('0');

  vAxisW := 0;
  for I := 0 to vTicks do
    vAxisW := Max(vAxisW, ACanvas.TextWidth(FormatValue(vStep * I)));
  Inc(vAxisW, ScaleValue(10));

  vBottom := FArea.Bottom - vTextH - ScaleValue(6);
  if IsZoomed then
    Dec(vBottom, ScaleValue(10));
  FPlot := Rect(FArea.Left + vAxisW, FArea.Top + vTextH div 2, FArea.Right, vBottom);
  if (FPlot.Width <= 0) or (FPlot.Height <= 0) then
    Exit;
  FSlot := FPlot.Width / FViewCount;

  if (FHoverIndex >= vFirst) and (FHoverIndex <= vLast) then
  begin
    ACanvas.Brush.Color := clUiHover;
    ACanvas.FillRect(SlotRect(FHoverIndex));
  end;

  for I := 0 to vTicks do
  begin
    vY := FPlot.Bottom - Round(I * vStep / vTop * FPlot.Height);
    if I = 0 then
      ACanvas.Pen.Color := clUiTableHeaderDivider
    else
      ACanvas.Pen.Color := clUiBorder;
    ACanvas.Pen.Width := 1;
    ACanvas.MoveTo(FPlot.Left, vY);
    ACanvas.LineTo(FPlot.Right, vY);
    ACanvas.Font.Color := clUiMuted;
    DrawTextIn(ACanvas, Rect(FArea.Left, vY - vTextH div 2, FPlot.Left - ScaleValue(8), vY + vTextH div 2 + 1),
      FormatValue(vStep * I), DT_RIGHT);
  end;

  if FSeries.Count = 1 then
    vGroup := FSlot * 0.62
  else
    vGroup := FSlot * 0.78;
  vGap := 0;
  if vGroup / FSeries.Count > ScaleValue(8) then
    vGap := ScaleValue(2);
  vBarW := (vGroup - vGap * (FSeries.Count - 1)) / FSeries.Count;
  for I := vFirst to vLast do
  begin
    vLeft := FPlot.Left + (I - vFirst) * FSlot + (FSlot - vGroup) / 2;
    for S := 0 to FSeries.Count - 1 do
    begin
      vBarH := Round(ValueAt(S, I) / vTop * FPlot.Height);
      if (ValueAt(S, I) > 0) and (vBarH < 1) then
        vBarH := 1;
      vBar.Left := Round(vLeft + S * (vBarW + vGap));
      vBar.Right := Max(vBar.Left + 1, Round(vLeft + S * (vBarW + vGap) + vBarW));
      vBar.Top := FPlot.Bottom - vBarH;
      vBar.Bottom := FPlot.Bottom;
      PaintBar(ACanvas, vBar, FSeries[S].Color);
    end;
  end;

  vLabelW := 0;
  for I := vFirst to vLast do
    vLabelW := Max(vLabelW, ACanvas.TextWidth(FLabels[I]));
  vLabelStep := Max(1, Ceil((vLabelW + ScaleValue(10)) / FSlot));
  for I := vFirst to vLast do
    if I mod vLabelStep = 0 then
    begin
      vText := FLabels[I];
      vX := FPlot.Left + Round((I - vFirst + 0.5) * FSlot);
      vLabelW := ACanvas.TextWidth(vText);
      if I = FHoverIndex then
        ACanvas.Font.Color := clUiText
      else
        ACanvas.Font.Color := clUiMuted;
      DrawTextIn(ACanvas, Rect(vX - vLabelW div 2 - 1, FPlot.Bottom + ScaleValue(6), vX + vLabelW div 2 + 2,
        FPlot.Bottom + ScaleValue(6) + vTextH), vText, DT_CENTER);
    end;

  if IsZoomed then
  begin
    vTrack := Rect(FPlot.Left, FArea.Bottom - ScaleValue(4), FPlot.Right, FArea.Bottom);
    DrawRounded(ACanvas, vTrack, ScaleValue(2), clUiDisabledFill, clUiDisabledFill);
    vThumb := vTrack;
    vThumb.Left := vTrack.Left + Round(vTrack.Width * FViewStart / Length(FLabels));
    vThumb.Right := Max(vThumb.Left + ScaleValue(8),
      vTrack.Left + Round(vTrack.Width * (FViewStart + FViewCount) / Length(FLabels)));
    if FDragging then
      DrawRounded(ACanvas, vThumb, ScaleValue(2), clUiScrollThumbHot, clUiScrollThumbHot)
    else
      DrawRounded(ACanvas, vThumb, ScaleValue(2), clUiScrollThumb, clUiScrollThumb);
  end;
end;

procedure TUiBarChart.PaintHorizontal(const ACanvas: TCanvas);
var
  vCount, vTicks, vLabelColW, vValueW, vTextH, I, S, vX, vTextW, vBarW: Integer;
  vStep, vTop, vGroup, vLimit, vBarH, vGap, vRowTop: Double;
  vText: string;
  vBar: TRect;
begin
  vCount := Length(FLabels);
  CalcTicks(MaxValue(0, vCount - 1), vStep, vTop);
  vTicks := Round(vTop / vStep);
  vTextH := ACanvas.TextHeight('0');

  vLabelColW := 0;
  for I := 0 to vCount - 1 do
    vLabelColW := Max(vLabelColW, ACanvas.TextWidth(FLabels[I]));
  vLabelColW := Min(vLabelColW + ScaleValue(12), FArea.Width * 2 div 5);

  vValueW := 0;
  if FSeries.Count = 1 then
    for I := 0 to vCount - 1 do
      vValueW := Max(vValueW, ACanvas.TextWidth(FormatValue(ValueAt(0, I))));
  vValueW := Max(vValueW, ACanvas.TextWidth(FormatValue(vTop)) div 2) + ScaleValue(10);

  FPlot := Rect(FArea.Left + vLabelColW, FArea.Top, FArea.Right - vValueW, FArea.Bottom - vTextH - ScaleValue(6));
  if (FPlot.Width <= 0) or (FPlot.Height <= 0) then
    Exit;
  FSlot := FPlot.Height / vCount;

  if (FHoverIndex >= 0) and (FHoverIndex < vCount) then
  begin
    ACanvas.Brush.Color := clUiHover;
    ACanvas.FillRect(SlotRect(FHoverIndex));
  end;

  for I := 0 to vTicks do
  begin
    vX := FPlot.Left + Round(I * vStep / vTop * FPlot.Width);
    if I = 0 then
      ACanvas.Pen.Color := clUiTableHeaderDivider
    else
      ACanvas.Pen.Color := clUiBorder;
    ACanvas.Pen.Width := 1;
    ACanvas.MoveTo(vX, FPlot.Top);
    ACanvas.LineTo(vX, FPlot.Bottom);
    vText := FormatValue(vStep * I);
    vTextW := ACanvas.TextWidth(vText);
    ACanvas.Font.Color := clUiMuted;
    DrawTextIn(ACanvas, Rect(vX - vTextW div 2 - 1, FPlot.Bottom + ScaleValue(6), vX + vTextW div 2 + 2,
      FPlot.Bottom + ScaleValue(6) + vTextH), vText, DT_CENTER);
  end;

  if FSeries.Count = 1 then
  begin
    vGroup := FSlot * 0.62;
    vLimit := ScaleValue(28);
  end
  else
  begin
    vGroup := FSlot * 0.78;
    vLimit := ScaleValue(14) * FSeries.Count;
  end;
  if vGroup > vLimit then
    vGroup := vLimit;
  vGap := 0;
  if vGroup / FSeries.Count > ScaleValue(8) then
    vGap := ScaleValue(2);
  vBarH := (vGroup - vGap * (FSeries.Count - 1)) / FSeries.Count;
  for I := 0 to vCount - 1 do
  begin
    vRowTop := FPlot.Top + I * FSlot;
    if I = FHoverIndex then
      ACanvas.Font.Color := clUiText
    else
      ACanvas.Font.Color := clUiMuted;
    DrawTextIn(ACanvas, Rect(FArea.Left, Round(vRowTop), FPlot.Left - ScaleValue(10), Round(vRowTop + FSlot)),
      FLabels[I], DT_RIGHT or DT_END_ELLIPSIS);
    for S := 0 to FSeries.Count - 1 do
    begin
      vBarW := Round(ValueAt(S, I) / vTop * FPlot.Width);
      if (ValueAt(S, I) > 0) and (vBarW < 1) then
        vBarW := 1;
      vBar.Left := FPlot.Left;
      vBar.Right := FPlot.Left + vBarW;
      vBar.Top := Round(vRowTop + (FSlot - vGroup) / 2 + S * (vBarH + vGap));
      vBar.Bottom := Max(vBar.Top + 1, Round(vRowTop + (FSlot - vGroup) / 2 + S * (vBarH + vGap) + vBarH));
      PaintBar(ACanvas, vBar, FSeries[S].Color);
      if FSeries.Count = 1 then
      begin
        ACanvas.Font.Color := clUiText;
        DrawTextIn(ACanvas, Rect(vBar.Right + ScaleValue(6), Round(vRowTop), FArea.Right, Round(vRowTop + FSlot)),
          FormatValue(ValueAt(S, I)), DT_LEFT);
      end;
    end;
  end;
end;

procedure TUiBarChart.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if (Button = mbLeft) and IsZoomed and (FSlot > 0) then
  begin
    FDragging := True;
    FDragOrigin := X;
    FDragStartView := FViewStart;
    Application.CancelHint;
    Invalidate;
  end;
end;

procedure TUiBarChart.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vStart: Integer;
begin
  inherited;
  if FDragging then
  begin
    vStart := FDragStartView + Round((FDragOrigin - X) / FSlot);
    if vStart <> FViewStart then
    begin
      FViewStart := vStart;
      ClampView;
      Invalidate;
    end;
    Exit;
  end;
  SetHover(IndexAt(X, Y));
end;

procedure TUiBarChart.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if FDragging then
  begin
    FDragging := False;
    SetHover(IndexAt(X, Y));
    Invalidate;
  end;
end;

procedure TUiBarChart.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if not FDragging then
    SetHover(-1);
end;

procedure TUiBarChart.CMHintShow(var Message: TCMHintShow);
var
  vIndex: Integer;
  vRect: TRect;
begin
  vIndex := IndexAt(Message.HintInfo.CursorPos.X, Message.HintInfo.CursorPos.Y);
  if FDragging or (vIndex < 0) then
  begin
    Message.Result := 1;
    Exit;
  end;
  vRect := SlotRect(vIndex);
  if FOrientation = ubcVertical then
    vRect.Bottom := FArea.Bottom;
  Message.HintInfo.HintStr := HintText(vIndex);
  Message.HintInfo.CursorRect := vRect;
  Message.HintInfo.HideTimeout := 30000;
  Message.Result := 0;
end;

function TUiBarChart.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  vPoint: TPoint;
  vAnchor, vOffset: Double;
  vCount: Integer;
begin
  if (FOrientation <> ubcVertical) or (Length(FLabels) < 2) or (FSeries.Count = 0) or (FSlot <= 0) then
    Exit(inherited DoMouseWheel(Shift, WheelDelta, MousePos));
  Result := True;
  vPoint := ScreenToClient(MousePos);
  vOffset := (vPoint.X - FPlot.Left) / FSlot;
  if vOffset < 0 then
    vOffset := 0
  else if vOffset > FViewCount then
    vOffset := FViewCount;
  vAnchor := FViewStart + vOffset;
  if WheelDelta > 0 then
    vCount := Round(FViewCount / cZoomStep)
  else
    vCount := Max(FViewCount + 1, Round(FViewCount * cZoomStep));
  vCount := EnsureRange(vCount, MinViewCount, Length(FLabels));
  if vCount = FViewCount then
    Exit;
  FViewStart := Round(vAnchor - (vAnchor - FViewStart) * vCount / FViewCount);
  FViewCount := vCount;
  ClampView;
  Application.CancelHint;
  SetHover(IndexAt(vPoint.X, vPoint.Y));
  Invalidate;
end;

end.
