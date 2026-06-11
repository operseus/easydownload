unit main;

{ ============================================================================
  EasyDownload — Ana pencere (Lazarus / Object Pascal, Chromium YOK)

  Mimari:
    * Geniş ANA TPageControl (pcMain):  İndir | Sıra | Geçmiş | Hakkında | Yapımcı
    * Sekmelerin sağ üstünde "Ayarlar" butonu (pop-up settingsform açar)
    * "İndir" sekmesi: Link + mavi ARA, Klasör, kapak/playlist, küçük Video/Ses
      sekmesi, "Bilgileri Ekle", ilerleme + yüzde, İNDİR/SIRAYA EKLE butonları,
      Duraklat/İptal butonları.
    * "Sıra": indirme kuyruğu (TListView, durum/yüzde), Başlat butonu.
    * "Geçmiş": data/history.json (TListView).
    * Yapımcı sekmesinde tıklanabilir site bağlantıları.
    * Ayarlar ve diller paylaşılan 'applang' biriminden gelir.

  ARA → bilgi getir → İNDİR veya SIRAYA EKLE.
  YouTube Music linkleri otomatik Audio sekmesine geçer.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, ExtCtrls, ComCtrls,
  StdCtrls, CheckLst, fpjson, jsonparser,
  applang, engine, themebtn, updater;

type
  TQueueStatus = (qsWaiting, qsRunning, qsDone, qsError, qsCanceled);

  // Kuyruktaki bir indirme işi
  TQueueItem = class
  public
    Url, Title, Kind, Quality, VideoFormat, AudioFormat, OutDir: string;
    Uploader, UploadDate, Description: string;
    Metadata, Thumbnail, Playlist: Boolean;
    Status: TQueueStatus;
    Percent: Integer;
  end;

  TThemedBtnArray = array of TThemedButton;

  { TMainForm }

  TMainForm = class(TForm)
    pcMain: TPageControl;
    tsDownload: TTabSheet;
    tsQueue: TTabSheet;
    tsHistory: TTabSheet;
    tsAbout: TTabSheet;
    tsMaker: TTabSheet;
    // --- Ayarlar butonu (üst sağ) ---
    btnSettings: TThemedButton;
    // --- İndir sekmesi ---
    lblLink: TLabel;
    edtUrl: TEdit;
    pnlSearch: TPanel;
    lblFolder: TLabel;
    edtFolder: TEdit;
    btnBrowse: TThemedButton;
    lblVideoTitle: TLabel;
    pnlThumb: TPanel;
    imgThumb: TImage;
    pcType: TPageControl;
    tsVideo: TTabSheet;
    tsAudio: TTabSheet;
    lblRes: TLabel;
    cmbResolution: TComboBox;
    lblFmtV: TLabel;
    cmbVideoFormat: TComboBox;
    lblFmtA: TLabel;
    cmbAudioFormat: TComboBox;
    chkInfo: TCheckBox;
    pbProgress: TProgressBar;
    lblPercent: TLabel;
    btnDownloadNow: TThemedButton;
    btnAddQueue: TThemedButton;
    btnPause: TThemedButton;
    btnCancel: TThemedButton;
    // --- Sıra sekmesi ---
    lvQueue: TListView;
    btnQueueRemove: TThemedButton;
    btnQueueClear: TThemedButton;
    btnQueueStart: TThemedButton;
    // --- Geçmiş sekmesi ---
    lvHistory: TListView;
    btnHistoryRetry: TThemedButton;
    btnHistoryOpen: TThemedButton;
    btnHistoryClear: TThemedButton;
    // --- Hakkında ---
    lblAboutTitle: TLabel;
    lblAboutVersion: TLabel;
    lblAboutDesc: TLabel;
    lblAboutPowered: TLabel;
    lblAboutLicense: TLabel;
    // --- Yapımcı ---
    lblMakerTitle: TLabel;
    lblMakerSignature: TLabel;
    lblMakerContact: TLabel;
    lblAppSite: TLabel;
    lblMakerSite: TLabel;
    // --- olaylar ---
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure btnSearchClick(Sender: TObject);
    procedure btnBrowseClick(Sender: TObject);
    procedure edtUrlChange(Sender: TObject);
    procedure pcTypeChange(Sender: TObject);
    procedure pcMainChange(Sender: TObject);
    procedure btnSettingsClick(Sender: TObject);
    procedure btnDownloadNowClick(Sender: TObject);
    procedure btnAddQueueClick(Sender: TObject);
    procedure btnPauseClick(Sender: TObject);
    procedure btnCancelClick(Sender: TObject);
    procedure btnQueueRemoveClick(Sender: TObject);
    procedure btnQueueClearClick(Sender: TObject);
    procedure btnQueueStartClick(Sender: TObject);
    procedure btnHistoryRetryClick(Sender: TObject);
    procedure btnHistoryOpenClick(Sender: TObject);
    procedure btnHistoryClearClick(Sender: TObject);
    procedure lblAppSiteClick(Sender: TObject);
    procedure lblMakerSiteClick(Sender: TObject);
  private
    FEngine: TEngine;
    FInfo: TMediaInfo;
    FInfoUrl: string;
    FHasInfo: Boolean;
    FAudio: Boolean;
    FLastFile: string;
    FActiveResult: string;        // 'done' | 'error' | 'canceled' | ''
    FQueue: TFPList;              // of TQueueItem
    FActiveItem: TQueueItem;
    FHistory: THistoryArray;
    FPlaylistBox: TCheckListBox;  // dinamik playlist kutusu
    FPendingSearchUrl: string;    // DoSearch ile en son istenen URL (yarış kontrolü)
    FLoadedFontFile: string;      // ApplyAppFont ile o an yüklü özel font dosyası

    // Özel (kendi çizdiğimiz) sekme şeritleri — yerel TPageControl sekmeleri
    // Windows koyu temasına uymadığı için gizlenip yerlerine bunlar konur.
    FMainTabBar: TPanel;
    FTypeTabBar: TPanel;
    FMainTabs: TThemedBtnArray;
    FTypeTabs: TThemedBtnArray;

    function FriendlyError(const RawMsg: string): string;

    procedure LoadAppIcon;
    procedure InitCombos;
    procedure LoadDownloadDefaults;
    function DefaultDownloadDir: string;
    function EffectiveFolder: string;

    procedure SetSearchMode;
    procedure UpdateActionButtons;
    procedure ShowDownloadControls(AShow: Boolean);
    function SelectedQuality: string;
    procedure SetQualityByValue(const V: string);
    procedure SetComboByText(Cmb: TComboBox; const V: string);

    // kapak & playlist UI
    procedure ClearThumbArea;
    procedure LoadThumbnail(const Path: string);
    procedure BuildPlaylistBox;
    procedure DetectYouTubeMusic(const Url: string);

    // kuyruk
    function StatusText(Item: TQueueItem): string;
    procedure AddQueueRow(Item: TQueueItem);
    procedure UpdateQueueRow(Idx: Integer);
    procedure UpdateActiveRow;
    procedure RefreshQueueTexts;
    procedure EnqueueCurrent(const Url: string; AutoStart: Boolean);
    procedure ProcessQueue;

    // geçmiş
    function HistoryStatusText(const Code: string): string;
    procedure RefreshHistory;

    // motor olayları
    procedure DoSearch(const Url: string);
    procedure OnInfo(const Info: TMediaInfo; const ErrMsg: string);
    procedure OnQuickAddInfo(const Info: TMediaInfo; const ErrMsg: string);
    procedure OnEngineLine(const JsonLine: string);
    procedure OnEngineDone;
    procedure HandleEvent(const Line: string);
    function IsYouTubeUrl(const S: string): Boolean;

    procedure SetupColumns;

    // düğmeleri kod ile oluştur (TThemedButton .lfm'de olmasın diye)
    procedure CreateThemedButtons;

    // açılışta güncelleme denetimi sonucu + otomatik kurulum
    procedure HandleStartupUpdate(const Info: TUpdateInfo);
    procedure StartAutoUpdate(const Url, Version: string);
    procedure FinishAutoUpdate(Ok: Boolean; const Dest, Err: string);

    // özel sekme şeritleri
    procedure BuildTabStrips;
    procedure LayoutTabStrip(pc: TPageControl; const Btns: TThemedBtnArray);
    procedure RefreshTabStrips;
    procedure MainTabClick(Sender: TObject);
    procedure TypeTabClick(Sender: TObject);
  public
    procedure ApplyLanguage;                  // settingsform de çağırır
    procedure SetActiveFolder(const Dir: string);
    procedure ApplyTheme(const ThemeFile: string);
    procedure ApplyAppFont(const FontName, FontFile: string);
  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

uses
  LazFileUtils, LCLIntf, settingsform, thememanager;

{ --- Sadece ihtiyacımız olan Win32 API fonksiyonları (Windows birimi OLMADAN) --- }
const
  FR_PRIVATE         = Cardinal($10);
  HWND_BROADCAST_VAL = PtrUInt($FFFF);
  WM_FONTCHANGE_MSG  = Cardinal($001D);

function AddFontResourceExW(lpszFilename: PWideChar; fl: Cardinal; pdv: Pointer): Integer;
         stdcall; external 'gdi32.dll' name 'AddFontResourceExW';
function RemoveFontResourceExW(lpszFilename: PWideChar; fl: Cardinal; pdv: Pointer): LongBool;
         stdcall; external 'gdi32.dll' name 'RemoveFontResourceExW';
function PostMessageW(hWnd: PtrUInt; Msg: Cardinal; wParam: PtrUInt; lParam: PtrInt): LongBool;
         stdcall; external 'user32.dll' name 'PostMessageW';

const
  QualityValues: array[0..6] of string =
    ('best', '2160', '1440', '1080', '720', '480', '360');
  AppVersion = updater.CurrentVersion;   // tek kaynak: updater birimi

type
  // Açılışta sürüm denetimini arka planda yapan iş parçacığı
  TStartupCheckThread = class(TThread)
  private
    FInfo: TUpdateInfo;
    procedure DoDone;
  protected
    procedure Execute; override;
  end;

  // Otomatik güncelleme: arka planda indir, sonra kurulumu başlat
  TUpdateInstallThread = class(TThread)
  private
    FUrl, FDest, FErr: string;
    FOk: Boolean;
    procedure DoDone;
  protected
    procedure Execute; override;
  public
    constructor Create(const AUrl, ADest: string);
  end;

{ ---------------------------------------------------------------------------
  JSON yardımcısı (motor olay satırları için)
  --------------------------------------------------------------------------- }
function OStr(O: TJSONObject; const Name: string; const Def: string = ''): string;
var d: TJSONData;
begin
  Result := Def;
  if O = nil then Exit;
  d := O.Find(Name);
  if (d <> nil) and (d.JSONType = jtString) then Result := d.AsString;
end;

{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
begin
  FQueue := TFPList.Create;
  FActiveItem := nil;
  FHasInfo := False;
  FAudio := False;
  FPlaylistBox := nil;
  FPendingSearchUrl := '';
  FLoadedFontFile := '';

  FEngine := TEngine.Create(applang.AppRoot);
  applang.LoadLanguage(applang.ReadSettingStr('language', 'auto'));

  // Düğmeleri kod ile oluştur (TThemedButton .lfm'de yok), sonra sekme şeritleri
  CreateThemedButtons;
  // Yerel sekmeleri özel (tema dostu) şeritlerle değiştir — temadan ÖNCE
  BuildTabStrips;

  // Kaydedilmiş tema ve fontu uygula
  ApplyTheme(applang.ReadSettingStr('theme', ''));
  ApplyAppFont(applang.ReadSettingStr('fontName', ''),
               applang.ReadSettingStr('fontFile', ''));

  LoadAppIcon;
  InitCombos;
  LoadDownloadDefaults;
  ApplyLanguage;        // kolon başlıkları + tüm metinler + geçmiş tazelenir
  SetSearchMode;
  ShowDownloadControls(False);
  pcMain.ActivePageIndex := 0;
  RefreshTabStrips;

  // Açılışta güncelleme denetimi (ayardan açıksa, arka planda, sessiz)
  if applang.ReadSettingBool('appUpdateCheck', True) then
    with TStartupCheckThread.Create(True) do
    begin
      FreeOnTerminate := True;
      Start;
    end;
end;

procedure TMainForm.FormDestroy(Sender: TObject);
var i: Integer;
begin
  if FEngine <> nil then
  begin
    FEngine.Cancel;
    FEngine.Free;
  end;
  if FPlaylistBox <> nil then FreeAndNil(FPlaylistBox);
  if FLoadedFontFile <> '' then
    RemoveFontResourceExW(PWideChar(WideString(FLoadedFontFile)), FR_PRIVATE, nil);
  if FQueue <> nil then
  begin
    for i := 0 to FQueue.Count - 1 do TObject(FQueue[i]).Free;
    FQueue.Free;
  end;
end;

procedure TMainForm.LoadAppIcon;
var ico: string;
begin
  ico := applang.LogosDir + 'logo.ico';
  if FileExists(ico) then
    try
      Icon.LoadFromFile(ico);
      Application.Icon.LoadFromFile(ico);
    except
      // ikon yüklenemese de uygulama çalışır
    end;
end;

{ ---------------------------------------------------------------------------
  Varsayılanlar
  --------------------------------------------------------------------------- }
procedure TMainForm.InitCombos;
begin
  cmbResolution.Items.Clear;
  cmbResolution.Items.Add('Best quality');   // ApplyLanguage yerelleştirir
  cmbResolution.Items.Add('2160p (4K)');
  cmbResolution.Items.Add('1440p (2K)');
  cmbResolution.Items.Add('1080p');
  cmbResolution.Items.Add('720p');
  cmbResolution.Items.Add('480p');
  cmbResolution.Items.Add('360p');
  cmbResolution.ItemIndex := 0;

  cmbVideoFormat.Items.Clear;
  cmbVideoFormat.Items.Add('mp4');
  cmbVideoFormat.Items.Add('mkv');
  cmbVideoFormat.ItemIndex := 0;

  cmbAudioFormat.Items.Clear;
  cmbAudioFormat.Items.Add('mp3');
  cmbAudioFormat.Items.Add('m4a');
  cmbAudioFormat.Items.Add('opus');
  cmbAudioFormat.Items.Add('flac');
  cmbAudioFormat.ItemIndex := 0;

  pbProgress.Position := 0;
  lblPercent.Caption := '%0';
end;

function TMainForm.DefaultDownloadDir: string;
var prof: string;
begin
  prof := SysUtils.GetEnvironmentVariable('USERPROFILE');
  if prof = '' then prof := SysUtils.GetEnvironmentVariable('HOME');
  Result := IncludeTrailingPathDelimiter(prof) + 'Downloads';
  if not DirectoryExists(Result) then Result := prof;
end;

procedure TMainForm.LoadDownloadDefaults;
var dir: string;
begin
  dir := applang.ReadSettingStr('downloadDir', '');
  if (dir = '') or (not DirectoryExists(dir)) then dir := DefaultDownloadDir;
  edtFolder.Text := dir;

  if applang.ReadSettingStr('defaultType', 'video') = 'audio' then
    pcType.ActivePageIndex := 1
  else
    pcType.ActivePageIndex := 0;
  FAudio := (pcType.ActivePageIndex = 1);
  RefreshTabStrips;

  SetQualityByValue(applang.ReadSettingStr('defaultQuality', 'best'));
  SetComboByText(cmbVideoFormat, applang.ReadSettingStr('videoFormat', 'mp4'));
  SetComboByText(cmbAudioFormat, applang.ReadSettingStr('audioFormat', 'mp3'));
  chkInfo.Checked := applang.ReadSettingBool('embedMetadata', True);
end;

function TMainForm.EffectiveFolder: string;
begin
  Result := edtFolder.Text;
  if (Result = '') or (not DirectoryExists(Result)) then
  begin
    Result := DefaultDownloadDir;
    edtFolder.Text := Result;
  end;
end;

procedure TMainForm.SetActiveFolder(const Dir: string);
begin
  edtFolder.Text := Dir;
end;

{ ---------------------------------------------------------------------------
  Açılışta güncelleme denetimi (arka plan iş parçacığı)
  --------------------------------------------------------------------------- }
procedure TStartupCheckThread.Execute;
begin
  FInfo := updater.CheckForUpdate;
  Synchronize(@DoDone);
end;

procedure TStartupCheckThread.DoDone;
begin
  if MainForm <> nil then MainForm.HandleStartupUpdate(FInfo);
end;

constructor TUpdateInstallThread.Create(const AUrl, ADest: string);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FUrl := AUrl;
  FDest := ADest;
  Start;
end;

procedure TUpdateInstallThread.Execute;
begin
  FOk := updater.DownloadFile(FUrl, FDest, nil, FErr);
  Synchronize(@DoDone);
end;

procedure TUpdateInstallThread.DoDone;
begin
  if MainForm <> nil then MainForm.FinishAutoUpdate(FOk, FDest, FErr);
end;

procedure TMainForm.HandleStartupUpdate(const Info: TUpdateInfo);
begin
  // Sessiz denetim: yalnızca gerçekten yeni sürüm varsa kullanıcıyı bilgilendir
  if not (Info.Ok and Info.Available) then Exit;

  if Info.Auto then
  begin
    // Otomatik kurulum: onayla → indir → kur → kapan
    if MessageDlg(
         applang.T('update.header', 'Application update'),
         Format(applang.T('update.autoPrompt',
           'A new version (%s) is available. Update now?'), [Info.Version]),
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      StartAutoUpdate(Info.Url, Info.Version);
  end
  else
  begin
    // Elle kurulum (updater'ı değiştiren büyük güncelleme): indirme sayfasını aç
    if MessageDlg(
         applang.T('update.header', 'Application update'),
         Format(applang.T('update.manualPrompt',
           'A major update (%s) requires manual installation. Open the download page?'),
           [Info.Version]),
         mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      OpenURL(Info.Url);
  end;
end;

// Arka planda indir; bitince kurulumu başlat
procedure TMainForm.StartAutoUpdate(const Url, Version: string);
var dest: string;
begin
  if Url = '' then Exit;
  dest := IncludeTrailingPathDelimiter(GetTempDir) +
          'EasyDownload-Setup-' + Version + '.exe';
  Caption := applang.T('update.downloading', 'Downloading update...');
  TUpdateInstallThread.Create(Url, dest);
end;

procedure TMainForm.FinishAutoUpdate(Ok: Boolean; const Dest, Err: string);
begin
  Caption := 'EasyDownload';
  if Ok then
  begin
    // Kurulumu çalıştır ve uygulamadan çık (dosyalar değiştirilebilsin)
    if OpenDocument(Dest) then
      Close
    else
      MessageDlg(applang.T('update.header', 'Application update'),
        applang.T('update.runFail', 'Could not start the installer.'),
        mtError, [mbOK], 0);
  end
  else
    MessageDlg(applang.T('update.header', 'Application update'),
      applang.T('update.downloadFail', 'Download failed: ') + Err,
      mtError, [mbOK], 0);
end;

{ ---------------------------------------------------------------------------
  Düğmeleri kod ile oluştur — TThemedButton'ı .lfm'e koymadığımız için
  (Lazarus tasarımcısı çalışma-zamanı bileşenini tanımaz, hata verirdi).
  Konumlar eski .lfm değerleriyle birebir aynıdır.
  --------------------------------------------------------------------------- }
procedure TMainForm.CreateThemedButtons;

  function Mk(AParent: TWinControl; L, T, W, H: Integer; const Cap: string;
    AClick: TNotifyEvent): TThemedButton;
  begin
    Result := TThemedButton.Create(Self);
    Result.Parent := AParent;
    Result.SetBounds(L, T, W, H);
    Result.Caption := Cap;
    Result.OnClick := AClick;
  end;

begin
  // --- İndir sekmesi ---
  btnBrowse := Mk(tsDownload, 618, 49, 42, 27, '...', @btnBrowseClick);

  btnDownloadNow := Mk(tsDownload, 12, 332, 322, 34, 'DOWNLOAD', @btnDownloadNowClick);
  btnDownloadNow.Font.Height := -14;
  btnDownloadNow.Font.Style := [fsBold];
  btnDownloadNow.Enabled := False;

  btnAddQueue := Mk(tsDownload, 342, 332, 318, 34, 'ADD TO QUEUE', @btnAddQueueClick);
  btnAddQueue.Font.Height := -14;
  btnAddQueue.Font.Style := [fsBold];
  btnAddQueue.Enabled := False;

  btnPause := Mk(tsDownload, 12, 372, 322, 34, 'Pause', @btnPauseClick);
  btnPause.Visible := False;

  btnCancel := Mk(tsDownload, 342, 372, 318, 34, 'Cancel Download', @btnCancelClick);
  btnCancel.Visible := False;

  // --- Sıra sekmesi ---
  btnQueueRemove := Mk(tsQueue, 8, 376, 140, 30, 'Remove', @btnQueueRemoveClick);
  btnQueueClear  := Mk(tsQueue, 156, 376, 140, 30, 'Clear all', @btnQueueClearClick);
  btnQueueStart  := Mk(tsQueue, 504, 376, 160, 30, 'Start Queue', @btnQueueStartClick);

  // --- Geçmiş sekmesi ---
  btnHistoryRetry := Mk(tsHistory, 8, 360, 140, 30, 'Download again', @btnHistoryRetryClick);
  btnHistoryOpen  := Mk(tsHistory, 156, 360, 140, 30, 'Open location', @btnHistoryOpenClick);
  btnHistoryClear := Mk(tsHistory, 304, 360, 140, 30, 'Clear history', @btnHistoryClearClick);
end;

{ ---------------------------------------------------------------------------
  Özel sekme şeritleri — yerel sekmeleri gizle, yerlerine TThemedButton koy
  --------------------------------------------------------------------------- }
procedure TMainForm.BuildTabStrips;

  function NewTabButtons(pc: TPageControl; bar: TPanel;
    AClick: TNotifyEvent): TThemedBtnArray;
  var k: Integer; b: TThemedButton;
  begin
    Result := nil;
    SetLength(Result, pc.PageCount);
    for k := 0 to pc.PageCount - 1 do
    begin
      b := TThemedButton.Create(Self);
      b.Parent := bar;
      b.TabStop := False;
      b.Tag := k;
      b.Caption := pc.Pages[k].Caption;
      b.OnClick := AClick;
      Result[k] := b;
    end;
    pc.ShowTabs := False;
  end;

begin
  // --- Ana sekme şeridi (Download/Queue/...) : forma alTop panel ---
  FMainTabBar := TPanel.Create(Self);
  FMainTabBar.Parent := Self;
  FMainTabBar.BevelOuter := bvNone;
  FMainTabBar.Align := alTop;
  FMainTabBar.Height := 34;
  FMainTabs := NewTabButtons(pcMain, FMainTabBar, @MainTabClick);

  // Ayarlar butonunu kod ile oluştur, şeridin sağına yerleştir
  btnSettings := TThemedButton.Create(Self);
  btnSettings.Parent := FMainTabBar;
  btnSettings.Caption := 'Settings';
  btnSettings.OnClick := @btnSettingsClick;
  btnSettings.SetBounds(FMainTabBar.ClientWidth - 90, 5, 82, 24);
  btnSettings.Anchors := [akTop, akRight];

  // pcMain alClient olduğundan alTop şeridin altına kendiliğinden yerleşir.
  pcMain.SendToBack;

  // --- Video/Audio sekme şeridi : tsDownload üstünde, pcType yerinde ---
  FTypeTabBar := TPanel.Create(Self);
  FTypeTabBar.Parent := tsDownload;
  FTypeTabBar.BevelOuter := bvNone;
  FTypeTabBar.SetBounds(pcType.Left, pcType.Top, pcType.Width, 26);
  FTypeTabs := NewTabButtons(pcType, FTypeTabBar, @TypeTabClick);
  // pcType'i şeridin altına indir, yüksekliğini şerit kadar kıs
  pcType.SetBounds(pcType.Left, pcType.Top + 26, pcType.Width, pcType.Height - 26);

  LayoutTabStrip(pcMain, FMainTabs);
  LayoutTabStrip(pcType, FTypeTabs);
end;

// Sekme düğmelerini yan yana diz, genişliği başlık metnine göre ayarla
procedure TMainForm.LayoutTabStrip(pc: TPageControl; const Btns: TThemedBtnArray);
var i, x, w, h: Integer; bmp: TBitmap;
begin
  if Length(Btns) = 0 then Exit;
  h := TWinControl(Btns[0].Parent).Height;
  // Metin ölçümü için pencere handle'ı gerektirmeyen geçici bitmap canvas
  bmp := TBitmap.Create;
  try
    x := 4;
    for i := 0 to High(Btns) do
    begin
      Btns[i].Caption := pc.Pages[i].Caption;
      bmp.Canvas.Font.Assign(Btns[i].Font);
      w := bmp.Canvas.TextWidth(Btns[i].Caption) + 26;
      if w < 64 then w := 64;
      Btns[i].SetBounds(x, 0, w, h);
      Inc(x, w + 2);
    end;
  finally
    bmp.Free;
  end;
end;

// Aktif sekmeyi vurgula, pasifleri soluk göster (tema renkleriyle)
procedure TMainForm.RefreshTabStrips;
var th: TAppTheme;

  procedure Recolor(pc: TPageControl; bar: TPanel; const Btns: TThemedBtnArray);
  var i: Integer;
  begin
    if bar <> nil then bar.Color := th.Bg;
    for i := 0 to High(Btns) do
      if i = pc.ActivePageIndex then
        Btns[i].SetThemeColors(th.Surface, th.Surface, th.Text, th.Surface, th.TextDim)
      else
        Btns[i].SetThemeColors(th.Bg, th.Bg, th.TextDim, th.Bg, th.TextDim);
  end;

begin
  th := thememanager.CurrentTheme;
  Recolor(pcMain, FMainTabBar, FMainTabs);
  Recolor(pcType, FTypeTabBar, FTypeTabs);
end;

procedure TMainForm.MainTabClick(Sender: TObject);
begin
  pcMain.ActivePageIndex := TThemedButton(Sender).Tag;
  pcMainChange(nil);
  RefreshTabStrips;
end;

procedure TMainForm.TypeTabClick(Sender: TObject);
begin
  pcType.ActivePageIndex := TThemedButton(Sender).Tag;
  pcTypeChange(nil);
  RefreshTabStrips;
end;

{ ---------------------------------------------------------------------------
  Tema uygulama — CSS değişkenlerini oku ve LCL bileşenlerine uygula
  --------------------------------------------------------------------------- }
procedure TMainForm.ApplyTheme(const ThemeFile: string);
var Theme: TAppTheme;
begin
  Theme := thememanager.LoadTheme(ThemeFile);
  thememanager.SetCurrentTheme(Theme);

  // ---- 1. Ana pencere + tüm bileşenler ----
  thememanager.ApplyThemeToForm(Self, Theme);

  // ---- 2. Aksiyona özel butonlar (primary renk) ----
  pnlSearch.Color           := Theme.Primary;
  pnlSearch.Font.Color      := Theme.PrimaryText;
  // İNDİR: vurgulu (primary) düğme; SIRAYA EKLE: ikincil yüzey rengi.
  // Pasifken (henüz arama yapılmadı) soluk yüzey/gri yazı gösterilir.
  btnDownloadNow.SetThemeColors(Theme.Primary, Theme.Primary, Theme.PrimaryText,
    Theme.Surface, Theme.TextDim);
  btnAddQueue.SetThemeColors(Theme.Surface2, Theme.Border, Theme.Text,
    Theme.Surface, Theme.TextDim);

  // ---- 3. Progress bar etiket rengi ----
  lblPercent.Font.Color := Theme.Text;
  lblVideoTitle.Font.Color := Theme.Text;

  // ---- 4. Çalışma zamanında oluşturulan playlist kutusu ----
  if FPlaylistBox <> nil then
    thememanager.ApplyThemeToControl(FPlaylistBox, Theme);

  // ---- 5. Ayarlar formu da temala (oluşturulduysa) ----
  if FrmSettings <> nil then
    thememanager.ApplyThemeToForm(FrmSettings, Theme);

  // ---- 6. Özel sekme şeritlerini yeniden renklendir ----
  RefreshTabStrips;
  pcMain.Invalidate;
  pcType.Invalidate;
end;

{ ---------------------------------------------------------------------------
  Font uygulama — TTF dosyasını Windows'a kaydet ve tüm formlara uygula
  --------------------------------------------------------------------------- }
procedure TMainForm.ApplyAppFont(const FontName, FontFile: string);
var
  actualName: string;
  fontPath: string;

  procedure SetFont(C: TControl);
  var j: Integer;
  begin
    C.Font.Name := actualName;
    if C is TWinControl then
      for j := 0 to (C as TWinControl).ControlCount - 1 do
        SetFont((C as TWinControl).Controls[j]);
  end;

begin
  // Önceden yüklenmiş özel font varsa, GDI kaynağını serbest bırak (sızıntı önleme)
  if FLoadedFontFile <> '' then
  begin
    RemoveFontResourceExW(PWideChar(WideString(FLoadedFontFile)), FR_PRIVATE, nil);
    PostMessageW(HWND_BROADCAST_VAL, WM_FONTCHANGE_MSG, 0, 0);
    FLoadedFontFile := '';
  end;

  fontPath := applang.FontFilePath(FontFile);   // bağıl ad -> FontsDir + ad
  if (FontName = '') or (fontPath = '') or (not FileExists(fontPath)) then
  begin
    actualName := 'Segoe UI';
  end
  else
  begin
    // TTF dosyasını Windows'a geçici olarak kaydet (uygulama yaşam süresiyle)
    AddFontResourceExW(PWideChar(WideString(fontPath)), FR_PRIVATE, nil);
    PostMessageW(HWND_BROADCAST_VAL, WM_FONTCHANGE_MSG, 0, 0);
    actualName := FontName;
    FLoadedFontFile := fontPath;
  end;

  Font.Name := actualName;
  SetFont(Self);
  Invalidate;
end;

{ ---------------------------------------------------------------------------
  Yardımcı: Ham yt-dlp/core.exe hata mesajını kullanıcı dostu metne dönüştür
  --------------------------------------------------------------------------- }
function TMainForm.FriendlyError(const RawMsg: string): string;
var
  msg, lo: string;
  p: Integer;
begin
  msg := Trim(RawMsg);
  if msg = '' then
  begin
    Result := T('error.unknown', 'An unexpected error occurred.');
    Exit;
  end;

  // "ERROR: " ön ekini temizle (yt-dlp bunu ekler)
  if Pos('ERROR:', msg) = 1 then
    msg := Trim(Copy(msg, 7, Length(msg)));
  // Birden fazla satır varsa sadece ilkini al
  p := Pos(#10, msg);
  if p > 0 then msg := Trim(Copy(msg, 1, p - 1));
  p := Pos(#13, msg);
  if p > 0 then msg := Trim(Copy(msg, 1, p - 1));

  lo := LowerCase(msg);

  // Yaygın hata kalıplarını kullanıcı dostu mesajlara çevir
  if (Pos('unsupported url', lo) > 0) or (Pos('is not a valid url', lo) > 0) then
    Result := T('error.unsupportedUrl', 'This link is not supported. Please check the URL and try again.')
  else if (Pos('video unavailable', lo) > 0) or (Pos('is not available', lo) > 0) then
    Result := T('error.unavailable', 'This video is not available. It may have been removed or is restricted in your region.')
  else if (Pos('private video', lo) > 0) then
    Result := T('error.private', 'This video is private and cannot be accessed.')
  else if (Pos('sign in', lo) > 0) or (Pos('login', lo) > 0) or (Pos('age', lo) > 0) then
    Result := T('error.loginRequired', 'This content requires sign-in or age verification.')
  else if (Pos('copyright', lo) > 0) then
    Result := T('error.copyright', 'This video has been removed due to a copyright claim.')
  else if (Pos('unable to extract', lo) > 0) or (Pos('no video formats', lo) > 0) then
    Result := T('error.extractFail', 'Could not extract video information. The link may be broken or the site is unsupported.')
  else if (Pos('timed out', lo) > 0) or (Pos('timeout', lo) > 0) then
    Result := T('error.timeout', 'Connection timed out. Please check your internet and try again.')
  else if (Pos('unable to download', lo) > 0) or (Pos('urlopen error', lo) > 0) or
          (Pos('connection', lo) > 0) or (Pos('network', lo) > 0) then
    Result := T('error.network', 'Network error. Please check your internet connection.')
  else if (Pos('not found', lo) > 0) or (Pos('404', lo) > 0) then
    Result := T('error.notFound', 'The page was not found (404). Please check the link.')
  else
  begin
    // Genel hata: mesajı 120 karakterle sınırla
    if Length(msg) > 120 then
      msg := Copy(msg, 1, 117) + '...';
    Result := msg;
  end;
end;

{ ---------------------------------------------------------------------------
  Yardımcı: URL'nin geçerli bir YouTube linki olup olmadığını tahmin et
  (Ağ isteği yapmadan, sadece metin kontrolü)
  --------------------------------------------------------------------------- }
function TMainForm.IsYouTubeUrl(const S: string): Boolean;
var lo: string;
begin
  lo := LowerCase(S);
  Result := (Pos('youtube.com/watch', lo) > 0) or
            (Pos('youtu.be/', lo) > 0) or
            (Pos('youtube.com/shorts/', lo) > 0) or
            (Pos('music.youtube.com/watch', lo) > 0) or
            (Pos('youtube.com/playlist', lo) > 0);
end;

{ ---------------------------------------------------------------------------
  Sessiz arka plan bilgi callback'i — sadece kuyruğa ekler, UI'ı değiştirmez
  --------------------------------------------------------------------------- }
procedure TMainForm.OnQuickAddInfo(const Info: TMediaInfo; const ErrMsg: string);
var
  it: TQueueItem;
  i, added: Integer;
  url: string;

  procedure AddOne(const ItemUrl, ItemTitle: string);
  var q: TQueueItem;
  begin
    q := TQueueItem.Create;
    q.Url         := ItemUrl;
    q.Title       := ItemTitle;
    if q.Title = '' then q.Title := ItemUrl;
    if FAudio then q.Kind := 'audio' else q.Kind := 'video';
    q.Quality     := SelectedQuality;
    q.VideoFormat := cmbVideoFormat.Text;
    q.AudioFormat := cmbAudioFormat.Text;
    q.Metadata    := chkInfo.Checked;
    q.Thumbnail   := chkInfo.Checked;
    q.OutDir      := EffectiveFolder;
    q.Uploader    := Info.Uploader;
    q.UploadDate  := Info.UploadDate;
    q.Description := '';
    q.Playlist    := False;
    q.Status      := qsWaiting;
    q.Percent     := 0;
    FQueue.Add(q);
    AddQueueRow(q);
    Inc(added);
  end;

begin
  url := Info.RequestUrl;   // edtUrl.Text yerine isteğin gerçek URL'si — yarış durumunu önler
  added := 0;

  if not Info.Ok then
  begin
    lblVideoTitle.Caption := T('msg.infoFail', 'Invalid or unsupported link.');
    MessageDlg(T('common.error', 'Error'),
               FriendlyError(ErrMsg),
               mtError, [mbOK], 0);
    Exit;
  end;

  if Info.IsPlaylist and (Length(Info.PlaylistItems) > 0) then
  begin
    for i := 0 to High(Info.PlaylistItems) do
    begin
      if (i <= High(Info.PlaylistUrls)) and (Info.PlaylistUrls[i] <> '') then
        AddOne(Info.PlaylistUrls[i], Info.PlaylistItems[i])
      else
        AddOne(url, Info.PlaylistItems[i]);
    end;
    lblVideoTitle.Caption := IntToStr(added) + ' ' + T('download.playlistDetected', 'tracks') + ' → ' + T('action.addQueue', 'ADD TO QUEUE') + ' ✓';
  end
  else
  begin
    it := TQueueItem.Create;
    it.Url         := url;
    it.Title       := Info.Title;
    if it.Title = '' then it.Title := url;
    if FAudio then it.Kind := 'audio' else it.Kind := 'video';
    it.Quality     := SelectedQuality;
    it.VideoFormat := cmbVideoFormat.Text;
    it.AudioFormat := cmbAudioFormat.Text;
    it.Metadata    := chkInfo.Checked;
    it.Thumbnail   := chkInfo.Checked;
    it.OutDir      := EffectiveFolder;
    it.Uploader    := Info.Uploader;
    it.UploadDate  := Info.UploadDate;
    it.Description := Info.Description;
    it.Playlist    := False;
    it.Status      := qsWaiting;
    it.Percent     := 0;
    FQueue.Add(it);
    AddQueueRow(it);
    lblVideoTitle.Caption := '"' + it.Title + '"  ' + T('action.addQueue', 'ADD TO QUEUE') + ' ✓';
  end;
end;

{ ---------------------------------------------------------------------------
  Dil uygulama
  --------------------------------------------------------------------------- }
procedure TMainForm.SetupColumns;
begin
  if lvQueue.Columns.Count = 0 then begin lvQueue.Columns.Add; lvQueue.Columns.Add; end;
  lvQueue.Columns[0].Caption := T('queue.colTitle', 'Title');  lvQueue.Columns[0].Width := 470;
  lvQueue.Columns[1].Caption := T('queue.colStatus', 'Status'); lvQueue.Columns[1].Width := 170;

  if lvHistory.Columns.Count = 0 then
  begin lvHistory.Columns.Add; lvHistory.Columns.Add; lvHistory.Columns.Add; end;
  lvHistory.Columns[0].Caption := T('history.colTitle', 'Title');  lvHistory.Columns[0].Width := 350;
  lvHistory.Columns[1].Caption := T('history.colDate', 'Date');    lvHistory.Columns[1].Width := 130;
  lvHistory.Columns[2].Caption := T('history.colStatus', 'Status'); lvHistory.Columns[2].Width := 160;
end;

procedure TMainForm.ApplyLanguage;
begin
  Caption := 'EasyDownload';
  if applang.CurrentLangDir = 'rtl' then BiDiMode := bdRightToLeft
  else BiDiMode := bdLeftToRight;

  // ayarlar butonu
  btnSettings.Caption := T('menu.settings', 'Settings');

  // ana sekmeler
  tsDownload.Caption := T('nav.download', 'Download');
  tsQueue.Caption    := T('nav.queue', 'Queue');
  tsHistory.Caption  := T('nav.history', 'History');
  tsAbout.Caption    := T('menu.about', 'About');
  tsMaker.Caption    := T('menu.maker', 'Maker');

  // İndir sekmesi
  lblLink.Caption    := T('ui.link', 'Link:');
  edtUrl.TextHint    := T('download.urlPlaceholder', '');
  lblFolder.Caption  := T('ui.folder', 'Folder:');
  btnBrowse.Caption  := T('ui.browse', '...');
  if not FHasInfo then lblVideoTitle.Caption := T('ui.videoTitle', 'Video Title');
  pnlSearch.Caption  := T('ui.search', 'SEARCH');
  tsVideo.Caption    := T('tab.video', 'Video');
  tsAudio.Caption    := T('tab.audio', 'Audio');
  lblRes.Caption     := T('ui.resolution', 'Resolution:');
  lblFmtV.Caption    := T('ui.format', 'Format:');
  lblFmtA.Caption    := T('ui.format', 'Format:');
  chkInfo.Caption    := T('ui.embedInfo', 'Embed info');
  if cmbResolution.Items.Count > 0 then
    cmbResolution.Items[0] := T('quality.best', 'Best quality');

  // Aksiyon butonları
  btnDownloadNow.Caption := T('action.downloadNow', 'DOWNLOAD');
  btnAddQueue.Caption    := T('action.addQueue', 'ADD TO QUEUE');
  if FEngine.Paused then
    btnPause.Caption := T('action.resume', 'Resume')
  else
    btnPause.Caption := T('action.pause', 'Pause');
  btnCancel.Caption := T('action.cancel', 'Cancel Download');

  // Sıra
  btnQueueRemove.Caption := T('queue.remove', 'Remove');
  btnQueueClear.Caption  := T('queue.clear', 'Clear all');
  btnQueueStart.Caption  := T('queue.start', 'Start Queue');

  // Geçmiş
  btnHistoryRetry.Caption := T('history.retry', 'Download again');
  btnHistoryOpen.Caption  := T('history.openFolder', 'Open location');
  btnHistoryClear.Caption := T('history.clear', 'Clear history');

  // Hakkında
  lblAboutTitle.Caption   := 'EasyDownload';
  lblAboutVersion.Caption := T('about.version', 'Version') + ' ' + AppVersion;
  lblAboutDesc.Caption    := T('about.desc', '');
  lblAboutPowered.Caption := T('about.powered', '');
  lblAboutLicense.Caption := T('about.license', 'Open-source software. Uses yt-dlp and FFmpeg.');

  // Yapımcı
  lblMakerTitle.Caption     := T('menu.maker', 'Maker');
  lblMakerSignature.Caption := T('maker.signature', 'p4rs');
  lblMakerContact.Caption   := T('maker.text', 'EasyDownload project');
  lblAppSite.Caption        := T('maker.appSite', 'App Website');
  lblMakerSite.Caption      := T('maker.makerSite', 'Maker Website');

  // Özel sekme şeritlerini yeni başlıklara göre yeniden boyutlandır + renklendir
  if Length(FMainTabs) > 0 then LayoutTabStrip(pcMain, FMainTabs);
  if Length(FTypeTabs) > 0 then LayoutTabStrip(pcType, FTypeTabs);
  RefreshTabStrips;

  SetupColumns;
  RefreshQueueTexts;
  RefreshHistory;
end;

{ ---------------------------------------------------------------------------
  Durum yönetimi — ARA, aksiyon butonları, indirme kontrolleri
  --------------------------------------------------------------------------- }
procedure TMainForm.SetSearchMode;
begin
  FHasInfo := False;
  pnlSearch.Caption := T('ui.search', 'SEARCH');
  pnlSearch.Enabled := True;
  ClearThumbArea;
  UpdateActionButtons;
end;

procedure TMainForm.UpdateActionButtons;
begin
  btnDownloadNow.Enabled := FHasInfo;
  // SIRAYA EKLE: bilgi zaten varıysa düz etkinleştir;
  // yoksa geçerli görünen YT URL varsa da etkinleştir (arka planda fetch yapacağız)
  btnAddQueue.Enabled := FHasInfo or IsYouTubeUrl(Trim(edtUrl.Text));
end;

procedure TMainForm.ShowDownloadControls(AShow: Boolean);
begin
  btnPause.Visible := AShow;
  btnCancel.Visible := AShow;
  if AShow then
  begin
    if FEngine.Paused then
      btnPause.Caption := T('action.resume', 'Resume')
    else
      btnPause.Caption := T('action.pause', 'Pause');
  end;
end;

function TMainForm.SelectedQuality: string;
begin
  if (cmbResolution.ItemIndex >= 0) and (cmbResolution.ItemIndex <= High(QualityValues)) then
    Result := QualityValues[cmbResolution.ItemIndex]
  else
    Result := 'best';
end;

procedure TMainForm.SetQualityByValue(const V: string);
var i: Integer;
begin
  for i := 0 to High(QualityValues) do
    if SameText(QualityValues[i], V) then begin cmbResolution.ItemIndex := i; Exit; end;
  cmbResolution.ItemIndex := 0;
end;

procedure TMainForm.SetComboByText(Cmb: TComboBox; const V: string);
var i: Integer;
begin
  for i := 0 to Cmb.Items.Count - 1 do
    if SameText(Cmb.Items[i], V) then begin Cmb.ItemIndex := i; Exit; end;
  if Cmb.Items.Count > 0 then Cmb.ItemIndex := 0;
end;

procedure TMainForm.pcTypeChange(Sender: TObject);
begin
  if pcType.ActivePage = tsVideo then FAudio := False
  else if pcType.ActivePage = tsAudio then FAudio := True;
end;

procedure TMainForm.edtUrlChange(Sender: TObject);
begin
  if Trim(edtUrl.Text) <> FInfoUrl then SetSearchMode;
  // URL değişirse SIRAYA EKLE butonunu URL geçerliliğine göre güncelle
  UpdateActionButtons;
end;

procedure TMainForm.btnBrowseClick(Sender: TObject);
var dir: string;
begin
  dir := '';
  if SelectDirectory(T('ui.folder', 'Folder'), edtFolder.Text, dir) then
    if dir <> '' then edtFolder.Text := dir;
end;

{ ---------------------------------------------------------------------------
  Kapak resmi & Playlist kutusu
  --------------------------------------------------------------------------- }
procedure TMainForm.ClearThumbArea;
begin
  if FPlaylistBox <> nil then FreeAndNil(FPlaylistBox);
  imgThumb.Picture.Clear;
  imgThumb.Visible := True;
end;

procedure TMainForm.LoadThumbnail(const Path: string);
begin
  if (Path = '') or (not FileExists(Path)) then Exit;
  try
    imgThumb.Picture.LoadFromFile(Path);
    imgThumb.Visible := True;
  except
    // desteklenmeyen format — sorun değil
  end;
end;

procedure TMainForm.BuildPlaylistBox;
var i: Integer;
begin
  if FPlaylistBox <> nil then FreeAndNil(FPlaylistBox);
  imgThumb.Visible := False;

  FPlaylistBox := TCheckListBox.Create(pnlThumb);
  FPlaylistBox.Parent := pnlThumb;
  FPlaylistBox.Align := alClient;
  FPlaylistBox.Font.Name := 'Segoe UI';
  FPlaylistBox.Font.Height := -12;

  for i := 0 to High(FInfo.PlaylistItems) do
  begin
    FPlaylistBox.Items.Add(FInfo.PlaylistItems[i]);
    FPlaylistBox.Checked[i] := True;   // hepsi seçili başlar
  end;

  thememanager.ApplyThemeToControl(FPlaylistBox, thememanager.CurrentTheme);
end;

procedure TMainForm.DetectYouTubeMusic(const Url: string);
begin
  if Pos('music.youtube.com', LowerCase(Url)) > 0 then
  begin
    pcType.ActivePageIndex := 1;   // Audio sekmesi
    FAudio := True;
    RefreshTabStrips;
  end;
end;

{ ---------------------------------------------------------------------------
  ARA düğmesi: HER ZAMAN sadece bilgi getirir
  --------------------------------------------------------------------------- }
procedure TMainForm.btnSearchClick(Sender: TObject);
var url: string;
begin
  url := Trim(edtUrl.Text);
  if url = '' then
  begin
    lblVideoTitle.Caption := T('msg.needLink', 'Please paste a link first.');
    Exit;
  end;
  if not FEngine.CoreExists then
  begin
    lblVideoTitle.Caption := T('msg.noEngine', 'core.exe not found.');
    Exit;
  end;

  // Aynı URL için tekrar aramaya gerek yok
  if FHasInfo and (FInfoUrl = url) then Exit;

  DoSearch(url);
end;

procedure TMainForm.DoSearch(const Url: string);
begin
  FHasInfo := False;
  ClearThumbArea;
  UpdateActionButtons;
  lblVideoTitle.Caption := T('msg.loading', 'Reading link...');
  pnlSearch.Enabled := False;

  // YouTube Music algılama — arama başlamadan önce
  DetectYouTubeMusic(Url);

  FPendingSearchUrl := Url;        // bu, en güncel istek olarak işaretlenir
  FEngine.FetchInfo(Url, @OnInfo);
end;

procedure TMainForm.OnInfo(const Info: TMediaInfo; const ErrMsg: string);
begin
  // Bu sonuç, kullanıcının daha sonra başlattığı yeni bir arama tarafından
  // geride bırakıldıysa (eski isteğin yanıtı) yoksay.
  if Info.RequestUrl <> FPendingSearchUrl then Exit;

  pnlSearch.Enabled := True;

  if not Info.Ok then
  begin
    SetSearchMode;
    lblVideoTitle.Caption := T('msg.infoFail', 'Could not read this link.');
    MessageDlg(T('common.error', 'Error'),
               FriendlyError(ErrMsg),
               mtError, [mbOK], 0);
    Exit;
  end;

  FInfo := Info;
  FInfoUrl := Trim(edtUrl.Text);
  FHasInfo := True;

  if Info.IsPlaylist then
  begin
    lblVideoTitle.Caption := '[' + T('download.playlistDetected', 'Playlist') + '] ' + Info.Title;
    BuildPlaylistBox;
  end
  else
  begin
    lblVideoTitle.Caption := Info.Title;
    // Kapak resmini yükle
    if Info.ThumbPath <> '' then
      LoadThumbnail(Info.ThumbPath);
  end;

  UpdateActionButtons;
end;

{ ---------------------------------------------------------------------------
  Aksiyon butonları: İNDİR / SIRAYA EKLE
  --------------------------------------------------------------------------- }
procedure TMainForm.btnDownloadNowClick(Sender: TObject);
var url: string;
begin
  url := Trim(edtUrl.Text);
  if (url = '') or (not FHasInfo) then Exit;
  EnqueueCurrent(url, True);   // AutoStart = True → hemen indir
end;

procedure TMainForm.btnAddQueueClick(Sender: TObject);
var url: string;
begin
  url := Trim(edtUrl.Text);
  if url = '' then Exit;

  // Hızlı yol: bu URL için bilgi zaten alındıysa hemen kuyruğa ekle
  if FHasInfo and (FInfoUrl = url) then
  begin
    EnqueueCurrent(url, False);
    Exit;
  end;

  // Geçerli YT linki: arka planda sessiz fetch yap, UI'yı kilitlemeden
  if not IsYouTubeUrl(url) then
  begin
    lblVideoTitle.Caption := T('msg.infoFail', 'Invalid or unsupported link.');
    Exit;
  end;
  if not FEngine.CoreExists then
  begin
    lblVideoTitle.Caption := T('msg.noEngine', 'core.exe not found.');
    Exit;
  end;

  // pnlSearch durumuna dokunmadan arka planda bilgi alınıyor
  lblVideoTitle.Caption := T('msg.loading', 'Adding to queue...');
  FEngine.FetchInfo(url, @OnQuickAddInfo);
end;

{ ---------------------------------------------------------------------------
  Duraklat / İptal butonları
  --------------------------------------------------------------------------- }
procedure TMainForm.btnPauseClick(Sender: TObject);
begin
  if FEngine.Paused then
  begin
    FEngine.Resume;
    btnPause.Caption := T('action.pause', 'Pause');
  end
  else
  begin
    FEngine.Pause;
    btnPause.Caption := T('action.resume', 'Resume');
  end;
end;

procedure TMainForm.btnCancelClick(Sender: TObject);
begin
  FEngine.Cancel;
  ShowDownloadControls(False);
end;

{ ---------------------------------------------------------------------------
  Kuyruk
  --------------------------------------------------------------------------- }
function TMainForm.StatusText(Item: TQueueItem): string;
begin
  case Item.Status of
    qsWaiting:  Result := T('queue.status.waiting', 'Waiting');
    qsRunning:  Result := T('queue.status.running', 'Downloading') + '  %' + IntToStr(Item.Percent);
    qsDone:     Result := T('queue.status.done', 'Done');
    qsError:    Result := T('queue.status.error', 'Error');
    qsCanceled: Result := T('msg.canceled', 'Canceled');
  else
    Result := '';
  end;
end;

procedure TMainForm.AddQueueRow(Item: TQueueItem);
var li: TListItem;
begin
  li := lvQueue.Items.Add;
  li.Caption := Item.Title;
  li.SubItems.Add(StatusText(Item));
end;

procedure TMainForm.UpdateQueueRow(Idx: Integer);
var it: TQueueItem;
begin
  if (Idx < 0) or (Idx >= lvQueue.Items.Count) or (Idx >= FQueue.Count) then Exit;
  it := TQueueItem(FQueue[Idx]);
  lvQueue.Items[Idx].Caption := it.Title;
  if lvQueue.Items[Idx].SubItems.Count = 0 then
    lvQueue.Items[Idx].SubItems.Add(StatusText(it))
  else
    lvQueue.Items[Idx].SubItems[0] := StatusText(it);
end;

procedure TMainForm.UpdateActiveRow;
var idx: Integer;
begin
  if FActiveItem = nil then Exit;
  idx := FQueue.IndexOf(FActiveItem);
  if idx >= 0 then UpdateQueueRow(idx);
end;

procedure TMainForm.RefreshQueueTexts;
var i: Integer;
begin
  for i := 0 to FQueue.Count - 1 do UpdateQueueRow(i);
end;

procedure TMainForm.EnqueueCurrent(const Url: string; AutoStart: Boolean);
var
  it: TQueueItem;
  i: Integer;
  isPlaylist: Boolean;
  info: TMediaInfo;
  itemUploader: string;

  procedure AddItem(const ItemUrl, ItemTitle, ItemUploader: string);
  var q: TQueueItem;
  begin
    q := TQueueItem.Create;
    q.Url         := ItemUrl;
    q.Title       := ItemTitle;
    if q.Title = '' then q.Title := ItemUrl;
    if FAudio then q.Kind := 'audio' else q.Kind := 'video';
    q.Quality     := SelectedQuality;
    q.VideoFormat := cmbVideoFormat.Text;
    q.AudioFormat := cmbAudioFormat.Text;
    q.Metadata    := chkInfo.Checked;
    q.Thumbnail   := chkInfo.Checked;
    q.OutDir      := EffectiveFolder;
    q.Uploader    := ItemUploader;  // bu parçanın kendi yükleyicisi (playlist sahibi DEĞİL)
    q.UploadDate  := info.UploadDate;
    q.Description := '';   // parça düzeyinde açıklama yok
    q.Playlist    := False; // her parça tek tek indirilecek
    q.Status      := qsWaiting;
    q.Percent     := 0;
    FQueue.Add(q);
    AddQueueRow(q);
  end;

begin
  isPlaylist := FHasInfo and (FInfoUrl = Url) and FInfo.IsPlaylist;
  if FHasInfo and (FInfoUrl = Url) then
    info := FInfo
  else
    info := Default(TMediaInfo);

  if isPlaylist and (Length(FInfo.PlaylistItems) > 0) then
  begin
    // Her parçayı ayrı öğe olarak ekle
    for i := 0 to High(FInfo.PlaylistItems) do
    begin
      // Bu parçanın kendi yükleyicisi (yoksa boş bırak; playlist sahibinin
      // adı SANATÇI olarak yazılmasın)
      if i <= High(FInfo.PlaylistUploaders) then
        itemUploader := FInfo.PlaylistUploaders[i]
      else
        itemUploader := '';

      // URL: önce PlaylistUrls'den al, yoksa master URL'yi kullan
      if (i <= High(FInfo.PlaylistUrls)) and (FInfo.PlaylistUrls[i] <> '') then
        AddItem(FInfo.PlaylistUrls[i], FInfo.PlaylistItems[i], itemUploader)
      else
        AddItem(Url, FInfo.PlaylistItems[i], itemUploader);  // fallback: master URL (yt-dlp sırayı bilir)
    end;
  end
  else
  begin
    // Tekli video — eski davranış
    it := TQueueItem.Create;
    it.Url         := Url;
    it.Title       := info.Title;
    if it.Title = '' then it.Title := Url;
    if FAudio then it.Kind := 'audio' else it.Kind := 'video';
    it.Quality     := SelectedQuality;
    it.VideoFormat := cmbVideoFormat.Text;
    it.AudioFormat := cmbAudioFormat.Text;
    it.Metadata    := chkInfo.Checked;
    it.Thumbnail   := chkInfo.Checked;
    it.OutDir      := EffectiveFolder;
    it.Uploader    := info.Uploader;
    it.UploadDate  := info.UploadDate;
    it.Description := info.Description;
    it.Playlist    := False;
    it.Status      := qsWaiting;
    it.Percent     := 0;
    FQueue.Add(it);
    AddQueueRow(it);
  end;

  SetSearchMode;                  // bir sonraki için tekrar "ARA"

  if AutoStart then
    ProcessQueue                  // hemen başlat
  else
  begin
    pcMain.ActivePage := tsQueue; // kuyruğu göster
    RefreshTabStrips;
  end;
end;


procedure TMainForm.ProcessQueue;
var i, idx: Integer; it: TQueueItem; req: TDownloadRequest;
begin
  if FEngine.Busy then Exit;

  idx := -1;
  for i := 0 to FQueue.Count - 1 do
    if TQueueItem(FQueue[i]).Status = qsWaiting then begin idx := i; Break; end;
  if idx < 0 then Exit;

  it := TQueueItem(FQueue[idx]);
  it.Status := qsRunning;
  it.Percent := 0;
  FActiveItem := it;
  FActiveResult := '';
  UpdateQueueRow(idx);

  pbProgress.Style := pbstMarquee;
  pbProgress.Position := 0;
  lblPercent.Caption := '%0';
  ShowDownloadControls(True);

  req := Default(TDownloadRequest);
  req.Url := it.Url;
  req.Kind := it.Kind;
  req.Quality := it.Quality;
  req.VideoFormat := it.VideoFormat;
  req.AudioFormat := it.AudioFormat;
  req.Metadata := it.Metadata;
  req.Thumbnail := it.Thumbnail;
  req.OutDir := it.OutDir;
  req.Title := it.Title;
  req.Uploader := it.Uploader;
  req.UploadDate := it.UploadDate;
  req.Description := it.Description;
  req.Playlist := it.Playlist;

  FEngine.StartDownload(req, @OnEngineLine, @OnEngineDone);
end;

procedure TMainForm.btnQueueRemoveClick(Sender: TObject);
var i: Integer; it: TQueueItem;
begin
  i := lvQueue.ItemIndex;
  if (i < 0) or (i >= FQueue.Count) then Exit;
  it := TQueueItem(FQueue[i]);
  if it.Status = qsRunning then Exit;   // çalışan iş kaldırılamaz
  FQueue.Delete(i);
  it.Free;
  lvQueue.Items.Delete(i);
end;

procedure TMainForm.btnQueueClearClick(Sender: TObject);
var i: Integer; it: TQueueItem;
begin
  i := 0;
  while i < FQueue.Count do
  begin
    it := TQueueItem(FQueue[i]);
    if it.Status <> qsRunning then
    begin
      FQueue.Delete(i);
      it.Free;
      lvQueue.Items.Delete(i);
    end
    else
      Inc(i);
  end;
end;

procedure TMainForm.btnQueueStartClick(Sender: TObject);
begin
  ProcessQueue;
end;

{ ---------------------------------------------------------------------------
  Geçmiş
  --------------------------------------------------------------------------- }
function TMainForm.HistoryStatusText(const Code: string): string;
begin
  if Code = 'done' then Result := T('queue.status.done', 'Done')
  else if Code = 'error' then Result := T('queue.status.error', 'Error')
  else Result := Code;
end;

procedure TMainForm.RefreshHistory;
var i: Integer; li: TListItem;
begin
  if FEngine = nil then Exit;
  FHistory := FEngine.LoadHistory;
  lvHistory.Items.BeginUpdate;
  try
    lvHistory.Items.Clear;
    for i := 0 to High(FHistory) do
    begin
      li := lvHistory.Items.Add;
      li.Caption := FHistory[i].Title;
      li.SubItems.Add(FHistory[i].Date);
      li.SubItems.Add(HistoryStatusText(FHistory[i].Status));
    end;
  finally
    lvHistory.Items.EndUpdate;
  end;
end;

procedure TMainForm.btnHistoryRetryClick(Sender: TObject);
var i: Integer;
begin
  i := lvHistory.ItemIndex;
  if (i < 0) or (i > High(FHistory)) then Exit;
  edtUrl.Text := FHistory[i].Url;
  pcMain.ActivePage := tsDownload;
  RefreshTabStrips;
  SetSearchMode;
  edtUrl.SetFocus;
end;

procedure TMainForm.btnHistoryOpenClick(Sender: TObject);
var i: Integer; f: string;
begin
  i := lvHistory.ItemIndex;
  if (i < 0) or (i > High(FHistory)) then Exit;
  f := FHistory[i].FilePath;
  if (f <> '') and DirectoryExists(ExtractFilePath(f)) then
    OpenDocument(ExtractFilePath(f));
end;

procedure TMainForm.btnHistoryClearClick(Sender: TObject);
begin
  if FileExists(FEngine.HistoryFile) then SysUtils.DeleteFile(FEngine.HistoryFile);
  RefreshHistory;
end;

{ ---------------------------------------------------------------------------
  Ayarlar butonu + Yapımcı link butonları
  --------------------------------------------------------------------------- }
procedure TMainForm.btnSettingsClick(Sender: TObject);
begin
  if FrmSettings = nil then
  begin
    FrmSettings := TSettingsForm.Create(Self);
    thememanager.ApplyThemeToForm(FrmSettings, thememanager.CurrentTheme);
  end;
  FrmSettings.OpenDialog;
end;

procedure TMainForm.lblAppSiteClick(Sender: TObject);
begin
  OpenURL('https://easydownload.net');
end;

procedure TMainForm.lblMakerSiteClick(Sender: TObject);
begin
  OpenURL('https://p4rs.com');
end;

procedure TMainForm.pcMainChange(Sender: TObject);
begin
  if pcMain.ActivePage = tsHistory then RefreshHistory;
end;

{ ---------------------------------------------------------------------------
  Motor olay akışı
  --------------------------------------------------------------------------- }
procedure TMainForm.OnEngineLine(const JsonLine: string);
begin
  HandleEvent(JsonLine);
end;

procedure TMainForm.OnEngineDone;
var idx: Integer;
begin
  if FActiveItem <> nil then
  begin
    if FActiveResult = 'done' then begin FActiveItem.Status := qsDone; FActiveItem.Percent := 100; end
    else if FActiveResult = 'error' then FActiveItem.Status := qsError
    else if FActiveResult = 'canceled' then FActiveItem.Status := qsCanceled
    else FActiveItem.Status := qsDone;

    if FActiveResult = 'done' then
      FEngine.AddHistory(FActiveItem.Title, FActiveItem.Url, FLastFile, 'done')
    else if FActiveResult = 'error' then
      FEngine.AddHistory(FActiveItem.Title, FActiveItem.Url, '', 'error');

    // Tamamlanan/hatalı/iptal edilen iş kuyruktan kaldırılır — sadece
    // bekleyen/aktif işler listede kalır
    idx := FQueue.IndexOf(FActiveItem);
    if idx >= 0 then
    begin
      FQueue.Delete(idx);
      lvQueue.Items.Delete(idx);
    end;
    FActiveItem.Free;
    FActiveItem := nil;

    RefreshHistory;
  end;

  pbProgress.Style := pbstNormal;
  ShowDownloadControls(False);
  ProcessQueue;   // sıradaki işi başlat
end;

procedure TMainForm.HandleEvent(const Line: string);
var
  Data: TJSONData; O: TJSONObject;
  ev, stage: string; pd: TJSONData; pct: Double;
begin
  Data := nil;
  try
    try Data := GetJSON(Line); except Exit; end;
    if not (Data is TJSONObject) then Exit;
    O := TJSONObject(Data);
    ev := OStr(O, 'event');

    if ev = 'started' then
    begin
      pbProgress.Style := pbstMarquee;
      pbProgress.Position := 0;
      lblPercent.Caption := '%0';
    end
    else if ev = 'stage' then
    begin
      stage := OStr(O, 'stage');
      if (stage = 'merge') or (stage = 'move') then pbProgress.Style := pbstMarquee
      else pbProgress.Style := pbstNormal;
    end
    else if ev = 'progress' then
    begin
      pd := O.Find('percent');
      if (pd <> nil) and (pd.JSONType = jtNumber) then
      begin
        pct := pd.AsFloat;
        if pct < 0 then pct := 0 else if pct > 100 then pct := 100;
        pbProgress.Style := pbstNormal;
        pbProgress.Position := Round(pct);
        lblPercent.Caption := Format('%%%d', [Round(pct)]);
        if FActiveItem <> nil then
        begin
          FActiveItem.Percent := Round(pct);
          UpdateActiveRow;
        end;
      end
      else
        pbProgress.Style := pbstMarquee;
    end
    else if ev = 'done' then
    begin
      FLastFile := OStr(O, 'file');
      FActiveResult := 'done';
      pbProgress.Style := pbstNormal;
      pbProgress.Position := 100;
      lblPercent.Caption := '%100';
    end
    else if ev = 'error' then
    begin
      FActiveResult := 'error';
      pbProgress.Style := pbstNormal;
      pbProgress.Position := 0;
      lblPercent.Caption := '%0';
      lblVideoTitle.Caption := T('msg.failed', 'Failed.');
      MessageDlg(T('common.error', 'Error'),
                 FriendlyError(OStr(O, 'message')),
                 mtError, [mbOK], 0);
    end
    else if ev = 'canceled' then
    begin
      FActiveResult := 'canceled';
      pbProgress.Style := pbstNormal;
      pbProgress.Position := 0;
      lblPercent.Caption := '%0';
    end;
  finally
    Data.Free;
  end;
end;

end.
