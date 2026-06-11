unit themebtn;

{ ============================================================================
  EasyDownload — Tema dostu düğme (TThemedButton)

  Neden gerekli?
    Windows'ta yerel (native) TButton'un arka plan rengi .Color ile
    DEĞİŞMEZ; koyu temada beyaz/gri kalır. "DarkMode_Explorer" hilesi de
    düğmelerde güvenilir biçimde çalışmaz. Bu yüzden düğmeyi tamamen kendimiz
    çiziyoruz: TCustomControl'ün kendi Canvas'ına zemin + kenarlık + yazı.

    TCustomControl tabanlı olduğu için .lfm'deki tüm TButton özellikleri
    (Caption, Enabled, Visible, Font, TabOrder...) olduğu gibi geçerlidir;
    .lfm'de yalnızca sınıf adı TButton -> TThemedButton olarak değişir.

  Tema renkleri thememanager.ApplyThemeToControl içinden SetThemeColors ile
  verilir.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Types, Controls, Graphics;

type

  { TThemedButton }

  TThemedButton = class(TCustomControl)
  private
    FHover: Boolean;
    FDown: Boolean;
    FBgColor: TColor;
    FBorderColor: TColor;
    FTextColor: TColor;
    FDisabledBg: TColor;
    FDisabledText: TColor;
    procedure ApplyColor(var Field: TColor; const Value: TColor);
    procedure SetBgColor(const V: TColor);
    procedure SetBorderColor(const V: TColor);
    procedure SetTextColor(const V: TColor);
  protected
    procedure Paint; override;
    procedure MouseEnter; override;
    procedure MouseLeave; override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
    procedure TextChanged; override;
    class function GetControlClassDefaultSize: TSize; override;
  public
    constructor Create(AOwner: TComponent); override;
    // Normal zemin, kenarlık, yazı + pasif (disabled) zemin/yazı renkleri
    procedure SetThemeColors(ABg, ABorder, AText, ADisBg, ADisText: TColor);
  published
    property BgColor: TColor read FBgColor write SetBgColor;
    property BorderColor: TColor read FBorderColor write SetBorderColor;
    property TextColor: TColor read FTextColor write SetTextColor;

    property Caption;
    property Enabled;
    property Font;
    property ParentFont;
    property TabOrder;
    property TabStop;
    property Visible;
    property OnClick;
    property OnMouseDown;
    property OnMouseUp;
    property OnMouseMove;
  end;

implementation

{ Bir rengi delta kadar açar (+) veya koyulaştırır (-), 0..255 sınırında tutar }
function Shade(C: TColor; Delta: Integer): TColor;
  function Clamp(V: Integer): Integer;
  begin
    if V < 0 then Result := 0
    else if V > 255 then Result := 255
    else Result := V;
  end;
var r, g, b: Integer;
begin
  C := ColorToRGB(C);
  r := Clamp(Red(C)   + Delta);
  g := Clamp(Green(C) + Delta);
  b := Clamp(Blue(C)  + Delta);
  Result := RGBToColor(r, g, b);
end;

{ TThemedButton }

constructor TThemedButton.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  ControlStyle := ControlStyle + [csOpaque];  // tüm alanı kendimiz boyuyoruz
  TabStop := True;
  Cursor := crHandPoint;
  FBgColor      := clBtnFace;
  FBorderColor  := clSilver;
  FTextColor    := clWindowText;
  FDisabledBg   := clBtnFace;
  FDisabledText := clGrayText;
end;

class function TThemedButton.GetControlClassDefaultSize: TSize;
begin
  Result.CX := 100;
  Result.CY := 30;
end;

procedure TThemedButton.ApplyColor(var Field: TColor; const Value: TColor);
begin
  if Field = Value then Exit;
  Field := Value;
  Invalidate;
end;

procedure TThemedButton.SetBgColor(const V: TColor);
begin ApplyColor(FBgColor, V); end;

procedure TThemedButton.SetBorderColor(const V: TColor);
begin ApplyColor(FBorderColor, V); end;

procedure TThemedButton.SetTextColor(const V: TColor);
begin ApplyColor(FTextColor, V); end;

procedure TThemedButton.SetThemeColors(ABg, ABorder, AText, ADisBg, ADisText: TColor);
begin
  FBgColor      := ABg;
  FBorderColor  := ABorder;
  FTextColor    := AText;
  FDisabledBg   := ADisBg;
  FDisabledText := ADisText;
  Invalidate;
end;

procedure TThemedButton.Paint;
var
  r: TRect;
  bg, bc, tc: TColor;
  ts: TTextStyle;
begin
  r := ClientRect;

  if not Enabled then
  begin
    bg := FDisabledBg;
    tc := FDisabledText;
    bc := FBorderColor;
  end
  else if FDown then
  begin
    bg := Shade(FBgColor, -22);
    tc := FTextColor;
    bc := Shade(FBorderColor, -22);
  end
  else if FHover then
  begin
    bg := Shade(FBgColor, +16);
    tc := FTextColor;
    bc := Shade(FBorderColor, +16);
  end
  else
  begin
    bg := FBgColor;
    tc := FTextColor;
    bc := FBorderColor;
  end;

  // Zemin
  Canvas.Brush.Style := bsSolid;
  Canvas.Brush.Color := bg;
  Canvas.FillRect(r);

  // Kenarlık
  Canvas.Pen.Color := bc;
  Canvas.Brush.Style := bsClear;
  Canvas.Rectangle(r);

  // Yazı (ortalanmış)
  Canvas.Font := Font;
  Canvas.Font.Color := tc;
  ts := Canvas.TextStyle;
  ts.Alignment := taCenter;
  ts.Layout := tlCenter;
  ts.Opaque := False;
  ts.Clipping := True;
  ts.SingleLine := True;
  Canvas.TextRect(r, r.Left, r.Top, Caption, ts);
end;

procedure TThemedButton.MouseEnter;
begin
  inherited MouseEnter;
  if not FHover then begin FHover := True; Invalidate; end;
end;

procedure TThemedButton.MouseLeave;
begin
  inherited MouseLeave;
  if FHover or FDown then begin FHover := False; FDown := False; Invalidate; end;
end;

procedure TThemedButton.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  inherited MouseDown(Button, Shift, X, Y);
  if Button = mbLeft then begin FDown := True; Invalidate; end;
end;

procedure TThemedButton.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbLeft then begin FDown := False; Invalidate; end;
  inherited MouseUp(Button, Shift, X, Y);  // OnClick burada tetiklenir
end;

procedure TThemedButton.TextChanged;
begin
  inherited TextChanged;
  Invalidate;
end;

initialization
  // .lfm akışının (streaming) TThemedButton'u tanıması için
  RegisterClass(TThemedButton);

end.
