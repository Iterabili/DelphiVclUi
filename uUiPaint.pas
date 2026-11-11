unit uUiPaint;

interface

uses
  Windows, Graphics;

const
  cPopupReopenGuardMs = 200;
  cSelectMaxRows = 8;

function ToGpColor(const AColor: TColor): Cardinal;
procedure DrawRounded(const ACanvas: TCanvas; const ARect: TRect; const ARadius: Integer;
  const AFill, ABorder: TColor; const ABorderWidth: Integer = 1);
procedure DrawCheckMark(const ACanvas: TCanvas; const ARect: TRect; const AColor: TColor; const AWidth: Integer);

implementation

uses
  Winapi.GDIPAPI, Winapi.GDIPOBJ;

function ToGpColor(const AColor: TColor): Cardinal;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := MakeColor(GetRValue(vRgb), GetGValue(vRgb), GetBValue(vRgb));
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

end.
