unit uUiEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, Forms, uUiTheme;

type
  TUiEdit = class(TCustomEdit)
  private
    FEnterToNext: Boolean;
    FTitle: string;
    function FontHeight: Integer;
    procedure SetTitle(const AValue: string);
    procedure FrameChanged;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
  protected
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    procedure KeyPress(var Key: Char); override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Alignment;
    property Anchors;
    property Color default clUiCard;
    property Enabled;
    property EnterToNext: Boolean read FEnterToNext write FEnterToNext default False;
    property Font;
    property Hint;
    property MaxLength;
    property NumbersOnly;
    property ParentFont;
    property ParentShowHint;
    property PasswordChar;
    property ReadOnly;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Text;
    property TextHint;
    property Title: string read FTitle write SetTitle;
    property Visible;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

function AddUiEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiEdit;

implementation

uses
  Math, System.Types, System.UITypes, uUiPaint, uUiCard;

function AddUiEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiEdit;
begin
  Result := TUiEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiEdit.Create(AOwner: TComponent);
begin
  inherited;
  AutoSize := False;
  BorderStyle := bsNone;
  ParentColor := False;
  Color := clUiCard;
  Width := 200;
  Height := 34;
end;

function TUiEdit.FontHeight: Integer;
var
  vDC: HDC;
  vOldFont: HFONT;
  vMetrics: TTextMetric;
begin
  vDC := GetDC(0);
  try
    vOldFont := SelectObject(vDC, Font.Handle);
    GetTextMetrics(vDC, vMetrics);
    SelectObject(vDC, vOldFont);
  finally
    ReleaseDC(0, vDC);
  end;
  Result := vMetrics.tmHeight;
end;

procedure TUiEdit.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  vRect: PRect;
  vPaddingX, vPaddingY: Integer;
begin
  vRect := @Message.CalcSize_Params^.rgrc[0];
  Inc(vRect^.Top, TitleHeight(Self, FTitle, Font));
  vPaddingX := ScaleValue(10);
  vPaddingY := Max(ScaleValue(2), (vRect^.Bottom - vRect^.Top - FontHeight) div 2);
  InflateRect(vRect^, -vPaddingX, -vPaddingY);
  inherited;
end;

procedure TUiEdit.WMNCPaint(var Message: TWMNCPaint);
var
  vBorder: TColor;
begin
  if Focused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  DrawFieldFrame(Self, SurfaceOf(Self), Color, vBorder, ScaleValue(6), FTitle, Font);
  Message.Result := 0;
end;

procedure TUiEdit.SetTitle(const AValue: string);
begin
  ChangeTitle(Self, Font, FTitle, AValue);
  FrameChanged;
end;

procedure TUiEdit.FrameChanged;
begin
  if HandleAllocated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
      SWP_NOACTIVATE);
end;

procedure TUiEdit.WMNCHitTest(var Message: TWMNCHitTest);
begin
  inherited;
  if (Message.Result = HTNOWHERE) or (Message.Result = HTBORDER) then
    Message.Result := HTCLIENT;
end;

procedure TUiEdit.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FrameChanged;
end;

procedure TUiEdit.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiEdit.CMColorChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiEdit.DoEnter;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiEdit.DoExit;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiEdit.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  if FEnterToNext and (Message.CharCode = VK_RETURN) then
    Message.Result := 1
  else
    inherited;
end;

procedure TUiEdit.KeyDown(var Key: Word; Shift: TShiftState);
var
  vForm: TCustomForm;
begin
  inherited;
  if FEnterToNext and (Key = VK_RETURN) and (Shift = []) then
  begin
    Key := 0;
    vForm := GetParentForm(Self);
    if Assigned(vForm) then
      vForm.Perform(WM_NEXTDLGCTL, 0, 0);
  end;
end;

procedure TUiEdit.KeyPress(var Key: Char);
begin
  if FEnterToNext and (Key = #13) then
    Key := #0;
  inherited;
end;

end.
