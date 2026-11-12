unit uUiHint;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms;

type
  TUiHintWindow = class(THintWindow)
  private
    function Px(const AValue: Integer): Integer;
    procedure ApplyRegion;
    procedure AssignHintFont(const AFont: TFont);
    procedure WMNCPaint(var Message: TMessage); message WM_NCPAINT;
  protected
    procedure CreateParams(var Params: TCreateParams); override;
    procedure Paint; override;
    procedure Resize; override;
  public
    function CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect; override;
    procedure ActivateHint(Rect: TRect; const AHint: string); override;
  end;

implementation

uses
  Math, uUiTheme, uUiPaint;

const
  cPadding = 10;
  cRadius = 8;

function TUiHintWindow.Px(const AValue: Integer): Integer;
begin
  Result := MulDiv(AValue, Screen.PixelsPerInch, 96);
end;

procedure TUiHintWindow.AssignHintFont(const AFont: TFont);
begin
  AFont.Assign(Screen.HintFont);
  AFont.Name := cUiFontName;
  AFont.Height := -Px(13);
  AFont.Color := clUiText;
end;

procedure TUiHintWindow.CreateParams(var Params: TCreateParams);
begin
  inherited;
  Params.Style := Params.Style and not WS_BORDER;
end;

procedure TUiHintWindow.WMNCPaint(var Message: TMessage);
begin
  Message.Result := 0;
end;

function TUiHintWindow.CalcHintRect(MaxWidth: Integer; const AHint: string; AData: TCustomData): TRect;
begin
  AssignHintFont(Canvas.Font);
  Result := Rect(0, 0, Max(Px(80), MaxWidth - Px(cPadding) * 2), 0);
  DrawText(Canvas.Handle, PChar(AHint), -1, Result, DT_CALCRECT or DT_LEFT or DT_WORDBREAK or DT_NOPREFIX);
  Inc(Result.Right, Px(cPadding) * 2);
  Inc(Result.Bottom, Px(cPadding) * 2 - Px(2));
end;

procedure TUiHintWindow.ActivateHint(Rect: TRect; const AHint: string);
begin
  inherited;
  ApplyRegion;
end;

procedure TUiHintWindow.Resize;
begin
  inherited;
  ApplyRegion;
end;

procedure TUiHintWindow.ApplyRegion;
var
  vRegion: HRGN;
begin
  if not HandleAllocated then
    Exit;
  vRegion := CreateRoundRectRgn(0, 0, Width + 1, Height + 1, Px(cRadius) * 2, Px(cRadius) * 2);
  SetWindowRgn(Handle, vRegion, True);
end;

procedure TUiHintWindow.Paint;
var
  vRect: TRect;
  vText: string;
begin
  vRect := ClientRect;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(vRect);
  DrawRounded(Canvas, vRect, Px(cRadius), clUiCard, clUiBorder);
  AssignHintFont(Canvas.Font);
  Canvas.Brush.Style := bsClear;
  InflateRect(vRect, -Px(cPadding), -Px(cPadding) + Px(1));
  vText := Caption;
  DrawText(Canvas.Handle, PChar(vText), -1, vRect, DT_LEFT or DT_WORDBREAK or DT_NOPREFIX);
  Canvas.Brush.Style := bsSolid;
end;

initialization
  HintWindowClass := TUiHintWindow;
  if Assigned(Application) and Application.ShowHint then
  begin
    Application.ShowHint := False;
    Application.ShowHint := True;
  end;

end.
