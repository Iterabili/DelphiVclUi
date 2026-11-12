unit uUiColorPicker;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, uUiEdit;

const
  CM_UI_PICK_OTHER_COLOR = WM_USER + 501;

type
  TUiColorPicker = class(TUiEdit)
  private
    FSelectedColor: TColor;
    FUsedColors: TArray<TColor>;
    FPopupOpen: Boolean;
    FPopupClosedAt: Cardinal;
    FSettingText: Boolean;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure WMNCLButtonDown(var Message: TWMNCLButtonDown); message WM_NCLBUTTONDOWN;
    procedure WMSetCursor(var Message: TWMSetCursor); message WM_SETCURSOR;
    procedure CMPickOtherColor(var Message: TMessage); message CM_UI_PICK_OTHER_COLOR;
    procedure SetSelectedColor(const AValue: TColor);
    procedure ShowColorText;
    function SwatchRect: TRect;
    function ButtonRect: TRect;
    function IsPickArea(const AScreenPoint: TPoint): Boolean;
    procedure OpenPopup;
    procedure PickColor(const AColor: TColor);
    procedure PickOtherColor;
  protected
    procedure Change; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
    function TextInsetLeft: Integer; override;
    function TextInsetRight: Integer; override;
    procedure PaintAdornments(const ACanvas: TCanvas; const AField: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    property UsedColors: TArray<TColor> read FUsedColors write FUsedColors;
  published
    property MaxLength default 7;
    property SelectedColor: TColor read FSelectedColor write SetSelectedColor default clNone;
  end;

function ColorToHex(const AColor: TColor): string;
function TryHexToColor(const AText: string; out AColor: TColor): Boolean;
function AddUiColorPicker(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiColorPicker;

implementation

uses
  Forms, Dialogs, Math, System.Types, System.UITypes, Winapi.GDIPAPI, Winapi.GDIPOBJ, uUiTheme, uUiPaint, uUiCard,
  uUiPopup, uUiButton;

const
  cPaletteColumns = 8;
  cPalette: array [0 .. 15] of TColor = (
    $00353EE5, $00008CFB, $0025A8F9, $0047A043, $007B8900, $00E5881E, $00AB4939, $00AA248E,
    $0028286C, $0000519E, $00249D9E, $00327D2E, $00C1AC00, $00C06515, $00601BD8, $007A6E54);

type
  TUiColorGrid = class(TCustomControl)
  private
    FPicker: TUiColorPicker;
    FColors: TArray<TColor>;
    FPaletteCount: Integer;
    FHot: Integer;
    FFocusIndex: Integer;
    function SwatchSize: Integer;
    function Gap: Integer;
    function SectionHeight: Integer;
    function SwatchRect(const AIndex: Integer): TRect;
    function IndexAt(const X, Y: Integer): Integer;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor CreateFor(const AOwner: TComponent; const APicker: TUiColorPicker);
    function ContentHeight: Integer;
    function ContentWidth: Integer;
  end;

  TUiColorPopup = class(TUiPopup)
  private
    FPicker: TUiColorPicker;
    FGrid: TUiColorGrid;
    FOtherButton: TUiButton;
    procedure OtherClick(Sender: TObject);
  protected
    procedure Closed; override;
  public
    constructor CreatePopup(const APicker: TUiColorPicker);
    procedure Pick(const AColor: TColor);
  end;

function ColorToHex(const AColor: TColor): string;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := Format('#%.2X%.2X%.2X', [GetRValue(vRgb), GetGValue(vRgb), GetBValue(vRgb)]);
end;

function AddUiColorPicker(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiColorPicker;
begin
  Result := TUiColorPicker.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiColorGrid.CreateFor(const AOwner: TComponent; const APicker: TUiColorPicker);
var
  I, J: Integer;
  vFound: Boolean;
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  TabStop := True;
  Cursor := crHandPoint;
  FPicker := APicker;
  FHot := -1;
  FFocusIndex := -1;
  FPaletteCount := Length(cPalette);
  SetLength(FColors, FPaletteCount);
  for I := 0 to FPaletteCount - 1 do
    FColors[I] := cPalette[I];
  for I := 0 to High(APicker.FUsedColors) do
  begin
    if APicker.FUsedColors[I] = clNone then
      Continue;
    vFound := False;
    for J := FPaletteCount to High(FColors) do
      if ColorToRGB(FColors[J]) = ColorToRGB(APicker.FUsedColors[I]) then
        vFound := True;
    if not vFound and (Length(FColors) - FPaletteCount < cPaletteColumns * 2) then
    begin
      SetLength(FColors, Length(FColors) + 1);
      FColors[High(FColors)] := APicker.FUsedColors[I];
    end;
  end;
  if APicker.FSelectedColor <> clNone then
    for I := 0 to High(FColors) do
      if ColorToRGB(FColors[I]) = ColorToRGB(APicker.FSelectedColor) then
        FFocusIndex := I;
  if FFocusIndex < 0 then
    FFocusIndex := 0;
end;

function TUiColorGrid.SwatchSize: Integer;
begin
  Result := ScaleValue(24);
end;

function TUiColorGrid.Gap: Integer;
begin
  Result := ScaleValue(6);
end;

function TUiColorGrid.SectionHeight: Integer;
begin
  if Length(FColors) > FPaletteCount then
    Result := TitleHeight(Self, 'X', Font) + Gap
  else
    Result := 0;
end;

function TUiColorGrid.SwatchRect(const AIndex: Integer): TRect;
var
  vIndex, vTop: Integer;
begin
  vIndex := AIndex;
  vTop := 0;
  if AIndex >= FPaletteCount then
  begin
    vIndex := AIndex - FPaletteCount;
    vTop := ((FPaletteCount - 1) div cPaletteColumns + 1) * (SwatchSize + Gap) + SectionHeight;
  end;
  Result.Left := (vIndex mod cPaletteColumns) * (SwatchSize + Gap);
  Result.Top := vTop + (vIndex div cPaletteColumns) * (SwatchSize + Gap);
  Result.Right := Result.Left + SwatchSize;
  Result.Bottom := Result.Top + SwatchSize;
end;

function TUiColorGrid.ContentWidth: Integer;
begin
  Result := cPaletteColumns * SwatchSize + (cPaletteColumns - 1) * Gap;
end;

function TUiColorGrid.ContentHeight: Integer;
begin
  Result := SwatchRect(High(FColors)).Bottom;
end;

function TUiColorGrid.IndexAt(const X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to High(FColors) do
    if SwatchRect(I).Contains(Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

procedure TUiColorGrid.Paint;
var
  I, vWidth: Integer;
  vRect: TRect;
  vBorder: TColor;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(ClientRect);
  if SectionHeight > 0 then
  begin
    vRect := SwatchRect(FPaletteCount);
    Canvas.Font.Assign(Font);
    Canvas.Font.Size := Max(1, Font.Size - 1);
    Canvas.Font.Color := clUiMuted;
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(0, vRect.Top - SectionHeight, 'Уже используются');
    Canvas.Brush.Style := bsSolid;
  end;
  for I := 0 to High(FColors) do
  begin
    vRect := SwatchRect(I);
    vBorder := ShadeColor(FColors[I], 15);
    vWidth := 1;
    if (FPicker.FSelectedColor <> clNone) and (ColorToRGB(FColors[I]) = ColorToRGB(FPicker.FSelectedColor)) then
      DrawRounded(Canvas, Rect(vRect.Left - ScaleValue(3), vRect.Top - ScaleValue(3), vRect.Right + ScaleValue(3),
        vRect.Bottom + ScaleValue(3)), ScaleValue(7), clUiCard, clUiAccent, ScaleValue(2))
    else if (I = FHot) or (Focused and (I = FFocusIndex)) then
    begin
      vBorder := clUiText;
      vWidth := ScaleValue(2);
    end;
    DrawRounded(Canvas, vRect, ScaleValue(5), FColors[I], vBorder, vWidth);
  end;
end;

procedure TUiColorGrid.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := IndexAt(X, Y);
  if vIndex <> FHot then
  begin
    FHot := vIndex;
    Invalidate;
  end;
end;

procedure TUiColorGrid.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHot := -1;
  Invalidate;
end;

procedure TUiColorGrid.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := IndexAt(X, Y);
  if (Button = mbLeft) and (vIndex >= 0) then
    TUiColorPopup(Owner).Pick(FColors[vIndex]);
end;

procedure TUiColorGrid.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TUiColorGrid.KeyDown(var Key: Word; Shift: TShiftState);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := FFocusIndex;
  case Key of
    VK_LEFT:
      Dec(vIndex);
    VK_RIGHT:
      Inc(vIndex);
    VK_UP:
      Dec(vIndex, cPaletteColumns);
    VK_DOWN:
      Inc(vIndex, cPaletteColumns);
    VK_RETURN, VK_SPACE:
      begin
        Key := 0;
        TUiColorPopup(Owner).Pick(FColors[FFocusIndex]);
        Exit;
      end;
  else
    Exit;
  end;
  Key := 0;
  FFocusIndex := EnsureRange(vIndex, 0, High(FColors));
  Invalidate;
end;

constructor TUiColorPopup.CreatePopup(const APicker: TUiColorPicker);
var
  vPadding, vWidth: Integer;
begin
  inherited CreateFor(APicker);
  FPicker := APicker;
  Color := clUiCard;
  vPadding := ScaleValue(12);

  FGrid := TUiColorGrid.CreateFor(Self, APicker);
  FGrid.Parent := Self;
  FGrid.Font.Assign(Font);
  FGrid.SetBounds(vPadding, vPadding, FGrid.ContentWidth, FGrid.ContentHeight);

  vWidth := Max(APicker.Width, FGrid.ContentWidth + vPadding * 2);
  FOtherButton := TUiButton.Create(Self);
  FOtherButton.Parent := Self;
  FOtherButton.Caption := 'Другой цвет…';
  FOtherButton.OnClick := OtherClick;
  FOtherButton.SetBounds(vPadding, FGrid.Top + FGrid.Height + vPadding, vWidth - vPadding * 2, ScaleValue(34));

  ClientWidth := vWidth;
  ClientHeight := FOtherButton.Top + FOtherButton.Height + vPadding;
  ActiveControl := FGrid;
  PlaceBelow(APicker);
end;

procedure TUiColorPopup.Pick(const AColor: TColor);
begin
  FPicker.PickColor(AColor);
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TUiColorPopup.OtherClick(Sender: TObject);
begin
  PostMessage(Handle, WM_CLOSE, 0, 0);
  PostMessage(FPicker.Handle, CM_UI_PICK_OTHER_COLOR, 0, 0);
end;

procedure TUiColorPopup.Closed;
begin
  FPicker.FPopupOpen := False;
  FPicker.FPopupClosedAt := GetTickCount;
  RedrawFrame(FPicker);
end;

function TryHexToColor(const AText: string; out AColor: TColor): Boolean;
var
  vText: string;
  vValue: Integer;
begin
  vText := Trim(AText);
  if (vText <> '') and (vText[1] = '#') then
    Delete(vText, 1, 1);
  if Length(vText) = 3 then
    vText := vText[1] + vText[1] + vText[2] + vText[2] + vText[3] + vText[3];
  Result := (Length(vText) = 6) and TryStrToInt('$' + vText, vValue);
  if Result then
    AColor := TColor(RGB((vValue shr 16) and $FF, (vValue shr 8) and $FF, vValue and $FF));
end;

constructor TUiColorPicker.Create(AOwner: TComponent);
begin
  inherited;
  Width := 160;
  MaxLength := 7;
  FSelectedColor := clNone;
  TextHint := '#RRGGBB';
end;

function TUiColorPicker.SwatchRect: TRect;
var
  vField: TRect;
  vSize: Integer;
begin
  vField := FieldRect;
  vSize := ScaleValue(18);
  Result.Left := ScaleValue(10);
  Result.Top := (vField.Top + vField.Bottom - vSize) div 2;
  Result.Right := Result.Left + vSize;
  Result.Bottom := Result.Top + vSize;
end;

function TUiColorPicker.ButtonRect: TRect;
var
  vField: TRect;
begin
  vField := FieldRect;
  Result := Rect(Width - ScaleValue(30), vField.Top, Width, vField.Bottom);
end;

function TUiColorPicker.TextInsetLeft: Integer;
begin
  Result := ScaleValue(10 + 18 + 8);
end;

function TUiColorPicker.TextInsetRight: Integer;
begin
  Result := ScaleValue(30);
end;

procedure TUiColorPicker.PaintAdornments(const ACanvas: TCanvas; const AField: TRect);
var
  vSwatch, vButton: TRect;
  vArrowX, vArrowY, vArrowSize: Integer;
  vGraphics: TGPGraphics;
  vPen: TGPPen;
begin
  vSwatch := SwatchRect;
  if FSelectedColor = clNone then
    DrawRounded(ACanvas, vSwatch, ScaleValue(4), Color, clUiMuted)
  else
    DrawRounded(ACanvas, vSwatch, ScaleValue(4), FSelectedColor, ShadeColor(FSelectedColor, 15));

  vButton := ButtonRect;
  vArrowSize := ScaleValue(4);
  vArrowX := vButton.Left + ScaleValue(14);
  vArrowY := (vButton.Top + vButton.Bottom) div 2 - vArrowSize div 2;
  vGraphics := TGPGraphics.Create(ACanvas.Handle);
  vPen := TGPPen.Create(ToGpColor(clUiMuted), ScaleValue(2));
  try
    vGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    vGraphics.DrawLine(vPen, vArrowX - vArrowSize, vArrowY, vArrowX, vArrowY + vArrowSize);
    vGraphics.DrawLine(vPen, vArrowX, vArrowY + vArrowSize, vArrowX + vArrowSize, vArrowY);
  finally
    vPen.Free;
    vGraphics.Free;
  end;
end;

function TUiColorPicker.IsPickArea(const AScreenPoint: TPoint): Boolean;
var
  vWindow: TRect;
  vPoint: TPoint;
  vSwatch: TRect;
begin
  GetWindowRect(Handle, vWindow);
  vPoint := Point(AScreenPoint.X - vWindow.Left, AScreenPoint.Y - vWindow.Top);
  vSwatch := SwatchRect;
  InflateRect(vSwatch, ScaleValue(4), ScaleValue(4));
  Result := vSwatch.Contains(vPoint) or ButtonRect.Contains(vPoint);
end;

procedure TUiColorPicker.WMNCHitTest(var Message: TWMNCHitTest);
begin
  if IsPickArea(Point(Message.XPos, Message.YPos)) then
    Message.Result := HTBORDER
  else
    inherited;
end;

procedure TUiColorPicker.WMSetCursor(var Message: TWMSetCursor);
begin
  if Message.HitTest = HTBORDER then
  begin
    Windows.SetCursor(Screen.Cursors[crHandPoint]);
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TUiColorPicker.WMNCLButtonDown(var Message: TWMNCLButtonDown);
begin
  if Message.HitTest = HTBORDER then
  begin
    if CanFocus then
      SetFocus;
    OpenPopup;
    Message.Result := 0;
  end
  else
    inherited;
end;

procedure TUiColorPicker.SetSelectedColor(const AValue: TColor);
begin
  FSelectedColor := AValue;
  ShowColorText;
  RedrawFrame(Self);
end;

procedure TUiColorPicker.ShowColorText;
begin
  FSettingText := True;
  try
    if FSelectedColor = clNone then
      Text := ''
    else
      Text := ColorToHex(FSelectedColor);
  finally
    FSettingText := False;
  end;
end;

procedure TUiColorPicker.Change;
var
  vColor: TColor;
begin
  if FSettingText then
    Exit;
  if Trim(Text) = '' then
    vColor := clNone
  else if not TryHexToColor(Text, vColor) then
    Exit;
  if vColor = FSelectedColor then
    Exit;
  FSelectedColor := vColor;
  RedrawFrame(Self);
  inherited;
end;

procedure TUiColorPicker.DoExit;
begin
  ShowColorText;
  inherited;
end;

procedure TUiColorPicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  if (Key = VK_F4) or ((Key = VK_DOWN) and (ssAlt in Shift)) then
  begin
    Key := 0;
    OpenPopup;
    Exit;
  end;
  inherited;
end;

procedure TUiColorPicker.KeyPress(var Key: Char);
begin
  if (Key >= ' ') and not CharInSet(Key, ['0' .. '9', 'a' .. 'f', 'A' .. 'F', '#']) then
    Key := #0;
  inherited;
end;

procedure TUiColorPicker.PickColor(const AColor: TColor);
var
  vChanged: Boolean;
begin
  vChanged := AColor <> FSelectedColor;
  SetSelectedColor(AColor);
  SelectAll;
  if vChanged and Assigned(OnChange) then
    OnChange(Self);
end;

procedure TUiColorPicker.PickOtherColor;
var
  vDialog: TColorDialog;
  vForm: TCustomForm;
  I: Integer;
begin
  vDialog := TColorDialog.Create(nil);
  try
    vDialog.Options := [cdFullOpen];
    if FSelectedColor <> clNone then
      vDialog.Color := FSelectedColor;
    for I := 0 to Min(High(FUsedColors), 15) do
      vDialog.CustomColors.Add('Color' + Char(Ord('A') + I) + '=' + IntToHex(ColorToRGB(FUsedColors[I]), 6));
    vForm := GetParentForm(Self);
    if Assigned(vForm) then
    begin
      if vDialog.Execute(vForm.Handle) then
        PickColor(vDialog.Color);
    end
    else if vDialog.Execute then
      PickColor(vDialog.Color);
  finally
    vDialog.Free;
  end;
end;

procedure TUiColorPicker.CMPickOtherColor(var Message: TMessage);
begin
  PickOtherColor;
end;

procedure TUiColorPicker.OpenPopup;
begin
  if FPopupOpen or (GetTickCount - FPopupClosedAt < cPopupReopenGuardMs) then
    Exit;
  FPopupOpen := True;
  TUiColorPopup.CreatePopup(Self).Show;
end;

end.
