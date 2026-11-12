unit uUiListBox;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, CheckLst, Forms, uUiTheme;

type
  TUiListBox = class(TListBox)
  private
    FShowFrame: Boolean;
    procedure SetShowFrame(const AValue: Boolean);
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BorderStyle default bsNone;
    property Color default clUiCard;
    property ItemHeight default 32;
    property ShowFrame: Boolean read FShowFrame write SetShowFrame default True;
    property Style default lbOwnerDrawFixed;
  end;

  TUiCheckList = class(TCheckListBox)
  private
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
  protected
    procedure DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property BorderStyle default bsNone;
    property Color default clUiCard;
    property ItemHeight default 32;
    property Style default lbOwnerDrawFixed;
  end;

implementation

uses
  Math, System.Types, System.UITypes, uUiPaint, uUiCard;

procedure ListNCCalcSize(const AControl: TWinControl; var Message: TWMNCCalcSize);
var
  vRect: PRect;
  vPadding: Integer;
begin
  vRect := @Message.CalcSize_Params^.rgrc[0];
  vPadding := AControl.ScaleValue(4);
  InflateRect(vRect^, -vPadding, -vPadding);
end;

procedure ListNCPaint(const AControl: TWinControl; const AFocused: Boolean);
var
  vBorder: TColor;
begin
  if AFocused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  DrawFieldFrame(AControl, SurfaceOf(AControl), clUiCard, vBorder, AControl.ScaleValue(6));
end;

procedure PrepareRow(const ACanvas: TCanvas; const AFont: TFont; const ASelected, AEnabled: Boolean);
begin
  ACanvas.Font.Assign(AFont);
  if ASelected then
    ACanvas.Brush.Color := clUiSelection
  else
    ACanvas.Brush.Color := clUiCard;
  if AEnabled then
    ACanvas.Font.Color := clUiText
  else
    ACanvas.Font.Color := clUiDisabledText;
end;

procedure DrawRowText(const ACanvas: TCanvas; const ARect: TRect; const AText: string);
var
  vRect: TRect;
  vText: string;
begin
  vRect := ARect;
  vText := AText;
  ACanvas.Brush.Style := bsClear;
  ACanvas.TextRect(vRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
  ACanvas.Brush.Style := bsSolid;
end;

constructor TUiListBox.Create(AOwner: TComponent);
begin
  inherited;
  FShowFrame := True;
  BorderStyle := bsNone;
  Color := clUiCard;
  Style := lbOwnerDrawFixed;
  ItemHeight := 32;
  Width := 200;
  Height := 160;
end;

procedure TUiListBox.SetShowFrame(const AValue: Boolean);
begin
  if FShowFrame = AValue then
    Exit;
  FShowFrame := AValue;
  if HandleAllocated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
      SWP_NOACTIVATE);
end;

procedure TUiListBox.WMNCCalcSize(var Message: TWMNCCalcSize);
begin
  if FShowFrame then
    ListNCCalcSize(Self, Message);
  inherited;
end;

procedure TUiListBox.WMNCPaint(var Message: TWMNCPaint);
begin
  inherited;
  if FShowFrame then
    ListNCPaint(Self, Focused);
end;

procedure TUiListBox.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiListBox.DoEnter;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiListBox.DoExit;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiListBox.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  vRect: TRect;
begin
  PrepareRow(Canvas, Font, odSelected in State, Enabled);
  if Assigned(OnDrawItem) then
    OnDrawItem(Self, Index, Rect, State)
  else
  begin
    Canvas.FillRect(Rect);
    vRect := Rect;
    Inc(vRect.Left, ScaleValue(10));
    Dec(vRect.Right, ScaleValue(6));
    if (Index >= 0) and (Index < Items.Count) then
      DrawRowText(Canvas, vRect, Items[Index]);
  end;
  if odFocused in State then
    Canvas.DrawFocusRect(Rect);
