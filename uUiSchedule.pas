unit uUiSchedule;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, ExtCtrls, Generics.Collections, Generics.Defaults;

type
  TUiScheduleItem = class
  public
    StartTime: TDateTime;
    EndTime: TDateTime;
    Columns: TArray<Integer>;
    Color: TColor;
    Title: string;
    Details: string;
    Hint: string;
    Marks: string;
    Faded: Boolean;
    Data: TObject;
  end;

  TUiScheduleItemEvent = procedure(Sender: TObject; const AItem: TUiScheduleItem) of object;
  TUiScheduleChangeEvent = procedure(Sender: TObject; const AItem: TUiScheduleItem; const AStart, AEnd: TDateTime;
    const AColumns: TArray<Integer>; const AAnchorColumn: Integer) of object;
  TUiScheduleRangeEvent = procedure(Sender: TObject; const AColumn: Integer; const AStart, AEnd: TDateTime) of object;
  TUiScheduleResolveColumns = reference to function(const AItem: TUiScheduleItem;
    const AAnchorColumn: Integer): TArray<Integer>;

  TUiScheduleDrag = (usgNone, usgPendingItem, usgPendingSelect, usgMove, usgResizeTop, usgResizeBottom, usgSelect);

  TUiScheduleGroup = record
    Caption: string;
    Color: TColor;
    FirstColumn: Integer;
    ColumnCount: Integer;
  end;

  TUiScheduleColumn = record
    Caption: string;
    Group: Integer;
  end;

  TUiScheduleSegment = record
    Item: TUiScheduleItem;
    StartTime: TDateTime;
    EndTime: TDateTime;
    FirstColumn: Integer;
    LastColumn: Integer;
    Lane: Integer;
    LaneCount: Integer;
    Rect: TRect;
  end;

  TUiSchedule = class(TCustomControl)
  private
    FGroups: TList<TUiScheduleGroup>;
    FColumns: TList<TUiScheduleColumn>;
    FItems: TObjectList<TUiScheduleItem>;
    FSegments: TList<TUiScheduleSegment>;
    FStartTime: TDateTime;
    FSpanHours: Double;
    FMinSpanHours: Double;
    FMaxSpanHours: Double;
    FSnapMinutes: Integer;
    FConflictGap: TDateTime;
    FUpdateCount: Integer;
    FHoverItem: TUiScheduleItem;
    FDrag: TUiScheduleDrag;
    FDragItem: TUiScheduleItem;
    FDragOrigin: TPoint;
    FDragTimeOrigin: TDateTime;
    FDragColumnOrigin: Integer;
    FDragStart: TDateTime;
    FDragEnd: TDateTime;
    FDragColumns: TArray<Integer>;
    FDragAnchor: Integer;
    FSelectColumn: Integer;
    FSelectAnchor: TDateTime;
    FTimer: TTimer;
    FResolveColumns: TUiScheduleResolveColumns;
    FOnItemClick: TUiScheduleItemEvent;
    FOnItemChange: TUiScheduleChangeEvent;
    FOnRangeSelect: TUiScheduleRangeEvent;
    FOnViewChange: TNotifyEvent;
    procedure SetStartTime(const AValue: TDateTime);
    procedure SetSpanHours(const AValue: Double);
    function GetItem(const AIndex: Integer): TUiScheduleItem;
    function GetItemCount: Integer;
    function GetColumnCount: Integer;
    function GetDragging: Boolean;
    procedure TimerTick(Sender: TObject);
    procedure Changed;
    procedure DoViewChange;
    function TextHeightOf(const ACanvas: TCanvas): Integer;
    function RulerWidth(const ACanvas: TCanvas): Integer;
    function HeaderHeight(const ACanvas: TCanvas): Integer;
    function ColumnLeft(const AIndex, AWidth, ARuler: Integer): Integer;
    function TimeToY(const ATime: TDateTime; const AHeight, AHeader: Integer): Integer;
    function YToTime(const Y: Integer): TDateTime;
    function SnapTime(const ATime: TDateTime): TDateTime;
    function SnapFloor(const ATime: TDateTime): TDateTime;
    function SnapStep: TDateTime;
    procedure BuildSegments(const ACanvas: TCanvas; const AWidth, AHeight: Integer);
    procedure AddItemSegments(const AItem: TUiScheduleItem; const AStart, AEnd: TDateTime;
      const AColumns: TArray<Integer>; const AList: TList<TUiScheduleSegment>);
    procedure LayoutLanes(const AList: TList<TUiScheduleSegment>; const AFirst: Integer);
    function SegmentRect(const ASegment: TUiScheduleSegment; const AWidth, AHeight, ARuler,
      AHeader: Integer): TRect;
    function HasConflict(const AItem: TUiScheduleItem; const AStart, AEnd: TDateTime;
      const AColumns: TArray<Integer>): Boolean;
    function SegmentAt(const X, Y: Integer; out ASegment: TUiScheduleSegment): Boolean;
    procedure PaintArea(const ACanvas: TCanvas; const AWidth, AHeight: Integer; const AExport: Boolean);
    procedure PaintGrid(const ACanvas: TCanvas; const AWidth, AHeight, ARuler, AHeader: Integer);
    procedure PaintBlock(const ACanvas: TCanvas; const ARect: TRect; const AItem: TUiScheduleItem;
      const AStart, AEnd: TDateTime; const AState: Integer);
    procedure PaintHeader(const ACanvas: TCanvas; const AWidth, ARuler, AHeader: Integer);
    procedure PaintSelectionLabel(const ACanvas: TCanvas; const ARect: TRect; const AWidth, ARuler: Integer;
      const AText: string);
    procedure CancelDrag;
    procedure UpdateCursor(const X, Y: Integer);
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMHintShow(var Message: TCMHintShow); message CM_HINTSHOW;
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
    procedure BeginUpdate;
    procedure EndUpdate;
    procedure ClearColumns;
    procedure ClearItems;
    function AddGroup(const ACaption: string; const AColor: TColor): Integer;
    function AddColumn(const AGroup: Integer; const ACaption: string): Integer;
    function AddItem: TUiScheduleItem;
    function ItemAt(const X, Y: Integer): TUiScheduleItem;
    function ColumnAt(const X: Integer): Integer;
    function TimeAt(const Y: Integer): TDateTime;
    procedure ZoomBy(const AFactor: Double);
    function RenderToBitmap(const AStartTime: TDateTime; const ASpanHours: Double;
      const AWidth, AHeight: Integer): TBitmap;
    property ColumnCount: Integer read GetColumnCount;
    property ItemCount: Integer read GetItemCount;
    property Items[const AIndex: Integer]: TUiScheduleItem read GetItem;
    property ItemDragging: Boolean read GetDragging;
    property ResolveColumns: TUiScheduleResolveColumns read FResolveColumns write FResolveColumns;
  published
    property Align;
    property Anchors;
    property ConflictGap: TDateTime read FConflictGap write FConflictGap;
    property Font;
    property MaxSpanHours: Double read FMaxSpanHours write FMaxSpanHours;
    property MinSpanHours: Double read FMinSpanHours write FMinSpanHours;
    property ParentFont;
    property SnapMinutes: Integer read FSnapMinutes write FSnapMinutes default 15;
    property SpanHours: Double read FSpanHours write SetSpanHours;
    property StartTime: TDateTime read FStartTime write SetStartTime;
    property TabStop default True;
    property Visible;
    property OnItemChange: TUiScheduleChangeEvent read FOnItemChange write FOnItemChange;
    property OnItemClick: TUiScheduleItemEvent read FOnItemClick write FOnItemClick;
    property OnRangeSelect: TUiScheduleRangeEvent read FOnRangeSelect write FOnRangeSelect;
    property OnViewChange: TNotifyEvent read FOnViewChange write FOnViewChange;
  end;

