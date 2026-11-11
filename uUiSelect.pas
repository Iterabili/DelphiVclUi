unit uUiSelect;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, StdCtrls;

type
  TUiSelect = class(TCustomControl)
  private
    FItems: TStringList;
    FItemIndex: Integer;
    FHover: Boolean;
    FPopupOpen: Boolean;
    FPopupClosedAt: Cardinal;
    FPlaceholder: string;
    FOnChange: TNotifyEvent;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    function GetSelectedObject: TObject;
    procedure SetSelectedObject(const AValue: TObject);
    procedure SetItemIndex(const AValue: Integer);
    function GetItem(const AIndex: Integer): string;
    function GetObject(const AIndex: Integer): TObject;
    procedure OpenPopup;
    procedure PickItem(const AIndex: Integer);
  protected
    procedure Paint; override;
    procedure DoEnter; override;
    procedure DoExit; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure ClearItems;
    procedure AddItem(const ACaption: string; const AObject: TObject = nil);
    function Count: Integer;
    function IndexOfObject(const AObject: TObject): Integer;
    property ItemIndex: Integer read FItemIndex write SetItemIndex;
    property Items[const AIndex: Integer]: string read GetItem;
    property Objects[const AIndex: Integer]: TObject read GetObject;
    property SelectedObject: TObject read GetSelectedObject write SetSelectedObject;
  published
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property Placeholder: string read FPlaceholder write FPlaceholder;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

