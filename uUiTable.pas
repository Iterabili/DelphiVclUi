unit uUiTable;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Generics.Collections;

type
  TUiTable = class;

  TUiTableTextFunc = reference to function(const AItem: TObject): string;
  TUiTableColorFunc = reference to function(const AItem: TObject): TColor;
  TUiSortDirection = (usdNone, usdAscending, usdDescending);
  TUiTableColumnEvent = procedure(Sender: TObject; const AColumn: Integer) of object;

  TUiTableSource = class
  public
    function Count: Integer; virtual; abstract;
    function Item(const AIndex: Integer): TObject; virtual; abstract;
    procedure Attach(const ATable: TUiTable); virtual;
    procedure Detach(const ATable: TUiTable); virtual;
  end;

  TUiListSource<T: class> = class(TUiTableSource)
  private
    FList: TList<T>;
    FOwnsList: Boolean;
  public
    constructor Create(const AList: TList<T>; const AOwnsList: Boolean = True);
    destructor Destroy; override;
    function Count: Integer; override;
    function Item(const AIndex: Integer): TObject; override;
  end;

  TUiTableColumn = class
  private
    FCaption: string;
    FWidth: Integer;
    FGetText: TUiTableTextFunc;
    FGetColor: TUiTableColorFunc;
    FSortKey: string;
    FSort: TUiSortDirection;
  public
    property Caption: string read FCaption write FCaption;
    property Width: Integer read FWidth write FWidth;
    property GetText: TUiTableTextFunc read FGetText write FGetText;
    property GetColor: TUiTableColorFunc read FGetColor write FGetColor;
    property SortKey: string read FSortKey write FSortKey;
    property Sort: TUiSortDirection read FSort write FSort;
  end;

  TUiTableDrag = (utdNone, utdVThumb, utdHThumb, utdColumn);

  TUiTableCacheRow = record
    Item: TObject;
    Texts: TArray<string>;
    Colors: TArray<TColor>;
    Back: TColor;
  end;

  TUiTable = class(TCustomControl)
  private
    FColumns: TObjectList<TUiTableColumn>;
    FSource: TUiTableSource;
    FSelected: TObject;
    FHover: TObject;
    FRowHeight: Integer;
    FHeaderHeight: Integer;
    FScrollBarSize: Integer;
    FScrollX: Integer;
    FScrollY: Integer;
    FNeedV: Boolean;
    FNeedH: Boolean;
    FDataWidth: Integer;
    FDataHeight: Integer;
    FWidths: TArray<Integer>;
    FTotalWidth: Integer;
    FCache: TArray<TUiTableCacheRow>;
    FCacheFirst: Integer;
    FCacheValid: Boolean;
    FDrag: TUiTableDrag;
    FDragOrigin: Integer;
    FDragStartValue: Integer;
    FDragColumn: Integer;
    FDownColumn: Integer;
    FDownOnItem: Boolean;
    FHotThumb: TUiTableDrag;
    FWidthsName: string;
    FEmptyText: string;
    FRowColor: TUiTableColorFunc;
    FOnSelect: TNotifyEvent;
    FOnHeaderClick: TUiTableColumnEvent;
    function GetColumn(const AIndex: Integer): TUiTableColumn;
    function GetColumnCount: Integer;
    function GetCount: Integer;
    procedure SetSource(const AValue: TUiTableSource);
    procedure SetSelected(const AValue: TObject);
    procedure SetRowHeight(const AValue: Integer);
    procedure SetHeaderHeight(const AValue: Integer);
    procedure SetScrollBarSize(const AValue: Integer);
    procedure UpdateLayout;
    procedure SetScroll(const AX, AY: Integer);
    function MaxScrollX: Integer;
    function MaxScrollY: Integer;
    function DataRect: TRect;
    function VTrackRect: TRect;
    function HTrackRect: TRect;
    function VThumbRect: TRect;
    function HThumbRect: TRect;
    function ResizeColumnAt(const X, Y: Integer): Integer;
    function IndexAtY(const Y: Integer): Integer;
    function IndexOfItem(const AItem: TObject): Integer;
    function RowRect(const AIndex: Integer): TRect;
    procedure FillCacheRow(var ARow: TUiTableCacheRow; const AIndex: Integer);
    procedure EnsureCache;
    procedure InvalidateItem(const AItem: TObject);
    procedure SetHover(const AItem: TObject);
    procedure UpdateHoverFromCursor;
    procedure SelectIndex(const AIndex: Integer);
    procedure ScrollIntoView(const AIndex: Integer);
    procedure SaveWidths;
    procedure PaintHeader;
    procedure PaintRows;
    procedure PaintScrollBar(const ATrack, AThumb: TRect; const AHot: Boolean);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure DblClick; override;
    procedure KeyDown(var Key: Word; Shift: TShiftState); override;
    function DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    function AddColumn(const ACaption: string; const AWidth: Integer; const AGetText: TUiTableTextFunc): TUiTableColumn;
    procedure DataChanged;
    procedure ItemChanged(const AItem: TObject);
    procedure ScrollToTop;
    procedure RestoreColumnWidths(const AName: string);
    function ItemAt(const X, Y: Integer): TObject;
    function ColumnAt(const X: Integer): Integer;
    property Columns[const AIndex: Integer]: TUiTableColumn read GetColumn;
    property ColumnCount: Integer read GetColumnCount;
    property Count: Integer read GetCount;
    property Source: TUiTableSource read FSource write SetSource;
    property SelectedItem: TObject read FSelected write SetSelected;
    property RowHeight: Integer read FRowHeight write SetRowHeight;
    property HeaderHeight: Integer read FHeaderHeight write SetHeaderHeight;
    property ScrollBarSize: Integer read FScrollBarSize write SetScrollBarSize;
    property EmptyText: string read FEmptyText write FEmptyText;
    property RowColor: TUiTableColorFunc read FRowColor write FRowColor;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property OnHeaderClick: TUiTableColumnEvent read FOnHeaderClick write FOnHeaderClick;
    property OnDblClick;
  end;

