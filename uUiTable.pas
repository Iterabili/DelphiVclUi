unit uUiTable;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ImgList, Generics.Collections;

type
  TUiTable = class;

  TUiTableTextFunc = reference to function(const AItem: TObject): string;
  TUiTableColorFunc = reference to function(const AItem: TObject): TColor;
  TUiTableImageFunc = reference to function(const AItem: TObject): Integer;
  TUiSortDirection = (usdNone, usdAscending, usdDescending);
  TUiTableColumnEvent = procedure(Sender: TObject; const AColumn: Integer) of object;
  TUiTableCellEvent = procedure(Sender: TObject; const AItem: TObject; const AColumn: Integer) of object;

  TUiTableSource = class
  private
    FSelection: TList<TObject>;
    FOwnerTable: TUiTable;
    FOnSelectionChanged: TNotifyEvent;
    function Selection: TList<TObject>;
  protected
    procedure DoSelectionChanged;
  public
    destructor Destroy; override;
    function Count: Integer; virtual; abstract;
    function Item(const AIndex: Integer): TObject; virtual; abstract;
    procedure Attach(const ATable: TUiTable); virtual;
    procedure Detach(const ATable: TUiTable); virtual;
    function IsSelected(const AItem: TObject): Boolean; virtual;
    procedure Select(const AItem: TObject); virtual;
    procedure ToggleSelected(const AItem: TObject); virtual;
    procedure ClearSelection; virtual;
    function SelectedCount: Integer; virtual;
    function SelectedAt(const AIndex: Integer): TObject; virtual;
    procedure PruneSelection; virtual;
    property OnSelectionChanged: TNotifyEvent read FOnSelectionChanged write FOnSelectionChanged;
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
    FGetImage: TUiTableImageFunc;
    FClickable: Boolean;
    FSortKey: string;
    FSort: TUiSortDirection;
    FAlignment: TAlignment;
    FHeaderAlignment: TAlignment;
  public
    class function TextFormat(const AAlignment: TAlignment): TTextFormat; static;
    class function TextRect(const AAlignment: TAlignment; const ACell: TRect;
      const APadding, ACloseGap: Integer): TRect; static;
    property Alignment: TAlignment read FAlignment write FAlignment;
    property HeaderAlignment: TAlignment read FHeaderAlignment write FHeaderAlignment;
    property Caption: string read FCaption write FCaption;
    property Width: Integer read FWidth write FWidth;
    property GetText: TUiTableTextFunc read FGetText write FGetText;
    property GetColor: TUiTableColorFunc read FGetColor write FGetColor;
    property GetImage: TUiTableImageFunc read FGetImage write FGetImage;
    property Clickable: Boolean read FClickable write FClickable;
    property SortKey: string read FSortKey write FSortKey;
    property Sort: TUiSortDirection read FSort write FSort;
  end;

  TUiTableDrag = (utdNone, utdVThumb, utdHThumb, utdColumn);

  TUiTableCacheRow = record
    Item: TObject;
    Texts: TArray<string>;
    Colors: TArray<TColor>;
    Images: TArray<Integer>;
    Back: TColor;
  end;

  TUiTable = class(TCustomControl)
  private
    FColumns: TObjectList<TUiTableColumn>;
    FSource: TUiTableSource;
    FFocused: TObject;
    FMultiSelect: Boolean;
    FAllowDeselect: Boolean;
    FSettingSelection: Boolean;
    FHover: TObject;
    FRowHeight: Integer;
    FRowHeightSetting: Integer;
    FRowPadding: Integer;
    FHeaderHeight: Integer;
    FScrollBarSize: Integer;
    FScrollBarSetting: Integer;
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
    FDownCellItem: TObject;
    FDownCellColumn: Integer;
    FImages: TCustomImageList;
    FOnCellClick: TUiTableCellEvent;
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
    function GetSelected: TObject;
    procedure SetSelected(const AValue: TObject);
    procedure SetMultiSelect(const AValue: Boolean);
    function IsItemSelected(const AItem: TObject): Boolean;
    function LeadWidth: Integer;
    procedure SourceSelectionChanged;
    procedure SetRowHeight(const AValue: Integer);
    procedure SetRowPadding(const AValue: Integer);
    procedure UpdateSizes;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
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
    procedure SetHitCursor(const ACursor: TCursor);
    function ClickableColumnAt(const X, Y: Integer): Integer;
    procedure SetImages(const AValue: TCustomImageList);
    procedure SelectIndex(const AIndex: Integer);
    procedure FocusIndex(const AIndex: Integer);
    procedure ToggleIndex(const AIndex: Integer);
    procedure ScrollIntoView(const AIndex: Integer);
    procedure SaveWidths;
    procedure PaintHeader;
    procedure PaintRows;
    procedure PaintScrollBar(const ATrack, AThumb: TRect; const AHot: Boolean);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure WMGetDlgCode(var Message: TWMGetDlgCode); message WM_GETDLGCODE;
    procedure CMWantSpecialKey(var Message: TCMWantSpecialKey); message CM_WANTSPECIALKEY;
  protected
    procedure Notification(AComponent: TComponent; Operation: TOperation); override;
    procedure ChangeScale(M, D: Integer; isDpiChange: Boolean); override;
    procedure Paint; override;
    procedure Resize; override;
    procedure CreateWnd; override;
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
    procedure AutoFitColumn(const AIndex: Integer);
    function ItemAt(const X, Y: Integer): TObject;
    function ColumnAt(const X: Integer): Integer;
    function RevealCell(const AColumn, AIndex: Integer): TRect;
    procedure ScrollToIndex(const AIndex: Integer);
    procedure RefreshRows;
    property Columns[const AIndex: Integer]: TUiTableColumn read GetColumn;
    property ColumnCount: Integer read GetColumnCount;
    property Count: Integer read GetCount;
    property Source: TUiTableSource read FSource write SetSource;
    property SelectedItem: TObject read GetSelected write SetSelected;
    property FocusedItem: TObject read FFocused;
    property HeaderHeight: Integer read FHeaderHeight;
    property RowColor: TUiTableColorFunc read FRowColor write FRowColor;
  published
    property Align;
    property AllowDeselect: Boolean read FAllowDeselect write FAllowDeselect default False;
    property Anchors;
    property DragMode;
    property EmptyText: string read FEmptyText write FEmptyText;
    property Enabled;
    property Font;
    property Hint;
    property Images: TCustomImageList read FImages write SetImages;
    property MultiSelect: Boolean read FMultiSelect write SetMultiSelect default False;
    property ParentFont;
    property ParentShowHint;
    property PopupMenu;
    property RowHeight: Integer read FRowHeightSetting write SetRowHeight default 0;
    property RowPadding: Integer read FRowPadding write SetRowPadding default 6;
    property ScrollBarSize: Integer read FScrollBarSetting write SetScrollBarSize default 10;
    property ShowHint;
    property TabOrder;
    property TabStop default True;
    property Visible;
    property OnCellClick: TUiTableCellEvent read FOnCellClick write FOnCellClick;
    property OnContextPopup;
    property OnDblClick;
    property OnDragDrop;
    property OnDragOver;
    property OnEndDrag;
    property OnEnter;
    property OnExit;
    property OnHeaderClick: TUiTableColumnEvent read FOnHeaderClick write FOnHeaderClick;
    property OnKeyDown;
    property OnMouseDown;
    property OnMouseMove;
    property OnMouseUp;
    property OnSelect: TNotifyEvent read FOnSelect write FOnSelect;
    property OnStartDrag;
  end;

