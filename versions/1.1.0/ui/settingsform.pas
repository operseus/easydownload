unit settingsform;

{ ============================================================================
  EasyDownload — Ayarlar pop-up penceresi

  Seçenekler doğrudan data/settings.json'a yazılır (applang üzerinden).
  Dil, Tema ve Font değişince hem bu pencere hem ana form ANINDA güncellenir.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Spin,
  applang, themebtn, updater;

type

  { TSettingsForm }

  TSettingsForm = class(TForm)
    lblLang: TLabel;
    cmbLang: TComboBox;
    lblTheme: TLabel;
    cmbTheme: TComboBox;
    lblFont: TLabel;
    cmbFont: TComboBox;
    lblFolder: TLabel;
    edtFolder: TEdit;
    btnBrowse: TThemedButton;
    lblConcurrent: TLabel;
    spnConcurrent: TSpinEdit;
    chkYtdlpUpdate: TCheckBox;
    btnYtdlpUpdate: TThemedButton;
    chkBackground: TCheckBox;
    chkNotify: TCheckBox;
    lblYtdlpStatus: TLabel;
    btnClose: TThemedButton;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure cmbLangChange(Sender: TObject);
    procedure cmbThemeChange(Sender: TObject);
    procedure cmbFontChange(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure spnConcurrentChange(Sender: TObject);
    procedure chkYtdlpUpdateChange(Sender: TObject);
    procedure btnYtdlpUpdateClick(Sender: TObject);
    procedure chkBackgroundChange(Sender: TObject);
    procedure chkNotifyChange(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FLangCodes: TStringList;
    FThemeFiles: TStringList;
    FFontFiles: TStringList;
    FUpdating: Boolean;

    // Çalışma zamanında oluşturulan uygulama-güncelleme bileşenleri
    FLblUpdateHeader: TLabel;
    FChkAppUpdate: TCheckBox;
    FBtnUpdate: TThemedButton;
    FLblUpdateStatus: TLabel;
    FUpdateAvailable: Boolean;     // denetim sonucu: yeni sürüm var mı
    FUpdateManual: Boolean;        // True: elle kurulum (otomatik kurma, sayfayı aç)
    FUpdateUrl: string;            // indirilecek dosya adresi
    FUpdateVersion: string;        // yeni sürüm etiketi
    FBusy: Boolean;                // denetim/indirme sürüyor mu

    procedure PopulateLanguageCombo(const SelectCode: string);
    procedure PopulateThemeCombo(const SelectFile: string);
    procedure PopulateFontCombo(const SelectName: string);
    procedure ApplyLanguage;

    procedure CreateRuntimeControls;        // .lfm'de olmayan düğmeler/güncelleme
    procedure chkAppUpdateChange(Sender: TObject);
    procedure btnUpdateClick(Sender: TObject);
    procedure SetUpdateStatus(const S: string);
    procedure OnUpdateChecked(const Info: TUpdateInfo);
    procedure StartUpdateDownload;
  public
    procedure OpenDialog;   // değerleri yükle + çeviriyi uygula + modal göster
  end;

var
  FrmSettings: TSettingsForm;

implementation

{$R *.lfm}

uses
  main, Process, LCLIntf, Math;   // ana formu anında tazelemek için

type
  // Uygulama sürüm denetimini arka planda yapan iş parçacığı
  TAppCheckThread = class(TThread)
  private
    FForm: TSettingsForm;
    FInfo: TUpdateInfo;
    procedure DoDone;
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TSettingsForm);
  end;

  // Güncellemeyi arka planda indirip kuran iş parçacığı
  TAppDownloadThread = class(TThread)
  private
    FForm: TSettingsForm;
    FUrl: string;
    FDest: string;
    FErr: string;
    FOk: Boolean;
    procedure DoDone;
  protected
    procedure Execute; override;
  public
    constructor Create(AForm: TSettingsForm; const AUrl, ADest: string);
  end;

  // yt-dlp -U çıktısını arka planda okuyan iş parçacığı (UI donmasını önler)
  TYtdlpUpdateThread = class(TThread)
  private
    FExe: string;
    FOutput: string;
    FForm: TSettingsForm;
    procedure DoDone;
  protected
    procedure Execute; override;
  public
    constructor Create(const Exe: string; AForm: TSettingsForm);
  end;

constructor TYtdlpUpdateThread.Create(const Exe: string; AForm: TSettingsForm);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FExe := Exe;
  FForm := AForm;
end;

procedure TYtdlpUpdateThread.Execute;
var
  P: TProcess;
  buf: array[0..4095] of Byte;
  avail, n: Integer;
  chunk: string;
begin
  P := TProcess.Create(nil);
  try
    P.Executable := FExe;
    P.Parameters.Add('-U');
    P.Options := [poUsePipes, poNoConsole];
    P.ShowWindow := swoHIDE;
    try
      P.Execute;
      while P.Running or (P.Output.NumBytesAvailable > 0) do
      begin
        avail := P.Output.NumBytesAvailable;
        if avail > 0 then
        begin
          n := P.Output.Read(buf, Min(SizeOf(buf), avail));
          if n > 0 then
          begin
            SetString(chunk, PChar(@buf[0]), n);
            FOutput := FOutput + chunk;
          end;
        end
        else
          Sleep(15);
      end;
    except
      on E: Exception do
        FOutput := 'Error: ' + E.Message;
    end;
  finally
    P.Free;
  end;
  Synchronize(@DoDone);
end;

procedure TYtdlpUpdateThread.DoDone;
var output: string;
begin
  output := Trim(FOutput);
  if output = '' then
    output := applang.T('settings.updateDone', 'yt-dlp is up to date.');
  // Son 120 karakteri göster (terminal çıktısı uzun olabilir)
  if Length(output) > 120 then
    output := '...' + Copy(output, Length(output) - 116, 117);
  FForm.lblYtdlpStatus.Caption := output;
  FForm.btnYtdlpUpdate.Enabled := True;
end;

{ TAppCheckThread — sürüm denetimi }

constructor TAppCheckThread.Create(AForm: TSettingsForm);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FForm := AForm;
end;

procedure TAppCheckThread.Execute;
begin
  FInfo := updater.CheckForUpdate;
  Synchronize(@DoDone);
end;

procedure TAppCheckThread.DoDone;
begin
  FForm.OnUpdateChecked(FInfo);
end;

{ TAppDownloadThread — indirme + kurulumu başlatma }

constructor TAppDownloadThread.Create(AForm: TSettingsForm; const AUrl, ADest: string);
begin
  inherited Create(False);
  FreeOnTerminate := True;
  FForm := AForm;
  FUrl  := AUrl;
  FDest := ADest;
end;

procedure TAppDownloadThread.Execute;
begin
  FOk := updater.DownloadFile(FUrl, FDest, nil, FErr);
  Synchronize(@DoDone);
end;

procedure TAppDownloadThread.DoDone;
begin
  FForm.FBusy := False;
  FForm.FBtnUpdate.Enabled := True;
  if FOk then
  begin
    FForm.SetUpdateStatus(applang.T('update.downloaded',
      'İndirildi. Kurulum başlatılıyor...'));
    // Kurulumu çalıştır ve uygulamadan çık (dosyalar değiştirilebilsin)
    if OpenDocument(FDest) then
    begin
      if main.MainForm <> nil then
        main.MainForm.Close
      else
        Application.Terminate;
    end;
  end
  else
    FForm.SetUpdateStatus(applang.T('update.downloadFail', 'İndirme başarısız: ') + FErr);
end;

{ TSettingsForm }

procedure TSettingsForm.FormCreate(Sender: TObject);
begin
  FLangCodes  := TStringList.Create;
  FThemeFiles := TStringList.Create;
  FFontFiles  := TStringList.Create;
  CreateRuntimeControls;
end;

procedure TSettingsForm.FormDestroy(Sender: TObject);
begin
  FLangCodes.Free;
  FThemeFiles.Free;
  FFontFiles.Free;
end;

{ ---------------------------------------------------------------------------
  .lfm'de tutmadığımız düğmeler + uygulama-güncelleme bölümünü kod ile kur
  --------------------------------------------------------------------------- }
procedure TSettingsForm.CreateRuntimeControls;

  function MkBtn(L, T, W, H: Integer; const Cap: string;
    AClick: TNotifyEvent): TThemedButton;
  begin
    Result := TThemedButton.Create(Self);
    Result.Parent := Self;
    Result.SetBounds(L, T, W, H);
    Result.Caption := Cap;
    Result.OnClick := AClick;
  end;

begin
  // Eski .lfm düğmeleri (aynı konumlar)
  btnBrowse      := MkBtn(388, 239, 52, 29, '...', @btnBrowseClick);
  btnYtdlpUpdate := MkBtn(328, 320, 112, 27, 'Update now', @btnYtdlpUpdateClick);
  btnClose       := MkBtn(340, 576, 100, 32, 'Close', @btnCloseClick);

  // --- Uygulama güncelleme bölümü ---
  FLblUpdateHeader := TLabel.Create(Self);
  FLblUpdateHeader.Parent := Self;
  FLblUpdateHeader.SetBounds(20, 448, 420, 20);
  FLblUpdateHeader.Font.Style := [fsBold];
  FLblUpdateHeader.Caption := 'Application update';

  FChkAppUpdate := TCheckBox.Create(Self);
  FChkAppUpdate.Parent := Self;
  FChkAppUpdate.SetBounds(20, 476, 420, 23);
  FChkAppUpdate.Caption := 'Check for updates at startup';
  FChkAppUpdate.OnChange := @chkAppUpdateChange;

  FBtnUpdate := MkBtn(20, 506, 220, 30, 'Check for updates', @btnUpdateClick);

  FLblUpdateStatus := TLabel.Create(Self);
  FLblUpdateStatus.Parent := Self;
  FLblUpdateStatus.SetBounds(20, 544, 420, 34);
  FLblUpdateStatus.AutoSize := False;
  FLblUpdateStatus.WordWrap := True;
  FLblUpdateStatus.Caption := '';
end;

procedure TSettingsForm.SetUpdateStatus(const S: string);
begin
  FLblUpdateStatus.Caption := S;
end;

procedure TSettingsForm.chkAppUpdateChange(Sender: TObject);
begin
  if FUpdating then Exit;
  applang.SaveSettingBool('appUpdateCheck', FChkAppUpdate.Checked);
end;

// Tek düğme: önce DENETLER; güncelleme varsa İNDİR/KUR'a dönüşür
procedure TSettingsForm.btnUpdateClick(Sender: TObject);
begin
  if FBusy then Exit;
  if FUpdateAvailable then
  begin
    if FUpdateManual then
      OpenURL(FUpdateUrl)            // büyük güncelleme: indirme sayfasını aç
    else
      StartUpdateDownload;           // otomatik: indir + kur
    Exit;
  end;
  FBusy := True;
  FBtnUpdate.Enabled := False;
  SetUpdateStatus(applang.T('update.checking', 'Checking for updates...'));
  TAppCheckThread.Create(Self);
end;

procedure TSettingsForm.OnUpdateChecked(const Info: TUpdateInfo);
begin
  FBusy := False;
  FBtnUpdate.Enabled := True;
  if not Info.Ok then
  begin
    SetUpdateStatus(applang.T('update.failed', 'Update check failed: ') + Info.Error);
    Exit;
  end;
  if Info.Available then
  begin
    FUpdateAvailable := True;
    FUpdateManual  := not Info.Auto;
    FUpdateUrl     := Info.Url;
    FUpdateVersion := Info.Version;
    if FUpdateManual then
      FBtnUpdate.Caption := applang.T('update.openPage', 'Open download page')
    else
      FBtnUpdate.Caption := applang.T('update.download', 'Download update') +
        ' (' + Info.Version + ')';
    if Info.Notes <> '' then
      SetUpdateStatus(applang.T('update.available', 'New version available: ') +
        Info.Version + ' — ' + Info.Notes)
    else
      SetUpdateStatus(applang.T('update.available', 'New version available: ') + Info.Version);
  end
  else
  begin
    FUpdateAvailable := False;
    SetUpdateStatus(applang.T('update.uptodate', 'You have the latest version.'));
  end;
end;

procedure TSettingsForm.StartUpdateDownload;
var dest: string;
begin
  if FUpdateUrl = '' then
  begin
    SetUpdateStatus(applang.T('update.noUrl', 'No download URL provided.'));
    Exit;
  end;
  FBusy := True;
  FBtnUpdate.Enabled := False;
  SetUpdateStatus(applang.T('update.downloading', 'Downloading...'));
  dest := IncludeTrailingPathDelimiter(GetTempDir) +
          'EasyDownload-Setup-' + FUpdateVersion + '.exe';
  TAppDownloadThread.Create(Self, FUpdateUrl, dest);
end;

procedure TSettingsForm.OpenDialog;
begin
  FUpdating := True;
  try
    PopulateLanguageCombo(applang.ReadSettingStr('language', 'auto'));
    PopulateThemeCombo(applang.ReadSettingStr('theme', ''));
    PopulateFontCombo(applang.ReadSettingStr('fontName', ''));
    edtFolder.Text         := applang.ReadSettingStr('downloadDir', '');
    spnConcurrent.Value    := applang.ReadSettingInt('maxConcurrent', 1);
    chkYtdlpUpdate.Checked := applang.ReadSettingBool('ytdlpUpdateCheck', False);
    chkBackground.Checked  := applang.ReadSettingBool('runInBackground', False);
    chkNotify.Checked      := applang.ReadSettingBool('notifyOnComplete', True);
    FChkAppUpdate.Checked  := applang.ReadSettingBool('appUpdateCheck', True);
    lblYtdlpStatus.Caption := '';
    FLblUpdateStatus.Caption := '';
  finally
    FUpdating := False;
  end;
  ApplyLanguage;
  ShowModal;
end;

procedure TSettingsForm.PopulateLanguageCombo(const SelectCode: string);
var
  Codes, Names: TStringList;
  i, sel: Integer;
  prev: Boolean;
begin
  prev := FUpdating;
  FUpdating := True;
  Codes := TStringList.Create;
  Names := TStringList.Create;
  try
    cmbLang.Items.Clear;
    FLangCodes.Clear;

    cmbLang.Items.Add(applang.T('settings.languageAuto', 'Automatic (system language)'));
    FLangCodes.Add('auto');

    applang.GetAvailableLanguages(Codes, Names);
    for i := 0 to Codes.Count - 1 do
    begin
      cmbLang.Items.Add(Names[i]);
      FLangCodes.Add(Codes[i]);
    end;

    sel := 0;
    for i := 0 to FLangCodes.Count - 1 do
      if SameText(FLangCodes[i], SelectCode) then begin sel := i; Break; end;
    cmbLang.ItemIndex := sel;
  finally
    Codes.Free;
    Names.Free;
    FUpdating := prev;
  end;
end;

procedure TSettingsForm.PopulateThemeCombo(const SelectFile: string);
var
  Names, Paths: TStringList;
  i, sel: Integer;
  prev: Boolean;
begin
  prev := FUpdating;
  FUpdating := True;
  Names := TStringList.Create;
  Paths := TStringList.Create;
  try
    FThemeFiles.Clear;
    cmbTheme.Items.Clear;

    // "System default" seçeneği — tema uygulanmaz
    cmbTheme.Items.Add(applang.T('settings.themeSystem', 'System default'));
    FThemeFiles.Add('');

    applang.GetAvailableThemes(Names, Paths);
    for i := 0 to Names.Count - 1 do
    begin
      cmbTheme.Items.Add(Names[i]);
      FThemeFiles.Add(Paths[i]);
    end;

    sel := 0;
    for i := 0 to FThemeFiles.Count - 1 do
      if SameText(FThemeFiles[i], SelectFile) then begin sel := i; Break; end;
    cmbTheme.ItemIndex := sel;
  finally
    Names.Free;
    Paths.Free;
    FUpdating := prev;
  end;
end;

procedure TSettingsForm.PopulateFontCombo(const SelectName: string);
var
  Names, Paths: TStringList;
  i, sel: Integer;
  prev: Boolean;
begin
  prev := FUpdating;
  FUpdating := True;
  Names := TStringList.Create;
  Paths := TStringList.Create;
  try
    FFontFiles.Clear;
    cmbFont.Items.Clear;

    // "System default" — özel font yüklenmez
    cmbFont.Items.Add(applang.T('settings.fontSystem', 'System default (Segoe UI)'));
    FFontFiles.Add('');

    applang.GetAvailableFonts(Names, Paths);
    for i := 0 to Names.Count - 1 do
    begin
      cmbFont.Items.Add(Names[i]);
      FFontFiles.Add(Paths[i]);
    end;

    sel := 0;
    for i := 1 to FFontFiles.Count - 1 do
    begin
      if SameText(ChangeFileExt(ExtractFileName(FFontFiles[i]), ''), SelectName) then
      begin sel := i; Break; end;
    end;
    cmbFont.ItemIndex := sel;
  finally
    Names.Free;
    Paths.Free;
    FUpdating := prev;
  end;
end;

procedure TSettingsForm.ApplyLanguage;
begin
  Caption := applang.T('settings.title', 'Settings');
  if applang.CurrentLangDir = 'rtl' then BiDiMode := bdRightToLeft
  else BiDiMode := bdLeftToRight;

  lblLang.Caption        := applang.T('settings.language', 'Language');
  lblTheme.Caption       := applang.T('settings.theme', 'Theme');
  lblFont.Caption        := applang.T('settings.font', 'Font');
  lblFolder.Caption      := applang.T('settings.defaultFolder', 'Default save folder');
  btnBrowse.Caption      := applang.T('ui.browse', '...');
  lblConcurrent.Caption  := applang.T('settings.maxConcurrent', 'Max concurrent downloads');
  chkYtdlpUpdate.Caption := applang.T('settings.ytdlpUpdate', 'Check yt-dlp for updates');
  btnYtdlpUpdate.Caption := applang.T('settings.updateNow', 'Update now');
  chkBackground.Caption  := applang.T('settings.background', 'Keep running in background');
  chkNotify.Caption      := applang.T('settings.notify', 'Notify when download finishes');
  btnClose.Caption       := applang.T('common.close', 'Close');

  // Uygulama güncelleme bölümü
  FLblUpdateHeader.Caption := applang.T('update.header', 'Application update');
  FChkAppUpdate.Caption    := applang.T('update.checkStartup', 'Check for updates at startup');
  if not FUpdateAvailable then
    FBtnUpdate.Caption := applang.T('update.check', 'Check for updates');

  PopulateLanguageCombo(applang.CurrentLangPref);
end;

procedure TSettingsForm.cmbLangChange(Sender: TObject);
var code: string;
begin
  if FUpdating then Exit;
  if (cmbLang.ItemIndex < 0) or (cmbLang.ItemIndex >= FLangCodes.Count) then Exit;

  code := FLangCodes[cmbLang.ItemIndex];
  applang.SaveSettingStr('language', code);
  applang.LoadLanguage(code);

  ApplyLanguage;
  if main.MainForm <> nil then
    main.MainForm.ApplyLanguage;
end;

procedure TSettingsForm.cmbThemeChange(Sender: TObject);
var themeFile: string;
begin
  if FUpdating then Exit;
  if (cmbTheme.ItemIndex < 0) or (cmbTheme.ItemIndex >= FThemeFiles.Count) then Exit;

  themeFile := FThemeFiles[cmbTheme.ItemIndex];
  applang.SaveSettingStr('theme', themeFile);

  if main.MainForm <> nil then
    main.MainForm.ApplyTheme(themeFile);
end;

procedure TSettingsForm.cmbFontChange(Sender: TObject);
var fontFile, fontName: string;
begin
  if FUpdating then Exit;
  if (cmbFont.ItemIndex < 0) or (cmbFont.ItemIndex >= FFontFiles.Count) then Exit;

  fontFile := FFontFiles[cmbFont.ItemIndex];
  if fontFile = '' then
    fontName := ''
  else
    fontName := ChangeFileExt(ExtractFileName(fontFile), '');

  applang.SaveSettingStr('fontName', fontName);
  applang.SaveSettingStr('fontFile', fontFile);

  if main.MainForm <> nil then
    main.MainForm.ApplyAppFont(fontName, fontFile);
end;

procedure TSettingsForm.btnBrowseClick(Sender: TObject);
var dir: string;
begin
  dir := '';
  if SelectDirectory(applang.T('settings.defaultFolder', 'Default save folder'),
                     edtFolder.Text, dir) then
    if dir <> '' then
    begin
      edtFolder.Text := dir;
      applang.SaveSettingStr('downloadDir', dir);
      if main.MainForm <> nil then main.MainForm.SetActiveFolder(dir);
    end;
end;

procedure TSettingsForm.spnConcurrentChange(Sender: TObject);
begin
  if FUpdating then Exit;
  applang.SaveSettingInt('maxConcurrent', spnConcurrent.Value);
end;

procedure TSettingsForm.chkYtdlpUpdateChange(Sender: TObject);
begin
  if FUpdating then Exit;
  applang.SaveSettingBool('ytdlpUpdateCheck', chkYtdlpUpdate.Checked);
end;

procedure TSettingsForm.btnYtdlpUpdateClick(Sender: TObject);
var ytdlpExe: string;
begin
  ytdlpExe := applang.AppRoot + 'bin' + PathDelim + 'yt-dlp.exe';
  if not FileExists(ytdlpExe) then
  begin
    lblYtdlpStatus.Caption := 'yt-dlp.exe not found in bin/';
    Exit;
  end;

  btnYtdlpUpdate.Enabled := False;
  lblYtdlpStatus.Caption := applang.T('settings.updating', 'Updating yt-dlp...');

  // Arka planda çalıştır — UI donmaz, bitince DoDone Caption'ı günceller
  TYtdlpUpdateThread.Create(ytdlpExe, Self);
end;

procedure TSettingsForm.chkBackgroundChange(Sender: TObject);
begin
  if FUpdating then Exit;
  applang.SaveSettingBool('runInBackground', chkBackground.Checked);
end;

procedure TSettingsForm.chkNotifyChange(Sender: TObject);
begin
  if FUpdating then Exit;
  applang.SaveSettingBool('notifyOnComplete', chkNotify.Checked);
end;

procedure TSettingsForm.btnCloseClick(Sender: TObject);
begin
  Close;
end;

end.
