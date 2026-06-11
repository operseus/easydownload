unit thememanager;

{ ============================================================================
  EasyDownload — Tema motoru

  Tek sorumluluğu: assets/themes/*.css içindeki --renk değişkenlerini okumak
  ve bunları TForm + tüm alt bileşenlere (statik veya çalışma zamanında
  oluşturulan) tutarlı biçimde uygulamak.

  GCurrentTheme son uygulanan temayı saklar; çalışma zamanında oluşturulan
  kontroller (ör. playlist kutusu) veya gecikmeli açılan formlar (ör. Ayarlar)
  ApplyThemeToControl/ApplyThemeToForm + CurrentTheme ile aynı görünümü alır.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Graphics, Controls, Forms, StdCtrls, ComCtrls,
  ExtCtrls, CheckLst, Spin, Buttons, applang, themebtn;

type
  TAppTheme = record
    Loaded: Boolean;       // True: assets/themes/*.css'den okundu, False: sistem teması
    IsDark: Boolean;
    Bg, Surface, Surface2, Text, TextDim,
    Border, Primary, PrimaryText, Danger, Success: TColor;
  end;

function SystemTheme: TAppTheme;
function LoadTheme(const ThemeFile: string): TAppTheme;
function CurrentTheme: TAppTheme;
procedure SetCurrentTheme(const Theme: TAppTheme);

procedure ApplyThemeToControl(C: TControl; const Theme: TAppTheme);
procedure ApplyThemeToForm(AForm: TCustomForm; const Theme: TAppTheme);

implementation

uses
  LCLIntf;

const
  DWMWA_USE_IMMERSIVE_DARK_MODE = Cardinal(20);
  WM_THEMECHANGED    = $031A;
  LVM_FIRST          = $1000;
  LVM_SETBKCOLOR     = LVM_FIRST + 1;
  LVM_SETTEXTCOLOR   = LVM_FIRST + 36;
  LVM_SETTEXTBKCOLOR = LVM_FIRST + 38;
  LVM_GETHEADER      = LVM_FIRST + 31;

function DwmSetWindowAttribute(hwnd: PtrUInt; dwAttribute: Cardinal;
         pvAttribute: Pointer; cbAttribute: Cardinal): Integer;
         stdcall; external 'dwmapi.dll' name 'DwmSetWindowAttribute';
function SetWindowThemeW(hwnd: PtrUInt; pszSubAppName: PWideChar;
         pszSubIdList: PWideChar): Integer;
         stdcall; external 'uxtheme.dll' name 'SetWindowTheme';

// Win32 "uxtheme" sıra-numarasıyla (ordinal) dışa aktarılan, belgelenmemiş
// koyu mod API'leri (Windows 10 1809+ / 11). Bu fonksiyonlar her derlemede
// var olmayabilir; bu yüzden derleme zamanında bağlanmaz, çalışma zamanında
// GetProcAddress ile aranır ve nil ise sessizce atlanır (çökme yok).
function Win32LoadLibraryW(lpLibFileName: PWideChar): PtrUInt;
         stdcall; external 'kernel32.dll' name 'LoadLibraryW';
function Win32GetProcAddress(hModule: PtrUInt; lpProcName: PAnsiChar): Pointer;
         stdcall; external 'kernel32.dll' name 'GetProcAddress';

type
  TFnSetPreferredAppMode = function(Mode: Integer): Integer; stdcall;
  TFnAllowDarkModeForWindow = function(Wnd: PtrUInt; Allow: LongBool): LongBool; stdcall;
  TFnFlushMenuThemes = procedure; stdcall;

var
  GCurrentTheme: TAppTheme;
  GHaveCurrent: Boolean = False;

  GDarkApiInit: Boolean = False;
  GUxThemeModule: PtrUInt = 0;
  GSetPreferredAppMode: TFnSetPreferredAppMode = nil;
  GAllowDarkModeForWindow: TFnAllowDarkModeForWindow = nil;
  GFlushMenuThemes: TFnFlushMenuThemes = nil;

procedure InitDarkModeApi;
var lib: UnicodeString;
begin
  if GDarkApiInit then Exit;
  GDarkApiInit := True;
  lib := 'uxtheme.dll';
  GUxThemeModule := Win32LoadLibraryW(PWideChar(lib));
  if GUxThemeModule = 0 then Exit;
  // Sıra numaraları Windows 10 1903+ (build 18362) ve Windows 11'de geçerlidir.
  Pointer(GSetPreferredAppMode)    := Win32GetProcAddress(GUxThemeModule, PAnsiChar(PtrUInt(135)));
  Pointer(GAllowDarkModeForWindow) := Win32GetProcAddress(GUxThemeModule, PAnsiChar(PtrUInt(133)));
  Pointer(GFlushMenuThemes)        := Win32GetProcAddress(GUxThemeModule, PAnsiChar(PtrUInt(136)));
end;

// Uygulama genelinde koyu/açık mod tercihi (mevcutsa)
procedure EnsureAppMode(IsDark: Boolean);
begin
  InitDarkModeApi;
  try
    if Assigned(GSetPreferredAppMode) then
    begin
      if IsDark then GSetPreferredAppMode(1)  // AllowDark
      else GSetPreferredAppMode(0);           // Default
      if Assigned(GFlushMenuThemes) then GFlushMenuThemes();
    end;
  except end;
end;

// TButton/TComboBox/TPageControl gibi Windows'un kendi koyu temasıyla
// (DarkMode_Explorer) düzgün çizdiği kontroller için: .Color özelliği bu
// kontrollerde işe yaramaz, bu yüzden işletim sisteminin koyu moduna geçeriz.
procedure ApplyNativeDarkMode(wc: TWinControl; IsDark: Boolean);
var cls: UnicodeString;
begin
  InitDarkModeApi;
  if not wc.HandleAllocated then wc.HandleNeeded;
  if not wc.HandleAllocated then Exit;
  try
    if Assigned(GAllowDarkModeForWindow) then
      GAllowDarkModeForWindow(wc.Handle, IsDark);
    if IsDark then cls := 'DarkMode_Explorer' else cls := '';
    if cls <> '' then SetWindowThemeW(wc.Handle, PWideChar(cls), nil)
    else SetWindowThemeW(wc.Handle, nil, nil);
    SendMessage(wc.Handle, WM_THEMECHANGED, 0, 0);
  except end;
end;

{ ---------------------------------------------------------------------------
  Tema kaydı
  --------------------------------------------------------------------------- }
function CurrentTheme: TAppTheme;
begin
  if GHaveCurrent then Result := GCurrentTheme
  else Result := SystemTheme;
end;

procedure SetCurrentTheme(const Theme: TAppTheme);
begin
  GCurrentTheme := Theme;
  GHaveCurrent := True;
end;

{ ---------------------------------------------------------------------------
  Sistem teması — CSS tema seçili değilken Windows varsayılan renkleri
  --------------------------------------------------------------------------- }
function SystemTheme: TAppTheme;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Loaded      := False;
  Result.IsDark      := False;
  Result.Bg          := clBtnFace;
  Result.Surface     := clWindow;
  Result.Surface2    := clWindow;
  Result.Text        := clWindowText;
  Result.TextDim     := clGrayText;
  Result.Border      := clSilver;
  Result.Primary     := clHighlight;
  Result.PrimaryText := clHighlightText;
  Result.Danger      := clRed;
  Result.Success     := clGreen;
end;

{ ---------------------------------------------------------------------------
  CSS değişken ayrıştırma: "--token: #rrggbb"
  --------------------------------------------------------------------------- }
function ParseColor(const css, token: string; Def: TColor): TColor;
var p, q: Integer; hex: string;
begin
  Result := Def;
  p := Pos(token + ':', css);
  if p <= 0 then Exit;
  p := p + Length(token) + 1;
  while (p <= Length(css)) and (css[p] in [' ', #9]) do Inc(p);
  if (p > Length(css)) or (css[p] <> '#') then Exit;
  q := p + 1;
  while (q <= Length(css)) and (css[q] in ['0'..'9','a'..'f','A'..'F']) do Inc(q);
  hex := Copy(css, p + 1, q - p - 1);
  try
    if Length(hex) = 6 then
      Result := TColor(
        (StrToInt('$' + Copy(hex,1,2))) or
        (StrToInt('$' + Copy(hex,3,2)) shl 8) or
        (StrToInt('$' + Copy(hex,5,2)) shl 16));
  except end;
end;

function LoadTheme(const ThemeFile: string): TAppTheme;
var css, themePath: string;
begin
  themePath := applang.ThemeFilePath(ThemeFile);
  css := '';
  if (themePath <> '') and FileExists(themePath) then
    css := Trim(applang.ReadFileUtf8(themePath));

  if css = '' then
  begin
    Result := SystemTheme;
    Exit;
  end;

  css := LowerCase(css);

  Result.Loaded      := True;
  Result.Bg          := ParseColor(css, '--bg',           clBtnFace);
  Result.Surface     := ParseColor(css, '--surface',      clWindow);
  Result.Surface2    := ParseColor(css, '--surface-2',    clWindow);
  Result.Text        := ParseColor(css, '--text',         clWindowText);
  Result.TextDim     := ParseColor(css, '--text-dim',     clGrayText);
  Result.Border      := ParseColor(css, '--border',       clSilver);
  Result.Primary     := ParseColor(css, '--primary',      clHighlight);
  Result.PrimaryText := ParseColor(css, '--primary-text', clHighlightText);
  Result.Danger      := ParseColor(css, '--danger',       clRed);
  Result.Success     := ParseColor(css, '--success',      clGreen);

  // Koyu tema tespiti (arka plan karanlıksa)
  Result.IsDark := (Red(Result.Bg) < 80) and (Green(Result.Bg) < 80) and (Blue(Result.Bg) < 80);
end;

{ ---------------------------------------------------------------------------
  Win32 görsel stil yardımcıları
  --------------------------------------------------------------------------- }

// Custom: .Color/.Font.Color'ın native (Edit/Button/ComboBox vb.) kontrollerde
// etkili olması için Windows görsel stilini kapatır. System: stili geri açar.
procedure SetNativeTheme(wc: TWinControl; CustomTheme: Boolean);
var s: UnicodeString;
begin
  if not wc.HandleAllocated then wc.HandleNeeded;
  if not wc.HandleAllocated then Exit;
  try
    if CustomTheme then
    begin
      // Tek boşluklu sınıf adı gerçek bir tema sınıfıyla eşleşmez,
      // bu da Windows'un görsel stilini etkin biçimde devre dışı bırakır.
      s := ' ';
      SetWindowThemeW(wc.Handle, PWideChar(s), PWideChar(s));
    end
    else
      SetWindowThemeW(wc.Handle, nil, nil);
  except end;
end;

// TListView: satır/arka plan rengi + (Win10+) koyu başlık (header) desteği
procedure ThemeListView(LV: TListView; const Theme: TAppTheme);
var hdr: PtrUInt; bg, txt: TColor; cls: UnicodeString;
begin
  if not LV.HandleAllocated then LV.HandleNeeded;
  if not LV.HandleAllocated then Exit;

  LV.Color := Theme.Surface;
  LV.Font.Color := Theme.Text;

  bg  := ColorToRGB(Theme.Surface);
  txt := ColorToRGB(Theme.Text);
  try
    SendMessage(LV.Handle, LVM_SETBKCOLOR, 0, bg);
    SendMessage(LV.Handle, LVM_SETTEXTCOLOR, 0, txt);
    SendMessage(LV.Handle, LVM_SETTEXTBKCOLOR, 0, bg);
  except end;

  try
    if Theme.IsDark then cls := 'DarkMode_Explorer'
    else if Theme.Loaded then cls := 'Explorer'
    else cls := '';

    if cls <> '' then SetWindowThemeW(LV.Handle, PWideChar(cls), nil)
    else SetWindowThemeW(LV.Handle, nil, nil);

    hdr := PtrUInt(SendMessage(LV.Handle, LVM_GETHEADER, 0, 0));
    if hdr <> 0 then
    begin
      if Theme.IsDark then cls := 'DarkMode_ItemsView'
      else if Theme.Loaded then cls := 'Explorer'
      else cls := '';

      if cls <> '' then SetWindowThemeW(hdr, PWideChar(cls), nil)
      else SetWindowThemeW(hdr, nil, nil);
    end;
  except end;
end;

{ ---------------------------------------------------------------------------
  Bileşen ağacını özyinelemeli olarak temala
  --------------------------------------------------------------------------- }
procedure ApplyThemeToControl(C: TControl; const Theme: TAppTheme);
var i: Integer; wc: TWinControl;
begin
  if C = nil then Exit;

  // -- TLabel: şeffaf, sadece yazı rengi --
  if C is TLabel then
  begin
    if C.Enabled then TLabel(C).Font.Color := Theme.Text
    else TLabel(C).Font.Color := Theme.TextDim;
    TLabel(C).Color := Theme.Bg;
    TLabel(C).Transparent := True;
    Exit;
  end;

  // -- Pencere altyapısı olmayan diğer bileşenler (TImage vb.) --
  if not (C is TWinControl) then
  begin
    if C.Enabled then C.Font.Color := Theme.Text else C.Font.Color := Theme.TextDim;
    Exit;
  end;

  wc := TWinControl(C);

  if wc is TEdit then
  begin
    TEdit(wc).Color := Theme.Surface2;
    TEdit(wc).Font.Color := Theme.Text;
    // Kenarlık dahil koyu görünüm için Windows koyu modu (klasik stil kapatma
    // kutu çevresinde açık gri bırakıyordu).
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TComboBox then
  begin
    TComboBox(wc).Color := Theme.Surface2;
    TComboBox(wc).Font.Color := Theme.Text;
    // ComboBox kapalı kutusu .Color'a uymaz; Windows'un koyu modunu kullan.
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TListView then
  begin
    ThemeListView(TListView(wc), Theme);
  end
  else if wc is TCheckListBox then
  begin
    TCheckListBox(wc).Color := Theme.Surface;
    TCheckListBox(wc).Font.Color := Theme.Text;
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TCheckBox then
  begin
    TCheckBox(wc).Font.Color := Theme.Text;
    TCheckBox(wc).Color := Theme.Bg;
    // Onay kutusunun karesi + çevresi koyu olsun diye Windows koyu modu.
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TPageControl then
  begin
    TPageControl(wc).Color := Theme.Surface;
    TPageControl(wc).Font.Color := Theme.Text;
    // Sekme şeridi (tab strip) .Color'a uymaz; Windows'un koyu modunu kullan.
    // (LCL TPageControl OnDrawTab desteklemediği için tek seçenek bu.)
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TTabSheet then
  begin
    TTabSheet(wc).Color := Theme.Surface;
    TTabSheet(wc).Font.Color := Theme.Text;
    SetNativeTheme(wc, Theme.Loaded);
  end
  else if wc is TThemedButton then
  begin
    // Kendi çizdiğimiz düğme: zemin/kenarlık/yazı + pasif renkleri ver.
    TThemedButton(wc).Font.Color := Theme.Text;
    TThemedButton(wc).SetThemeColors(
      Theme.Surface2,   // zemin
      Theme.Border,     // kenarlık
      Theme.Text,       // yazı
      Theme.Surface,    // pasif zemin
      Theme.TextDim);   // pasif yazı
  end
  else if (wc is TButton) or (wc is TBitBtn) then
  begin
    wc.Color := Theme.Surface2;
    wc.Font.Color := Theme.Text;
    // Native Win32 düğmeler .Color'a uymaz (devre dışı/aktif fark etmeksizin);
    // Windows'un kendi koyu mod çizimini kullan.
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TPanel then
  begin
    TPanel(wc).Color := Theme.Bg;
    TPanel(wc).Font.Color := Theme.Text;
    TPanel(wc).BevelColor := Theme.Border;
  end
  else if wc is TGroupBox then
  begin
    TGroupBox(wc).Color := Theme.Surface;
    TGroupBox(wc).Font.Color := Theme.Text;
  end
  else if wc is TSpinEdit then
  begin
    TSpinEdit(wc).Color := Theme.Surface2;
    TSpinEdit(wc).Font.Color := Theme.Text;
    ApplyNativeDarkMode(wc, Theme.IsDark);
  end
  else if wc is TProgressBar then
  begin
    TProgressBar(wc).Color := Theme.Surface2;
    SetNativeTheme(wc, Theme.Loaded);
  end
  else
  begin
    wc.Color := Theme.Surface;
    wc.Font.Color := Theme.Text;
  end;

  // Pasif (disabled) bileşenler için soluk metin rengi
  if not wc.Enabled then wc.Font.Color := Theme.TextDim;

  // Alt bileşenleri özyinelemeli olarak renkle
  for i := 0 to wc.ControlCount - 1 do
    ApplyThemeToControl(wc.Controls[i], Theme);
end;

{ ---------------------------------------------------------------------------
  Bir formu (ana pencere veya Ayarlar) baştan sona temala
  --------------------------------------------------------------------------- }
procedure ApplyThemeToForm(AForm: TCustomForm; const Theme: TAppTheme);
var darkVal: Cardinal; i: Integer;
begin
  if AForm = nil then Exit;
  if not AForm.HandleAllocated then AForm.HandleNeeded;

  EnsureAppMode(Theme.IsDark);

  AForm.Color := Theme.Bg;
  AForm.Font.Color := Theme.Text;

  for i := 0 to AForm.ControlCount - 1 do
    ApplyThemeToControl(AForm.Controls[i], Theme);

  // Pencere başlık çubuğu (Win10 1809+ koyu mod)
  if Theme.IsDark then darkVal := 1 else darkVal := 0;
  try DwmSetWindowAttribute(AForm.Handle, DWMWA_USE_IMMERSIVE_DARK_MODE, @darkVal, SizeOf(darkVal)); except end;

  AForm.Invalidate;
end;

end.