function AddUiTable(const AParent: TWinControl): TUiTable;

implementation

uses
  Forms, Math, IniFiles, System.Types, System.UITypes, uUiTheme, uUiPaint;

function ColumnWidthsFile: TIniFile;
begin
  Result := TIniFile.Create(ExtractFilePath(ParamStr(0)) + 'config.ini');
end;

procedure SaveColumnWidths(const AName: string; const AWidths: array of Integer);
var
  vIni: TIniFile;
  vSection: string;
  i: Integer;
begin
  vSection := 'GridWidths_' + AName;
  vIni := ColumnWidthsFile;
  try
    vIni.WriteInteger(vSection, 'ColCount', Length(AWidths));
    for i := 0 to High(AWidths) do
      vIni.WriteInteger(vSection, 'Col' + IntToStr(i), AWidths[i]);
  finally
    vIni.Free;
  end;
end;

function LoadColumnWidths(const AName: string; var AWidths: TArray<Integer>): Boolean;
var
  vIni: TIniFile;
  vSection: string;
  i: Integer;
begin
  vSection := 'GridWidths_' + AName;
  vIni := ColumnWidthsFile;
  try
    Result := vIni.ReadInteger(vSection, 'ColCount', -1) = Length(AWidths);
    if not Result then
      Exit;
    for i := 0 to High(AWidths) do
      AWidths[i] := vIni.ReadInteger(vSection, 'Col' + IntToStr(i), AWidths[i]);
  finally
    vIni.Free;
  end;
