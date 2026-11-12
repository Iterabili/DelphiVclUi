unit uUiPaint;

interface

uses
  Windows, Graphics, Controls;

const
  cPopupReopenGuardMs = 200;
  cSelectMaxRows = 8;

function ToGpColor(const AColor: TColor): Cardinal;
function ShadeColor(const AColor: TColor; const APercent: Integer): TColor;
function IsDarkColor(const AColor: TColor): Boolean;
procedure DrawRounded(const ACanvas: TCanvas; const ARect: TRect; const ARadius: Integer;
  const AFill, ABorder: TColor; const ABorderWidth: Integer = 1);
procedure DrawRoundedFrame(const ACanvas: TCanvas; const ARect: TRect; const ARadius: Integer;
  const ASurface, ABorder: TColor);
procedure DrawCheckMark(const ACanvas: TCanvas; const ARect: TRect; const AColor: TColor; const AWidth: Integer);
function FieldInnerRect(const AControl: TWinControl): TRect;
procedure DrawFieldFrame(const AControl: TWinControl; const ASurface, AFill, ABorder: TColor; const ARadius: Integer;
  const ATitle: string = ''; const AFont: TFont = nil);
procedure RedrawFrame(const AControl: TWinControl);
function TitleHeight(const AControl: TControl; const ATitle: string; const AFont: TFont): Integer;
procedure DrawTitle(const ACanvas: TCanvas; const AControl: TControl; const ATitle: string; const AFont: TFont);
procedure ChangeTitle(const AControl: TControl; const AFont: TFont; var ATitle: string; const AValue: string);

implementation

uses
  System.Types, Winapi.GDIPAPI, Winapi.GDIPOBJ, Classes, Math, uUiTheme;

procedure AssignTitleFont(const ATarget, ASource: TFont);
begin
  ATarget.Assign(ASource);
  ATarget.Name := cUiFontName;
  ATarget.Size := Max(1, ASource.Size - 1);
  ATarget.Style := [];
  ATarget.Color := clUiMuted;
end;

function TitleHeight(const AControl: TControl; const ATitle: string; const AFont: TFont): Integer;
var
  vFont: TFont;
  vDC: HDC;
  vOldFont: HGDIOBJ;
  vMetrics: TTextMetric;
begin
  if ATitle = '' then
    Exit(0);
  vFont := TFont.Create;
  try
    AssignTitleFont(vFont, AFont);
    vDC := GetDC(0);
    try
      vOldFont := SelectObject(vDC, vFont.Handle);
      GetTextMetrics(vDC, vMetrics);
      SelectObject(vDC, vOldFont);
    finally
      ReleaseDC(0, vDC);
    end;
  finally
    vFont.Free;
  end;
  Result := vMetrics.tmHeight + AControl.ScaleValue(4);
end;

procedure DrawTitle(const ACanvas: TCanvas; const AControl: TControl; const ATitle: string; const AFont: TFont);
var
  vRect: TRect;
  vText: string;
