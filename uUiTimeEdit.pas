unit uUiTimeEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, uUiEdit;

type
  TUiTimeEdit = class(TUiEdit)
  private
    FSelectOnClick: Boolean;
    function GetTime: TDateTime;
    procedure SetTime(const AValue: TDateTime);
  protected
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure Click; override;
    procedure KeyPress(var Key: Char); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Normalize;
    property Time: TDateTime read GetTime write SetTime;
  published
    property MaxLength default 5;
  end;

function NormalizeUiTime(const AText: string): string;
function AddUiTimeEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiTimeEdit;

implementation

uses
  StrUtils, DateUtils;

function NormalizeUiTime(const AText: string): string;
var
  vHours, vMinutes: Integer;
  vDigits: string;
begin
  vDigits := ReplaceStr(Trim(AText), ':', '');
  vHours := 0;
  vMinutes := 0;
  case Length(vDigits) of
    1 .. 2:
      vHours := StrToIntDef(vDigits, 0);
    3:
      begin
        vHours := StrToIntDef(Copy(vDigits, 1, 1), 0);
        vMinutes := StrToIntDef(Copy(vDigits, 2, 2), 0);
      end;
    4:
      begin
        vHours := StrToIntDef(Copy(vDigits, 1, 2), 0);
        vMinutes := StrToIntDef(Copy(vDigits, 3, 2), 0);
      end;
  end;
  if (vHours < 0) or (vHours > 23) then
    vHours := 0;
  if (vMinutes < 0) or (vMinutes > 59) then
    vMinutes := 0;
  Result := Format('%d:%.2d', [vHours, vMinutes]);
end;

function AddUiTimeEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiTimeEdit;
begin
  Result := TUiTimeEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiTimeEdit.Create(AOwner: TComponent);
begin
  inherited;
  MaxLength := 5;
  Width := 80;
  Text := '0:00';
end;

procedure TUiTimeEdit.Normalize;
begin
  Text := NormalizeUiTime(Text);
end;

function TUiTimeEdit.GetTime: TDateTime;
var
  vText: string;
  vColon: Integer;
begin
  vText := NormalizeUiTime(Text);
  vColon := Pos(':', vText);
  Result := EncodeTime(StrToInt(Copy(vText, 1, vColon - 1)), StrToInt(Copy(vText, vColon + 1, 2)), 0, 0);
end;

procedure TUiTimeEdit.SetTime(const AValue: TDateTime);
begin
  Text := Format('%d:%.2d', [HourOf(AValue), MinuteOf(AValue)]);
end;

procedure TUiTimeEdit.DoEnter;
begin
  inherited;
  SelectAll;
  FSelectOnClick := GetKeyState(VK_LBUTTON) < 0;
end;

procedure TUiTimeEdit.Click;
begin
  if FSelectOnClick then
  begin
    FSelectOnClick := False;
    SelectAll;
  end;
  inherited;
end;

procedure TUiTimeEdit.DoExit;
begin
  FSelectOnClick := False;
  Normalize;
  inherited;
end;

procedure TUiTimeEdit.KeyPress(var Key: Char);
begin
  if not CharInSet(Key, ['0' .. '9', ':', #8, #13, #27]) and (Key >= ' ') then
    Key := #0;
  inherited;
end;

end.