end;

function AddUiTable(const AParent: TWinControl): TUiTable;
begin
  Result := TUiTable.Create(AParent);
  Result.Parent := AParent;
  Result.Align := alClient;
end;

class function TUiTableColumn.TextFormat(const AAlignment: TAlignment): TTextFormat;
begin
  Result := [tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis];
  case AAlignment of
    taRightJustify:
      Include(Result, tfRight);
    taCenter:
      Include(Result, tfCenter);
  else
    Include(Result, tfLeft);
  end;
end;

class function TUiTableColumn.TextRect(const AAlignment: TAlignment; const ACell: TRect;
  const APadding, ACloseGap: Integer): TRect;
begin
  Result := ACell;
  case AAlignment of
    taRightJustify:
      begin
        Inc(Result.Left, ACloseGap);
        Dec(Result.Right, APadding);
      end;
    taCenter:
      begin
        Inc(Result.Left, APadding);
        Dec(Result.Right, APadding);
      end;
  else
    Inc(Result.Left, APadding);
    Dec(Result.Right, ACloseGap);
  end;
end;

procedure TUiTableSource.Attach(const ATable: TUiTable);
begin
end;

destructor TUiTableSource.Destroy;
begin
  FreeAndNil(FSelection);
  inherited;
end;

function TUiTableSource.Selection: TList<TObject>;
begin
  if not Assigned(FSelection) then
    FSelection := TList<TObject>.Create;
  Result := FSelection;
end;

procedure TUiTableSource.DoSelectionChanged;
begin
  if Assigned(FOwnerTable) then
    FOwnerTable.SourceSelectionChanged;
  if Assigned(FOnSelectionChanged) then
    FOnSelectionChanged(Self);
end;

function TUiTableSource.IsSelected(const AItem: TObject): Boolean;
begin
  Result := Assigned(AItem) and Assigned(FSelection) and (FSelection.IndexOf(AItem) >= 0);
end;

procedure TUiTableSource.Select(const AItem: TObject);
begin
  if Assigned(AItem) and (SelectedCount = 1) and (Selection[0] = AItem) then
    Exit;
  if not Assigned(AItem) and (SelectedCount = 0) then
    Exit;
  Selection.Clear;
  if Assigned(AItem) then
    Selection.Add(AItem);
  DoSelectionChanged;
end;

procedure TUiTableSource.ToggleSelected(const AItem: TObject);
begin
  if not Assigned(AItem) then
    Exit;
  if Selection.Remove(AItem) < 0 then
    Selection.Add(AItem);
  DoSelectionChanged;
end;

procedure TUiTableSource.ClearSelection;
begin
  if SelectedCount = 0 then
    Exit;
  Selection.Clear;
  DoSelectionChanged;
end;

function TUiTableSource.SelectedCount: Integer;
begin
  if Assigned(FSelection) then
    Result := FSelection.Count
  else
    Result := 0;
end;

function TUiTableSource.SelectedAt(const AIndex: Integer): TObject;
begin
  Result := Selection[AIndex];
end;

procedure TUiTableSource.PruneSelection;
var
  I, J: Integer;
  vFound, vChanged: Boolean;