function AddUiSelect(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiSelect;

implementation

uses
  Forms, Math, System.Types, System.UITypes, Winapi.GDIPAPI, Winapi.GDIPOBJ, uUiTheme, uUiPaint, uUiCard, uUiPopup;

type
  TUiSelectPopup = class(TUiPopup)
  private
    FSelect: TUiSelect;
    FList: TListBox;
    procedure ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
    procedure ListMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure ListMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure ListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Pick;
  protected
    procedure Closed; override;
  public
    constructor CreatePopup(const ASelect: TUiSelect);
  end;

function AddUiSelect(const AParent: TWinControl; const ALeft, ATop, AWidth, AHeight: Integer): TUiSelect;
begin
  Result := TUiSelect.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
end;

constructor TUiSelectPopup.CreatePopup(const ASelect: TUiSelect);
var
  vRows: Integer;
begin
  inherited CreateFor(ASelect);
  FSelect := ASelect;

  FList := TListBox.Create(Self);
  FList.Parent := Self;
  FList.BorderStyle := bsNone;
  FList.Style := lbOwnerDrawFixed;
  FList.ItemHeight := ScaleValue(32);
  FList.Color := clUiCard;
  FList.Items.Assign(ASelect.FItems);
  FList.ItemIndex := ASelect.FItemIndex;
  FList.OnDrawItem := ListDraw;
  FList.OnMouseMove := ListMouseMove;
  FList.OnMouseUp := ListMouseUp;
  FList.OnKeyDown := ListKeyDown;

  vRows := FList.Items.Count;
  if vRows > cSelectMaxRows then
    vRows := cSelectMaxRows;
  if vRows < 1 then
    vRows := 1;
  FList.SetBounds(1, 1, ASelect.Width - 2, vRows * FList.ItemHeight);
  ClientWidth := ASelect.Width;
  ClientHeight := FList.Height + 2;
  ActiveControl := FList;
  PlaceBelow(ASelect);
end;

procedure TUiSelectPopup.ListDraw(Control: TWinControl; Index: Integer; Rect: TRect; State: TOwnerDrawState);
var
  vRect: TRect;
  vText: string;
begin
  if odSelected in State then
    FList.Canvas.Brush.Color := clUiSelection
  else
    FList.Canvas.Brush.Color := clUiCard;
  FList.Canvas.FillRect(Rect);
  FList.Canvas.Font.Assign(Font);
  FList.Canvas.Brush.Style := bsClear;
  vRect := Rect;
  Inc(vRect.Left, ScaleValue(10));
  vText := FList.Items[Index];
  FList.Canvas.TextRect(vRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
  FList.Canvas.Brush.Style := bsSolid;
  if odFocused in State then
    FList.Canvas.DrawFocusRect(Rect);
end;

procedure TUiSelectPopup.ListMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  vIndex := FList.ItemAtPos(Point(X, Y), True);
  if (vIndex >= 0) and (vIndex <> FList.ItemIndex) then
    FList.ItemIndex := vIndex;
end;

procedure TUiSelectPopup.ListMouseUp(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) and (FList.ItemAtPos(Point(X, Y), True) >= 0) then
    Pick;
end;

procedure TUiSelectPopup.ListKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    Pick;
  end;
end;

procedure TUiSelectPopup.Pick;
begin
  if FList.ItemIndex >= 0 then
    FSelect.PickItem(FList.ItemIndex);
  PostMessage(Handle, WM_CLOSE, 0, 0);
end;

procedure TUiSelectPopup.Closed;
begin
  FSelect.FPopupOpen := False;
  FSelect.FPopupClosedAt := GetTickCount;
end;

constructor TUiSelect.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque] - [csDoubleClicks];
  DoubleBuffered := True;
  TabStop := True;
  Cursor := crHandPoint;
  FItems := TStringList.Create;
  FItemIndex := -1;
  FPlaceholder := 'Не выбрано';
end;

destructor TUiSelect.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

procedure TUiSelect.ClearItems;
begin
  FItems.Clear;
  FItemIndex := -1;
  Invalidate;
end;

procedure TUiSelect.AddItem(const ACaption: string; const AObject: TObject);
begin
  FItems.AddObject(ACaption, AObject);
  Invalidate;
end;

function TUiSelect.Count: Integer;
begin
  Result := FItems.Count;
end;

function TUiSelect.IndexOfObject(const AObject: TObject): Integer;
begin
  Result := FItems.IndexOfObject(AObject);
end;

function TUiSelect.GetItem(const AIndex: Integer): string;
begin
  Result := FItems[AIndex];
end;

function TUiSelect.GetObject(const AIndex: Integer): TObject;
begin
  Result := FItems.Objects[AIndex];
end;

procedure TUiSelect.SetItemIndex(const AValue: Integer);
begin
  if (AValue >= 0) and (AValue < FItems.Count) then
    FItemIndex := AValue
  else
    FItemIndex := -1;
  Invalidate;
end;

function TUiSelect.GetSelectedObject: TObject;
begin
  if FItemIndex >= 0 then
    Result := FItems.Objects[FItemIndex]
  else
    Result := nil;
end;

procedure TUiSelect.SetSelectedObject(const AValue: TObject);
begin
  FItemIndex := FItems.IndexOfObject(AValue);
  Invalidate;
end;

procedure TUiSelect.PickItem(const AIndex: Integer);
begin
  FItemIndex := AIndex;
  Invalidate;
  if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiSelect.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  FHover := True;
  Invalidate;
end;

procedure TUiSelect.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  FHover := False;
  Invalidate;
end;

procedure TUiSelect.DoEnter;
begin
  inherited;
  Invalidate;
end;

procedure TUiSelect.DoExit;
begin
  inherited;
  Invalidate;
end;

procedure TUiSelect.OpenPopup;
begin
  if FPopupOpen or (GetTickCount - FPopupClosedAt < cPopupReopenGuardMs) then
    Exit;
  FPopupOpen := True;
  TUiSelectPopup.CreatePopup(Self).Show;
  Invalidate;
end;

procedure TUiSelect.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited;
  if Button = mbLeft then
  begin
    if CanFocus then
      SetFocus;
    OpenPopup;
  end;
end;

procedure TUiSelect.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  if Key in [VK_RETURN, VK_SPACE, VK_DOWN] then
  begin
    Key := 0;
    OpenPopup;
  end;
end;

procedure TUiSelect.Paint;
var
  vBorder, vFill: TColor;
  vTextRect: TRect;
  vText: string;
  vArrowX, vArrowY, vArrowSize: Integer;
  vGraphics: TGPGraphics;
  vPen: TGPPen;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);
  if Focused then
    vBorder := clUiAccent
  else
    vBorder := clUiBorder;
  if FHover then
    vFill := clUiHover
  else
    vFill := clUiCard;
  DrawRounded(Canvas, ClientRect, ScaleValue(6), vFill, vBorder);

  Canvas.Font.Assign(Font);
  Canvas.Brush.Style := bsClear;
  if FItemIndex >= 0 then
  begin
    vText := FItems[FItemIndex];
    Canvas.Font.Color := clUiText;
  end
  else
  begin
    vText := FPlaceholder;
    Canvas.Font.Color := clUiMuted;
  end;
  vTextRect := Rect(ScaleValue(10), 0, Width - ScaleValue(28), Height);
  Canvas.TextRect(vTextRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);

  vArrowSize := ScaleValue(4);
  vArrowX := Width - ScaleValue(16);
  vArrowY := Height div 2 - vArrowSize div 2;
  vGraphics := TGPGraphics.Create(Canvas.Handle);
  vPen := TGPPen.Create(ToGpColor(clUiMuted), ScaleValue(2));
  try
    vGraphics.SetSmoothingMode(SmoothingModeAntiAlias);
    vGraphics.DrawLine(vPen, vArrowX - vArrowSize, vArrowY, vArrowX, vArrowY + vArrowSize);
    vGraphics.DrawLine(vPen, vArrowX, vArrowY + vArrowSize, vArrowX + vArrowSize, vArrowY);
  finally
    vPen.Free;
    vGraphics.Free;
  end;
end;

end.
