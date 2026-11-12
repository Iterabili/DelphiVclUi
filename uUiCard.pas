unit uUiCard;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls;

type
  TUiCard = class(TCustomControl)
  private
    FTitle: string;
    procedure SetTitle(const AValue: string);
    procedure AssignTitleFont(const AFont: TFont);
  protected
    procedure Paint; override;
    procedure Resize; override;
    procedure AdjustClientRect(var Rect: TRect); override;
  public
    constructor Create(AOwner: TComponent); override;
    function TitleBottom: Integer;
  published
    property Align;
    property AlignWithMargins;
    property Anchors;
    property Enabled;
    property Font;
    property Margins;
    property Padding;
    property ParentFont;
    property TabOrder;
    property Title: string read FTitle write SetTitle;
    property Visible;
  end;

  TUiStat = class(TCustomControl)
  private
    FValue: string;
    FGlyph: string;
    FAccent: TColor;
    procedure SetValue(const AValue: string);
    procedure SetGlyph(const AValue: string);
    procedure SetAccent(const AValue: TColor);
    procedure CMTextChanged(var Message: TMessage); message CM_TEXTCHANGED;
  protected
    procedure Paint; override;
  public
    constructor Create(AOwner: TComponent); override;
  published
    property Accent: TColor read FAccent write SetAccent default clNone;
    property Align;
    property Anchors;
    property Caption;
    property Font;
    property Glyph: string read FGlyph write SetGlyph;
    property Hint;
    property ParentFont;
    property ParentShowHint;
    property ShowHint;
    property Value: string read FValue write SetValue;
    property Visible;
    property OnClick;
  end;

function AddUiCard(const AParent: TWinControl; const AAlign: TAlign; const AHeight, AMargin: Integer): TUiCard;
function AddUiStat(const AParent: TWinControl; const ACaption, AGlyph: string; const AAccent: TColor;
  const ALeft, ATop, AWidth, AHeight: Integer): TUiStat;
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
  ParentColor := False;
  Color := clUiCard;
  Width := 300;
  Height := 200;
end;

procedure TUiCard.Paint;
begin
  Canvas.Brush.Color := clUiBg;
  Canvas.FillRect(ClientRect);
  DrawRounded(Canvas, ClientRect, ScaleValue(10), clUiCard, clUiBorder);
  if FTitle <> '' then
  begin
    AssignTitleFont(Canvas.Font);
    Canvas.Brush.Style := bsClear;
    Canvas.TextOut(ScaleValue(16), ScaleValue(12), FTitle);
    Canvas.Brush.Style := bsSolid;
  end;
end;

procedure TUiCard.AssignTitleFont(const AFont: TFont);
begin
  AFont.Assign(Font);
  AFont.Name := cUiFontSemibold;
  AFont.Size := Font.Size + 1;
  AFont.Color := clUiText;
end;

function TUiCard.TitleBottom: Integer;
begin
  if FTitle = '' then
    Exit(0);
  AssignTitleFont(Canvas.Font);
  Result := ScaleValue(12) + Canvas.TextHeight(FTitle) + ScaleValue(8);
end;

procedure TUiCard.SetTitle(const AValue: string);
begin
  if FTitle = AValue then
    Exit;
  FTitle := AValue;
  Realign;
  Invalidate;
end;

procedure TUiCard.AdjustClientRect(var Rect: TRect);
begin
  inherited;
  Inc(Rect.Top, TitleBottom);
end;

procedure TUiCard.Resize;
begin
  inherited;
  Invalidate;
end;

function AddUiStat(const AParent: TWinControl; const ACaption, AGlyph: string; const AAccent: TColor;
  const ALeft, ATop, AWidth, AHeight: Integer): TUiStat;
begin
  Result := TUiStat.Create(AParent);
  Result.Parent := AParent;
  Result.SetBounds(ALeft, ATop, AWidth, AHeight);
  Result.Caption := ACaption;
  Result.Glyph := AGlyph;
  Result.Accent := AAccent;
end;

constructor TUiStat.Create(AOwner: TComponent);
begin
  inherited;
  ControlStyle := ControlStyle + [csOpaque];
  DoubleBuffered := True;
  FAccent := clNone;
  Width := 200;
  Height := 64;
end;

procedure TUiStat.Paint;
var
  vAccent: TColor;
  vCircle, vGlyphRect, vTextRect: TRect;
  vSize, vLeft, vCaptionHeight, vValueHeight, vTop: Integer;
  vText: string;
begin
  if FAccent = clNone then
    vAccent := clUiAccent
  else
    vAccent := FAccent;
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := SurfaceOf(Self);
  Canvas.FillRect(ClientRect);
  DrawRounded(Canvas, ClientRect, ScaleValue(10), clUiCard, clUiBorder);

  vLeft := ScaleValue(16);
  if FGlyph <> '' then
  begin
    vSize := Height - ScaleValue(24);
    vCircle := Rect(vLeft, (Height - vSize) div 2, vLeft + vSize, (Height - vSize) div 2 + vSize);
    DrawRounded(Canvas, vCircle, vSize div 2, TintColor(vAccent, 85), TintColor(vAccent, 85));
    Canvas.Font.Assign(Font);
    Canvas.Font.Name := UiIconFontName;
    Canvas.Font.Height := -vSize * 45 div 100;
    Canvas.Font.Color := vAccent;
    Canvas.Brush.Style := bsClear;
    vGlyphRect := vCircle;
    vText := FGlyph;
    Canvas.TextRect(vGlyphRect, vText, [tfCenter, tfVerticalCenter, tfSingleLine, tfNoPrefix]);
    vLeft := vCircle.Right + ScaleValue(12);
  end;

  Canvas.Brush.Style := bsClear;
  Canvas.Font.Assign(Font);
  Canvas.Font.Size := Max(1, Font.Size - 2);
  Canvas.Font.Color := clUiMuted;
  vCaptionHeight := Canvas.TextHeight('Wg');
  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  Canvas.Font.Size := Font.Size + 3;
  vValueHeight := Canvas.TextHeight('Wg');
  vTop := (Height - vCaptionHeight - vValueHeight) div 2;

  Canvas.Font.Assign(Font);
  Canvas.Font.Size := Max(1, Font.Size - 2);
  Canvas.Font.Color := clUiMuted;
  vTextRect := Rect(vLeft, vTop, Width - ScaleValue(12), vTop + vCaptionHeight);
  vText := Caption;
  Canvas.TextRect(vTextRect, vText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix, tfEndEllipsis]);

  Canvas.Font.Assign(Font);
  Canvas.Font.Name := cUiFontSemibold;
  Canvas.Font.Size := Font.Size + 3;
  Canvas.Font.Color := clUiText;
  vTextRect := Rect(vLeft, vTop + vCaptionHeight, Width - ScaleValue(12), vTop + vCaptionHeight + vValueHeight);
  vText := FValue;
  Canvas.TextRect(vTextRect, vText, [tfLeft, tfTop, tfSingleLine, tfNoPrefix, tfEndEllipsis]);
  Canvas.Brush.Style := bsSolid;
end;

procedure TUiStat.SetValue(const AValue: string);
begin
  if FValue = AValue then
    Exit;
  FValue := AValue;
  Invalidate;
end;

procedure TUiStat.SetGlyph(const AValue: string);
begin
  FGlyph := AValue;
  Invalidate;
end;

procedure TUiStat.SetAccent(const AValue: TColor);
begin
  FAccent := AValue;
  Invalidate;
end;

procedure TUiStat.CMTextChanged(var Message: TMessage);
begin
  inherited;
  Invalidate;
end;

end.