function AddUiTable(const AParent: TWinControl; const ARowHeight: Integer): TUiTable;

implementation

uses
  Math, System.Types, System.UITypes, uStringGrid, uUiTheme;

function AddUiTable(const AParent: TWinControl; const ARowHeight: Integer): TUiTable;
begin
  Result := TUiTable.Create(AParent);
  Result.Parent := AParent;
  Result.Align := alClient;
  Result.RowHeight := ARowHeight;
end;

procedure TUiTableSource.Attach(const ATable: TUiTable);
begin
end;

procedure TUiTableSource.Detach(const ATable: TUiTable);
begin
end;

constructor TUiListSource<T>.Create(const AList: TList<T>; const AOwnsList: Boolean);
begin
  inherited Create;
  FList := AList;
  FOwnsList := AOwnsList;
end;

destructor TUiListSource<T>.Destroy;
begin
  if FOwnsList then
    FList.Free;
  inherited;
end;

function TUiListSource<T>.Count: Integer;
begin
  if Assigned(FList) then
    Result := FList.Count
  else
    Result := 0;
end;

function TUiListSource<T>.Item(const AIndex: Integer): TObject;
begin
  Result := FList[AIndex];
end;

constructor TUiTable.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  FColumns := TObjectList<TUiTableColumn>.Create(True);
  FRowHeight := ScaleValue(36);
  FHeaderHeight := FRowHeight;
  FScrollBarSize := ScaleValue(10);
  FCacheFirst := -1;
  FDownColumn := -1;
  FDragColumn := -1;
  TabStop := True;
  DoubleBuffered := True;
  Color := clUiCard;
end;

destructor TUiTable.Destroy;
begin
  if Assigned(FSource) then
    FSource.Detach(Self);
  FreeAndNil(FSource);
  FreeAndNil(FColumns);
  inherited;
end;

function TUiTable.GetColumn(const AIndex: Integer): TUiTableColumn;
begin
  Result := FColumns[AIndex];
end;

function TUiTable.GetColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TUiTable.GetCount: Integer;
begin
  if Assigned(FSource) then
    Result := FSource.Count
  else
    Result := 0;
end;

function TUiTable.AddColumn(const ACaption: string; const AWidth: Integer;
  const AGetText: TUiTableTextFunc): TUiTableColumn;