begin
  if SelectedCount = 0 then
    Exit;
  vChanged := False;
  for I := FSelection.Count - 1 downto 0 do
  begin
    vFound := False;
    for J := 0 to Count - 1 do
      if Item(J) = FSelection[I] then
      begin
        vFound := True;
        Break;
      end;
    if not vFound then
    begin
      FSelection.Delete(I);
      vChanged := True;
    end;
  end;
  if vChanged then
    DoSelectionChanged;
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
  Width := 300;
  Height := 200;
  FRowPadding := 6;
  FScrollBarSetting := 10;
  FCacheFirst := -1;
  FDownColumn := -1;
  FDownCellColumn := -1;
  FDragColumn := -1;
  TabStop := True;
  DoubleBuffered := True;
  Color := clUiCard;
  UpdateSizes;
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
  Result.HeaderAlignment := taCenter;
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
      FSource.FOwnerTable := nil;
      FSource.Detach(Self);
      FSource.Free;
    end;
    FSource := AValue;
    FFocused := nil;
    if Assigned(FSource) then
    begin
      FSource.FOwnerTable := Self;
      FSource.Attach(Self);
    end;
  end;
  DataChanged;
end;

function TUiTable.GetSelected: TObject;
begin
  if Assigned(FSource) and (FSource.SelectedCount = 1) then
    Result := FSource.SelectedAt(0)
  else
    Result := nil;
end;

function TUiTable.IsItemSelected(const AItem: TObject): Boolean;
begin
  Result := Assigned(FSource) and FSource.IsSelected(AItem);
end;

procedure TUiTable.SetMultiSelect(const AValue: Boolean);
begin
  FMultiSelect := AValue;
  Invalidate;
end;

function TUiTable.LeadWidth: Integer;
begin
  Result := ScaleValue(3) + ScaleValue(4) + ScaleValue(4);
  if FMultiSelect then
    Inc(Result, ScaleValue(18) + ScaleValue(8))
  else
    Inc(Result, ScaleValue(16));
end;

procedure TUiTable.SourceSelectionChanged;
begin
  Invalidate;
  if not FSettingSelection and Assigned(FOnSelect) then
    FOnSelect(Self);
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
  if Assigned(FFocused) and (IndexOfItem(FFocused) < 0) then
    FFocused := nil;
  if Assigned(FSource) then
    FSource.PruneSelection;
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
  if not HandleAllocated then
    Exit;
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

procedure TUiTable.CreateWnd;
begin
  inherited;
  UpdateLayout;
end;

procedure TUiTable.SetRowHeight(const AValue: Integer);
begin
  FRowHeightSetting := Max(0, AValue);
  UpdateSizes;
end;

procedure TUiTable.SetRowPadding(const AValue: Integer);
begin
  FRowPadding := Max(0, AValue);
  UpdateSizes;
end;

procedure TUiTable.SetScrollBarSize(const AValue: Integer);
begin
  FScrollBarSetting := Max(1, AValue);
  UpdateSizes;
end;

procedure TUiTable.UpdateSizes;
var
  vDC: HDC;
  vOldFont: HGDIOBJ;
  vMetrics: TTextMetric;
begin
  if FRowHeightSetting > 0 then
    FRowHeight := ScaleValue(FRowHeightSetting)
  else
  begin
    vDC := GetDC(0);
    try
      vOldFont := SelectObject(vDC, Font.Handle);
      GetTextMetrics(vDC, vMetrics);
      SelectObject(vDC, vOldFont);
    finally
      ReleaseDC(0, vDC);
    end;
    FRowHeight := Max(1, vMetrics.tmHeight + 2 * ScaleValue(FRowPadding));
  end;
  FHeaderHeight := FRowHeight;
  FScrollBarSize := ScaleValue(FScrollBarSetting);
  FCacheValid := False;
  UpdateLayout;
  Invalidate;
end;

procedure TUiTable.CMFontChanged(var Message: TMessage);
begin
  inherited;
  UpdateSizes;
end;

procedure TUiTable.ChangeScale(M, D: Integer; isDpiChange: Boolean);
begin
  inherited;
  UpdateSizes;
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

procedure TUiTable.AutoFitColumn(const AIndex: Integer);
var
  vColumn: TUiTableColumn;
  vText: string;
  vWidth, I: Integer;
