unit uUiPopup;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms;

type
  TUiPopup = class(TForm)
  private
    procedure PopupDeactivate(Sender: TObject);
    procedure PopupClose(Sender: TObject; var Action: TCloseAction);
    procedure PopupKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  protected
    procedure Closed; virtual; abstract;
    procedure PlaceBelow(const AControl: TControl);
  public
    constructor CreateFor(const AControl: TControl);
  end;

implementation

uses
  Math, System.Types, System.UITypes, uUiTheme;

constructor TUiPopup.CreateFor(const AControl: TControl);
begin
  inherited CreateNew(nil);
  BorderStyle := bsNone;
  Color := clUiBorder;
  ApplyUiFont(Font);
  KeyPreview := True;
  OnDeactivate := PopupDeactivate;
  OnClose := PopupClose;
  OnKeyDown := PopupKeyDown;
  PopupMode := pmExplicit;
  PopupParent := GetParentForm(AControl);
end;

procedure TUiPopup.PlaceBelow(const AControl: TControl);
var
  vPoint: TPoint;
  vWorkArea: TRect;
begin
  vPoint := AControl.ClientToScreen(Point(0, AControl.Height + 4));
  vWorkArea := Screen.MonitorFromPoint(vPoint).WorkareaRect;
  if vPoint.Y + Height > vWorkArea.Bottom then
    vPoint.Y := AControl.ClientToScreen(Point(0, 0)).Y - Height - 4;
  if vPoint.X + Width > vWorkArea.Right then
    vPoint.X := vWorkArea.Right - Width;
  SetBounds(vPoint.X, vPoint.Y, Width, Height);
end;

procedure TUiPopup.PopupDeactivate(Sender: TObject);
begin
  Close;
end;

procedure TUiPopup.PopupClose(Sender: TObject; var Action: TCloseAction);
begin
  Action := caFree;
  Closed;
end;

procedure TUiPopup.PopupKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
  begin
    Key := 0;
    Close;
  end;
end;

end.
