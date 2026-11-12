unit uUiTheme;

interface

uses
  SysUtils, Graphics, Controls, StdCtrls;

const
  clUiBg = TColor($00F8F6F4);
  clUiCard = TColor($00FFFFFF);
  clUiBorder = TColor($00EBE6E2);
  clUiText = TColor($0030251E);
  clUiMuted = TColor($00857066);
  clUiAccent = TColor($000F48D9);
  clUiAccentHover = TColor($000C41C2);
  clUiAccentPressed = TColor($0012349A);
  clUiHover = TColor($00F7F4F2);
  clUiSelection = TColor($00E8F1FF);
  clUiRowSelected = TColor($00C8DCFF);
  clUiPressed = TColor($00ECE7E4);
  clUiDanger = TColor($001823B4);
  clUiDangerHover = TColor($00F2F3FE);
  clUiDangerBorder = TColor($009BA2FD);
  clUiDisabledFill = TColor($00F0ECEA);
  clUiDisabledText = TColor($00B3A298);
  clUiWarning = TColor($000847B5);
  clUiSuccess = TColor($003D8015);
  clUiScrollThumb = TColor($00D6CFC9);
  clUiScrollThumbHot = TColor($00A99D95);
  clUiTableHeader = TColor($00F3EFEC);
  clUiTableHeaderDivider = TColor($00C2B8B1);
  cUiFontName = 'Segoe UI';
  cUiFontSemibold = 'Segoe UI Semibold';
  cUiFontMono = 'Consolas';
  cUiFontSize = 10;

  cUiIconAdd = #$E710;
  cUiIconDelete = #$E74D;
  cUiIconEdit = #$E70F;
  cUiIconCalculator = #$E8EF;
  cUiIconClock = #$E823;
  cUiIconComment = #$E90A;
  cUiIconCalendar = #$E787;
  cUiIconPeople = #$E716;
  cUiIconContact = #$E77B;
  cUiIconHistory = #$E81C;
  cUiIconMore = #$E712;
  cUiIconSearch = #$E721;
  cUiIconPause = #$E769;
  cUiIconPlay = #$E768;
  cUiIconTag = #$E8EC;
  cUiIconSwitch = #$E8AB;
  cUiIconMoney = #$E8C7;
  cUiIconCheckList = #$E9D5;

  clUiInfo = TColor($00C0782B);
  clUiPurple = TColor($00B0457E);

type
  EUiError = class(Exception);

  TUiLabelStyle = (ulsTitle, ulsSection, ulsBody, ulsMuted);

function AddUiLabel(const AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer;
  const AStyle: TUiLabelStyle = ulsBody): TLabel;
procedure ApplyUiFont(const AFont: TFont);
function UiIconFontName: string;
function TintColor(const AColor: TColor; const APercent: Integer): TColor;

implementation

uses
  Windows, Forms;

var
  GIconFontName: string;

function UiIconFontName: string;
begin
  if GIconFontName = '' then
  begin
    if Screen.Fonts.IndexOf('Segoe Fluent Icons') >= 0 then
      GIconFontName := 'Segoe Fluent Icons'
    else
      GIconFontName := 'Segoe MDL2 Assets';
  end;
  Result := GIconFontName;
end;

function TintColor(const AColor: TColor; const APercent: Integer): TColor;
var
  vRgb: COLORREF;
begin
  vRgb := ColorToRGB(AColor);
  Result := TColor(RGB(GetRValue(vRgb) + (255 - GetRValue(vRgb)) * APercent div 100,
    GetGValue(vRgb) + (255 - GetGValue(vRgb)) * APercent div 100,
    GetBValue(vRgb) + (255 - GetBValue(vRgb)) * APercent div 100));
end;

procedure ApplyUiFont(const AFont: TFont);
begin
  AFont.Name := cUiFontName;
  AFont.Size := cUiFontSize;
  AFont.Color := clUiText;
end;

function AddUiLabel(const AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer;
  const AStyle: TUiLabelStyle): TLabel;
begin
  Result := TLabel.Create(AParent);
  Result.Parent := AParent;
  Result.Transparent := True;
  Result.Caption := ACaption;
  Result.Left := ALeft;
  Result.Top := ATop;
  Result.Font.Name := cUiFontName;
  Result.Font.Color := clUiText;
  case AStyle of
    ulsTitle:
      begin
        Result.Font.Name := cUiFontSemibold;
        Result.Font.Size := 18;
      end;
    ulsSection:
      begin
        Result.Font.Name := cUiFontSemibold;
        Result.Font.Size := 11;
      end;
    ulsBody:
      Result.Font.Size := cUiFontSize;
    ulsMuted:
      begin
        Result.Font.Size := 9;
        Result.Font.Color := clUiMuted;
      end;
  end;
end;

end.