begin
  if (AIndex < 0) or (AIndex >= FColumns.Count) then
    Exit;
  vColumn := FColumns[AIndex];
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  vText := vColumn.Caption;
  if vColumn.Sort <> usdNone then
    vText := vText + ' ↑';
  vWidth := Canvas.TextWidth(vText);
  if Assigned(FSource) then
  begin
    EnsureCache;
    for I := 0 to High(FCache) do
      if (FCache[I].Images[AIndex] >= 0) and Assigned(FImages) then
        vWidth := Max(vWidth, FImages.Width)
      else
      begin
        if FCache[I].Colors[AIndex] <> clNone then
          Canvas.Font.Name := cUiFontSemibold
        else
          Canvas.Font.Name := Font.Name;
        vWidth := Max(vWidth, Canvas.TextWidth(FCache[I].Texts[AIndex]));
      end;
  end;
  if AIndex = 0 then
    Inc(vWidth, Max(ScaleValue(10), LeadWidth))
  else
    Inc(vWidth, ScaleValue(10));
  Inc(vWidth, ScaleValue(6) + ScaleValue(2));
  vColumn.Width := Max(ScaleValue(40), vWidth);
  UpdateLayout;
  Invalidate;
  SaveWidths;
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
  SetLength(ARow.Images, FColumns.Count);
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
    if Assigned(vColumn.GetImage) then
      ARow.Images[I] := vColumn.GetImage(ARow.Item)
    else
      ARow.Images[I] := -1;
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

procedure TUiTable.SetHitCursor(const ACursor: TCursor);
begin
  if Cursor = ACursor then
    Exit;
  Cursor := ACursor;
  Windows.SetCursor(Screen.Cursors[ACursor]);
end;

function TUiTable.ClickableColumnAt(const X, Y: Integer): Integer;
begin
  Result := ColumnAt(X);
  if (Result >= 0) and ((IndexAtY(Y) < 0) or not FColumns[Result].Clickable) then
    Result := -1;
end;

procedure TUiTable.SetImages(const AValue: TCustomImageList);
begin
  if FImages = AValue then
    Exit;
  if Assigned(FImages) then
    FImages.RemoveFreeNotification(Self);
  FImages := AValue;
  if Assigned(FImages) then
    FImages.FreeNotification(Self);
  Invalidate;
end;

procedure TUiTable.Notification(AComponent: TComponent; Operation: TOperation);
begin
  inherited;
  if (Operation = opRemove) and (AComponent = FImages) then
    FImages := nil;
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
  if not Assigned(FSource) then
    Exit;
  FSettingSelection := True;
  try
    FSource.Select(AValue);
  finally
    FSettingSelection := False;
  end;
  FFocused := AValue;
  vIndex := IndexOfItem(AValue);
  if vIndex >= 0 then
    ScrollIntoView(vIndex);
  Invalidate;
end;

procedure TUiTable.FocusIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;
  FFocused := FSource.Item(AIndex);
  ScrollIntoView(AIndex);
  Invalidate;
end;

procedure TUiTable.SelectIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;
  FocusIndex(AIndex);
  FSource.Select(FFocused);
end;

procedure TUiTable.ToggleIndex(const AIndex: Integer);
begin
  if (AIndex < 0) or (AIndex >= GetCount) then
    Exit;
  FocusIndex(AIndex);
  FSource.ToggleSelected(FFocused);
end;

function TUiTable.RevealCell(const AColumn, AIndex: Integer): TRect;
var
  I: Integer;
begin
  ScrollIntoView(AIndex);
  Result := RowRect(AIndex);
  if (AColumn < 0) or (AColumn > High(FWidths)) then
    Exit;
  Result.Left := -FScrollX;
  for I := 0 to AColumn - 1 do
    Inc(Result.Left, FWidths[I]);
  Result.Right := Min(Result.Left + FWidths[AColumn], FDataWidth);
  Result.Left := Max(Result.Left, 0);
end;

procedure TUiTable.RefreshRows;
begin
  FCacheValid := False;
  Invalidate;
end;

procedure TUiTable.ScrollToIndex(const AIndex: Integer);
begin
  if (AIndex >= 0) and (AIndex < GetCount) then
    SetScroll(FScrollX, AIndex * FRowHeight);
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
  vSelected, vDark: Boolean;
  vMark: TColor;
  vGlyphLeft, vGlyphRight, vBox, vDot: Integer;
  vGlyphRect: TRect;