implementation

uses
  Forms, Math, DateUtils, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

const
  cBlockNormal = 0;
  cBlockHover = 1;
  cBlockGhost = 2;
  cBlockConflict = 3;
  cBlockOrigin = 4;

function SameColumns(const A, B: TArray<Integer>): Boolean;
var
  I: Integer;
begin
  Result := Length(A) = Length(B);
  if Result then
    for I := 0 to High(A) do
      if A[I] <> B[I] then
        Exit(False);
end;

function SortedColumns(const AColumns: TArray<Integer>): TArray<Integer>;
begin
  Result := Copy(AColumns);
  TArray.Sort<Integer>(Result);
end;

constructor TUiSchedule.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque, csCaptureMouse, csClickEvents, csDoubleClicks];
  TabStop := True;
  ShowHint := True;
  FGroups := TList<TUiScheduleGroup>.Create;
  FColumns := TList<TUiScheduleColumn>.Create;
  FItems := TObjectList<TUiScheduleItem>.Create(True);
  FSegments := TList<TUiScheduleSegment>.Create;
  FSpanHours := 16;
  FMinSpanHours := 3;
  FMaxSpanHours := 48;
  FSnapMinutes := 15;
  FStartTime := Trunc(Now);
  FSelectColumn := -1;
  FTimer := TTimer.Create(Self);
  FTimer.Interval := 60000;
  FTimer.OnTimer := TimerTick;
  Width := 600;
  Height := 400;
end;

destructor TUiSchedule.Destroy;
begin
  FreeAndNil(FSegments);
  FreeAndNil(FItems);
  FreeAndNil(FColumns);
  FreeAndNil(FGroups);
  inherited;
end;

procedure TUiSchedule.TimerTick(Sender: TObject);
begin
  Invalidate;
end;

procedure TUiSchedule.Changed;
begin
  if FUpdateCount = 0 then
    Invalidate;
end;

procedure TUiSchedule.DoViewChange;
begin
  Changed;
  if Assigned(FOnViewChange) then
    FOnViewChange(Self);
end;

procedure TUiSchedule.BeginUpdate;
begin
  Inc(FUpdateCount);
end;

procedure TUiSchedule.EndUpdate;
begin
  Dec(FUpdateCount);
  Changed;
end;

procedure TUiSchedule.ClearColumns;
begin
  CancelDrag;
  FGroups.Clear;
  FColumns.Clear;
  Changed;
end;

procedure TUiSchedule.ClearItems;
begin
  CancelDrag;
  FHoverItem := nil;
  FSegments.Clear;
  FItems.Clear;
  Changed;
end;

function TUiSchedule.AddGroup(const ACaption: string; const AColor: TColor): Integer;
var
  vGroup: TUiScheduleGroup;
begin
  vGroup.Caption := ACaption;
  vGroup.Color := AColor;
  vGroup.FirstColumn := FColumns.Count;
  vGroup.ColumnCount := 0;
  Result := FGroups.Add(vGroup);
  Changed;
end;

function TUiSchedule.AddColumn(const AGroup: Integer; const ACaption: string): Integer;
var
  vColumn: TUiScheduleColumn;
  vGroup: TUiScheduleGroup;
begin
  vColumn.Caption := ACaption;
  vColumn.Group := AGroup;
  Result := FColumns.Add(vColumn);
  vGroup := FGroups[AGroup];
  if vGroup.ColumnCount = 0 then
    vGroup.FirstColumn := Result;
  Inc(vGroup.ColumnCount);
  FGroups[AGroup] := vGroup;
  Changed;
end;

function TUiSchedule.AddItem: TUiScheduleItem;
begin
  Result := TUiScheduleItem.Create;
  Result.Color := clUiAccent;
  FItems.Add(Result);
  Changed;
end;

function TUiSchedule.GetItem(const AIndex: Integer): TUiScheduleItem;
begin
  Result := FItems[AIndex];
end;

function TUiSchedule.GetItemCount: Integer;
begin
  Result := FItems.Count;
end;

function TUiSchedule.GetColumnCount: Integer;
begin
  Result := FColumns.Count;
end;

function TUiSchedule.GetDragging: Boolean;
begin
  Result := FDrag <> usgNone;
end;

procedure TUiSchedule.SetStartTime(const AValue: TDateTime);
begin
  if SameValue(FStartTime, AValue, OneSecond) then
    Exit;
  FStartTime := AValue;
  DoViewChange;
end;

procedure TUiSchedule.SetSpanHours(const AValue: Double);
var
  vValue: Double;
begin
  vValue := EnsureRange(AValue, FMinSpanHours, FMaxSpanHours);
  if SameValue(FSpanHours, vValue) then
    Exit;
  FSpanHours := vValue;
  DoViewChange;
end;

procedure TUiSchedule.ZoomBy(const AFactor: Double);
var
  vCenter: TDateTime;
  vSpan: Double;
begin
  vCenter := FStartTime + FSpanHours / 2 * OneHour;
  vSpan := EnsureRange(FSpanHours * AFactor, FMinSpanHours, FMaxSpanHours);
  FSpanHours := vSpan;
  FStartTime := vCenter - vSpan / 2 * OneHour;
  DoViewChange;
end;

function TUiSchedule.SnapStep: TDateTime;
begin
  Result := Max(1, FSnapMinutes) * OneMinute;
end;

function TUiSchedule.SnapTime(const ATime: TDateTime): TDateTime;
begin
  Result := Round(ATime / SnapStep) * SnapStep;
end;

function TUiSchedule.SnapFloor(const ATime: TDateTime): TDateTime;
begin
  Result := Floor(ATime / SnapStep + 1E-6) * SnapStep;
end;

function TUiSchedule.TextHeightOf(const ACanvas: TCanvas): Integer;
begin
  ACanvas.Font.Assign(Font);
  Result := ACanvas.TextHeight('Wg');
end;

function TUiSchedule.RulerWidth(const ACanvas: TCanvas): Integer;
begin
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Name := cUiFontSemibold;
  Result := Max(ACanvas.TextWidth('00:00'), ACanvas.TextWidth('ww 00.00')) + ScaleValue(20);
end;

function TUiSchedule.HeaderHeight(const ACanvas: TCanvas): Integer;
begin
  Result := (TextHeightOf(ACanvas) + ScaleValue(14)) * 2;
end;

function TUiSchedule.ColumnLeft(const AIndex, AWidth, ARuler: Integer): Integer;
begin
  if FColumns.Count = 0 then
    Exit(ARuler);
  Result := ARuler + MulDiv(AWidth - ARuler, AIndex, FColumns.Count);
end;

function TUiSchedule.TimeToY(const ATime: TDateTime; const AHeight, AHeader: Integer): Integer;
var
  vHourHeight: Double;
