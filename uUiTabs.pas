unit uUiTabs;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Generics.Collections;

type
  TUiTabs = class;

  TUiTabPosition = (utpTop, utpLeft);

  TUiTabSheet = class(TCustomControl)
  private
    FTabs: TUiTabs;
    FTabVisible: Boolean;
    FGlyph: string;
    FOnShow: TNotifyEvent;
    procedure SetTabVisible(const AValue: Boolean);
    procedure SetGlyph(const AValue: string);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
    function GetPageIndex: Integer;
  protected
    procedure SetParent(AParent: TWinControl); override;
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    property Tabs: TUiTabs read FTabs;
    property PageIndex: Integer read GetPageIndex;
  published
    property Caption;
    property Enabled;
    property Font;
    property Glyph: string read FGlyph write SetGlyph;
    property Hint;
    property Padding;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property TabVisible: Boolean read FTabVisible write SetTabVisible default True;
    property OnShow: TNotifyEvent read FOnShow write FOnShow;
  end;

  TUiTabs = class(TCustomControl)
  private
    FPages: TList<TUiTabSheet>;
    FActivePage: TUiTabSheet;
    FHotIndex: Integer;
    FShowTabs: Boolean;
    FTabPosition: TUiTabPosition;
    FOnChange: TNotifyEvent;
    procedure SetShowTabs(const AValue: Boolean);
    procedure SetTabPosition(const AValue: TUiTabPosition);
    function TabSize: Integer;
    function StripWidth: Integer;
    function LeftGlyphWidth: Integer;
    procedure PaintTopTabs(const ACanvas: TCanvas);
    procedure PaintLeftTabs(const ACanvas: TCanvas);
    function TabsBarRect: TRect;
    procedure InvalidateTabsBar;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure CMDesignHitTest(var Message: TCMDesignHitTest); message CM_DESIGNHITTEST;
    procedure CMFontChanged(var Message: TMessage); message CM_FONTCHANGED;
    function GetPage(const AIndex: Integer): TUiTabSheet;
    function GetPageCount: Integer;
    function GetActivePageIndex: Integer;
    procedure SetActivePageIndex(const AValue: Integer);
    procedure SetActivePage(const AValue: TUiTabSheet);
    procedure InsertPage(const APage: TUiTabSheet);
    procedure RemovePage(const APage: TUiTabSheet);
    procedure UpdatePagesVisibility(const AFireShow: Boolean = False);
    function TabAt(const X, Y: Integer): Integer;
  protected
    procedure Paint; override;
    procedure Loaded; override;
    procedure AdjustClientRect(var Rect: TRect); override;
    procedure ShowControl(AControl: TControl); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X, Y: Integer); override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure GetChildren(Proc: TGetChildProc; Root: TComponent); override;
    function HeaderHeight: Integer;
    function TabRect(const AIndex: Integer): TRect;
    procedure SelectNextPage(const AForward: Boolean);
    property Pages[const AIndex: Integer]: TUiTabSheet read GetPage;
    property PageCount: Integer read GetPageCount;
    property ActivePageIndex: Integer read GetActivePageIndex write SetActivePageIndex;
  published
    property ActivePage: TUiTabSheet read FActivePage write SetActivePage;
    property Align;
    property Anchors;
    property Enabled;
    property Font;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property ShowTabs: Boolean read FShowTabs write SetShowTabs default True;
    property TabOrder;
    property TabPosition: TUiTabPosition read FTabPosition write SetTabPosition default utpTop;
    property Visible;
    property OnChange: TNotifyEvent read FOnChange write FOnChange;
  end;

implementation

uses
  Forms, Math, System.Types, System.UITypes, uUiTheme, uUiPaint, uUiCard;

constructor TUiTabSheet.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque, csNoDesignVisible];
  Align := alClient;
  ParentColor := True;
  FTabVisible := True;
  Visible := False;
end;

destructor TUiTabSheet.Destroy;
begin
  if Assigned(FTabs) then
    FTabs.RemovePage(Self);
  inherited;
end;

procedure TUiTabSheet.SetParent(AParent: TWinControl);
begin
  if Assigned(FTabs) and (AParent <> FTabs) then
    FTabs.RemovePage(Self);
  inherited;
  if (AParent is TUiTabs) and (FTabs <> AParent) then
    TUiTabs(AParent).InsertPage(Self);
