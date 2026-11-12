unit uUiMenuBar;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Menus;

type
  TUiMenuBar = class(TCustomControl)
  private
    FMenu: TMenu;
    FHotIndex: Integer;
    FPopup: TPopupMenu;
    procedure SetMenu(const AValue: TMenu);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    procedure PopupItemClick(Sender: TObject);
    function ItemCount: Integer;
    function Item(const AIndex: Integer): TMenuItem;
    function ItemRectAt(const AIndex: Integer): TRect;
    function IndexAt(const X, Y: Integer): Integer;
    procedure ShowSubMenu(const AIndex: Integer);
  protected
    procedure Paint; override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
  public
    constructor Create(AOwner: TComponent); override;
    function ItemRect(const AItem: TMenuItem): TRect;
    function ContentWidth: Integer;
  published
    property Align;
    property Anchors;
    property Color;
    property Font;
    property Menu: TMenu read FMenu write SetMenu;
    property ParentFont default False;
    property Visible;
  end;

implementation

uses
  Forms, Math, System.Types, System.UITypes, uUiTheme, uUiPaint;

constructor TUiMenuBar.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque] - [csDoubleClicks];
  DoubleBuffered := True;
  ParentFont := False;
  Font.Name := cUiFontName;
  Font.Size := 9;
  Font.Color := clUiText;
  Color := clUiBg;
  FHotIndex := -1;
  Width := 300;
  Height := 30;
end;

procedure TUiMenuBar.SetMenu(const AValue: TMenu);
begin
  if FMenu = AValue then
    Exit;
  if Assigned(FMenu) then
    FMenu.RemoveFreeNotification(Self);
  FMenu := AValue;
  if Assigned(FMenu) then
    FMenu.FreeNotification(Self);
  FHotIndex := -1;
  Invalidate;
end;

procedure TUiMenuBar.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FMenu) then
    FMenu := nil;
end;

function TUiMenuBar.ItemCount: Integer;
begin
  if Assigned(FMenu) then
    Result := FMenu.Items.Count
  else
    Result := 0;
end;

function TUiMenuBar.Item(const AIndex: Integer): TMenuItem;
begin
  Result := FMenu.Items[AIndex];
end;

function TUiMenuBar.ItemRectAt(const AIndex: Integer): TRect;
var
  I, vLeft, vGap: Integer;
begin
  Canvas.Font.Assign(Font);
  vLeft := 0;
  vGap := ScaleValue(4);
  Result := TRect.Empty;
  for I := 0 to ItemCount - 1 do
  begin
    if not Item(I).Visible then
      Continue;
    Result := Rect(vLeft, vGap, vLeft + Canvas.TextWidth(StripHotkey(Item(I).Caption)) + ScaleValue(20),
      Height - vGap);
    if I = AIndex then
      Exit;
    vLeft := Result.Right + ScaleValue(2);
  end;
  Result := TRect.Empty;
end;

function TUiMenuBar.ItemRect(const AItem: TMenuItem): TRect;
var
  I: Integer;
begin
  for I := 0 to ItemCount - 1 do
    if Item(I) = AItem then
      Exit(ItemRectAt(I));
  Result := TRect.Empty;
end;

function TUiMenuBar.ContentWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to ItemCount - 1 do
    if Item(I).Visible then
      Result := Max(Result, ItemRectAt(I).Right);
end;

function TUiMenuBar.IndexAt(const X, Y: Integer): Integer;
var
  I: Integer;
begin
  for I := 0 to ItemCount - 1 do
    if Item(I).Visible and ItemRectAt(I).Contains(Point(X, Y)) then
      Exit(I);
  Result := -1;
end;

procedure TUiMenuBar.Paint;
var
  I: Integer;
  vRect: TRect;
  vText: string;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
  for I := 0 to ItemCount - 1 do
  begin
    if not Item(I).Visible then
      Continue;
    vRect := ItemRectAt(I);
    if (I = FHotIndex) and Item(I).Enabled then
      DrawRounded(Canvas, vRect, ScaleValue(5), clUiPressed, clUiPressed);
    Canvas.Font.Assign(Font);
    if not Item(I).Enabled then
      Canvas.Font.Color := clUiDisabledText;
    Canvas.Brush.Style := bsClear;
    vText := StripHotkey(Item(I).Caption);
    Canvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TUiMenuBar.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := IndexAt(X, Y);
  if vIndex <> FHotIndex then
  begin
    FHotIndex := vIndex;
    if vIndex >= 0 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    Invalidate;
  end;
end;

procedure TUiMenuBar.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotIndex >= 0 then
  begin
    FHotIndex := -1;
    Invalidate;
  end;
end;

procedure TUiMenuBar.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

procedure TUiMenuBar.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := IndexAt(X, Y);
  if (Button <> mbLeft) or (vIndex < 0) or not Item(vIndex).Enabled then
    Exit;
  if Item(vIndex).Count > 0 then
    ShowSubMenu(vIndex)
  else
    Item(vIndex).Click;
end;

procedure TUiMenuBar.ShowSubMenu(const AIndex: Integer);
var
  I: Integer;
  vSource, vCopy: TMenuItem;
  vRect: TRect;
  vPoint: TPoint;
begin
  if not Assigned(FPopup) then
    FPopup := TPopupMenu.Create(Self);
  FPopup.Items.Clear;
  for I := 0 to Item(AIndex).Count - 1 do
  begin
    vSource := Item(AIndex).Items[I];
    vCopy := TMenuItem.Create(FPopup);
    vCopy.Caption := vSource.Caption;
    vCopy.Enabled := vSource.Enabled;
    vCopy.Visible := vSource.Visible;
    vCopy.Checked := vSource.Checked;
    vCopy.Tag := NativeInt(vSource);
    vCopy.OnClick := PopupItemClick;
    FPopup.Items.Add(vCopy);
  end;
  vRect := ItemRectAt(AIndex);
  vPoint := ClientToScreen(Point(vRect.Left, vRect.Bottom));
  FPopup.Popup(vPoint.X, vPoint.Y);
end;

procedure TUiMenuBar.PopupItemClick(Sender: TObject);
begin
  TMenuItem(TMenuItem(Sender).Tag).Click;
end;

end.
