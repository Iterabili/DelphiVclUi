unit uUiButton;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms;

type
  TUiButtonKind = (ubkPrimary, ubkSecondary, ubkDanger);

  TUiButton = class(TCustomControl)
  private
    FKind: TUiButtonKind;
    FHover: Boolean;
    FPressed: Boolean;
    FMouseFocus: Boolean;
    FModalResult: TModalResult;
    FDefault: Boolean;
    FCancel: Boolean;
    FActive: Boolean;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    procedure CMDialogKey(var Message: TCMDialogKey); message CM_DIALOGKEY;
    procedure CMFocusChanged(var Message: TCMFocusChanged); message CM_FOCUSCHANGED;
    procedure SetKind(const AValue: TUiButtonKind);
    procedure SetDefault(const AValue: Boolean);
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
  published
    property Align;
    property Anchors;
    property Cancel: Boolean read FCancel write FCancel default False;
    property Caption;
    property Default: Boolean read FDefault write SetDefault default False;
    property Enabled;
    property Font;
    property Hint;
    property Kind: TUiButtonKind read FKind write SetKind default ubkSecondary;
    property ModalResult: TModalResult read FModalResult write FModalResult default mrNone;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnClick;
  end;

function AddUiButton(const AParent: TWinControl; const ACaption: string; const ALeft, ATop, AWidth, AHeight: Integer;
  const AKind: TUiButtonKind; const AOnClick: TNotifyEvent): TUiButton;

implementation

uses
  StdCtrls, Dialogs, Math, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

function IsButtonControl(const AControl: TControl): Boolean;
begin
  Result := (AControl is TUiButton) or (AControl is TButtonControl);
end;

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
var
  vForm: TCustomForm;
begin
  vForm := GetParentForm(Self);
  if Assigned(vForm) and (FModalResult <> mrNone) then
    vForm.ModalResult := FModalResult;
  try
    inherited;
  except
    on E: EUiError do
    begin
      if Assigned(vForm) then
        vForm.ModalResult := mrNone;
      MessageDlg(E.Message, mtWarning, [mbOK], 0);
    end;
  end;
end;

procedure TUiButton.SetDefault(const AValue: Boolean);
var
  vForm: TCustomForm;
begin
  FDefault := AValue;
  vForm := GetParentForm(Self);
  if Assigned(vForm) and IsButtonControl(vForm.ActiveControl) then
    FActive := vForm.ActiveControl = Self
  else
    FActive := FDefault;
end;

procedure TUiButton.CMDialogKey(var Message: TCMDialogKey);
begin
  if (((Message.CharCode = VK_RETURN) and FActive) or ((Message.CharCode = VK_ESCAPE) and FCancel)) and
    (KeyDataToShiftState(Message.KeyData) = []) and CanFocus then
  begin
    Click;
    Message.Result := 1;
  end
  else
    inherited;
end;

procedure TUiButton.CMFocusChanged(var Message: TCMFocusChanged);
begin
  if IsButtonControl(Message.Sender) then
    FActive := Message.Sender = Self
  else
    FActive := FDefault;
  inherited;
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
