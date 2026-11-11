unit uUiCard;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiCard = class(TCustomControl)
  protected
    procedure Paint; override;
    procedure Resize; override;
  public
    constructor Create(AOwner: TComponent); override;
  end;

function AddUiCard(const AParent: TWinControl; const AAlign: TAlign; const AHeight, AMargin: Integer): TUiCard;
function SurfaceOf(const AControl: TControl): TColor;

implementation

uses
  Math, System.Types, System.UITypes, uUiTheme, uUiPaint;

type
  TControlAccess = class(TControl);

function SurfaceOf(const AControl: TControl): TColor;
begin
  if AControl.Parent is TUiCard then
    Result := clUiCard
  else if Assigned(AControl.Parent) then
    Result := TControlAccess(AControl.Parent).Color
  else
    Result := clUiBg;
end;

function AddUiCard(const AParent: TWinControl; const AAlign: TAlign; const AHeight, AMargin: Integer): TUiCard;
begin
  Result := TUiCard.Create(AParent);
  Result.Parent := AParent;
  if AAlign = alTop then
    Result.SetBounds(AMargin, AParent.ClientHeight, AParent.ClientWidth - AMargin * 2, AHeight)
  else
    Result.SetBounds(AMargin, 0, AParent.ClientWidth - AMargin * 2, AHeight);
  Result.Align := AAlign;
  Result.AlignWithMargins := True;
  Result.Margins.SetBounds(AMargin, AMargin div 2, AMargin, AMargin div 2);
end;

constructor TUiCard.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
end;

procedure TUiCard.Paint;
begin
  Canvas.Brush.Color := clUiBg;
  Canvas.FillRect(ClientRect);
  DrawRounded(Canvas, ClientRect, ScaleValue(10), clUiCard, clUiBorder);
end;

procedure TUiCard.Resize;
begin
  inherited;
  Invalidate;
end;

end.
