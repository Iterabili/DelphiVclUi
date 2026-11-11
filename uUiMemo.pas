unit uUiMemo;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls;

type
  TUiMemo = class(TCustomControl)
  private
    FMemo: TMemo;
    FFocused: Boolean;
    function GetText: string;
    procedure SetText(const AValue: string);
    procedure MemoEnter(Sender: TObject);
    procedure MemoExit(Sender: TObject);
    procedure LayoutMemo;
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
    property Text: string read GetText write SetText;
  end;

function AddUiMemo(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiMemo;

implementation

uses
  Math, System.Types, System.UITypes, Forms, uUiTheme, uUiPaint, uUiCard;

function AddUiMemo(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiMemo;
begin
  Result := TUiMemo.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiMemo.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  FMemo := TMemo.Create(Self);
  FMemo.Parent := Self;
  FMemo.BorderStyle := bsNone;
  FMemo.Color := clUiCard;
  FMemo.ScrollBars := ssVertical;
  FMemo.OnEnter := MemoEnter;
  FMemo.OnExit := MemoExit;
end;

function TUiMemo.GetText: string;
begin
  Result := FMemo.Text;
end;

procedure TUiMemo.SetText(const AValue: string);
begin
  FMemo.Text := AValue;
end;

procedure TUiMemo.MemoEnter(Sender: TObject);
begin
  FFocused := True;
  Invalidate;
end;

procedure TUiMemo.MemoExit(Sender: TObject);
begin
  FFocused := False;
  Invalidate;
end;

procedure TUiMemo.LayoutMemo;
var
  vPadding: Integer;
begin
  vPadding := ScaleValue(6);
  FMemo.SetBounds(vPadding + ScaleValue(4), vPadding, ClientWidth - vPadding * 2 - ScaleValue(4),
    ClientHeight - vPadding * 2);
end;

procedure TUiMemo.Resize;
begin
  inherited;
  LayoutMemo;
  Invalidate;
end;

procedure TUiMemo.Paint;
var
  vBorder: TColor;
begin
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