begin
  vHourHeight := (AHeight - AHeader) / FSpanHours;
  Result := AHeader + Round((ATime - FStartTime) / OneHour * vHourHeight);
end;

function TUiSchedule.YToTime(const Y: Integer): TDateTime;
var
  vHeader: Integer;
  vHourHeight: Double;
begin
  vHeader := HeaderHeight(Canvas);
  vHourHeight := (ClientHeight - vHeader) / FSpanHours;
  if vHourHeight <= 0 then
    Exit(FStartTime);
  Result := FStartTime + (Y - vHeader) / vHourHeight * OneHour;
end;

function TUiSchedule.TimeAt(const Y: Integer): TDateTime;
begin
  Result := YToTime(Y);
end;

function TUiSchedule.ColumnAt(const X: Integer): Integer;
var
  vRuler, I: Integer;
begin
  Result := -1;
  vRuler := RulerWidth(Canvas);
  if X < vRuler then
    Exit;
  for I := 0 to FColumns.Count - 1 do
    if (X >= ColumnLeft(I, ClientWidth, vRuler)) and (X < ColumnLeft(I + 1, ClientWidth, vRuler)) then
      Exit(I);
end;

procedure TUiSchedule.AddItemSegments(const AItem: TUiScheduleItem; const AStart, AEnd: TDateTime;
  const AColumns: TArray<Integer>; const AList: TList<TUiScheduleSegment>);
var
  vColumns: TArray<Integer>;
  vSegment: TUiScheduleSegment;
  I: Integer;
begin
  vColumns := SortedColumns(AColumns);
  I := 0;
  while I <= High(vColumns) do
  begin
    if (vColumns[I] < 0) or (vColumns[I] >= FColumns.Count) then
    begin
      Inc(I);
      Continue;
    end;
    vSegment.Item := AItem;
    vSegment.StartTime := AStart;
    vSegment.EndTime := AEnd;
    vSegment.FirstColumn := vColumns[I];
    vSegment.LastColumn := vColumns[I];
    vSegment.Lane := 0;
    vSegment.LaneCount := 1;
    while (I < High(vColumns)) and (vColumns[I + 1] = vSegment.LastColumn + 1) do
    begin
      Inc(I);
      vSegment.LastColumn := vColumns[I];
    end;
    AList.Add(vSegment);
    Inc(I);
  end;
end;

function SegmentsOverlap(const A, B: TUiScheduleSegment): Boolean;
begin
  Result := (A.StartTime < B.EndTime) and (B.StartTime < A.EndTime) and
    (A.FirstColumn = B.FirstColumn) and (A.LastColumn = B.LastColumn);
end;

procedure TUiSchedule.LayoutLanes(const AList: TList<TUiScheduleSegment>; const AFirst: Integer);
var
  I, J, vLane: Integer;
  vUsed: TList<Integer>;
  vSegment, vOther: TUiScheduleSegment;
begin
  vUsed := TList<Integer>.Create;
  try
    for I := AFirst to AList.Count - 1 do
    begin
      vUsed.Clear;
      for J := AFirst to I - 1 do
        if SegmentsOverlap(AList[I], AList[J]) then
          vUsed.Add(AList[J].Lane);
      vLane := 0;
      while vUsed.Contains(vLane) do
        Inc(vLane);
      vSegment := AList[I];
      vSegment.Lane := vLane;
      AList[I] := vSegment;
    end;
    for I := AFirst to AList.Count - 1 do
    begin
      vSegment := AList[I];
      vSegment.LaneCount := vSegment.Lane + 1;
      for J := AFirst to AList.Count - 1 do
      begin
        vOther := AList[J];
        if (J <> I) and SegmentsOverlap(vSegment, vOther) then
          vSegment.LaneCount := Max(vSegment.LaneCount, vOther.Lane + 1);
      end;
      AList[I] := vSegment;
    end;
  finally
    vUsed.Free;
  end;
end;

function TUiSchedule.SegmentRect(const ASegment: TUiScheduleSegment; const AWidth, AHeight, ARuler,
  AHeader: Integer): TRect;
var
  vLeft, vRight: Integer;
  vLaneWidth: Double;
begin
  vLeft := ColumnLeft(ASegment.FirstColumn, AWidth, ARuler);
  vRight := ColumnLeft(ASegment.LastColumn + 1, AWidth, ARuler);
  vLaneWidth := (vRight - vLeft) / Max(1, ASegment.LaneCount);
  if (ASegment.LaneCount > 1) and (vLaneWidth < ScaleValue(110)) then
  begin
    Result.Left := vLeft + ScaleValue(3) + ASegment.Lane * ScaleValue(14);
    Result.Right := vRight - ScaleValue(3);
    if Result.Right - Result.Left < ScaleValue(40) then
      Result.Left := Result.Right - ScaleValue(40);
  end
  else
  begin
    Result.Left := vLeft + Round(ASegment.Lane * vLaneWidth) + ScaleValue(3);
    Result.Right := vLeft + Round((ASegment.Lane + 1) * vLaneWidth) - ScaleValue(3);
  end;
  Result.Top := TimeToY(ASegment.StartTime, AHeight, AHeader) + ScaleValue(1);
  Result.Bottom := TimeToY(ASegment.EndTime, AHeight, AHeader) - ScaleValue(2);
  if Result.Bottom - Result.Top < ScaleValue(10) then
    Result.Bottom := Result.Top + ScaleValue(10);
end;

procedure TUiSchedule.BuildSegments(const ACanvas: TCanvas; const AWidth, AHeight: Integer);
var
  vEnd: TDateTime;
  vItem: TUiScheduleItem;
  vFaded: TList<TUiScheduleSegment>;
  vSegment: TUiScheduleSegment;
  vRuler, vHeader, I, vFirstActive: Integer;
begin
  FSegments.Clear;
  vEnd := FStartTime + FSpanHours * OneHour;
  vFaded := TList<TUiScheduleSegment>.Create;
  try
    for vItem in FItems do
      if vItem.Faded and (vItem.StartTime < vEnd) and (vItem.EndTime > FStartTime) then
        AddItemSegments(vItem, vItem.StartTime, vItem.EndTime, vItem.Columns, vFaded);
    FSegments.AddRange(vFaded);
  finally
    vFaded.Free;
  end;
  vFirstActive := FSegments.Count;
  for vItem in FItems do
    if not vItem.Faded and (vItem.StartTime < vEnd) and (vItem.EndTime > FStartTime) then
      AddItemSegments(vItem, vItem.StartTime, vItem.EndTime, vItem.Columns, FSegments);
  LayoutLanes(FSegments, vFirstActive);
  FSegments.Sort(TComparer<TUiScheduleSegment>.Construct(
    function(const A, B: TUiScheduleSegment): Integer
    begin
      Result := Ord(B.Item.Faded) - Ord(A.Item.Faded);
      if Result = 0 then
        Result := (B.LastColumn - B.FirstColumn) - (A.LastColumn - A.FirstColumn);
      if Result = 0 then
        Result := A.Lane - B.Lane;
      if Result = 0 then
        Result := CompareValue(A.StartTime, B.StartTime);
    end));
  vRuler := RulerWidth(ACanvas);
  vHeader := HeaderHeight(ACanvas);
  for I := 0 to FSegments.Count - 1 do
  begin
    vSegment := FSegments[I];
    vSegment.Rect := SegmentRect(vSegment, AWidth, AHeight, vRuler, vHeader);
    FSegments[I] := vSegment;
  end;