end;

procedure TUiTabSheet.Paint;
begin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := Color;
  Canvas.FillRect(ClientRect);
end;

procedure TUiTabSheet.SetTabVisible(const AValue: Boolean);
begin
  if FTabVisible = AValue then
    Exit;
  FTabVisible := AValue;
  if Assigned(FTabs) then
  begin
    if not FTabVisible and (FTabs.FActivePage = Self) then
      FTabs.SelectNextPage(True);
    FTabs.UpdatePagesVisibility;
    FTabs.Invalidate;
  end;
end;

procedure TUiTabSheet.SetGlyph(const AValue: string);
begin
  if FGlyph = AValue then
    Exit;
  FGlyph := AValue;
  if Assigned(FTabs) then
  begin
    FTabs.Realign;
    FTabs.Invalidate;
  end;
end;

procedure TUiTabSheet.CMTextChanged(var Message: TMessage);
begin
  inherited;
  if Assigned(FTabs) then
    FTabs.Invalidate;
end;

function TUiTabSheet.GetPageIndex: Integer;
begin
  if Assigned(FTabs) then
    Result := FTabs.FPages.IndexOf(Self)
  else
    Result := -1;
end;

constructor TUiTabs.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csAcceptsControls, csOpaque];
  FPages := TList<TUiTabSheet>.Create;
  FHotIndex := -1;
  FShowTabs := True;
  Width := 400;
  Height := 300;
end;

destructor TUiTabs.Destroy;
var
  vPage: TUiTabSheet;
begin
  for vPage in FPages do
    vPage.FTabs := nil;
  FreeAndNil(FPages);
  inherited;
end;

procedure TUiTabs.InsertPage(const APage: TUiTabSheet);
begin
  FPages.Add(APage);
  APage.FTabs := Self;
  if not Assigned(FActivePage) then
    FActivePage := APage;
  UpdatePagesVisibility;
  Invalidate;
end;

procedure TUiTabs.RemovePage(const APage: TUiTabSheet);
begin
  if not Assigned(FPages) then
    Exit;
  FPages.Remove(APage);
  APage.FTabs := nil;
  if FActivePage = APage then
  begin
    FActivePage := nil;
    if FPages.Count > 0 then
      FActivePage := FPages[0];
  end;
  if not (csDestroying in ComponentState) then
  begin
    UpdatePagesVisibility;
    Invalidate;
  end;
end;

procedure TUiTabs.UpdatePagesVisibility(const AFireShow: Boolean);
var
  vPage: TUiTabSheet;
  vShown: Boolean;
begin
  if csLoading in ComponentState then
    Exit;
  vShown := False;
  for vPage in FPages do
  begin
    if (vPage = FActivePage) and not vPage.Visible then
      vShown := True;
    vPage.Visible := vPage = FActivePage;
  end;
  if Assigned(FActivePage) then
  begin
    FActivePage.BringToFront;
    if vShown and AFireShow and not (csDesigning in ComponentState) and Assigned(FActivePage.FOnShow) then
      FActivePage.FOnShow(FActivePage);
  end;
end;

procedure TUiTabs.Loaded;
begin
  inherited;
  if not Assigned(FActivePage) and (FPages.Count > 0) then
    FActivePage := FPages[0];
  UpdatePagesVisibility;
end;

function TUiTabs.GetPage(const AIndex: Integer): TUiTabSheet;
begin
  Result := FPages[AIndex];
end;

function TUiTabs.GetPageCount: Integer;
begin
  Result := FPages.Count;
end;

function TUiTabs.GetActivePageIndex: Integer;
begin
  Result := FPages.IndexOf(FActivePage);
end;

procedure TUiTabs.SetActivePageIndex(const AValue: Integer);
begin
  if (AValue >= 0) and (AValue < FPages.Count) then
    SetActivePage(FPages[AValue])
  else
    SetActivePage(nil);
end;

procedure TUiTabs.SetActivePage(const AValue: TUiTabSheet);
var
  vForm: TCustomForm;
