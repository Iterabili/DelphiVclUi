unit uUiCheck;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiCheck = class(TCustomControl)
  private
    FChecked: Boolean;
    FMouseFocus: Boolean;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure SetChecked(const AValue: Boolean);
  protected
    procedure Paint; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
    property Checked: Boolean read FChecked write SetChecked;
    property Caption;
    property OnClick;
  end;

function AddUiCheck(const AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth, AHeight: Integer): TUiCheck;

implementation

uses
  Math, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

function AddUiCheck(const AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth, AHeight: Integer): TUiCheck;
begin
  Result := TUiCheck.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
  Result.Caption := ACaption;
end;

constructor TUiCheck.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csOpaque] - [csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;
  Cursor := crHandPoint;
end;

procedure TUiCheck.Click;
begin
  FChecked := not FChecked;
  Invalidate;
  inherited;
end;

procedure TUiCheck.SetChecked(const AValue: Boolean);
begin
  FChecked := AValue;
  Invalidate;
end;

procedure TUiCheck.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiCheck.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiCheck.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TUiCheck.DoExit;
begin
  inherited;
  FMouseFocus := False;
  Invalidate;
end;

procedure TUiCheck.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FMouseFocus := True;
    if CanFocus then
      SetFocus;
  end;
  inherited;
end;

procedure TUiCheck.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key = VK_SPACE then
  begin
    Key := 0;
    Click;
  end;
end;

procedure TUiCheck.Paint;
var
  vBox, vTextRect: TRect;
  vSize: Integer;
  vFill, vBorder: TColor;
  vCaption: string;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);

  vSize := ScaleValue(18);
  vBox := Rect(0, (Height - vSize) div 2, vSize, (Height - vSize) div 2 + vSize);
  if not Enabled then
  begin
    vFill := clUiDisabledFill;
    vBorder := clUiDisabledFill;
  end
  else if FChecked then
  begin
    vFill := clUiAccent;
    vBorder := clUiAccent;
  end
  else
  begin
    vFill := clUiCard;
    if Focused and not FMouseFocus then
      vBorder := clUiAccent
    else
      vBorder := clUiMuted;
  end;
  DrawRounded(Canvas, vBox, ScaleValue(4), vFill, vBorder);
  if FChecked then
    DrawCheckMark(Canvas, vBox, clWhite, ScaleValue(2));

  Canvas.Font.Assign(Font);
  if Enabled then
    Canvas.Font.Color := clUiText
  else
    Canvas.Font.Color := clUiDisabledText;
  Canvas.Brush.Style := bsClear;
  vTextRect := Rect(vSize + ScaleValue(8), 0, Width, Height);
  vCaption := Caption;
  Canvas.TextRect(vTextRect, vCaption, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
end;

end.