end;

function TUiSchedule.HasConflict(const AItem: TUiScheduleItem; const AStart, AEnd: TDateTime;
  const AColumns: TArray<Integer>): Boolean;
var
  vItem: TUiScheduleItem;
  vColumn, vOther: Integer;
begin
  Result := False;
  for vItem in FItems do
  begin
    if (vItem = AItem) or vItem.Faded then
      Continue;
    if not ((vItem.StartTime < AEnd + FConflictGap) and (AStart < vItem.EndTime + FConflictGap)) then
      Continue;
    for vColumn in AColumns do
      for vOther in vItem.Columns do
        if vColumn = vOther then
          Exit(True);
  end;
end;

function TUiSchedule.SegmentAt(const X, Y: Integer; out ASegment: TUiScheduleSegment): Boolean;
var
  I: Integer;
begin
  for I := FSegments.Count - 1 downto 0 do
    if FSegments[I].Rect.Contains(Point(X, Y)) then
    begin
      ASegment := FSegments[I];
      Exit(True);
    end;
  Result := False;
end;

function TUiSchedule.ItemAt(const X, Y: Integer): TUiScheduleItem;
var
  vSegment: TUiScheduleSegment;
begin
  if SegmentAt(X, Y, vSegment) then
    Result := vSegment.Item
  else
    Result := nil;
end;

procedure TUiSchedule.Resize;
begin
  inherited;
  Invalidate;
end;

procedure TUiSchedule.Paint;
var
  vBuffer: TBitmap;
begin
  vBuffer := TBitmap.Create;
  try
    vBuffer.SetSize(ClientWidth, ClientHeight);
    PaintArea(vBuffer.Canvas, ClientWidth, ClientHeight, False);
    Canvas.Draw(0, 0, vBuffer);
  finally
    vBuffer.Free;
  end;
end;

function TUiSchedule.RenderToBitmap(const AStartTime: TDateTime; const ASpanHours: Double;
  const AWidth, AHeight: Integer): TBitmap;
var
  vStart: TDateTime;
  vSpan: Double;
  vHover: TUiScheduleItem;
  vDrag: TUiScheduleDrag;
begin
  vStart := FStartTime;
  vSpan := FSpanHours;
  vHover := FHoverItem;
  vDrag := FDrag;
  FStartTime := AStartTime;
  FSpanHours := ASpanHours;
  FHoverItem := nil;
  FDrag := usgNone;
  Result := TBitmap.Create;
  try
    Result.PixelFormat := pf24bit;
    Result.SetSize(AWidth, AHeight);
    PaintArea(Result.Canvas, AWidth, AHeight, True);
  finally
    FStartTime := vStart;
    FSpanHours := vSpan;
    FHoverItem := vHover;
    FDrag := vDrag;
    if HandleAllocated then
    begin
      BuildSegments(Canvas, ClientWidth, ClientHeight);
      Invalidate;
    end;
  end;
end;

procedure TUiSchedule.PaintArea(const ACanvas: TCanvas; const AWidth, AHeight: Integer; const AExport: Boolean);
var
  vRuler, vHeader, vY, I: Integer;
  vSegment: TUiScheduleSegment;
  vState: Integer;
  vGhost: TList<TUiScheduleSegment>;
  vRect: TRect;
begin
  vRuler := RulerWidth(ACanvas);
  vHeader := HeaderHeight(ACanvas);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clUiCard;
  ACanvas.FillRect(Rect(0, 0, AWidth, AHeight));
  BuildSegments(ACanvas, AWidth, AHeight);
  PaintGrid(ACanvas, AWidth, AHeight, vRuler, vHeader);

  IntersectClipRect(ACanvas.Handle, vRuler, vHeader, AWidth, AHeight);
  try
    for I := 0 to FSegments.Count - 1 do
    begin
      vSegment := FSegments[I];
      if (FDrag in [usgMove, usgResizeTop, usgResizeBottom]) and (vSegment.Item = FDragItem) then
        vState := cBlockOrigin
      else if not AExport and (vSegment.Item = FHoverItem) and (FDrag = usgNone) then
        vState := cBlockHover
      else
        vState := cBlockNormal;
      PaintBlock(ACanvas, vSegment.Rect, vSegment.Item, vSegment.StartTime, vSegment.EndTime, vState);
    end;

    if FDrag in [usgMove, usgResizeTop, usgResizeBottom] then
    begin
      vGhost := TList<TUiScheduleSegment>.Create;
      try
        AddItemSegments(FDragItem, FDragStart, FDragEnd, FDragColumns, vGhost);
        if HasConflict(FDragItem, FDragStart, FDragEnd, FDragColumns) then
          vState := cBlockConflict
        else
          vState := cBlockGhost;
        for vSegment in vGhost do
          PaintBlock(ACanvas, SegmentRect(vSegment, AWidth, AHeight, vRuler, vHeader), FDragItem,
            FDragStart, FDragEnd, vState);
      finally
        vGhost.Free;
      end;
    end
    else if FDrag = usgSelect then
    begin
      vRect := Rect(ColumnLeft(FSelectColumn, AWidth, vRuler) + ScaleValue(3), TimeToY(FDragStart, AHeight, vHeader),
        ColumnLeft(FSelectColumn + 1, AWidth, vRuler) - ScaleValue(3), TimeToY(FDragEnd, AHeight, vHeader));
      DrawRounded(ACanvas, vRect, ScaleValue(8), TintColor(clUiAccent, 80), clUiAccent, 2);
      PaintSelectionLabel(ACanvas, vRect, AWidth, vRuler,
        FormatDateTime('h:nn', FDragStart) + '–' + FormatDateTime('h:nn', FDragEnd));
    end;

    if (Now > FStartTime) and (Now < FStartTime + FSpanHours * OneHour) then
    begin
      vY := TimeToY(Now, AHeight, vHeader);
      ACanvas.Pen.Color := clUiAccent;
      ACanvas.Pen.Width := ScaleValue(2);
      ACanvas.Pen.Style := psSolid;
      ACanvas.MoveTo(vRuler, vY);
      ACanvas.LineTo(AWidth, vY);
      ACanvas.Pen.Width := 1;
    end;
  finally
    SelectClipRgn(ACanvas.Handle, 0);
  end;

  if (Now > FStartTime) and (Now < FStartTime + FSpanHours * OneHour) then
  begin
    vY := TimeToY(Now, AHeight, vHeader);
    DrawRounded(ACanvas, Rect(vRuler - ScaleValue(5), vY - ScaleValue(5), vRuler + ScaleValue(5), vY + ScaleValue(5)),
      ScaleValue(5), clUiAccent, clUiAccent);
  end;
  PaintHeader(ACanvas, AWidth, vRuler, vHeader);
  if AExport then
    DrawRoundedFrame(ACanvas, Rect(0, 0, AWidth, AHeight), ScaleValue(12), clUiCard, clUiBorder)
  else
    DrawRoundedFrame(ACanvas, Rect(0, 0, AWidth, AHeight), ScaleValue(12), SurfaceOf(Self), clUiBorder);