begin
  Result := TUiTableColumn.Create;
  Result.Caption := ACaption;
  Result.Width := AWidth;
  Result.GetText := AGetText;
  FColumns.Add(Result);
  FCacheValid := False;
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.SetSource(const AValue: TUiTableSource);
begin
  if AValue <> FSource then
  begin
    if Assigned(FSource) then
    begin
      FSource.Detach(Self);
      FSource.Free;
    end;
    FSource := AValue;
    if Assigned(FSource) then
      FSource.Attach(Self);
  end;
  DataChanged;
end;

procedure TUiTable.DataChanged;
var
  vAnchor: TObject;
  vOffset, vIndex: Integer;
begin
  vAnchor := nil;
  vOffset := 0;
  if FCacheValid and (Length(FCache) > 0) then
  begin
    vAnchor := FCache[0].Item;
    vOffset := FScrollY - FCacheFirst * FRowHeight;
  end;
  FCacheValid := False;
  UpdateLayout;
  if Assigned(vAnchor) then
  begin
    vIndex := IndexOfItem(vAnchor);
    if vIndex >= 0 then
      FScrollY := EnsureRange(vIndex * FRowHeight + vOffset, 0, MaxScrollY);
  end;
  if Assigned(FHover) and (IndexOfItem(FHover) < 0) then
    FHover := nil;
  if Assigned(FSelected) and (IndexOfItem(FSelected) < 0) then
  begin
    FSelected := nil;
    if Assigned(FOnSelect) then
      FOnSelect(Self);
  end;
  Invalidate;
end;

procedure TUiTable.ItemChanged(const AItem: TObject);
var
  I: Integer;
  vRect: TRect;
begin
  if not FCacheValid then
    Exit;
  for I := 0 to High(FCache) do
    if FCache[I].Item = AItem then
    begin
      FillCacheRow(FCache[I], FCacheFirst + I);
      if HandleAllocated then
      begin
        vRect := RowRect(FCacheFirst + I);
        InvalidateRect(Handle, @vRect, False);
      end;
      Exit;
    end;
end;

procedure TUiTable.ScrollToTop;
begin
  SetScroll(FScrollX, 0);
end;

procedure TUiTable.UpdateLayout;
var
  vWidth, vHeight, vContent: Integer;

  procedure CalcWidths(const AAvailable: Integer);
  var
    I, vOthers: Integer;
  begin
    SetLength(FWidths, FColumns.Count);
    vOthers := 0;
    for I := 0 to FColumns.Count - 1 do
    begin
      FWidths[I] := FColumns[I].Width;
      if I < FColumns.Count - 1 then
        Inc(vOthers, FWidths[I]);
    end;
    if FColumns.Count > 0 then
      FWidths[FColumns.Count - 1] := Max(FColumns[FColumns.Count - 1].Width, AAvailable - vOthers);
    FTotalWidth := vOthers;
    if FColumns.Count > 0 then
      Inc(FTotalWidth, FWidths[FColumns.Count - 1]);
  end;

begin
  vContent := GetCount * FRowHeight;
  vWidth := ClientWidth;
  vHeight := ClientHeight - FHeaderHeight;
  FNeedV := vContent > vHeight;
  if FNeedV then
    Dec(vWidth, FScrollBarSize);
  CalcWidths(vWidth);
  FNeedH := FTotalWidth > vWidth;
  if FNeedH then
  begin
    Dec(vHeight, FScrollBarSize);
    if not FNeedV and (vContent > vHeight) then
    begin
      FNeedV := True;
      Dec(vWidth, FScrollBarSize);
      CalcWidths(vWidth);
    end;
  end;
  FDataWidth := Max(vWidth, 0);
  FDataHeight := Max(vHeight, 0);
  FScrollX := EnsureRange(FScrollX, 0, MaxScrollX);
  FScrollY := EnsureRange(FScrollY, 0, MaxScrollY);
end;

function TUiTable.MaxScrollX: Integer;
begin
  Result := Max(0, FTotalWidth - FDataWidth);
end;

function TUiTable.MaxScrollY: Integer;
begin
  Result := Max(0, GetCount * FRowHeight - FDataHeight);
end;

procedure TUiTable.SetScroll(const AX, AY: Integer);
var
  vX, vY: Integer;
begin
  vX := EnsureRange(AX, 0, MaxScrollX);
  vY := EnsureRange(AY, 0, MaxScrollY);
  if (vX = FScrollX) and (vY = FScrollY) then
    Exit;
  FScrollX := vX;
  FScrollY := vY;
  Invalidate;
