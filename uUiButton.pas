unit uUiButton;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiButtonKind = (ubkPrimary, ubkSecondary, ubkDanger);

  TUiButton = class(TCustomControl)
  private
    FKind: TUiButtonKind;
    FHover: Boolean;
    FPressed: Boolean;
    FMouseFocus: Boolean;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure SetKind(const AValue: TUiButtonKind);
  protected
    procedure Paint; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Click; override;
    property Kind: TUiButtonKind read FKind write SetKind;
    property Caption;
    property OnClick;
  end;

function AddUiButton(const AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth, AHeight: Integer;
  const AKind: TUiButtonKind; const AOnClick: TNotifyEvent): TUiButton;

implementation

uses
  Dialogs, Math, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

function AddUiButton(const AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth, AHeight: Integer;
  const AKind: TUiButtonKind; const AOnClick: TNotifyEvent): TUiButton;
begin
  Result := TUiButton.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
  Result.Kind := AKind;
  Result.Caption := ACaption;
  Result.OnClick := AOnClick;
end;

constructor TUiButton.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csCaptureMouse, csClickEvents, csOpaque] - [csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;
  Cursor := crHandPoint;
  FKind := ubkSecondary;
end;

procedure TUiButton.Click;
begin
  try
    inherited;
  except
    on E: EUiError do
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TUiButton.SetKind(const AValue: TUiButtonKind);
begin
  FKind := AValue;
  Invalidate;
end;

procedure TUiButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHover := True;
  Invalidate;
end;

procedure TUiButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHover := False;
  Invalidate;
end;

procedure TUiButton.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  FHover := False;
  FPressed := False;
  Invalidate;
end;

procedure TUiButton.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiButton.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TUiButton.DoExit;
begin
  inherited;
  FMouseFocus := False;
  Invalidate;
end;

procedure TUiButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then
  begin
    FMouseFocus := True;
    FPressed := True;
    if CanFocus then
      SetFocus;
    Invalidate;
  end;
  inherited;
end;

procedure TUiButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  FPressed := False;
  Invalidate;
  inherited;
end;

procedure TUiButton.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key in [VK_RETURN, VK_SPACE] then
  begin
    Key := 0;
    Click;
  end;
end;

procedure TUiButton.Paint;
var
  vFill, vBorder, vText: TColor;
  vRect: TRect;
  vCaption: string;
begin
  if not Enabled then
  begin
    vFill := clUiDisabledFill;
    vBorder := clUiDisabledFill;
    vText := clUiDisabledText;
  end
  else
    case FKind of
      ubkPrimary:
        begin
          if FPressed then
            vFill := clUiAccentPressed
          else if FHover then
            vFill := clUiAccentHover
          else
            vFill := clUiAccent;
          vBorder := vFill;
          vText := clWhite;
        end;
      ubkDanger:
        begin
          if FPressed or FHover then
            vFill := clUiDangerHover
          else
            vFill := clUiCard;
          vBorder := clUiDangerBorder;
          vText := clUiDanger;
        end;
    else
      begin
        if FPressed then
          vFill := clUiPressed
        else if FHover then
          vFill := clUiHover
        else
          vFill := clUiCard;
        vBorder := clUiBorder;
        vText := clUiText;
      end;
    end;

  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);
  DrawRounded(Canvas, ClientRect, ScaleValue(6), vFill, vBorder);
  if Focused and not FMouseFocus then
    DrawRounded(Canvas, Rect(ScaleValue(2), ScaleValue(2), Width - ScaleValue(2), Height - ScaleValue(2)),
      ScaleValue(5), vFill, clUiAccentPressed);

  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  Canvas.Font.Color := vText;
  Canvas.Brush.Style := bsClear;
  vRect := ClientRect;
  vCaption := Caption;
  Canvas.TextRect(vRect, vCaption, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
end;

end.