begin
  if Assigned(AValue) and (AValue.FTabs <> Self) then
    Exit;
  if FActivePage = AValue then
    Exit;
  FActivePage := AValue;
  UpdatePagesVisibility(True);
  Invalidate;
  if [csLoading, csDestroying] * ComponentState <> [] then
    Exit;
  if csDesigning in ComponentState then
  begin
    vForm := GetParentForm(Self);
    if Assigned(vForm) and Assigned(vForm.Designer) then
      vForm.Designer.Modified;
  end
  else if Assigned(FOnChange) then
    FOnChange(Self);
end;

procedure TUiTabs.SelectNextPage(const AForward: Boolean);
var
  vIndex, vStep, I: Integer;
begin
  if FPages.Count = 0 then
    Exit;
  vIndex := FPages.IndexOf(FActivePage);
  if AForward then
    vStep := 1
  else
    vStep := -1;
  for I := 1 to FPages.Count do
  begin
    vIndex := (vIndex + vStep + FPages.Count) mod FPages.Count;
    if FPages[vIndex].FTabVisible then
    begin
      SetActivePage(FPages[vIndex]);
      Exit;
    end;
  end;
end;

procedure TUiTabs.SetShowTabs(const AValue: Boolean);
begin
  if FShowTabs = AValue then
    Exit;
  FShowTabs := AValue;
  Realign;
  Invalidate;
end;

procedure TUiTabs.SetTabPosition(const AValue: TUiTabPosition);
begin
  if FTabPosition = AValue then
    Exit;
  FTabPosition := AValue;
  Realign;
  Invalidate;
end;

function TUiTabs.HeaderHeight: Integer;
begin
  if (FTabPosition = utpTop) and (FShowTabs or (csDesigning in ComponentState)) then
    Result := TabSize
  else
    Result := 0;
end;

function TUiTabs.LeftGlyphWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  for I := 0 to FPages.Count - 1 do
    if FPages[I].FTabVisible and (FPages[I].FGlyph <> '') then
    begin
      Canvas.Font.Assign(Font);
      Canvas.Font.Name := UiIconFontName;
      Result := Max(Result, Canvas.TextWidth(FPages[I].FGlyph));
    end;
  if Result > 0 then
    Inc(Result, ScaleValue(12));
end;

function TUiTabs.StripWidth: Integer;
var
  I: Integer;
begin
  Result := 0;
  if (FTabPosition <> utpLeft) or not (FShowTabs or (csDesigning in ComponentState)) then
    Exit;
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  for I := 0 to FPages.Count - 1 do
    if FPages[I].FTabVisible then
      Result := Max(Result, Canvas.TextWidth(FPages[I].Caption));
  Result := Max(Result + LeftGlyphWidth + ScaleValue(44), ScaleValue(110));
end;

function TUiTabs.TabSize: Integer;
var
  vDC: HDC;
  vOldFont: HGDIOBJ;
  vMetrics: TTextMetric;
begin
  vDC := GetDC(0);
  try
    vOldFont := SelectObject(vDC, Font.Handle);
    GetTextMetrics(vDC, vMetrics);
    SelectObject(vDC, vOldFont);
  finally
    ReleaseDC(0, vDC);
  end;
  Result := vMetrics.tmHeight + ScaleValue(22);
end;

function TUiTabs.TabRect(const AIndex: Integer): TRect;
var
  I, vLeft: Integer;
begin
  Result := TRect.Empty;
  if FTabPosition = utpLeft then
  begin
    vLeft := ScaleValue(8);
    for I := 0 to FPages.Count - 1 do
    begin
      if not FPages[I].FTabVisible then
        Continue;
      Result := Rect(ScaleValue(6), vLeft, StripWidth - ScaleValue(8), vLeft + TabSize);
      if I = AIndex then
        Exit;
      vLeft := Result.Bottom + ScaleValue(2);
    end;
    Exit(TRect.Empty);
  end;
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  vLeft := ScaleValue(4);
  for I := 0 to FPages.Count - 1 do
  begin
    if not FPages[I].FTabVisible then
      Continue;
    Result := Rect(vLeft, 0, vLeft + Canvas.TextWidth(FPages[I].Caption) + ScaleValue(28), HeaderHeight);
    if I = AIndex then
      Exit;
    vLeft := Result.Right;
  end;
  Result := TRect.Empty;
end;

