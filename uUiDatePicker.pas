unit uUiDatePicker;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiDatePicker = class(TCustomControl)
  private
    FDate: TDateTime;
    FHover: Boolean;
    FPopupOpen: Boolean;
    FPopupClosedAt: Cardinal;
    FTitle: string;
    FOnChange: TNotifyEvent;
    procedure SetTitle(const AValue: string);
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetDate(const AValue: TDateTime);
    procedure OpenPopup;
  protected
    procedure Paint; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    property Date: TDateTime read FDate write SetDate;
  published
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Title: string read FTitle write SetTitle;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
    property OnEnter;
    property OnExit;
  end;

function AddUiDatePicker(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiDatePicker;

implementation

uses
  Forms, ComCtrls, Math, System.Types, System.UITypes, Winapi.CommCtrl, Winapi.GDIPAPI, Winapi.GDIPOBJ, uUiTheme, uUiPaint, uUiCard, uUiPopup;

type
  TUiMonthCalendar = class(TMonthCalendar)
  private
    FOnPicked: TNotifyEvent;
    procedure CNNotify(var Message: TWMNotify); message CN_NOTIFY;
  public
    property OnPicked: TNotifyEvent read FOnPicked write FOnPicked;
  end;

  TUiCalendarPopup = class(TUiPopup)
  private
    FPicker: TUiDatePicker;
    FCalendar: TUiMonthCalendar;
    procedure CalendarPicked(Sender: TObject);
  protected
    procedure Closed; override;
  public
    constructor CreatePopup(const APicker: TUiDatePicker);
  end;

function AddUiDatePicker(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiDatePicker;
begin
  Result := TUiDatePicker.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

procedure TUiMonthCalendar.CNNotify(var Message: TWMNotify);
begin
  inherited;
  if (Integer(Message.NMHdr.code) = MCN_SELECT) and Assigned(FOnPicked) then
    FOnPicked(Self);
end;

constructor TUiCalendarPopup.CreatePopup(const APicker: TUiDatePicker);
var
  vRect: TRect;
begin
  inherited CreateFor(APicker);
  FPicker := APicker;

  FCalendar := TUiMonthCalendar.Create(Self);
  FCalendar.Parent := Self;
  if APicker.Date > 0 then
    FCalendar.Date := APicker.Date
  else
    FCalendar.Date := Trunc(Now);
  FCalendar.OnPicked := CalendarPicked;
  MonthCal_GetMinReqRect(FCalendar.Handle, vRect);
  FCalendar.SetBounds(1, 1, vRect.Right - vRect.Left, vRect.Bottom - vRect.Top);
  ClientWidth := FCalendar.Width + 2;
  ClientHeight := FCalendar.Height + 2;
  ActiveControl := FCalendar;
  PlaceBelow(APicker);
end;

procedure TUiCalendarPopup.CalendarPicked(Sender: TObject);
begin
  FPicker.Date := Trunc(FCalendar.Date);
  if Assigned(FPicker.FOnChange) then
    FPicker.FOnChange(FPicker);
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TUiCalendarPopup.Closed;
begin
  FPicker.FPopupOpen := False;
  FPicker.FPopupClosedAt := GetTickCount;
end;

constructor TUiDatePicker.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque] - [csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;
  Cursor := crHandPoint;
  Width := 160;
  Height := 34;
  FDate := Trunc(Now);
end;

procedure TUiDatePicker.SetTitle(const AValue: string);
begin
  ChangeTitle(Self, Font, FTitle, AValue);
  Invalidate;
end;

procedure TUiDatePicker.SetDate(const AValue: TDateTime);
begin
  FDate := AValue;
  Invalidate;
end;

procedure TUiDatePicker.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHover := True;
  Invalidate;
end;

procedure TUiDatePicker.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHover := False;
  Invalidate;
end;

procedure TUiDatePicker.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TUiDatePicker.DoExit;
begin
  inherited;
  Invalidate;
end;

procedure TUiDatePicker.OpenPopup;
begin
  if FPopupOpen or (GetTickCount - FPopupClosedAt < cPopupReopenGuardMs) then
    Exit;
  FPopupOpen := True;
  TUiCalendarPopup.CreatePopup(Self).Show;
  Invalidate;
end;

procedure TUiDatePicker.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    if CanFocus then
      SetFocus;
    OpenPopup;
  end;
end;

procedure TUiDatePicker.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key in [VK_RETURN, VK_SPACE, VK_DOWN] then
  begin
    Key := 0;
    OpenPopup;
  end
  else if Key = VK_DELETE then
  begin
    Key := 0;
    Date := 0;
    if Assigned(FOnChange) then
      FOnChange(Self);
  end;
end;

procedure TUiDatePicker.Paint;
var
  vBorder, vFill: TColor;
  vTextRect: TRect;
  vText: string;
  vArrowX, vArrowY, vArrowSize, vTop: Integer;
  vGraphics: TGPGraphics;
  vPen: TGPPen;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);
  if Focused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  if FHover then
    vFill := clUiHover
  else
    vFill := clUiCard;
  vTop := TitleHeight(Self, FTitle, Font);
  DrawTitle(Canvas, Self, FTitle, Font);
  DrawRounded(Canvas, Rect(0, vTop, Width, Height), ScaleValue(6), vFill, vBorder);

  Canvas.Font.Assign(Font);
  Canvas.Font.Color := clUiText;
  Canvas.Brush.Style := bsClear;
  vTextRect := Rect(ScaleValue(10), vTop, Width - ScaleValue(28), Height);
  if FDate > 0 then
    vText := FormatDateTime('dd.mm.yyyy', FDate)
  else
  begin
    vText := 'не указана';
    Canvas.Font.Color := clUiMuted;
  end;
  Canvas.TextRect(vTextRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix]);

  vArrowSize := ScaleValue(4);
  vArrowX := Width - ScaleValue(16);
  vArrowY := (vTop + Height) div 2 - vArrowSize div 2;
  vGraphics := TGPGraphics.Create(Canvas.Handle);
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

end.
