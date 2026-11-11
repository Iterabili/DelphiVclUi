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

type
  EUiError = class(Exception);

  TUiLabelStyle = (ulsTitle, ulsSection, ulsBody, ulsMuted);

function AddUiLabel(const AParent: TWinControl; const ACaption: string; const ALeft, ATop: Integer;
  const AStyle: TUiLabelStyle = ulsBody): TLabel;
procedure ApplyUiFont(const AFont: TFont);

implementation

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
