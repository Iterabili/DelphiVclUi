unit uUiForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Vcl.TitleBarCtrls;

type
  TUiForm = class(TForm)
  private
    FTitleBarPanel: TTitleBarPanel;
    FTitleBarReady: Boolean;
    procedure SetupTitleBar;
    procedure ShiftContent(const ADelta: Integer);
  protected
    procedure DoShow; override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
  end;

implementation

uses
  uUiTheme;

constructor TUiForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited;
  Color := clUiBg;
  ApplyUiFont(Font);
end;

procedure TUiForm.DoShow;
begin
  SetupTitleBar;
  inherited;
end;

procedure TUiForm.SetupTitleBar;
var
  vClientHeight: Integer;
begin
  if FTitleBarReady or (csDesigning in ComponentState) or not TTitleBar.Supported then
    Exit;
  FTitleBarReady := True;
  vClientHeight := ClientHeight;
  FTitleBarPanel := TTitleBarPanel.Create(Self);
  FTitleBarPanel.Parent := Self;
  CustomTitleBar.Control := FTitleBarPanel;
  CustomTitleBar.Enabled := True;
  CustomTitleBar.SystemColors := False;
  CustomTitleBar.SystemButtons := False;
  CustomTitleBar.BackgroundColor := clUiBg;
  CustomTitleBar.InactiveBackgroundColor := clUiBg;
  CustomTitleBar.ForegroundColor := clUiText;
  CustomTitleBar.InactiveForegroundColor := clUiMuted;
  CustomTitleBar.ButtonBackgroundColor := clUiBg;
  CustomTitleBar.ButtonInactiveBackgroundColor := clUiBg;
  CustomTitleBar.ButtonForegroundColor := clUiText;
  CustomTitleBar.ButtonInactiveForegroundColor := clUiMuted;
  CustomTitleBar.ButtonHoverBackgroundColor := clUiPressed;
  CustomTitleBar.ButtonHoverForegroundColor := clUiText;
  CustomTitleBar.ButtonPressedBackgroundColor := clUiScrollThumb;
  CustomTitleBar.ButtonPressedForegroundColor := clUiText;
  ShiftContent(ClientHeight - vClientHeight);
end;

procedure TUiForm.ShiftContent(const ADelta: Integer);
var
  I: Integer;
  vControl: TControl;
begin
  if ADelta = 0 then
    Exit;
  for I := 0 to ControlCount - 1 do
  begin
    vControl := Controls[I];
    if (vControl = FTitleBarPanel) or (vControl.Align <> alNone) or not (akTop in vControl.Anchors) then
      Continue;
    if akBottom in vControl.Anchors then
      vControl.SetBounds(vControl.Left, vControl.Top + ADelta, vControl.Width, vControl.Height - ADelta)
    else
      vControl.Top := vControl.Top + ADelta;
  end;
end;

end.