end;

constructor TUiCheckList.Create(AOwner: TComponent);
begin
  inherited;
  BorderStyle := bsNone;
  Color := clUiCard;
  Style := lbOwnerDrawFixed;
  ItemHeight := 32;
  Width := 200;
  Height := 160;
end;

procedure TUiCheckList.WMNCCalcSize(var Message: TWMNCCalcSize);
begin
  ListNCCalcSize(Self, Message);
  inherited;
end;

procedure TUiCheckList.WMNCPaint(var Message: TWMNCPaint);
begin
  inherited;
  ListNCPaint(Self, Focused);
end;

procedure TUiCheckList.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiCheckList.DoEnter;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiCheckList.DoExit;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiCheckList.DrawItem(Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  vRow, vBox, vText: TRect;
  vSize: Integer;
  vEnabled: Boolean;
  vMark: TColor;
begin
  if (Index < 0) or (Index >= Items.Count) then
    Exit;
  vEnabled := Enabled and ItemEnabled[Index];
  vRow := Rect;
  if not Header[Index] then
    vRow.Left := Rect.Left - GetCheckWidth;
  try
    PrepareRow(Canvas, Font, (odSelected in State) and not Header[Index], vEnabled);
    Canvas.FillRect(vRow);

    if Header[Index] then
    begin
      Canvas.Font.Name := cUiFontSemibold;
      vText := vRow;
      Inc(vText.Left, ScaleValue(10));
      vText.Top := vText.Top + ScaleValue(4);
      DrawRowText(Canvas, vText, Items[Index]);
      Exit;
    end;

    vSize := Min(ScaleValue(18), GetCheckWidth - ScaleValue(4));
    vBox.Left := vRow.Left + (GetCheckWidth - vSize) div 2;
    vBox.Top := (vRow.Top + vRow.Bottom - vSize) div 2;
    vBox.Right := vBox.Left + vSize;
    vBox.Bottom := vBox.Top + vSize;
    if vEnabled then
      vMark := clUiAccent
    else
      vMark := clUiDisabledText;
    case self.State[Index] of
      cbChecked:
        begin
          DrawRounded(Canvas, vBox, ScaleValue(4), vMark, vMark);
          DrawCheckMark(Canvas, vBox, clWhite, ScaleValue(2));
        end;
      cbGrayed:
        begin
          DrawRounded(Canvas, vBox, ScaleValue(4), Canvas.Brush.Color, vMark);
          InflateRect(vBox, -ScaleValue(5), -ScaleValue(5));
          DrawRounded(Canvas, vBox, ScaleValue(2), vMark, vMark);
        end;
    else
      if vEnabled then
        DrawRounded(Canvas, vBox, ScaleValue(4), clUiCard, clUiMuted)
      else
        DrawRounded(Canvas, vBox, ScaleValue(4), clUiDisabledFill, clUiDisabledText);
    end;
    Canvas.Brush.Style := bsSolid;

    if Assigned(OnDrawItem) then
    begin
      PrepareRow(Canvas, Font, odSelected in State, vEnabled);
      OnDrawItem(Self, Index, Rect, State);
      Exit;
    end;
    vText := Rect;
    Inc(vText.Left, ScaleValue(4));
    Dec(vText.Right, ScaleValue(6));
    DrawRowText(Canvas, vText, Items[Index]);
  finally
    if odFocused in State then
      Canvas.DrawFocusRect(Rect);
  end;
end;

procedure TUiCheckList.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  vIndex := ItemAtPos(Point(X, Y), True);
  if (vIndex < 0) or Header[vIndex] or not ItemEnabled[vIndex] then
    Exit;
  if X - ItemRect(vIndex).Left < GetCheckWidth then
    Exit;
  if State[vIndex] = cbChecked then
    State[vIndex] := cbUnchecked
  else
    State[vIndex] := cbChecked;
  ClickCheck;
end;

end.
