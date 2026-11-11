unit uUiMemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, uUiTheme;

type
  TUiMemo = class(TCustomMemo)
  private
    FTitle: string;
    procedure SetTitle(const AValue: string);
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure FrameChanged;
    procedure WMNCCalcSize(var Message: TWMNCCalcSize); message WM_NCCALCSIZE;
    procedure WMNCPaint(var Message: TWMNCPaint); message WM_NCPAINT;
    procedure WMNCHitTest(var Message: TWMNCHitTest); message WM_NCHITTEST;
    procedure CMEnabledChanged(var Message: TMessage); message CM_ENABLEDCHANGED;
    procedure CMColorChanged(var Message: TMessage); message CM_COLORCHANGED;
  protected
    procedure DoEnter; override;
    procedure DoExit; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Align;
    property Alignment;
    property Anchors;
    property Color default clUiCard;
    property Enabled;
    property Font;
    property Hint;
    property Lines;
    property MaxLength;
    property ParentFont;
    property ParentShowHint;
    property ReadOnly;
    property ScrollBars default ssVertical;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Text;
    property Title: string read FTitle write SetTitle;
    property Visible;
    property WantReturns;
    property WantTabs;
    property WordWrap;
    property OnChange;
    property OnClick;
    property OnDblClick;
    property OnEnter;
    property OnExit;
    property OnKeyDown;
    property OnKeyPress;
    property OnKeyUp;
  end;

function AddUiMemo(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiMemo;

implementation

uses
  Math, System.Types, System.UITypes, Forms, uUiPaint, uUiCard;

function AddUiMemo(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiMemo;
begin
  Result := TUiMemo.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiMemo.Create(AOwner: TComponent);
begin
  inherited;
  BorderStyle := bsNone;
  ParentColor := False;
  Color := clUiCard;
  ScrollBars := ssVertical;
  Width := 200;
  Height := 90;
end;

procedure TUiMemo.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  vRect: PRect;
  vPadding: Integer;
begin
  vRect := @Message.CalcSize_Params^.rgrc[0];
  vPadding := ScaleValue(6);
  Inc(vRect^.Left, ScaleValue(10));
  Inc(vRect^.Top, TitleHeight(Self, FTitle, Font) + vPadding);
  Dec(vRect^.Right, vPadding);
  Dec(vRect^.Bottom, vPadding);
  inherited;
end;

procedure TUiMemo.WMNCPaint(var Message: TWMNCPaint);
var
  vBorder: TColor;
begin
  inherited;
  if Focused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  DrawFieldFrame(Self, SurfaceOf(Self), Color, vBorder, ScaleValue(6), FTitle, Font);
end;

procedure TUiMemo.SetTitle(const AValue: string);
begin
  ChangeTitle(Self, Font, FTitle, AValue);
  FrameChanged;
end;

procedure TUiMemo.CMFontChanged(var Message: TMessage);
begin
  inherited;
  FrameChanged;
end;

procedure TUiMemo.FrameChanged;
begin
  if HandleAllocated then
    SetWindowPos(Handle, 0, 0, 0, 0, 0, SWP_FRAMECHANGED or SWP_NOMOVE or SWP_NOSIZE or SWP_NOZORDER or
      SWP_NOACTIVATE);
end;

procedure TUiMemo.WMNCHitTest(var Message: TWMNCHitTest);
begin
  inherited;
  if (Message.Result = HTNOWHERE) or (Message.Result = HTBORDER) then
    Message.Result := HTCLIENT;
end;

procedure TUiMemo.CMEnabledChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiMemo.CMColorChanged(var Message: TMessage);
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiMemo.DoEnter;
begin
  inherited;
  RedrawFrame(Self);
end;

procedure TUiMemo.DoExit;
begin
  inherited;
  RedrawFrame(Self);
end;

end.
