unit applang;

{ ============================================================================
  EasyDownload — Paylaşılan altyapı: yol çözümleme + dinamik dil + ayarlar.

  Hem ana form (main) hem de Ayarlar pop-up'ı (settingsform) bu birimi kullanır.
  Böylece dil sözlüğü ve settings.json yönetimi TEK yerde toplanır; dil
  değiştiğinde tek çağrıyla tüm formlar tazelenebilir.

  * Diller:   assets/languages/<kod>.json   (_meta.name, _meta.dir)
  * Ayarlar:  data/settings.json             (alanlar korunarak güncellenir)
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

// --- yollar (uygulama kökü = exe klasörü; geliştirmede assets aranarak bulunur) ---
function AppRoot: string;
function LanguagesDir: string;
function DataDir: string;
function SettingsFile: string;
function HistoryFile: string;
function LogosDir: string;
function ThemesDir: string;
function FontsDir: string;
function ThemeFilePath(const FileName: string): string;  // ThemesDir + dosya adı (bağıl -> tam yol)
function FontFilePath(const FileName: string): string;    // FontsDir + dosya adı (bağıl -> tam yol)

// --- dil ---
procedure LoadLanguage(const Pref: string);   // 'auto' veya kod; çözer + yükler
function CurrentLangCode: string;
function CurrentLangPref: string;
function CurrentLangDir: string;               // 'ltr' | 'rtl'
function T(const Key: string; const Def: string = ''): string;  // çeviri
procedure GetAvailableLanguages(Codes, Names: TStrings);         // dosyadan diller
function LangFileExists(const Code: string): Boolean;
function DetectOSLang: string;

// --- tema & font keşfi ---
procedure GetAvailableThemes(Names, Files: TStrings);
procedure GetAvailableFonts(Names, Files: TStrings);

// --- ayarlar (settings.json), diğer alanları koruyarak ---
function ReadSettingStr(const Key, Def: string): string;
function ReadSettingBool(const Key: string; Def: Boolean): Boolean;
function ReadSettingInt(const Key: string; Def: Integer): Integer;
procedure SaveSettingStr(const Key, Val: string);
procedure SaveSettingBool(const Key: string; Val: Boolean);
procedure SaveSettingInt(const Key: string; Val: Integer);

// --- ortak yardımcı ---
function ReadFileUtf8(const FileName: string): string;

implementation

uses
  fileutil, LazFileUtils, gettext;

var
  GAppRoot: string = '';
  GDict: TStringList = nil;
  GLangCode: string = '';
  GLangPref: string = 'auto';
  GLangDir: string = 'ltr';

{ ---------------------------------------------------------------------------- }
function ReadFileUtf8(const FileName: string): string;
var fs: TFileStream;
begin
  Result := '';
  if not FileExists(FileName) then Exit;
  fs := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
  try
    if fs.Size > 0 then
    begin
      SetLength(Result, fs.Size);
      fs.ReadBuffer(Result[1], fs.Size);
    end;
  finally
    fs.Free;
  end;
  if (Length(Result) >= 3) and (Result[1] = #$EF) and
     (Result[2] = #$BB) and (Result[3] = #$BF) then
    Delete(Result, 1, 3);
end;

procedure WriteFileUtf8(const FileName, Content: string);
var fs: TFileStream;
begin
  ForceDirectories(ExtractFileDir(FileName));
  fs := TFileStream.Create(FileName, fmCreate);
  try
    if Length(Content) > 0 then fs.WriteBuffer(Content[1], Length(Content));
  finally
    fs.Free;
  end;
end;

{ ---- yollar -------------------------------------------------------------- }
function AppRoot: string;
var Dir: string; i: Integer;
begin
  if GAppRoot <> '' then Exit(GAppRoot);

  Dir := GetEnvironmentVariable('EASYDOWNLOAD_ROOT');
  if (Dir <> '') and DirectoryExists(Dir) then
  begin
    GAppRoot := IncludeTrailingPathDelimiter(Dir);
    Exit(GAppRoot);
  end;

  Dir := ExtractFilePath(ParamStr(0));
  for i := 0 to 6 do
  begin
    if DirectoryExists(IncludeTrailingPathDelimiter(Dir) + 'assets') then
    begin
      GAppRoot := IncludeTrailingPathDelimiter(Dir);
      Exit(GAppRoot);
    end;
    Dir := ExtractFileDir(ExcludeTrailingPathDelimiter(Dir));
    if Dir = '' then Break;
  end;

  GAppRoot := ExtractFilePath(ParamStr(0));
  Result := GAppRoot;
end;

function LanguagesDir: string;
begin Result := AppRoot + 'assets' + PathDelim + 'languages' + PathDelim; end;

function DataDir: string;
begin Result := AppRoot + 'data' + PathDelim; end;

function SettingsFile: string;
begin Result := DataDir + 'settings.json'; end;

function HistoryFile: string;
begin Result := DataDir + 'history.json'; end;

function LogosDir: string;
begin Result := AppRoot + 'assets' + PathDelim + 'logos' + PathDelim; end;

function ThemesDir: string;
begin Result := AppRoot + 'assets' + PathDelim + 'themes' + PathDelim; end;

function FontsDir: string;
begin Result := AppRoot + 'assets' + PathDelim + 'fonts' + PathDelim; end;

function ThemeFilePath(const FileName: string): string;
begin
  if FileName = '' then Result := '' else Result := ThemesDir + FileName;
end;

function FontFilePath(const FileName: string): string;
begin
  if FileName = '' then Result := '' else Result := FontsDir + FileName;
end;

{ ---- dil ----------------------------------------------------------------- }
function LangFileExists(const Code: string): Boolean;
begin Result := (Code <> '') and FileExists(LanguagesDir + Code + '.json'); end;

function DetectOSLang: string;
var Lang, FallbackLang: string;
begin
  Lang := ''; FallbackLang := '';
  GetLanguageIDs(Lang, FallbackLang);
  if FallbackLang <> '' then Result := LowerCase(Copy(FallbackLang, 1, 2))
  else Result := LowerCase(Copy(Lang, 1, 2));
end;

function FirstAvailableLang: string;
var Files: TStringList;
begin
  Result := '';
  Files := FindAllFiles(LanguagesDir, '*.json', False);
  try
    if Files.Count > 0 then
    begin
      Files.Sort;
      Result := ChangeFileExt(ExtractFileName(Files[0]), '');
    end;
  finally
    Files.Free;
  end;
end;

function ResolveLangCode(const Pref: string): string;
var OSLang: string;
begin
  if (Pref <> '') and (LowerCase(Pref) <> 'auto') and LangFileExists(Pref) then
    Exit(Pref);
  OSLang := DetectOSLang;
  if LangFileExists(OSLang) then Exit(OSLang);
  if LangFileExists('en') then Exit('en');
  Result := FirstAvailableLang;
end;

function ReadLangName(const Code: string): string;
var Raw: string; Data: TJSONData; Meta: TJSONObject;
begin
  Result := Code;
  Raw := ReadFileUtf8(LanguagesDir + Code + '.json');
  if Raw = '' then Exit;
  try Data := GetJSON(Raw); except Exit; end;
  try
    if Data is TJSONObject then
    begin
      Meta := TJSONObject(TJSONObject(Data).Find('_meta', jtObject));
      if Meta <> nil then Result := Meta.Get('name', Code);
    end;
  finally
    Data.Free;
  end;
end;

procedure LoadLanguage(const Pref: string);
var
  Raw: string; Data: TJSONData; Obj, Meta: TJSONObject;
  i: Integer; Item: TJSONData;
begin
  if GDict = nil then
  begin
    GDict := TStringList.Create;
    GDict.NameValueSeparator := '=';
    GDict.CaseSensitive := True;
  end;
  GDict.Clear;
  GLangPref := Pref;
  GLangDir := 'ltr';
  GLangCode := ResolveLangCode(Pref);
  if GLangCode = '' then Exit;

  Raw := ReadFileUtf8(LanguagesDir + GLangCode + '.json');
  if Raw = '' then Exit;
  try Data := GetJSON(Raw); except Exit; end;
  try
    if not (Data is TJSONObject) then Exit;
    Obj := TJSONObject(Data);
    Meta := TJSONObject(Obj.Find('_meta', jtObject));
    if Meta <> nil then GLangDir := LowerCase(Meta.Get('dir', 'ltr'));
    GDict.BeginUpdate;
    try
      for i := 0 to Obj.Count - 1 do
      begin
        Item := Obj.Items[i];
        if Item.JSONType = jtString then
          GDict.Add(Obj.Names[i] + '=' + Item.AsString);
      end;
    finally
      GDict.EndUpdate;
    end;
  finally
    Data.Free;
  end;
end;

function CurrentLangCode: string; begin Result := GLangCode; end;
function CurrentLangPref: string; begin Result := GLangPref; end;
function CurrentLangDir: string;  begin Result := GLangDir;  end;

function T(const Key: string; const Def: string): string;
var idx: Integer;
begin
  if GDict <> nil then
  begin
    idx := GDict.IndexOfName(Key);
    if idx >= 0 then Exit(GDict.ValueFromIndex[idx]);
  end;
  if Def <> '' then Result := Def else Result := Key;
end;

procedure GetAvailableLanguages(Codes, Names: TStrings);
var Files: TStringList; i: Integer; code: string;
begin
  Codes.Clear; Names.Clear;
  Files := FindAllFiles(LanguagesDir, '*.json', False);
  try
    Files.Sort;
    for i := 0 to Files.Count - 1 do
    begin
      code := ChangeFileExt(ExtractFileName(Files[i]), '');
      Codes.Add(code);
      Names.Add(ReadLangName(code));
    end;
  finally
    Files.Free;
  end;
end;

{ ---- tema & font keşfi ---------------------------------------------------- }
procedure GetAvailableThemes(Names, Files: TStrings);
var F: TStringList; i: Integer; raw, name, fname: string;
    p: Integer;
begin
  Names.Clear; Files.Clear;
  if not DirectoryExists(ThemesDir) then Exit;
  F := FindAllFiles(ThemesDir, '*.css', False);
  try
    F.Sort;
    for i := 0 to F.Count - 1 do
    begin
      fname := F[i];
      name  := ChangeFileExt(ExtractFileName(fname), '');
      // /* @name ... */ yorum satırını oku
      raw := ReadFileUtf8(fname);
      p := Pos('@name', raw);
      if p > 0 then
      begin
        Delete(raw, 1, p + 5);
        raw := Trim(raw);
        p := Pos('*/', raw);
        if p > 0 then name := Trim(Copy(raw, 1, p - 1));
      end;
      Names.Add(name);
      Files.Add(ExtractFileName(F[i]));   // bağıl dosya adı (örn. "dark.css")
    end;
  finally
    F.Free;
  end;
end;

procedure GetAvailableFonts(Names, Files: TStrings);
var F: TStringList; i: Integer; fname: string;
begin
  Names.Clear; Files.Clear;
  if not DirectoryExists(FontsDir) then Exit;
  F := FindAllFiles(FontsDir, '*.ttf', False);
  try
    F.Sort;
    for i := 0 to F.Count - 1 do
    begin
      fname := ExtractFileName(F[i]);     // bağıl dosya adı (örn. "Ubuntu Bold.ttf")
      Names.Add(ChangeFileExt(fname, ''));
      Files.Add(fname);
    end;
  finally
    F.Free;
  end;
end;

{ ---- ayarlar ------------------------------------------------------------- }
function LoadSettingsObj: TJSONObject;   // her zaman geçerli bir nesne döner
var Raw: string; Data: TJSONData;
begin
  Raw := ReadFileUtf8(SettingsFile);
  if Raw <> '' then
    try
      Data := GetJSON(Raw);
      if Data is TJSONObject then Exit(TJSONObject(Data));
      Data.Free;
    except
    end;
  Result := TJSONObject.Create;
end;

procedure WriteSettingsObj(O: TJSONObject);
begin
  WriteFileUtf8(SettingsFile, O.FormatJSON);
end;

procedure RemoveKey(O: TJSONObject; const Key: string);
var idx: Integer;
begin
  idx := O.IndexOfName(Key);
  if idx >= 0 then O.Delete(idx);
end;

function ReadSettingStr(const Key, Def: string): string;
var O: TJSONObject; d: TJSONData;
begin
  Result := Def;
  O := LoadSettingsObj;
  try
    d := O.Find(Key);
    if (d <> nil) and (d.JSONType = jtString) then Result := d.AsString;
  finally
    O.Free;
  end;
end;

function ReadSettingBool(const Key: string; Def: Boolean): Boolean;
var O: TJSONObject; d: TJSONData;
begin
  Result := Def;
  O := LoadSettingsObj;
  try
    d := O.Find(Key);
    if (d <> nil) and (d.JSONType = jtBoolean) then Result := d.AsBoolean;
  finally
    O.Free;
  end;
end;

function ReadSettingInt(const Key: string; Def: Integer): Integer;
var O: TJSONObject; d: TJSONData;
begin
  Result := Def;
  O := LoadSettingsObj;
  try
    d := O.Find(Key);
    if (d <> nil) and (d.JSONType = jtNumber) then Result := d.AsInteger;
  finally
    O.Free;
  end;
end;

procedure SaveSettingStr(const Key, Val: string);
var O: TJSONObject;
begin
  O := LoadSettingsObj;
  try RemoveKey(O, Key); O.Add(Key, Val); WriteSettingsObj(O); finally O.Free; end;
end;

procedure SaveSettingBool(const Key: string; Val: Boolean);
var O: TJSONObject;
begin
  O := LoadSettingsObj;
  try RemoveKey(O, Key); O.Add(Key, Val); WriteSettingsObj(O); finally O.Free; end;
end;

procedure SaveSettingInt(const Key: string; Val: Integer);
var O: TJSONObject;
begin
  O := LoadSettingsObj;
  try RemoveKey(O, Key); O.Add(Key, Val); WriteSettingsObj(O); finally O.Free; end;
end;

initialization
  GDict := TStringList.Create;
  GDict.NameValueSeparator := '=';
  GDict.CaseSensitive := True;

finalization
  FreeAndNil(GDict);

end.
