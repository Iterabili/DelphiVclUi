unit uUiEdit;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls, Forms;

type
  TUiEdit = class(TCustomControl)
  private
    FEdit: TEdit;
    FFocused: Boolean;
    function GetText: string;
    procedure SetText(const AValue: string);
    function GetOnChange: TNotifyEvent;
    procedure SetOnChange(const AValue: TNotifyEvent);
    function GetPasswordChar: Char;
    procedure SetPasswordChar(const AValue: Char);
    procedure EditEnter(Sender: TObject);
    procedure EditExit(Sender: TObject);
    procedure LayoutEdit;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    procedure Focus;
    property Text: string read GetText write SetText;
    property OnChange: TNotifyEvent read GetOnChange write SetOnChange;
    property PasswordChar: Char read GetPasswordChar write SetPasswordChar;
  end;

function AddUiEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiEdit;

implementation

uses
  Math, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

function AddUiEdit(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiEdit;
begin
  Result := TUiEdit.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiEdit.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  Cursor := crIBeam;
  FEdit := TEdit.Create(Self);
  FEdit.Parent := Self;
  FEdit.BorderStyle := bsNone;
  FEdit.Color := clUiCard;
  FEdit.OnEnter := EditEnter;
  FEdit.OnExit := EditExit;
end;

function TUiEdit.GetText: string;
begin
  Result := FEdit.Text;
end;

procedure TUiEdit.SetText(const AValue: string);
begin
  FEdit.Text := AValue;
end;

function TUiEdit.GetOnChange: TNotifyEvent;
begin
  Result := FEdit.OnChange;
end;

procedure TUiEdit.SetOnChange(const AValue: TNotifyEvent);
begin
  FEdit.OnChange := AValue;
end;

function TUiEdit.GetPasswordChar: Char;
begin
  Result := FEdit.PasswordChar;
end;

procedure TUiEdit.SetPasswordChar(const AValue: Char);
begin
  FEdit.PasswordChar := AValue;
end;

procedure TUiEdit.EditEnter(Sender: TObject);
begin
  FFocused := True;
  Invalidate;
end;

procedure TUiEdit.EditExit(Sender: TObject);
begin
  FFocused := False;
  Invalidate;
end;

procedure TUiEdit.Focus;
begin
  if FEdit.CanFocus then
    FEdit.SetFocus;
end;

procedure TUiEdit.LayoutEdit;
var
  vPadding: Integer;
begin
  vPadding := ScaleValue(10);
  FEdit.SetBounds(vPadding, (ClientHeight - FEdit.Height) div 2, ClientWidth - vPadding * 2, FEdit.Height);
end;

procedure TUiEdit.Resize;
begin
  inherited;
  LayoutEdit;
  Invalidate;
end;

procedure TUiEdit.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  Focus;
  inherited;
end;

procedure TUiEdit.Paint;
var
  vBorder: TColor;
begin
  LayoutEdit;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);
  if FFocused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  DrawRounded(Canvas, ClientRect, ScaleValue(6), clUiCard, vBorder);
end;

end.