function TUiTabs.TabAt(const X, Y: Integer): Integer;
var
  I: Integer;
begin
  if ((FTabPosition = utpTop) and (Y >= 0) and (Y < HeaderHeight)) or
    ((FTabPosition = utpLeft) and (X >= 0) and (X < StripWidth)) then
    for I := 0 to FPages.Count - 1 do
      if FPages[I].FTabVisible and TabRect(I).Contains(Point(X, Y)) then
        Exit(I);
  Result := -1;
end;

procedure TUiTabs.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  Inc(Rect.Top, HeaderHeight);
  Inc(Rect.Left, StripWidth);
end;

procedure TUiTabs.GetChildren(Proc: TGetChildProc; Root: TComponent);
var
  vPage: TUiTabSheet;
  I: Integer;
begin
  for vPage in FPages do
    Proc(vPage);
  for I := 0 to ControlCount - 1 do
    if not (Controls[I] is TUiTabSheet) and (Controls[I].Owner = Root) then
      Proc(Controls[I]);
end;

procedure TUiTabs.ShowControl(AControl: TControl);
begin
  if (AControl is TUiTabSheet) and (TUiTabSheet(AControl).FTabs = Self) then
    SetActivePage(TUiTabSheet(AControl));
  inherited;
end;

procedure TUiTabs.CMDesignHitTest(var Message: TCMDesignHitTest);
begin
  if TabAt(Message.XPos, Message.YPos) >= 0 then
    Message.Result := 1
  else
    inherited;
end;

procedure TUiTabs.CMFontChanged(var Message: TMessage);
begin
  inherited;
  Realign;
  Invalidate;
end;

procedure TUiTabs.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  if FHotIndex >= 0 then
  begin
    FHotIndex := -1;
    InvalidateTabsBar;
  end;
end;

procedure TUiTabs.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := TabAt(X, Y);
  if (Button = mbLeft) and (vIndex >= 0) then
    SetActivePage(FPages[vIndex]);
end;

procedure TUiTabs.MouseMove(Shift: TShiftState; X, Y: Integer);
var
  vIndex: Integer;
begin
  inherited;
  vIndex := TabAt(X, Y);
  if vIndex <> FHotIndex then
  begin
    FHotIndex := vIndex;
    if vIndex >= 0 then
      Cursor := crHandPoint
    else
      Cursor := crDefault;
    InvalidateTabsBar;
  end;
end;

function TUiTabs.TabsBarRect: TRect;
begin
  if FTabPosition = utpLeft then
    Result := Rect(0, 0, StripWidth, Height)
  else
    Result := Rect(0, 0, Width, HeaderHeight);
end;

procedure TUiTabs.InvalidateTabsBar;
var
  vRect: TRect;
begin
  if not HandleAllocated then
    Exit;
  vRect := TabsBarRect;
  InvalidateRect(Handle, @vRect, False);
end;

procedure TUiTabs.Paint;
var
  vBar: TRect;
  vBuffer: TBitmap;
begin
  vBar := TabsBarRect;
  if not vBar.IsEmpty then
  begin
    vBuffer := TBitmap.Create;
    try
      vBuffer.SetSize(vBar.Width, vBar.Height);
      vBuffer.Canvas.Font.Assign(Font);
      if FTabPosition = utpLeft then
        PaintLeftTabs(vBuffer.Canvas)
      else
        PaintTopTabs(vBuffer.Canvas);
      Canvas.Draw(vBar.Left, vBar.Top, vBuffer);
    finally
      vBuffer.Free;
    end;
  end;
  if not Assigned(FActivePage) then
  begin
    Canvas.Brush.Style := bsSolid;
    Canvas.Brush.Color := SurfaceOf(Self);
    if FTabPosition = utpLeft then
      Canvas.FillRect(Rect(vBar.Right, 0, Width, Height))
    else
      Canvas.FillRect(Rect(0, vBar.Bottom, Width, Height));
  end;
end;

procedure TUiTabs.PaintLeftTabs(const ACanvas: TCanvas);
var
  I, vStrip, vGlyphWidth: Integer;
  vRect, vTextRect, vGlyphRect: TRect;
  vText: string;