end;

procedure TUiSchedule.PaintSelectionLabel(const ACanvas: TCanvas; const ARect: TRect; const AWidth, ARuler: Integer;
  const AText: string);
var
  vTag: TRect;
  vText: string;
  vPad, vWidth, vHeight: Integer;
begin
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Name := cUiFontSemibold;
  ACanvas.Font.Size := Max(1, Font.Size - 1);
  vPad := ScaleValue(8);
  vWidth := ACanvas.TextWidth(AText) + vPad * 2;
  vHeight := ACanvas.TextHeight(AText) + ScaleValue(8);
  vText := AText;
  if (vWidth <= ARect.Width) and (vHeight <= ARect.Height) then
  begin
    vTag := Rect(ARect.Left, ARect.Top, ARect.Left + vWidth, ARect.Top + vHeight);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := ShadeColor(clUiAccent, 25);
    ACanvas.TextRect(vTag, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
    ACanvas.Brush.Style := bsSolid;
    Exit;
  end;
  vTag := Rect(ARect.Right + ScaleValue(6), ARect.Top, ARect.Right + ScaleValue(6) + vWidth, ARect.Top + vHeight);
  if vTag.Right > AWidth - ScaleValue(4) then
    vTag := Rect(ARect.Left - ScaleValue(6) - vWidth, ARect.Top, ARect.Left - ScaleValue(6), ARect.Top + vHeight);
  if vTag.Left < ARuler then
    OffsetRect(vTag, ARuler - vTag.Left + ScaleValue(4), 0);
  DrawRounded(ACanvas, vTag, vHeight div 2, clUiAccent, clUiAccent);
  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Color := clWhite;
  ACanvas.TextRect(vTag, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TUiSchedule.PaintGrid(const ACanvas: TCanvas; const AWidth, AHeight, ARuler, AHeader: Integer);
const
  cSteps: array[0..6] of Integer = (1, 2, 3, 4, 6, 12, 24);
var
  I, vLeft, vRight, vY, vNowY, vTextHeight, vStep: Integer;
  vColor: TColor;
  vHour, vEnd: TDateTime;
  vHourHeight: Double;
  vText: string;
  vRect: TRect;
  vMidnight: Boolean;
begin
  vNowY := TimeToY(Now, AHeight, AHeader);
  vEnd := FStartTime + FSpanHours * OneHour;
  for I := 0 to FColumns.Count - 1 do
  begin
    vLeft := ColumnLeft(I, AWidth, ARuler);
    vRight := ColumnLeft(I + 1, AWidth, ARuler);
    vColor := TintColor(FGroups[FColumns[I].Group].Color, 93);
    ACanvas.Brush.Color := vColor;
    ACanvas.FillRect(Rect(vLeft, AHeader, vRight, AHeight));
    vHour := Trunc(FStartTime / OneHour) * OneHour;
    while vHour < vEnd do
    begin
      if Odd(HourOf(vHour + OneSecond)) then
      begin
        ACanvas.Brush.Color := ShadeColor(vColor, 3);
        ACanvas.FillRect(Rect(vLeft, Max(AHeader, TimeToY(vHour, AHeight, AHeader)), vRight,
          Min(AHeight, TimeToY(vHour + OneHour, AHeight, AHeader))));
      end;
      vHour := vHour + OneHour;
    end;
    if vNowY > AHeader then
    begin
      vHour := Trunc(FStartTime / OneHour) * OneHour;
      while vHour < Min(Now, vEnd) do
      begin
        if Odd(HourOf(vHour + OneSecond)) then
          ACanvas.Brush.Color := ShadeColor(vColor, 8)
        else
          ACanvas.Brush.Color := ShadeColor(vColor, 5);
        ACanvas.FillRect(Rect(vLeft, Max(AHeader, TimeToY(vHour, AHeight, AHeader)), vRight,
          Min(Min(vNowY, AHeight), TimeToY(vHour + OneHour, AHeight, AHeader))));
        vHour := vHour + OneHour;
      end;
    end;
  end;

  vTextHeight := TextHeightOf(ACanvas);
  vHourHeight := (AHeight - AHeader) / FSpanHours;
  if vHourHeight >= vTextHeight * 2.5 then
  begin
    ACanvas.Pen.Color := clUiScrollThumb;
    ACanvas.Pen.Style := psDot;
    vHour := Trunc(FStartTime / OneHour) * OneHour + OneHour / 2;
    while vHour < vEnd do
    begin
      if vHour > FStartTime then
      begin
        vY := TimeToY(vHour, AHeight, AHeader);
        ACanvas.MoveTo(ARuler, vY);
        ACanvas.LineTo(AWidth, vY);
      end;
      vHour := vHour + OneHour;
    end;
    ACanvas.Pen.Style := psSolid;
  end;
  vStep := 24;
  for I := 0 to High(cSteps) do
    if cSteps[I] * vHourHeight >= vTextHeight * 1.6 then
    begin
      vStep := cSteps[I];
      Break;
    end;

  vEnd := FStartTime + FSpanHours * OneHour;
  vHour := Trunc(FStartTime / OneHour) * OneHour;
  ACanvas.Font.Assign(Font);
  while vHour <= vEnd do
  begin
    if vHour >= FStartTime then
    begin
      vY := TimeToY(vHour, AHeight, AHeader);
      vMidnight := HourOf(vHour + OneSecond) = 0;
      if vMidnight then
      begin
        ACanvas.Pen.Color := clUiMuted;
        ACanvas.Pen.Width := ScaleValue(2);
      end
      else
      begin
        ACanvas.Pen.Color := clUiScrollThumb;
        ACanvas.Pen.Width := 1;
      end;
      ACanvas.MoveTo(ARuler, vY);
      ACanvas.LineTo(AWidth, vY);
      if vMidnight or (HourOf(vHour + OneSecond) mod vStep = 0) then
      begin
        ACanvas.Brush.Style := bsClear;
        ACanvas.Font.Assign(Font);
        if vMidnight then
        begin
          ACanvas.Font.Name := cUiFontSemibold;
          ACanvas.Font.Color := clUiText;
          vText := FormatDateTime('ddd dd.mm', vHour + OneSecond);
        end
        else
        begin
          ACanvas.Font.Color := clUiMuted;
          vText := FormatDateTime('hh:nn', vHour + OneSecond);
        end;
        vRect := Rect(0, vY - vTextHeight div 2, ARuler - ScaleValue(8), vY + vTextHeight div 2 + 1);
        if vMidnight and (vRect.Top < AHeader) then
          OffsetRect(vRect, 0, AHeader - vRect.Top);
        if vMidnight and (vRect.Bottom > AHeight) then
          OffsetRect(vRect, 0, AHeight - vRect.Bottom);
        if (vRect.Top >= AHeader) and (vRect.Bottom <= AHeight) then
          ACanvas.TextRect(vRect, vText, [tfRight, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
        ACanvas.Brush.Style := bsSolid;
      end;
    end;
    vHour := vHour + OneHour;
  end;
  ACanvas.Pen.Width := 1;

  for I := 1 to FColumns.Count - 1 do
  begin
    vLeft := ColumnLeft(I, AWidth, ARuler);
    if FColumns[I].Group <> FColumns[I - 1].Group then
      ACanvas.Pen.Color := clUiTableHeaderDivider
    else
      ACanvas.Pen.Color := clUiBorder;
    ACanvas.MoveTo(vLeft, AHeader);
    ACanvas.LineTo(vLeft, AHeight);
  end;
  ACanvas.Pen.Color := clUiTableHeaderDivider;
  ACanvas.MoveTo(ARuler, AHeader);
  ACanvas.LineTo(ARuler, AHeight);
end;

function WrapLines(const ACanvas: TCanvas; const AText: string; const AWidth: Integer): TArray<string>;
var
  vWords: TArray<string>;
  vWord, vCurrent, vCandidate: string;
  vCount: Integer;
begin
  Result := nil;
  if AWidth <= 0 then
    Exit(TArray<string>.Create(AText));
  vCurrent := '';
  vWords := AText.Split([' ']);
  for vWord in vWords do
  begin
    if vWord = '' then
      Continue;
    if vCurrent = '' then
      vCandidate := vWord
    else
      vCandidate := vCurrent + ' ' + vWord;
    if ACanvas.TextWidth(vCandidate) <= AWidth then
    begin
      vCurrent := vCandidate;
      Continue;
    end;
    if vCurrent <> '' then
      Result := Result + [vCurrent];
    vCurrent := vWord;
    while ACanvas.TextWidth(vCurrent) > AWidth do
    begin
      vCount := Length(vCurrent) - 1;
      while (vCount > 1) and (ACanvas.TextWidth(Copy(vCurrent, 1, vCount)) > AWidth) do
        Dec(vCount);
      vCount := Max(vCount, 1);
      Result := Result + [Copy(vCurrent, 1, vCount)];
      Delete(vCurrent, 1, vCount);
    end;
  end;
  if vCurrent <> '' then
    Result := Result + [vCurrent];
end;

procedure TUiSchedule.PaintBlock(const ACanvas: TCanvas; const ARect: TRect; const AItem: TUiScheduleItem;
  const AStart, AEnd: TDateTime; const AState: Integer);
var
  vFill, vBorder, vBar, vText, vMuted: TColor;
  vInner, vLine, vBarRect: TRect;
  vTextHeight, vSmallHeight, vMarksWidth, vBorderWidth, vInset, vBarWidth: Integer;
  vLines: TStringList;
  vTime, vLineText, vPart, vDrawText: string;
  vWrapped: TArray<string>;
  vNarrow: Boolean;
  I: Integer;
begin
  vNarrow := ARect.Width < ScaleValue(140);
  if vNarrow then
  begin
    vInset := ScaleValue(8);
    vBarWidth := ScaleValue(3);
  end
  else
  begin
    vInset := ScaleValue(12);
    vBarWidth := ScaleValue(4);
  end;
  vBorderWidth := 1;
  vBar := AItem.Color;
  vText := clUiText;
  vMuted := clUiMuted;
  if AItem.Faded then
  begin
    vFill := clUiDisabledFill;
    vBorder := clUiBorder;
    vBar := clUiDisabledText;
    vText := clUiDisabledText;
    vMuted := clUiDisabledText;
  end
  else
    case AState of
      cBlockHover:
        begin
          vFill := TintColor(AItem.Color, 72);
          vBorder := TintColor(AItem.Color, 35);
        end;
      cBlockGhost:
        begin
          vFill := TintColor(AItem.Color, 78);
          vBorder := AItem.Color;
          vBorderWidth := ScaleValue(2);
        end;
      cBlockConflict:
        begin
          vFill := TintColor(clUiDanger, 85);
          vBorder := clUiDanger;
          vBar := clUiDanger;
          vBorderWidth := ScaleValue(2);
        end;
      cBlockOrigin:
        begin
          vFill := TintColor(AItem.Color, 92);
          vBorder := TintColor(AItem.Color, 70);
          vBar := TintColor(AItem.Color, 60);
          vText := clUiMuted;
        end;
    else
      vFill := TintColor(AItem.Color, 80);
      vBorder := TintColor(AItem.Color, 50);
    end;

  DrawRounded(ACanvas, ARect, ScaleValue(8), vFill, vBorder, vBorderWidth);
  vBarRect := Rect(ARect.Left + ScaleValue(2), ARect.Top + ScaleValue(3), ARect.Left + ScaleValue(2) + vBarWidth,
    ARect.Bottom - ScaleValue(3));
  if vBarRect.Bottom > vBarRect.Top + ScaleValue(4) then
    DrawRounded(ACanvas, vBarRect, ScaleValue(2), vBar, vBar);

  vInner := Rect(ARect.Left + vInset, ARect.Top + ScaleValue(4), ARect.Right - ScaleValue(4),
    ARect.Bottom - ScaleValue(3));
  if vInner.Right <= vInner.Left then
    Exit;
  IntersectClipRect(ACanvas.Handle, ARect.Left, ARect.Top, ARect.Right, ARect.Bottom);
  vLines := TStringList.Create;
  try
    ACanvas.Brush.Style := bsClear;
    vMarksWidth := 0;
    if AItem.Marks <> '' then
    begin
      ACanvas.Font.Assign(Font);
      ACanvas.Font.Name := UiIconFontName;
      ACanvas.Font.Size := Max(1, Font.Size - 2);
      ACanvas.Font.Color := vMuted;
      vMarksWidth := ACanvas.TextWidth(AItem.Marks) + ScaleValue(6);
      ACanvas.TextOut(vInner.Right - vMarksWidth + ScaleValue(6), vInner.Top + ScaleValue(2), AItem.Marks);
    end;

    ACanvas.Font.Assign(Font);
    ACanvas.Font.Name := cUiFontSemibold;
    ACanvas.Font.Size := Max(1, Font.Size - 1);
    vTextHeight := ACanvas.TextHeight('Wg');
    ACanvas.Font.Name := cUiFontName;
    ACanvas.Font.Size := Max(1, Font.Size - 2);
    vSmallHeight := ACanvas.TextHeight('Wg');
    vTime := FormatDateTime('h:nn', AStart) + '–' + FormatDateTime('h:nn', AEnd);
    if ACanvas.TextWidth(vTime) > vInner.Width then
      vTime := FormatDateTime('h:nn', AStart);

    if vInner.Height < vTextHeight + vSmallHeight then
    begin
      ACanvas.Font.Name := cUiFontSemibold;
      ACanvas.Font.Size := Max(1, Font.Size - 1);
      ACanvas.Font.Color := vText;
      vLine := Rect(vInner.Left, vInner.Top, vInner.Right - vMarksWidth, vInner.Bottom);
      vLineText := vTime + '  ' + AItem.Title;
      ACanvas.TextRect(vLine, vLineText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
      Exit;
    end;

    ACanvas.Font.Name := cUiFontSemibold;
    ACanvas.Font.Size := Max(1, Font.Size - 1);
    ACanvas.Font.Color := vText;
    vLine := Rect(vInner.Left, vInner.Top, vInner.Right - vMarksWidth, vInner.Top);
    vWrapped := WrapLines(ACanvas, AItem.Title, vLine.Width);
    for I := 0 to High(vWrapped) do
    begin
      if (I > 0) and (vLine.Top + vTextHeight > vInner.Bottom) then
        Break;
      vLine.Bottom := vLine.Top + vTextHeight;
      vLineText := vWrapped[I];
      ACanvas.TextRect(vLine, vLineText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix]);
      vLine.Top := vLine.Bottom;
      vLine.Right := vInner.Right;
    end;

    ACanvas.Font.Name := cUiFontName;
    ACanvas.Font.Size := Max(1, Font.Size - 2);
    ACanvas.Font.Color := vMuted;
    vLines.Text := vTime + sLineBreak + AItem.Details;
    vLine.Right := vInner.Right;
    for vLineText in vLines do
      for vPart in WrapLines(ACanvas, vLineText, vInner.Width) do
      begin
        if vLine.Top + vSmallHeight > vInner.Bottom then
          Break;
        vLine.Bottom := vLine.Top + vSmallHeight;
        vDrawText := vPart;
        ACanvas.TextRect(vLine, vDrawText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix]);
        vLine.Top := vLine.Bottom;
      end;
  finally
    vLines.Free;
    ACanvas.Brush.Style := bsSolid;
    SelectClipRgn(ACanvas.Handle, 0);
  end;
end;

procedure TUiSchedule.PaintHeader(const ACanvas: TCanvas; const AWidth, ARuler, AHeader: Integer);
var
  I, vRow, vLeft, vRight, vGap, vRadius: Integer;
  vGroup: TUiScheduleGroup;
  vRect: TRect;
  vText: string;
begin
  vRow := AHeader div 2;
  vGap := ScaleValue(2);
  vRadius := ScaleValue(8);
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := clUiCard;
  ACanvas.FillRect(Rect(0, 0, AWidth, AHeader));
  for I := 0 to FGroups.Count - 1 do
  begin
    vGroup := FGroups[I];
    if vGroup.ColumnCount = 0 then
      Continue;
    vLeft := ColumnLeft(vGroup.FirstColumn, AWidth, ARuler) + vGap;
    vRight := ColumnLeft(vGroup.FirstColumn + vGroup.ColumnCount, AWidth, ARuler) - vGap;
    DrawRounded(ACanvas, Rect(vLeft, vGap * 2, vRight, AHeader - vGap * 2), vRadius,
      TintColor(vGroup.Color, 78), TintColor(vGroup.Color, 78));
    DrawRounded(ACanvas, Rect(vLeft, vGap * 2, vRight, vRow + vRadius), vRadius,
      TintColor(vGroup.Color, 55), TintColor(vGroup.Color, 55));
    ACanvas.Brush.Style := bsSolid;
    ACanvas.Brush.Color := TintColor(vGroup.Color, 78);
    ACanvas.FillRect(Rect(vLeft, vRow, vRight, vRow + vRadius));
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Assign(Font);
    ACanvas.Font.Name := cUiFontSemibold;
    ACanvas.Font.Color := ShadeColor(vGroup.Color, 55);
    vRect := Rect(vLeft + ScaleValue(4), 0, vRight - ScaleValue(4), vRow);
    vText := vGroup.Caption;
    ACanvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
    ACanvas.Brush.Style := bsSolid;
  end;
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Size := Max(1, Font.Size - 1);
  for I := 0 to FColumns.Count - 1 do
  begin
    vLeft := ColumnLeft(I, AWidth, ARuler);
    vRight := ColumnLeft(I + 1, AWidth, ARuler);
    ACanvas.Brush.Style := bsClear;
    ACanvas.Font.Color := ShadeColor(FGroups[FColumns[I].Group].Color, 50);
    vRect := Rect(vLeft + ScaleValue(2), vRow, vRight - ScaleValue(2), AHeader);
    vText := FColumns[I].Caption;
    ACanvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
    ACanvas.Brush.Style := bsSolid;
    if (I > 0) and (FColumns[I].Group = FColumns[I - 1].Group) then
    begin
      ACanvas.Pen.Color := TintColor(FGroups[FColumns[I].Group].Color, 60);
      ACanvas.MoveTo(vLeft, vRow + ScaleValue(8));
      ACanvas.LineTo(vLeft, AHeader - ScaleValue(10));
    end;
  end;

  ACanvas.Brush.Style := bsClear;
  ACanvas.Font.Assign(Font);
  ACanvas.Font.Name := cUiFontSemibold;
  ACanvas.Font.Color := clUiText;
  vRect := Rect(ScaleValue(4), 0, ARuler - ScaleValue(4), vRow);
  vText := FormatDateTime('ddd', FStartTime);
  ACanvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
  ACanvas.Font.Name := cUiFontName;
  ACanvas.Font.Color := clUiMuted;
  vRect := Rect(ScaleValue(4), vRow, ARuler - ScaleValue(4), AHeader);
  vText := FormatDateTime('dd.mm', FStartTime);
  ACanvas.TextRect(vRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
  ACanvas.Brush.Style := bsSolid;
end;

procedure TUiSchedule.CancelDrag;
begin
  if FDrag = usgNone then
    Exit;
  FDrag := usgNone;
  FDragItem := nil;
  if MouseCapture then
    MouseCapture := False;
  Invalidate;
end;

procedure TUiSchedule.UpdateCursor(const X, Y: Integer);
var
  vSegment: TUiScheduleSegment;
  vEdge: Integer;
  vCursor: TCursor;
  vHover: TUiScheduleItem;
begin
  vEdge := ScaleValue(6);
  vHover := nil;
  vCursor := crDefault;
  if SegmentAt(X, Y, vSegment) then
  begin
    vHover := vSegment.Item;
    if not vSegment.Item.Faded and ((Abs(Y - vSegment.Rect.Top) <= vEdge) or (Abs(Y - vSegment.Rect.Bottom) <= vEdge)) then
      vCursor := crSizeNS
    else
      vCursor := crHandPoint;
  end;
  if Cursor <> vCursor then
    Cursor := vCursor;
  if vHover <> FHoverItem then
  begin
    FHoverItem := vHover;
    Application.CancelHint;
    Invalidate;
  end;
end;

procedure TUiSchedule.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if Assigned(FHoverItem) and (FDrag = usgNone) then
  begin
    FHoverItem := nil;
    Invalidate;
  end;
end;

procedure TUiSchedule.CMHintShow(var Message: TCMHintShow);
var
  vSegment: TUiScheduleSegment;
  vPoint: TPoint;
begin
  vPoint := Message.HintInfo.CursorPos;
  if (FDrag <> usgNone) or not SegmentAt(vPoint.X, vPoint.Y, vSegment) or (vSegment.Item.Hint = '') then
  begin
    Message.Result := 1;
    Exit;
  end;
  Message.HintInfo.HintStr := vSegment.Item.Hint;
  Message.HintInfo.CursorRect := vSegment.Rect;
  Message.HintInfo.HideTimeout := 30000;
  Message.Result := 0;
end;

procedure TUiSchedule.WMGetDlgCode(var Message: TWMGetDlgCode);
begin
  Message.Result := DLGC_WANTARROWS;
end;

procedure TUiSchedule.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vSegment: TUiScheduleSegment;
  vEdge: Integer;
begin
  inherited;
  if CanFocus then
    SetFocus;
  if Button <> mbLeft then
    Exit;
  FDragOrigin := Point(X, Y);
  FDragTimeOrigin := YToTime(Y);
  FDragColumnOrigin := ColumnAt(X);
  if SegmentAt(X, Y, vSegment) then
  begin
    FDragItem := vSegment.Item;
    FDragStart := FDragItem.StartTime;
    FDragEnd := FDragItem.EndTime;
    FDragColumns := Copy(FDragItem.Columns);
    FDragAnchor := FDragColumnOrigin;
    FDrag := usgPendingItem;
    vEdge := ScaleValue(6);
    if not FDragItem.Faded then
    begin
      if Abs(Y - vSegment.Rect.Top) <= vEdge then
        FDragAnchor := -2
      else if Abs(Y - vSegment.Rect.Bottom) <= vEdge then
        FDragAnchor := -3;
    end;
  end
  else if (FDragColumnOrigin >= 0) and (Y >= HeaderHeight(Canvas)) then
  begin
    FDrag := usgPendingSelect;
    FSelectColumn := FDragColumnOrigin;
    FSelectAnchor := SnapFloor(FDragTimeOrigin);
  end;
end;

procedure TUiSchedule.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vDelta: TDateTime;
  vColumn: Integer;
  vTime: TDateTime;
  vCanDrag: Boolean;
begin
  inherited;
  vCanDrag := (Abs(X - FDragOrigin.X) > ScaleValue(4)) or (Abs(Y - FDragOrigin.Y) > ScaleValue(4));
  if (FDrag = usgPendingItem) and vCanDrag and not FDragItem.Faded and Assigned(FOnItemChange) then
  begin
    if FDragAnchor = -2 then
      FDrag := usgResizeTop
    else if FDragAnchor = -3 then
      FDrag := usgResizeBottom
    else
      FDrag := usgMove;
    FDragAnchor := FDragColumnOrigin;
    Application.CancelHint;
  end
  else if (FDrag = usgPendingSelect) and vCanDrag and Assigned(FOnRangeSelect) then
    FDrag := usgSelect;

  case FDrag of
    usgMove:
      begin
        vDelta := SnapTime(YToTime(Y) - FDragTimeOrigin);
        FDragStart := FDragItem.StartTime + vDelta;
        FDragEnd := FDragItem.EndTime + vDelta;
        vColumn := ColumnAt(X);
        if (vColumn >= 0) and (vColumn <> FDragColumnOrigin) then
        begin
          FDragAnchor := vColumn;
          if Assigned(FResolveColumns) then
            FDragColumns := FResolveColumns(FDragItem, vColumn)
          else
            FDragColumns := TArray<Integer>.Create(vColumn);
        end
        else if vColumn = FDragColumnOrigin then
        begin
          FDragAnchor := FDragColumnOrigin;
          FDragColumns := Copy(FDragItem.Columns);
        end;
        Invalidate;
      end;
    usgResizeTop:
      begin
        FDragStart := Min(SnapTime(YToTime(Y)), FDragItem.EndTime - SnapStep);
        Invalidate;
      end;
    usgResizeBottom:
      begin
        FDragEnd := Max(SnapTime(YToTime(Y)), FDragItem.StartTime + SnapStep);
        Invalidate;
      end;
    usgSelect:
      begin
        vTime := SnapTime(YToTime(Y));
        FDragStart := Min(FSelectAnchor, vTime);
        FDragEnd := Max(FSelectAnchor, vTime);
        if FDragEnd - FDragStart < SnapStep / 2 then
          FDragEnd := FDragStart + SnapStep;
        Invalidate;
      end;
  else
    if FDrag = usgNone then
      UpdateCursor(X, Y);
  end;
end;

procedure TUiSchedule.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vDrag: TUiScheduleDrag;
  vItem: TUiScheduleItem;
  vStart, vEnd: TDateTime;
  vColumns: TArray<Integer>;
  vAnchor, vColumn: Integer;
begin
  inherited;
  if Button <> mbLeft then
    Exit;
  vDrag := FDrag;
  vItem := FDragItem;
  vStart := FDragStart;
  vEnd := FDragEnd;
  vColumns := FDragColumns;
  vAnchor := FDragAnchor;
  vColumn := FSelectColumn;
  FDrag := usgNone;
  FDragItem := nil;
  Invalidate;
  case vDrag of
    usgPendingItem:
      if Assigned(FOnItemClick) then
        FOnItemClick(Self, vItem);
    usgMove, usgResizeTop, usgResizeBottom:
      if Assigned(FOnItemChange) and (not SameValue(vStart, vItem.StartTime, OneSecond) or
        not SameValue(vEnd, vItem.EndTime, OneSecond) or
        not SameColumns(SortedColumns(vColumns), SortedColumns(vItem.Columns))) then
        FOnItemChange(Self, vItem, vStart, vEnd, vColumns, vAnchor);
    usgSelect:
      if Assigned(FOnRangeSelect) then
        FOnRangeSelect(Self, vColumn, vStart, vEnd);
  end;
  UpdateCursor(X, Y);
end;

procedure TUiSchedule.DblClick;
var
  vPoint: TPoint;
  vColumn: Integer;
  vStart: TDateTime;
begin
  inherited;
  vPoint := ScreenToClient(Mouse.CursorPos);
  if Assigned(ItemAt(vPoint.X, vPoint.Y)) or (vPoint.Y < HeaderHeight(Canvas)) then
    Exit;
  vColumn := ColumnAt(vPoint.X);
  if (vColumn < 0) or not Assigned(FOnRangeSelect) then
    Exit;
  FDrag := usgNone;
  vStart := SnapFloor(YToTime(vPoint.Y));
  FOnRangeSelect(Self, vColumn, vStart, vStart + OneHour);
end;

procedure TUiSchedule.KeyDown(var Key: Word; Shift: TShiftState);
begin
  inherited;
  case Key of
    VK_ESCAPE:
      CancelDrag;
    VK_UP:
      StartTime := FStartTime - OneHour;
    VK_DOWN:
      StartTime := FStartTime + OneHour;
    VK_PRIOR:
      StartTime := FStartTime - FSpanHours / 2 * OneHour;
    VK_NEXT:
      StartTime := FStartTime + FSpanHours / 2 * OneHour;
  end;
end;

function TUiSchedule.DoMouseWheel(Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint): Boolean;
var
  vPoint: TPoint;
  vAnchor: TDateTime;
  vSpan, vRatio: Double;
  vStep: TDateTime;
begin
  Result := True;
  vPoint := ScreenToClient(MousePos);
  if ssCtrl in Shift then
  begin
    vAnchor := YToTime(vPoint.Y);
    if WheelDelta > 0 then
      vSpan := FSpanHours / 1.25
    else
      vSpan := FSpanHours * 1.25;
    vSpan := EnsureRange(vSpan, FMinSpanHours, FMaxSpanHours);
    vRatio := vSpan / FSpanHours;
    FStartTime := vAnchor - (vAnchor - FStartTime) * vRatio;
    FSpanHours := vSpan;
    DoViewChange;
  end
  else
  begin
    vStep := Max(SnapStep, Round(FSpanHours / 8 * 4) / 4 * OneHour);
    if WheelDelta > 0 then
      StartTime := FStartTime - vStep
    else
      StartTime := FStartTime + vStep;
  end;
  if FDrag <> usgNone then
    MouseMove(KeyboardStateToShiftState, vPoint.X, vPoint.Y);
end;

end.