begin
  vGlyphLeft := ScaleValue(11);
  vGlyphRight := LeadWidth;
  IntersectClipRect(Canvas.Handle, 0, FHeaderHeight, FDataWidth, FHeaderHeight + FDataHeight);
  try
    for I := 0 to High(FCache) do
    begin
      vRow := RowRect(FCacheFirst + I);
      vSelected := IsItemSelected(FCache[I].Item);
      if FCache[I].Back <> clNone then
        vFill := FCache[I].Back
      else if vSelected then
        vFill := clUiRowSelected
      else
        vFill := clUiCard;
      if FCache[I].Item = FHover then
        vFill := ShadeColor(vFill, 7);
      vDark := IsDarkColor(vFill);
      Canvas.Brush.Style := bsSolid;
      Canvas.Brush.Color := clUiCard;
      Canvas.FillRect(vRow);
      if vFill <> clUiCard then
      begin
        DrawRounded(Canvas, Rect(vRow.Left + ScaleValue(4), vRow.Top + 1, vRow.Right - ScaleValue(4),
          vRow.Bottom - 1), ScaleValue(6), vFill, vFill);
        Canvas.Brush.Style := bsSolid;
      end;
      Canvas.Pen.Color := clUiBorder;
      Canvas.Pen.Width := 1;
      Canvas.MoveTo(vRow.Left + ScaleValue(4), vRow.Bottom - 1);
      Canvas.LineTo(vRow.Right - ScaleValue(4), vRow.Bottom - 1);

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
        if vDark then
          Canvas.Font.Color := clWhite;
        Canvas.Brush.Style := bsClear;
        vTextRect := TUiTableColumn.TextRect(FColumns[J].Alignment, vCell, ScaleValue(10), ScaleValue(6));
        if (vSelected or FMultiSelect) and (J = 0) then
          vTextRect.Left := Max(vTextRect.Left, vRow.Left + vGlyphRight);
        if (FCache[I].Images[J] >= 0) and Assigned(FImages) then
          FImages.Draw(Canvas, (vTextRect.Left + vTextRect.Right - FImages.Width) div 2,
            (vCell.Top + vCell.Bottom - FImages.Height) div 2, FCache[I].Images[J])
        else
        begin
          vText := FCache[I].Texts[J];
          Canvas.TextRect(vTextRect, vText, TUiTableColumn.TextFormat(FColumns[J].Alignment));
        end;
      end;

      if vSelected and not FMultiSelect then
      begin
        if vDark then
          vMark := clWhite
        else
          vMark := clUiAccent;
        vDot := ScaleValue(10);
        vGlyphRect := Rect(vRow.Left + vGlyphLeft, vRow.Top + (vRow.Height - vDot) div 2,
          vRow.Left + vGlyphLeft + vDot, vRow.Top + (vRow.Height - vDot) div 2 + vDot);
        DrawRounded(Canvas, vGlyphRect, vDot div 2, vMark, vMark);
        Canvas.Brush.Style := bsSolid;
      end;

      if FMultiSelect then
      begin
        vBox := ScaleValue(18);
        vGlyphRect := Rect(vRow.Left + vGlyphLeft, vRow.Top + (vRow.Height - vBox) div 2,
          vRow.Left + vGlyphLeft + vBox, vRow.Top + (vRow.Height - vBox) div 2 + vBox);
        if vSelected then
        begin
          if vDark then
            vMark := clWhite
          else
            vMark := clUiAccent;
          DrawRounded(Canvas, vGlyphRect, ScaleValue(4), vMark, vMark);
          if vDark then
            DrawCheckMark(Canvas, vGlyphRect, vFill, ScaleValue(2))
          else
            DrawCheckMark(Canvas, vGlyphRect, clWhite, ScaleValue(2));
        end
        else
          DrawRounded(Canvas, vGlyphRect, ScaleValue(4), clUiCard, clUiMuted);
      end;
    end;
  finally
    SelectClipRgn(Canvas.Handle, 0);
  end;
end;

procedure TUiTable.PaintHeader;
var
  I, vLeft, vInset: Integer;
  vCell, vTextRect, vPill: TRect;
  vText: string;
