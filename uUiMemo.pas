unit uUiMemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, uUiTheme;

type
  TUiMemo = class(TCustomMemo)
  private
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
    property ScrollBars;
    property ShowHint;
    property TabOrder;
    property TabStop;
    property Text;
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
end;

procedure TUiMemo.WMNCCalcSize(var Message: TWMNCCalcSize);
var
  vRect: PRect;
  vPadding: Integer;
begin
  vRect := @Message.CalcSize_Params^.rgrc[0];
  vPadding := ScaleValue(6);
  Inc(vRect^.Left, ScaleValue(10));
  Inc(vRect^.Top, vPadding);
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
  DrawFieldFrame(Self, SurfaceOf(Self), Color, vBorder, ScaleValue(6));
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