begin
  if ATitle = '' then
    Exit;
  AssignTitleFont(ACanvas.Font, AFont);
  ACanvas.Brush.Style := bsClear;
  vRect := Rect(0, 0, AControl.Width, TitleHeight(AControl, ATitle, AFont));
  vText := ATitle;
  ACanvas.TextRect(vRect, vText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
  ACanvas.Brush.Style := bsSolid;
end;

procedure ChangeTitle(const AControl: TControl; const AFont: TFont; var ATitle: string; const AValue: string);
var
  vOldHeight: Integer;
begin
  if ATitle = AValue then
    Exit;
  vOldHeight := TitleHeight(AControl, ATitle, AFont);
  ATitle := AValue;
  if not (csLoading in AControl.ComponentState) then
    AControl.Height := AControl.Height + TitleHeight(AControl, ATitle, AFont) - vOldHeight;
end;

function ToGpColor(const AColor: TColor): Cardinal;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := MakeColor(GetRValue(vRgb), GetGValue(vRgb), GetBValue(vRgb));
end;

function ShadeColor(const AColor: TColor; const APercent: Integer): TColor;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := TColor(RGB(GetRValue(vRgb) * (100 - APercent) div 100, GetGValue(vRgb) * (100 - APercent) div 100,
    GetBValue(vRgb) * (100 - APercent) div 100));
end;

function IsDarkColor(const AColor: TColor): Boolean;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := GetRValue(vRgb) * 299 + GetGValue(vRgb) * 587 + GetBValue(vRgb) * 114 < 150000;
end;

procedure DrawRounded(const ACanvas: TCanvas; const ARect: TRect; const ARadius: Integer;
  const AFill, ABorder: TColor; const ABorderWidth: Integer = 1);
var
  vGraphics: TGPGraphics;
  vPath: TGPGraphicsPath;
  vBrush: TGPSolidBrush;
  vPen: TGPPen;
  vDiameter, vLeft, vTop, vRight, vBottom: Integer;
begin
  vDiameter := ARadius * 2;
  vLeft := ARect.Left + ABorderWidth div 2;
  vTop := ARect.Top + ABorderWidth div 2;
  vRight := ARect.Right - 1 - (ABorderWidth - 1) div 2;
  vBottom := ARect.Bottom - 1 - (ABorderWidth - 1) div 2;
  vGraphics := TGPGraphics.Create(ACanvas.Handle);
  vPath := TGPGraphicsPath.Create;
  vBrush := TGPSolidBrush.Create(ToGpColor(AFill));
  vPen := TGPPen.Create(ToGpColor(ABorder), ABorderWidth);
  try
    vGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    vPath.AddArc(vLeft, vTop, vDiameter, vDiameter, 180, 90);
    vPath.AddArc(vRight - vDiameter, vTop, vDiameter, vDiameter, 270, 90);
    vPath.AddArc(vRight - vDiameter, vBottom - vDiameter, vDiameter, vDiameter, 0, 90);
    vPath.AddArc(vLeft, vBottom - vDiameter, vDiameter, vDiameter, 90, 90);
    vPath.CloseFigure;
    vGraphics.FillPath(vBrush, vPath);
    vGraphics.DrawPath(vPen, vPath);
  finally
    vPen.Free;
    vBrush.Free;
    vPath.Free;
    vGraphics.Free;
  end;
end;

procedure DrawRoundedFrame(const ACanvas: TCanvas; const ARect: TRect; const ARadius: Integer;
  const ASurface, ABorder: TColor);
var
  vGraphics: TGPGraphics;
  vOuter, vInner: TGPGraphicsPath;
  vRegion: TGPRegion;
  vBrush: TGPSolidBrush;
  vPen: TGPPen;
  vDiameter, vLeft, vTop, vRight, vBottom: Integer;
begin
  vDiameter := ARadius * 2;
  vLeft := ARect.Left;
  vTop := ARect.Top;
  vRight := ARect.Right - 1;
  vBottom := ARect.Bottom - 1;
  vGraphics := TGPGraphics.Create(ACanvas.Handle);
  vOuter := TGPGraphicsPath.Create;
  vInner := TGPGraphicsPath.Create;
  vBrush := TGPSolidBrush.Create(ToGpColor(ASurface));
  vPen := TGPPen.Create(ToGpColor(ABorder), 1);
  try
    vGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    vOuter.AddRectangle(MakeRect(vLeft - 1, vTop - 1, vRight - vLeft + 3, vBottom - vTop + 3));
    vInner.AddArc(vLeft, vTop, vDiameter, vDiameter, 180, 90);
    vInner.AddArc(vRight - vDiameter, vTop, vDiameter, vDiameter, 270, 90);
    vInner.AddArc(vRight - vDiameter, vBottom - vDiameter, vDiameter, vDiameter, 0, 90);
    vInner.AddArc(vLeft, vBottom - vDiameter, vDiameter, vDiameter, 90, 90);
    vInner.CloseFigure;
    vRegion := TGPRegion.Create(vOuter);
    try
      vRegion.Exclude(vInner);
      vGraphics.FillRegion(vBrush, vRegion);
    finally
      vRegion.Free;
    end;
    vGraphics.DrawPath(vPen, vInner);
  finally
    vPen.Free;
    vBrush.Free;
    vInner.Free;
    vOuter.Free;
    vGraphics.Free;
  end;
end;

procedure DrawCheckMark(const ACanvas: TCanvas; const ARect: TRect; const AColor: TColor; const AWidth: Integer);
var
  vGraphics: TGPGraphics;
  vPen: TGPPen;
  vSize: Integer;
begin
  vSize := ARect.Right - ARect.Left;
  vGraphics := TGPGraphics.Create(ACanvas.Handle);
  vPen := TGPPen.Create(ToGpColor(AColor), AWidth);
  try
    vGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    vGraphics.DrawLine(vPen, ARect.Left + vSize * 23 div 100, ARect.Top + vSize * 52 div 100,
      ARect.Left + vSize * 43 div 100, ARect.Top + vSize * 71 div 100);
    vGraphics.DrawLine(vPen, ARect.Left + vSize * 43 div 100, ARect.Top + vSize * 71 div 100,
      ARect.Left + vSize * 77 div 100, ARect.Top + vSize * 31 div 100);
  finally
    vPen.Free;
    vGraphics.Free;
  end;
end;

function FieldInnerRect(const AControl: TWinControl): TRect;
var
  vWindow: TRect;
  vOrigin: TPoint;
  vStyle: NativeInt;
begin
  GetWindowRect(AControl.Handle, vWindow);
  vOrigin := AControl.ClientOrigin;
  Result.Left := vOrigin.X - vWindow.Left;
  Result.Top := vOrigin.Y - vWindow.Top;
  Result.Right := Result.Left + AControl.ClientWidth;
  Result.Bottom := Result.Top + AControl.ClientHeight;
  vStyle := GetWindowLong(AControl.Handle, GWL_STYLE);
  if vStyle and WS_VSCROLL <> 0 then
    Inc(Result.Right, GetSystemMetrics(SM_CXVSCROLL));
  if vStyle and WS_HSCROLL <> 0 then
    Inc(Result.Bottom, GetSystemMetrics(SM_CYHSCROLL));
end;

procedure DrawFieldFrame(const AControl: TWinControl; const ASurface, AFill, ABorder: TColor; const ARadius: Integer;
  const ATitle: string; const AFont: TFont);
var
  vDC: HDC;
  vCanvas: TCanvas;
  vWindow, vRect, vInner: TRect;
begin
  GetWindowRect(AControl.Handle, vWindow);
  vRect := Rect(0, 0, vWindow.Right - vWindow.Left, vWindow.Bottom - vWindow.Top);
  vInner := FieldInnerRect(AControl);
  vDC := GetWindowDC(AControl.Handle);
  try
    ExcludeClipRect(vDC, vInner.Left, vInner.Top, vInner.Right, vInner.Bottom);
    vCanvas := TCanvas.Create;
    try
      vCanvas.Handle := vDC;
      vCanvas.Brush.Style := bsSolid;
      vCanvas.Brush.Color := ASurface;
      vCanvas.FillRect(vRect);
      if ATitle <> '' then
      begin
        DrawTitle(vCanvas, AControl, ATitle, AFont);
        vRect.Top := TitleHeight(AControl, ATitle, AFont);
      end;
      DrawRounded(vCanvas, vRect, ARadius, AFill, ABorder);
    finally
      vCanvas.Handle := 0;
      vCanvas.Free;
    end;
  finally
    ReleaseDC(AControl.Handle, vDC);
  end;
end;

procedure RedrawFrame(const AControl: TWinControl);
begin
  if AControl.HandleAllocated then
    RedrawWindow(AControl.Handle, nil, 0, RDW_FRAME or RDW_INVALIDATE or RDW_NOCHILDREN);
end;

end.