begin
  vGlyphWidth := LeftGlyphWidth;
  vStrip := StripWidth;
  if vStrip = 0 then
    Exit;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := SurfaceOf(Self);
  ACanvas.FillRect(Rect(0, 0, vStrip, Height));
  ACanvas.Brush.Color := clUiBorder;
  ACanvas.FillRect(Rect(vStrip - ScaleValue(1), 0, vStrip, Height));
  for I := 0 to FPages.Count - 1 do
  begin
    if not FPages[I].FTabVisible then
      Continue;
    vRect := TabRect(I);
    if FPages[I] = FActivePage then
      DrawRounded(ACanvas, vRect, ScaleValue(6), clUiSelection, clUiSelection)
    else if I = FHotIndex then
      DrawRounded(ACanvas, vRect, ScaleValue(6), clUiHover, clUiHover);
    if FPages[I] = FActivePage then
      DrawRounded(ACanvas, Rect(vRect.Left, vRect.Top + ScaleValue(8), vRect.Left + ScaleValue(3),
        vRect.Bottom - ScaleValue(8)), ScaleValue(1), clUiAccent, clUiAccent);
    ACanvas.Font.Assign(Font);
    ACanvas.Font.Name := cUiFontSemibold;
    if FPages[I] = FActivePage then
      ACanvas.Font.Color := clUiAccent
    else
      ACanvas.Font.Color := clUiMuted;
    ACanvas.Brush.Style := bsClear;
    vTextRect := vRect;
    Inc(vTextRect.Left, ScaleValue(14));
    if FPages[I].FGlyph <> '' then
    begin
      vText := FPages[I].FGlyph;
      ACanvas.Font.Name := UiIconFontName;
      vGlyphRect := Rect(vTextRect.Left, vTextRect.Top, vTextRect.Left + vGlyphWidth, vTextRect.Bottom);
      ACanvas.TextRect(vGlyphRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
      ACanvas.Font.Name := cUiFontSemibold;
    end;
    Inc(vTextRect.Left, vGlyphWidth);
    vText := FPages[I].Caption;
    ACanvas.TextRect(vTextRect, vText, [tfLeft, tfVerticalCenter, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
    ACanvas.Brush.Style := bsSolid;
  end;
end;

procedure TUiTabs.PaintTopTabs(const ACanvas: TCanvas);
var
  I, vHeader, vLine: Integer;
  vRect, vTextRect: TRect;
  vText: string;
begin
  vHeader := HeaderHeight;
  if vHeader = 0 then
    Exit;
  ACanvas.Brush.Style := bsSolid;
  ACanvas.Brush.Color := SurfaceOf(Self);
  ACanvas.FillRect(Rect(0, 0, Width, vHeader));
  vLine := ScaleValue(1);
  ACanvas.Brush.Color := clUiBorder;
  ACanvas.FillRect(Rect(0, vHeader - vLine, Width, vHeader));
  for I := 0 to FPages.Count - 1 do
  begin
    if not FPages[I].FTabVisible then
      Continue;
    vRect := TabRect(I);
    if (I = FHotIndex) and (FPages[I] <> FActivePage) then
      DrawRounded(ACanvas, Rect(vRect.Left + ScaleValue(2), vRect.Top + ScaleValue(5), vRect.Right - ScaleValue(2),
        vRect.Bottom - ScaleValue(7)), ScaleValue(6), clUiHover, clUiHover);
    ACanvas.Font.Assign(Font);
    ACanvas.Font.Name := cUiFontSemibold;
    if FPages[I] = FActivePage then
      ACanvas.Font.Color := clUiAccent
    else
      ACanvas.Font.Color := clUiMuted;
    ACanvas.Brush.Style := bsClear;
    vTextRect := vRect;
    Dec(vTextRect.Bottom, ScaleValue(2));
    vText := FPages[I].Caption;
    ACanvas.TextRect(vTextRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
    ACanvas.Brush.Style := bsSolid;
    if FPages[I] = FActivePage then
      DrawRounded(ACanvas, Rect(vRect.Left + ScaleValue(8), vHeader - ScaleValue(3), vRect.Right - ScaleValue(8),
        vHeader + ScaleValue(1)), ScaleValue(1), clUiAccent, clUiAccent);
  end;
end;

initialization
  RegisterClasses([TUiTabSheet]);

end.