end;

procedure TUiTable.Resize;
begin
  inherited;
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.SetRowHeight(const AValue: Integer);
begin
  FRowHeight := Max(1, AValue);
  FHeaderHeight := FRowHeight;
  FCacheValid := False;
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.SetHeaderHeight(const AValue: Integer);
begin
  FHeaderHeight := Max(0, AValue);
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.SetScrollBarSize(const AValue: Integer);
begin
  FScrollBarSize := Max(1, AValue);
  UpdateLayout;
  Invalidate;
end;

function TUiTable.DataRect: TRect;
begin
  Result := Rect(0, FHeaderHeight, FDataWidth, FHeaderHeight + FDataHeight);
end;

function TUiTable.VTrackRect: TRect;
begin
  Result := Rect(FDataWidth, FHeaderHeight, FDataWidth + FScrollBarSize, FHeaderHeight + FDataHeight);
end;

function TUiTable.HTrackRect: TRect;
begin
  Result := Rect(0, FHeaderHeight + FDataHeight, FDataWidth, FHeaderHeight + FDataHeight + FScrollBarSize);
end;

function TUiTable.VThumbRect: TRect;
var
  vTrack: TRect;
  vLength, vPosition: Integer;
begin
  vTrack := VTrackRect;
  vLength := Max(ScaleValue(24), MulDiv(vTrack.Height, FDataHeight, Max(1, GetCount * FRowHeight)));
  vLength := Min(vLength, vTrack.Height);
  vPosition := 0;
  if MaxScrollY > 0 then
    vPosition := MulDiv(vTrack.Height - vLength, FScrollY, MaxScrollY);
  Result := Rect(vTrack.Left, vTrack.Top + vPosition, vTrack.Right, vTrack.Top + vPosition + vLength);
end;

function TUiTable.HThumbRect: TRect;
var
  vTrack: TRect;
  vLength, vPosition: Integer;
begin
  vTrack := HTrackRect;
  vLength := Max(ScaleValue(24), MulDiv(vTrack.Width, FDataWidth, Max(1, FTotalWidth)));
  vLength := Min(vLength, vTrack.Width);
  vPosition := 0;
  if MaxScrollX > 0 then
    vPosition := MulDiv(vTrack.Width - vLength, FScrollX, MaxScrollX);
  Result := Rect(vTrack.Left + vPosition, vTrack.Top, vTrack.Left + vPosition + vLength, vTrack.Bottom);
end;

function TUiTable.ResizeColumnAt(const X, Y: Integer): Integer;
var
  I, vEdge: Integer;
begin
  Result := -1;
  if (Y < 0) or (Y >= FHeaderHeight) or (X >= FDataWidth) then
    Exit;
  vEdge := -FScrollX;
  for I := 0 to High(FWidths) do
  begin
    Inc(vEdge, FWidths[I]);
    if Abs(X - vEdge) <= ScaleValue(4) then
      Exit(I);
  end;
end;

function TUiTable.ColumnAt(const X: Integer): Integer;
var
  I, vLeft: Integer;
begin
  Result := -1;
  if (X < 0) or (X >= FDataWidth) then
    Exit;
  vLeft := -FScrollX;
  for I := 0 to High(FWidths) do
  begin
    if (X >= vLeft) and (X < vLeft + FWidths[I]) then
      Exit(I);
    Inc(vLeft, FWidths[I]);
  end;
end;

function TUiTable.IndexAtY(const Y: Integer): Integer;
begin
  Result := -1;
  if (Y < FHeaderHeight) or (Y >= FHeaderHeight + FDataHeight) then
    Exit;
  Result := (Y - FHeaderHeight + FScrollY) div FRowHeight;
  if Result >= GetCount then
    Result := -1;
end;

function TUiTable.ItemAt(const X, Y: Integer): TObject;
var
  vIndex: Integer;
begin
  Result := nil;
  if (X < 0) or (X >= FDataWidth) then
    Exit;
  vIndex := IndexAtY(Y);
  if vIndex >= 0 then
    Result := FSource.Item(vIndex);
end;

function TUiTable.IndexOfItem(const AItem: TObject): Integer;
var
  I: Integer;