begin
  if FHeaderHeight <= 0 then
    Exit;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := clUiCard;
  Canvas.FillRect(Rect(0, 0, ClientWidth, FHeaderHeight));
  vPill := Rect(ScaleValue(4), ScaleValue(3), ClientWidth - ScaleValue(4), FHeaderHeight - ScaleValue(3));
  DrawRounded(Canvas, vPill, ScaleValue(6), clUiTableHeader, clUiTableHeader);
  Canvas.Brush.Style := bsSolid;
  Canvas.Pen.Width := 1;
  IntersectClipRect(Canvas.Handle, vPill.Left, vPill.Top, Min(vPill.Right, FDataWidth), vPill.Bottom);
  try
    vInset := FHeaderHeight div 4;
    vLeft := -FScrollX;
    for I := 0 to FColumns.Count - 1 do
    begin
      vCell := Rect(vLeft, 0, vLeft + FWidths[I], FHeaderHeight);
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
      vTextRect := TUiTableColumn.TextRect(FColumns[I].HeaderAlignment, vCell, ScaleValue(10), ScaleValue(6));
      if FMultiSelect and (I = 0) then
        vTextRect.Left := Max(vTextRect.Left, LeadWidth);
      Canvas.TextRect(vTextRect, vText, TUiTableColumn.TextFormat(FColumns[I].HeaderAlignment));
      if I < FColumns.Count - 1 then
      begin
        Canvas.Pen.Color := clUiTableHeaderDivider;
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
  FDownCellItem := nil;
  FDownCellColumn := -1;
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
    if ssDouble in Shift then
    begin
      AutoFitColumn(vColumn);
      Exit;
    end;
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
    vColumn := ClickableColumnAt(X, Y);
    if vColumn >= 0 then
    begin
      if not (ssDouble in Shift) then
      begin
        FDownCellItem := FSource.Item(vIndex);
        FDownCellColumn := vColumn;
      end;
      Exit;
    end;
    FDownOnItem := True;
    if ssDouble in Shift then
      Exit;
    if FMultiSelect then
      ToggleIndex(vIndex)
    else if FAllowDeselect and (FSource.SelectedCount = 1) and IsItemSelected(FSource.Item(vIndex)) then
    begin
      FocusIndex(vIndex);
      FSource.Select(nil);
    end
    else
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
    SetHitCursor(crSizeWE)
  else if ClickableColumnAt(X, Y) >= 0 then
    SetHitCursor(crHandPoint)
  else
    SetHitCursor(crDefault);
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
  vColumn, vCellColumn: Integer;
  vCellItem: TObject;
begin
  inherited;
  vDrag := FDrag;
  vColumn := FDownColumn;
  vCellItem := FDownCellItem;
  vCellColumn := FDownCellColumn;
  FDrag := utdNone;
  FDownColumn := -1;
  FDownCellItem := nil;
  FDownCellColumn := -1;
  if (Button = mbLeft) and Assigned(vCellItem) and (ItemAt(X, Y) = vCellItem) and
    (ClickableColumnAt(X, Y) = vCellColumn) and Assigned(FOnCellClick) then
  begin
    FOnCellClick(Self, vCellItem, vCellColumn);
    Exit;
  end;
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
  if FDownOnItem and Assigned(FFocused) then
    inherited;
end;

procedure TUiTable.KeyDown(var Key: Word; Shift: TShiftState);
var
  vIndex, vPage, vTarget: Integer;
begin
  inherited;
  if GetCount = 0 then
    Exit;
  vIndex := IndexOfItem(FFocused);
  if FMultiSelect and (Key = VK_SPACE) then
  begin
    if vIndex >= 0 then
      ToggleIndex(vIndex);
    Key := 0;
    Exit;
  end;
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
        if Assigned(FFocused) and Assigned(OnDblClick) then
          OnDblClick(Self);
        Key := 0;
        Exit;
      end;
  else
    Exit;
  end;
  if FMultiSelect then
    FocusIndex(EnsureRange(vTarget, 0, GetCount - 1))
  else
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

procedure TUiTable.CMWantSpecialKey(var Message: TCMWantSpecialKey);
begin
  inherited;
  if (Message.CharCode = VK_RETURN) and Assigned(FFocused) and Assigned(OnDblClick) then
    Message.Result := 1;
end;

end.
