unit uUiForm;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Vcl.TitleBarCtrls, uUiMenuBar;

type
  TUiForm = class(TForm)
  private
    FTitleBarPanel: TTitleBarPanel;
    FMenuBar: TUiMenuBar;
    FTitleBarReady: Boolean;
    procedure SetupTitleBar;
    procedure ShiftContent(const ADelta: Integer);
    procedure PositionMenuBar;
    function CaptionTextWidth: Integer;
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    procedure DoShow; override;
    procedure Loaded; override;
    procedure Resize; override;
  public
    constructor CreateNew(AOwner: TComponent; Dummy: Integer = 0); override;
    function ContentTop: Integer;
    property MenuBar: TUiMenuBar read FMenuBar;
  end;

implementation

uses
  Math, Menus, uUiTheme;

constructor TUiForm.CreateNew(AOwner: TComponent; Dummy: Integer);
begin
  inherited;
  Color := clUiBg;
  ApplyUiFont(Font);
end;

function TUiForm.ContentTop: Integer;
begin
  if CustomTitleBar.Enabled then
    Result := GlassFrame.Top
  else
    Result := 0;
end;

procedure TUiForm.Loaded;
begin
  inherited;
  if Color = clBtnFace then
    Color := clUiBg;
end;

procedure TUiForm.DoShow;
begin
  SetupTitleBar;
  inherited;
end;

procedure TUiForm.Resize;
begin
  inherited;
  PositionMenuBar;
end;

procedure TUiForm.CMTextChanged(var Message: TMessage);
begin
  inherited;
  PositionMenuBar;
end;

procedure TUiForm.SetupTitleBar;
var
  vClientHeight: Integer;
  vMenu: TMainMenu;
begin
  if FTitleBarReady or (csDesigning in ComponentState) or not TTitleBar.Supported then
    Exit;
  FTitleBarReady := True;
  vClientHeight := ClientHeight;
  vMenu := Menu;
  if Assigned(vMenu) then
    Menu := nil;
  FTitleBarPanel := TTitleBarPanel.Create(nil);
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
  if Assigned(vMenu) then
  begin
    FMenuBar := TUiMenuBar.Create(Self);
    FMenuBar.Name := 'MenuBar';
    FMenuBar.Parent := FTitleBarPanel;
    FMenuBar.Font.Name := cUiFontName;
    FMenuBar.Font.Height := -ScaleValue(12);
    FMenuBar.Color := clUiBg;
    FMenuBar.Menu := vMenu;
    PositionMenuBar;
  end;
  ShiftContent(ClientHeight - vClientHeight);
end;

function TUiForm.CaptionTextWidth: Integer;
var
  vMetrics: TNonClientMetrics;
  vFont: TFont;
  vBitmap: TBitmap;
begin
  FillChar(vMetrics, SizeOf(vMetrics), 0);
  vMetrics.cbSize := SizeOf(vMetrics);
  vFont := TFont.Create;
  vBitmap := TBitmap.Create;
  try
    if SystemParametersInfo(SPI_GETNONCLIENTMETRICS, SizeOf(vMetrics), @vMetrics, 0) then
    begin
      vMetrics.lfCaptionFont.lfHeight := MulDiv(vMetrics.lfCaptionFont.lfHeight, CurrentPPI, Screen.PixelsPerInch);
      vFont.Handle := CreateFontIndirect(vMetrics.lfCaptionFont);
    end;
    vBitmap.Canvas.Font.Assign(vFont);
    Result := vBitmap.Canvas.TextWidth(Caption);
  finally
    vBitmap.Free;
    vFont.Free;
  end;
end;

procedure TUiForm.PositionMenuBar;
var
  vLeft, vTop: Integer;
begin
  if not Assigned(FMenuBar) or not Assigned(FTitleBarPanel) then
    Exit;
  vLeft := CustomTitleBar.IconRect.Right + ScaleValue(8) + CaptionTextWidth + ScaleValue(24);
  vTop := Max(0, (FTitleBarPanel.Height - ScaleValue(30)) div 2);
  FMenuBar.SetBounds(vLeft, vTop, FMenuBar.ContentWidth, Min(ScaleValue(30), FTitleBarPanel.Height));
  FMenuBar.Width := FMenuBar.ContentWidth;
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