begin
  Result := -1;
  if not Assigned(AItem) then
    Exit;
  if FCacheValid then
    for I := 0 to High(FCache) do
      if FCache[I].Item = AItem then
        Exit(FCacheFirst + I);
  for I := 0 to GetCount - 1 do
    if FSource.Item(I) = AItem then
      Exit(I);
end;

function TUiTable.RowRect(const AIndex: Integer): TRect;
var
  vTop: Integer;
begin
  vTop := FHeaderHeight + AIndex * FRowHeight - FScrollY;
  Result := Rect(0, vTop, FDataWidth, vTop + FRowHeight);
end;

procedure TUiTable.FillCacheRow(var ARow: TUiTableCacheRow; const AIndex: Integer);
var
  I: Integer;
  vColumn: TUiTableColumn;
begin
  ARow.Item := FSource.Item(AIndex);
  SetLength(ARow.Texts, FColumns.Count);
  SetLength(ARow.Colors, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
  begin
    vColumn := FColumns[I];
    if Assigned(vColumn.GetText) then
      ARow.Texts[I] := vColumn.GetText(ARow.Item)
    else
      ARow.Texts[I] := '';
    if Assigned(vColumn.GetColor) then
      ARow.Colors[I] := vColumn.GetColor(ARow.Item)
    else
      ARow.Colors[I] := clNone;
  end;
  if Assigned(FRowColor) then
    ARow.Back := FRowColor(ARow.Item)
  else
    ARow.Back := clNone;
end;

procedure TUiTable.EnsureCache;
var
  vFirst, vLast, vLength, I, vOld: Integer;
  vCache: TArray<TUiTableCacheRow>;
begin
  vFirst := FScrollY div FRowHeight;
  vLast := Min(GetCount - 1, (FScrollY + FDataHeight - 1) div FRowHeight);
  vLength := Max(0, vLast - vFirst + 1);
  if FCacheValid and (vFirst = FCacheFirst) and (vLength = Length(FCache)) then
    Exit;
  SetLength(vCache, vLength);
  for I := 0 to vLength - 1 do
  begin
    vOld := vFirst + I - FCacheFirst;
    if FCacheValid and (vOld >= 0) and (vOld < Length(FCache)) then
      vCache[I] := FCache[vOld]
    else
      FillCacheRow(vCache[I], vFirst + I);
  end;
  FCache := vCache;
  FCacheFirst := vFirst;
  FCacheValid := True;
end;

procedure TUiTable.InvalidateItem(const AItem: TObject);
var
  I: Integer;
  vRect: TRect;
begin
  if not Assigned(AItem) or not FCacheValid or not HandleAllocated then
    Exit;
  for I := 0 to High(FCache) do
    if FCache[I].Item = AItem then
    begin
      vRect := RowRect(FCacheFirst + I);
      InvalidateRect(Handle, @vRect, False);
      Exit;
    end;
end;

procedure TUiTable.SetHover(const AItem: TObject);
begin
  if AItem = FHover then
    Exit;
  InvalidateItem(FHover);
  FHover := AItem;
  InvalidateItem(FHover);
end;

procedure TUiTable.UpdateHoverFromCursor;
var
  vPoint: TPoint;
begin
  vPoint := ScreenToClient(Mouse.CursorPos);
  if PtInRect(ClientRect, vPoint) then
    SetHover(ItemAt(vPoint.X, vPoint.Y))
  else
    SetHover(nil);
end;

procedure TUiTable.SetSelected(const AValue: TObject);
var
  vIndex: Integer;
begin
  if AValue = FSelected then
    Exit;
  InvalidateItem(FSelected);
  FSelected := AValue;
  vIndex := IndexOfItem(FSelected);
  if vIndex >= 0 then
    ScrollIntoView(vIndex);
  InvalidateItem(FSelected);
end;

procedure TUiTable.SelectIndex(const AIndex: Integer);
var
  vItem: TObject;
begin
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;
  vItem := FSource.Item(AIndex);
  ScrollIntoView(AIndex);
  if vItem = FSelected then
    Exit;
  SetSelected(vItem);
  if Assigned(FOnSelect) then
    FOnSelect(Self);
end;

procedure TUiTable.ScrollIntoView(const AIndex: Integer);
var
  vTop: Integer;
begin
  vTop := AIndex * FRowHeight;
  if vTop < FScrollY then
    SetScroll(FScrollX, vTop)
  else if vTop + FRowHeight > FScrollY + FDataHeight then
    SetScroll(FScrollX, vTop + FRowHeight - FDataHeight);
end;

procedure TUiTable.RestoreColumnWidths(const AName: string);
var
  vWidths: TArray<Integer>;
  I: Integer;
begin
  SetLength(vWidths, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
    vWidths[I] := FColumns[I].Width;
  if LoadColumnWidths(AName, vWidths) then
    for I := 0 to FColumns.Count - 1 do
      FColumns[I].Width := Max(ScaleValue(40), vWidths[I]);
  FWidthsName := AName;
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.SaveWidths;
var
  vWidths: TArray<Integer>;
  I: Integer;
begin
  if FWidthsName = '' then
    Exit;
  SetLength(vWidths, FColumns.Count);
  for I := 0 to FColumns.Count - 1 do
    vWidths[I] := FColumns[I].Width;
  SaveColumnWidths(FWidthsName, vWidths);
end;

procedure TUiTable.Paint;
var
  vRect: TRect;
  vText: string;
begin
  EnsureCache;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(ClientRect);
  PaintRows;
  PaintHeader;
  if FNeedV then
    PaintScrollBar(VTrackRect, VThumbRect, (FHotThumb = utdVThumb) or (FDrag = utdVThumb));
  if FNeedH then
    PaintScrollBar(HTrackRect, HThumbRect, (FHotThumb = utdHThumb) or (FDrag = utdHThumb));
  if (GetCount = 0) and (FEmptyText <> '') then
  begin
    Canvas.Font.Assign(Font);
    Canvas.Font.Color := clUiMuted;
    Canvas.Brush.Style := bsClear;
    vRect := DataRect;
    vText := FEmptyText;
    Canvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
  end;
end;

procedure TUiTable.PaintRows;
var
  I, J, vLeft: Integer;
  vRow, vCell, vTextRect: TRect;
  vFill: TColor;
  vText: string;
begin
  IntersectClipRect(Canvas.Handle, 0, FHeaderHeight, FDataWidth, FHeaderHeight + FDataHeight);
  try
    for I := 0 to High(FCache) do
    begin
      vRow := RowRect(FCacheFirst + I);
      if FCache[I].Item = FSelected then
        vFill := clUiSelection
      else if FCache[I].Item = FHover then
        vFill := clUiHover
      else if FCache[I].Back <> clNone then
        vFill := FCache[I].Back
      else
        vFill := clUiCard;
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := vFill;
      Canvas.FillRect(vRow);
      Canvas.Pen.Color := clUiBorder;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(vRow.Left, vRow.Bottom - 1);
      Canvas.LineTo(vRow.Right, vRow.Bottom - 1);

      vLeft := -FScrollX;
      for J := 0 to FColumns.Count - 1 do
      begin
        vCell := Rect(vLeft, vRow.Top, vLeft + FWidths[J], vRow.Bottom);
        Inc(vLeft, FWidths[J]);
        if (vCell.Right <= 0) or (vCell.Left >= FDataWidth) then
          Continue;
        Canvas.Font.Assign(Font);
        if FCache[I].Colors[J] <> clNone then
        begin
          Canvas.Font.Name := cUiFontSemibold;
          Canvas.Font.Color := FCache[I].Colors[J];
        end
        else
          Canvas.Font.Color := clUiText;
        Canvas.Brush.Style := bsClear;
        vTextRect := vCell;
        Inc(vTextRect.Left, ScaleValue(10));
        Dec(vTextRect.Right, ScaleValue(6));
        vText := FCache[I].Texts[J];
        Canvas.TextRect(vTextRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
      end;
    end;
  finally
    SelectClipRgn(Canvas.Handle, 0);
  end;
end;

procedure TUiTable.PaintHeader;
var
  I, vLeft, vInset: Integer;
  vCell, vTextRect: TRect;
  vText: string;
begin
  if FHeaderHeight <= 0 then
    Exit;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(Rect(0, 0, ClientWidth, FHeaderHeight));
  Canvas.Pen.Color := clUiBorder;
  Canvas.Pen.Width := 1;
  Canvas.MoveTo(0, FHeaderHeight - 1);
  Canvas.LineTo(ClientWidth, FHeaderHeight - 1);
  IntersectClipRect(Canvas.Handle, 0, 0, FDataWidth, FHeaderHeight);
  try
    vInset := FHeaderHeight div 4;
    vLeft := -FScrollX;
    for I := 0 to FColumns.Count - 1 do
    begin
      vCell := Rect(vLeft, 0, vLeft + FWidths[I], FHeaderHeight - 1);
      Inc(vLeft, FWidths[I]);
      if (vCell.Right <= 0) or (vCell.Left >= FDataWidth) then
        Continue;
      Canvas.Font.Assign(Font);
      Canvas.Font.Name := cUiFontSemibold;
      Canvas.Font.Color := clUiMuted;
      Canvas.Brush.Style := bsClear;
      vText := FColumns[I].Caption;
      case FColumns[I].Sort of
        usdAscending:
          vText := vText + ' ↑';
        usdDescending:
          vText := vText + ' ↓';
      end;
      vTextRect := vCell;
      Inc(vTextRect.Left, ScaleValue(10));
      Dec(vTextRect.Right, ScaleValue(6));
      Canvas.TextRect(vTextRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
      if I < FColumns.Count - 1 then
      begin
        Canvas.MoveTo(vCell.Right - 1, vInset);
        Canvas.LineTo(vCell.Right - 1, FHeaderHeight - vInset);
      end;
    end;
  finally
    SelectClipRgn(Canvas.Handle, 0);
  end;
end;

procedure TUiTable.PaintScrollBar(const ATrack, AThumb: TRect; const AHot: Boolean);
var
  vThumb: TRect;
  vInset, vRadius: Integer;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(ATrack);
  vInset := Max(1, FScrollBarSize div 5);
  vThumb := AThumb;
  InflateRect(vThumb, -vInset, -vInset);
  if (vThumb.Width <= 0) or (vThumb.Height <= 0) then
    Exit;
  if AHot then
    Canvas.Brush.Color := clUiScrollThumbHot
  else
    Canvas.Brush.Color := clUiScrollThumb;
  Canvas.Pen.Color := Canvas.Brush.Color;
  vRadius := Min(vThumb.Width, vThumb.Height);
  Canvas.RoundRect(vThumb.Left, vThumb.Top, vThumb.Right, vThumb.Bottom, vRadius, vRadius);
  if FNeedV and FNeedH then
  begin
    Canvas.Brush.Color := clUiCard;
    Canvas.FillRect(Rect(FDataWidth, FHeaderHeight + FDataHeight, ClientWidth, ClientHeight));
  end;
end;

procedure TUiTable.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vPoint: TPoint;
  vColumn, vIndex: Integer;
begin
  inherited;
  if CanFocus and not Focused then
    SetFocus;
  FDownOnItem := False;
  FDownColumn := -1;
  if Button <> mbLeft then
    Exit;
  vPoint := Point(X, Y);
  if FNeedV and PtInRect(VTrackRect, vPoint) then
  begin
    if PtInRect(VThumbRect, vPoint) then
    begin
      FDrag := utdVThumb;
      FDragOrigin := Y;
      FDragStartValue := FScrollY;
      Invalidate;
    end
    else if Y < VThumbRect.Top then
      SetScroll(FScrollX, FScrollY - FDataHeight)
    else
      SetScroll(FScrollX, FScrollY + FDataHeight);
    Exit;
  end;
  if FNeedH and PtInRect(HTrackRect, vPoint) then
  begin
    if PtInRect(HThumbRect, vPoint) then
    begin
      FDrag := utdHThumb;
      FDragOrigin := X;
      FDragStartValue := FScrollX;
      Invalidate;
    end
    else if X < HThumbRect.Left then
      SetScroll(FScrollX - FDataWidth, FScrollY)
    else
      SetScroll(FScrollX + FDataWidth, FScrollY);
    Exit;
  end;
  vColumn := ResizeColumnAt(X, Y);
  if vColumn >= 0 then
  begin
    FDrag := utdColumn;
    FDragColumn := vColumn;
    FDragOrigin := X;
    FDragStartValue := FWidths[vColumn];
    Exit;
  end;
  if Y < FHeaderHeight then
  begin
    FDownColumn := ColumnAt(X);
    Exit;
  end;
  vIndex := IndexAtY(Y);
  if (vIndex >= 0) and (X < FDataWidth) then
  begin
    FDownOnItem := True;
    SelectIndex(vIndex);
  end;
end;

procedure TUiTable.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vPoint: TPoint;
  vFree: Integer;
  vHot: TUiTableDrag;
begin
  inherited;
  case FDrag of
    utdVThumb:
      begin
        vFree := VTrackRect.Height - VThumbRect.Height;
        if vFree > 0 then
          SetScroll(FScrollX, FDragStartValue + MulDiv(Y - FDragOrigin, MaxScrollY, vFree));
        Exit;
      end;
    utdHThumb:
      begin
        vFree := HTrackRect.Width - HThumbRect.Width;
        if vFree > 0 then
          SetScroll(FDragStartValue + MulDiv(X - FDragOrigin, MaxScrollX, vFree), FScrollY);
        Exit;
      end;
    utdColumn:
      begin
        FColumns[FDragColumn].Width := Max(ScaleValue(40), FDragStartValue + X - FDragOrigin);
        UpdateLayout;
        Invalidate;
        Exit;
      end;
  end;
  if ResizeColumnAt(X, Y) >= 0 then
    Cursor := crHSplit
  else
    Cursor := crDefault;
  vPoint := Point(X, Y);
  vHot := utdNone;
  if FNeedV and PtInRect(VThumbRect, vPoint) then
    vHot := utdVThumb
  else if FNeedH and PtInRect(HThumbRect, vPoint) then
    vHot := utdHThumb;
  if vHot <> FHotThumb then
  begin
    FHotThumb := vHot;
    Invalidate;
  end;
  SetHover(ItemAt(X, Y));
end;

procedure TUiTable.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vDrag: TUiTableDrag;
  vColumn: Integer;
begin
  inherited;
  vDrag := FDrag;
  vColumn := FDownColumn;
  FDrag := utdNone;
  FDownColumn := -1;
  case vDrag of
    utdColumn:
      SaveWidths;
    utdVThumb, utdHThumb:
      Invalidate;
    utdNone:
      if (vColumn >= 0) and (Y >= 0) and (Y < FHeaderHeight) and (ColumnAt(X) = vColumn) and
        Assigned(FOnHeaderClick) then
        FOnHeaderClick(Self, vColumn);
  end;
end;

procedure TUiTable.DblClick;
begin
  if FDownOnItem and Assigned(FSelected) then
    inherited;
end;

procedure TUiTable.KeyDown(var Key: Word; Shift: TShiftState);
var
  vIndex, vPage, vTarget: Integer;
begin
  inherited;
  if GetCount = 0 then
    Exit;
  vIndex := IndexOfItem(FSelected);
  vPage := Max(1, FDataHeight div FRowHeight);
  case Key of
    VK_UP:
      vTarget := Max(0, vIndex - 1);
    VK_DOWN:
      vTarget := vIndex + 1;
    VK_PRIOR:
      vTarget := Max(0, vIndex - vPage);
    VK_NEXT:
      vTarget := vIndex + vPage;
    VK_HOME:
      vTarget := 0;
    VK_END:
      vTarget := GetCount - 1;
    VK_RETURN:
      begin
        if Assigned(FSelected) and Assigned(OnDblClick) then
          OnDblClick(Self);
        Key := 0;
        Exit;
      end;
  else
    Exit;
  end;
  SelectIndex(EnsureRange(vTarget, 0, GetCount - 1));
  Key := 0;
end;

function TUiTable.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
begin
  Result := True;
  if ssShift in Shift then
    SetScroll(FScrollX - MulDiv(WheelDelta, ScaleValue(60), WHEEL_DELTA), FScrollY)
  else
    SetScroll(FScrollX, FScrollY - MulDiv(WheelDelta, FRowHeight * 3, WHEEL_DELTA));
  UpdateHoverFromCursor;
end;

procedure TUiTable.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  SetHover(nil);
  if FHotThumb <> utdNone then
  begin
    FHotThumb := utdNone;
    Invalidate;
  end;
end;

procedure TUiTable.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  inherited;
  Message.Result := Message.Result or DLGC_WANTARROWS;
end;

end.
