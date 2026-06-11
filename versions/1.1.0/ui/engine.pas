unit engine;

{ ============================================================================
  EasyDownload — Motor köprüsü (core.exe ile konuşan katman)

  Eski C# "EngineClient.cs" sınıfının yaptığı işi devralır:
    * core.exe'yi TProcess ile başlatır (gizli pencere, pipe ile stdout okur).
    * 'info' komutuyla yt-dlp -J JSON'unu alıp UI'ın ihtiyacı olan birkaç
      alana indirger (ParseMediaInfo).
    * 'run' komutuyla indirmeyi başlatır; core.exe'nin her satırda bastığı
      JSON olaylarını (started/stage/progress/done/error) ana iş parçacığına
      aktarır.
    * Meta veri gömülecekse 'meta.ffmeta' dosyasını (UTF-8, BOM'suz) yazar.
    * İptal: süreç ağacını taskkill ile (core.exe + yt-dlp + ffmpeg) kapatır.

  Tüm geri çağırımlar (callback) ANA İŞ PARÇACIĞINDA çalışır (Synchronize),
  böylece doğrudan arayüz bileşenlerine dokunmak güvenlidir.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, fpjson, jsonparser;

type
  // core.exe info çıktısının sadeleştirilmiş hâli
  TMediaInfo = record
    Ok: Boolean;
    IsPlaylist: Boolean;
    Title: string;
    Uploader: string;
    UploadDate: string;   // yt-dlp formatı: YYYYMMDD
    Description: string;
    Thumbnail: string;    // uzak görsel URL'si
    ThumbPath: string;    // indirilen kapak dosya yolu
    Duration: Double;     // saniye
    Count: Integer;       // playlist parça sayısı
    PlaylistItems: array of string;  // playlist video başlıkları
    PlaylistUrls:  array of string;  // playlist video URL'leri (her bir parça için)
    PlaylistUploaders: array of string; // her parçanın kendi yükleyicisi (boşsa playlist sahibinin adı kullanılmaz)
    Url: string;          // kanonik bağlantı
    RequestUrl: string;   // FetchInfo'ya verilen orijinal URL (yarışan istekleri ayırt etmek için)
  end;

  // Bir indirme isteğinin tüm parametreleri
  TDownloadRequest = record
    Url: string;
    Kind: string;          // 'video' | 'audio'
    Quality: string;       // 'best' | '2160' | '1440' | '1080' | '720' | '480' | '360'
    VideoFormat: string;   // 'mp4' | 'mkv'
    AudioFormat: string;   // 'mp3' | 'm4a' | 'opus' | 'flac'
    Metadata: Boolean;
    Thumbnail: Boolean;
    Playlist: Boolean;
    OutDir: string;
    // meta veri gömme için (info'dan gelir; boş olabilir)
    Title: string;
    Uploader: string;
    UploadDate: string;
    Description: string;
  end;

  // Geçmiş kaydı (data/history.json)
  THistoryEntry = record
    Title: string;
    Url: string;
    FilePath: string;
    Status: string;   // 'done' | 'error'
    Date: string;     // 'yyyy-mm-dd hh:nn'
  end;
  THistoryArray = array of THistoryEntry;

  // Olay geri çağırımları — HEPSİ ana iş parçacığında tetiklenir
  TInfoCallback    = procedure(const Info: TMediaInfo; const ErrMsg: string) of object;
  TEngineLineEvent = procedure(const JsonLine: string) of object;
  TEngineDoneEvent = procedure of object;

  { TEngine }

  TEngine = class
  private
    FAppDir: string;            // çalışma kökü (versions/1.0.0b), sonunda PathDelim
    FDownloadThread: TThread;   // o an aktif indirme (tek seferde bir tane)
    FPaused: Boolean;
    function GetBusy: Boolean;
  public
    constructor Create(const AAppDir: string);

    function CoreExe: string;   // <kök>\core.exe
    function BinDir: string;    // <kök>\bin
    function TempDir: string;   // <kök>\temp
    function CoreExists: Boolean;
    property AppDir: string read FAppDir;

    // URL'yi çöz (asenkron). Bittiğinde OnDone ana iş parçacığında çağrılır.
    procedure FetchInfo(const Url: string; OnDone: TInfoCallback);

    // İndirmeyi başlat (asenkron). OnLine her JSON satırında, OnFinished bitişte.
    procedure StartDownload(const Req: TDownloadRequest;
                            OnLine: TEngineLineEvent; OnFinished: TEngineDoneEvent);

    procedure Cancel;          // aktif indirmeyi durdur
    procedure Pause;           // askıya al (NtSuspendProcess)
    procedure Resume;          // devam ettir (NtResumeProcess)
    property Busy: Boolean read GetBusy;
    property Paused: Boolean read FPaused;

    // geçmiş (data/history.json)
    function HistoryFile: string;
    procedure AddHistory(const ATitle, AUrl, AFilePath, AStatus: string);
    function LoadHistory: THistoryArray;
  end;

// Yardımcılar (dışarıdan da kullanılabilir)
function ParseMediaInfo(const Raw, InputUrl: string; out ErrMsg: string): TMediaInfo;
function SanitizeFileName(const S: string): string;

implementation

uses
  Math, FileUtil, LazFileUtils
  {$IFDEF WINDOWS}, Windows{$ENDIF};

const
  MaxDescription = 4000;
  ReadBufSize    = 8192;

{ ---------------------------------------------------------------------------
  Dosyayı UTF-8 metin olarak oku (varsa BOM'u at) — history.json için
  --------------------------------------------------------------------------- }
function ReadFileToStringUtf8(const FileName: string): string;
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

{ ---------------------------------------------------------------------------
  Küçük JSON yardımcıları
  --------------------------------------------------------------------------- }
function JStr(O: TJSONObject; const Name: string; const Def: string = ''): string;
var d: TJSONData;
begin
  if O = nil then Exit(Def);
  d := O.Find(Name);
  if (d <> nil) and (d.JSONType = jtString) then Result := d.AsString else Result := Def;
end;

function JNum(O: TJSONObject; const Name: string): Double;
var d: TJSONData;
begin
  Result := 0;
  if O = nil then Exit;
  d := O.Find(Name);
  if (d <> nil) and (d.JSONType = jtNumber) then Result := d.AsFloat;
end;

function FirstNonEmpty(const A, B: string): string; overload;
begin if Trim(A) <> '' then Result := A else Result := B; end;

function FirstNonEmpty(const A, B, C: string): string; overload;
begin
  if Trim(A) <> '' then Result := A
  else if Trim(B) <> '' then Result := B
  else Result := C;
end;

function FirstNonEmpty(const A, B, C, D: string): string; overload;
begin
  if Trim(A) <> '' then Result := A
  else if Trim(B) <> '' then Result := B
  else if Trim(C) <> '' then Result := C
  else Result := D;
end;

// --flat-playlist girdileri için 'url'/'id' genelde tam URL değil, sadece
// video ID'sidir (örn. "dQw4w9WgXcQ"). core.exe/yt-dlp'nin kabul edeceği
// bir bağlantı haline getirmek için tam izleme URL'sine çevir.
function ToFullUrl(const S: string): string;
begin
  if (S = '') or (Pos('://', S) > 0) then Result := S
  else Result := 'https://www.youtube.com/watch?v=' + S;
end;

function PickUploader(O: TJSONObject): string;
begin
  Result := FirstNonEmpty(JStr(O, 'uploader'), JStr(O, 'channel'),
                          JStr(O, 'creator'), JStr(O, 'uploader_id'));
end;

function PickThumbnail(O: TJSONObject): string;
var arr: TJSONData; i: Integer; u: string;
begin
  Result := JStr(O, 'thumbnail');
  if Result <> '' then Exit;
  arr := O.Find('thumbnails');
  if (arr <> nil) and (arr.JSONType = jtArray) then
    for i := 0 to TJSONArray(arr).Count - 1 do
      if TJSONArray(arr).Items[i].JSONType = jtObject then
      begin
        u := JStr(TJSONObject(TJSONArray(arr).Items[i]), 'url');
        if u <> '' then Result := u;   // en sondaki genelde en yüksek kalite
      end;
end;

{ ---------------------------------------------------------------------------
  Dosya adı temizleme (EngineClient.SanitizeFileName eşdeğeri)
  --------------------------------------------------------------------------- }
function SanitizeFileName(const S: string): string;
const Invalid = '\/:*?"<>|' + #13 + #10 + #9;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    if Pos(c, Invalid) > 0 then Result := Result + '_' else Result := Result + c;
  end;
  Result := Trim(Result);
  while (Result <> '') and (Result[Length(Result)] in ['.', ' ']) do
    SetLength(Result, Length(Result) - 1);
  if Length(Result) > 150 then Result := Trim(Copy(Result, 1, 150));
  if Result = '' then Result := 'download';
end;

{ ---------------------------------------------------------------------------
  yt-dlp -J JSON'unu sadeleştir (InfoParser.cs eşdeğeri)
  --------------------------------------------------------------------------- }
function ParseMediaInfo(const Raw, InputUrl: string; out ErrMsg: string): TMediaInfo;
var
  data: TJSONData;
  root, first: TJSONObject;
  entries: TJSONData;
  t, desc: string;
  i: Integer;
  isList: Boolean;
begin
  ErrMsg := '';
  Result := Default(TMediaInfo);
  Result.Ok := False;
  Result.Count := 1;
  Result.Url := InputUrl;
  Result.RequestUrl := InputUrl;

  if Trim(Raw) = '' then begin ErrMsg := 'empty info output'; Exit; end;

  try
    data := GetJSON(Raw);
  except
    on E: Exception do begin ErrMsg := 'invalid info JSON'; Exit; end;
  end;

  try
    if not (data is TJSONObject) then begin ErrMsg := 'unexpected info JSON'; Exit; end;
    root := TJSONObject(data);

    // core.exe hata olayını da stdout'a basabilir
    if JStr(root, 'event') = 'error' then
    begin
      ErrMsg := JStr(root, 'message', 'info failed');
      Exit;
    end;

    t := JStr(root, '_type');
    entries := root.Find('entries');
    isList := (t = 'playlist') or ((entries <> nil) and (t <> 'video'));

    if isList then
    begin
      Result.IsPlaylist := True;
      Result.Title := FirstNonEmpty(JStr(root, 'title'), JStr(root, 'id'), '', 'playlist');
      Result.Uploader := PickUploader(root);
      if (entries <> nil) and (entries.JSONType = jtArray) then
      begin
        Result.Count := TJSONArray(entries).Count;
        SetLength(Result.PlaylistItems, Result.Count);
        SetLength(Result.PlaylistUrls,  Result.Count);
        SetLength(Result.PlaylistUploaders, Result.Count);
        for i := 0 to TJSONArray(entries).Count - 1 do
          if TJSONArray(entries).Items[i].JSONType = jtObject then
          begin
            first := TJSONObject(TJSONArray(entries).Items[i]);
            Result.PlaylistItems[i] := JStr(first, 'title', 'Track ' + IntToStr(i + 1));
            // Her parçanın URL'sini sakla (--flat-playlist modu); 'url'/'id'
            // çoğu zaman sadece video ID'sidir, tam URL'ye tamamla.
            Result.PlaylistUrls[i]  := ToFullUrl(FirstNonEmpty(
              JStr(first, 'webpage_url'),
              JStr(first, 'url'),
              JStr(first, 'id')));
            // Parçanın kendi yükleyicisi (varsa); playlist sahibiyle karıştırılmaz.
            Result.PlaylistUploaders[i] := PickUploader(first);
            if i = 0 then
              Result.Thumbnail := PickThumbnail(first);
          end;
      end;
    end
    else
    begin
      Result.IsPlaylist := False;
      Result.Title := JStr(root, 'title', 'video');
      Result.Uploader := PickUploader(root);
      Result.UploadDate := JStr(root, 'upload_date');
      Result.Thumbnail := PickThumbnail(root);
      Result.Duration := JNum(root, 'duration');
      desc := JStr(root, 'description');
      if Length(desc) > MaxDescription then desc := Copy(desc, 1, MaxDescription);
      Result.Description := desc;
      Result.Url := FirstNonEmpty(JStr(root, 'webpage_url'),
                                  JStr(root, 'original_url'), InputUrl);
      Result.Count := 1;
    end;

    Result.Ok := True;
  finally
    data.Free;
  end;
end;

{ ---------------------------------------------------------------------------
  Genel TProcess yardımcıları
  --------------------------------------------------------------------------- }
procedure ConfigureHidden(P: TProcess);
begin
  P.Options := [poUsePipes, poNoConsole];
  P.ShowWindow := swoHIDE;
end;

// stdout'u tamamen oku (info komutu için — küçük tek seferlik çıktı)
function ReadAllStdout(P: TProcess): string;
var
  buf: array[0..ReadBufSize - 1] of Byte;
  n, avail: Integer;
  chunk: string;
begin
  Result := '';
  while True do
  begin
    avail := P.Output.NumBytesAvailable;
    if avail > 0 then
    begin
      n := P.Output.Read(buf, Min(SizeOf(buf), avail));
      if n > 0 then begin SetString(chunk, PChar(@buf[0]), n); Result := Result + chunk; end;
    end
    else if not P.Running then
      Break
    else
      Sleep(15);
  end;
  // kalanı boşalt
  while True do
  begin
    avail := P.Output.NumBytesAvailable;
    if avail <= 0 then Break;
    n := P.Output.Read(buf, Min(SizeOf(buf), avail));
    if n <= 0 then Break;
    SetString(chunk, PChar(@buf[0]), n);
    Result := Result + chunk;
  end;
end;

// Süreç ağacını öldür (core.exe + alt süreçler: yt-dlp / ffmpeg)
procedure KillTree(PID: Integer);
var P: TProcess;
begin
  if PID <= 0 then Exit;
  P := TProcess.Create(nil);
  try
    P.Executable := 'taskkill';
    P.Parameters.Add('/PID'); P.Parameters.Add(IntToStr(PID));
    P.Parameters.Add('/T');   P.Parameters.Add('/F');
    P.Options := [poNoConsole, poWaitOnExit];
    try P.Execute; except end;
  finally
    P.Free;
  end;
end;

function JsonEscape(const S: string): string;
var i: Integer; c: Char;
begin
  Result := '';
  for i := 1 to Length(S) do
  begin
    c := S[i];
    case c of
      '\': Result := Result + '\\';
      '"': Result := Result + '\"';
      #13, #10, #9: Result := Result + ' ';
    else
      Result := Result + c;
    end;
  end;
end;

{ ===========================================================================
  TInfoThread — 'core.exe info' arka planda
  =========================================================================== }
type
  TInfoThread = class(TThread)
  private
    FEngine: TEngine;
    FUrl: string;
    FCallback: TInfoCallback;
    FInfo: TMediaInfo;
    FErr: string;
    procedure DoCallback;
  protected
    procedure Execute; override;
  public
    constructor Create(AEngine: TEngine; const AUrl: string; ACallback: TInfoCallback);
  end;

constructor TInfoThread.Create(AEngine: TEngine; const AUrl: string; ACallback: TInfoCallback);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FEngine := AEngine;
  FUrl := AUrl;
  FCallback := ACallback;
  Start;
end;

procedure TInfoThread.DoCallback;
begin
  if Assigned(FCallback) then FCallback(FInfo, FErr);
end;

procedure TInfoThread.Execute;
var P: TProcess; raw, thumbFile: string;
begin
  P := TProcess.Create(nil);
  try
    P.Executable := FEngine.CoreExe;
    P.CurrentDirectory := FEngine.AppDir;
    P.Parameters.Add('info');
    P.Parameters.Add('--url'); P.Parameters.Add(FUrl);
    P.Parameters.Add('--bin'); P.Parameters.Add(FEngine.BinDir);
    ConfigureHidden(P);
    try
      P.Execute;
    except
      on E: Exception do
      begin
        FInfo.Ok := False;
        FErr := 'core.exe başlatılamadı: ' + E.Message;
        Synchronize(@DoCallback);
        Exit;
      end;
    end;
    raw := ReadAllStdout(P);
    P.WaitOnExit;
  finally
    P.Free;
  end;

  FInfo := ParseMediaInfo(raw, FUrl, FErr);

  // Kapak resmini indir (curl.exe ile — Windows 10+ yerleşik) ve JPEG'e dönüştür
  if FInfo.Ok and (FInfo.Thumbnail <> '') then
  begin
    thumbFile := FEngine.TempDir + 'thumb.jpg';
    ForceDirectories(FEngine.TempDir);
    // Adım 1: Ham dosyayı indir (WebP, JPEG, PNG olabilir)
    P := TProcess.Create(nil);
    try
      P.Executable := 'curl.exe';
      P.Parameters.Add('-sL');
      P.Parameters.Add('--max-time');
      P.Parameters.Add('8');
      P.Parameters.Add('-o');
      P.Parameters.Add(thumbFile + '.raw');
      P.Parameters.Add(FInfo.Thumbnail);
      ConfigureHidden(P);
      try
        P.Execute;
        P.WaitOnExit;
      except
        // curl yoksa kapak yüklenmez, uygulama çalışmaya devam eder
      end;
    finally
      P.Free;
    end;
    // Adım 2: ffmpeg ile gerçek JPEG'e dönüştür (WebP dahil her formatı işler)
    if FileExists(thumbFile + '.raw') then
    begin
      P := TProcess.Create(nil);
      try
        P.Executable := FEngine.BinDir + PathDelim + 'ffmpeg.exe';
        P.Parameters.Add('-y');
        P.Parameters.Add('-hide_banner');
        P.Parameters.Add('-loglevel'); P.Parameters.Add('error');
        P.Parameters.Add('-i');        P.Parameters.Add(thumbFile + '.raw');
        P.Parameters.Add('-vf');       P.Parameters.Add('crop=min(iw\,ih):min(iw\,ih),setsar=1');
        P.Parameters.Add('-frames:v'); P.Parameters.Add('1');
        P.Parameters.Add(thumbFile);
        ConfigureHidden(P);
        try
          P.Execute;
          P.WaitOnExit;
        except end;
      finally
        P.Free;
      end;
      try SysUtils.DeleteFile(thumbFile + '.raw'); except end;
    end;
    if FileExists(thumbFile) then
      FInfo.ThumbPath := thumbFile;
  end;

  Synchronize(@DoCallback);
end;

{ ===========================================================================
  TDownloadThread — 'core.exe run' arka planda, satır satır olay akışı
  =========================================================================== }
type
  TDownloadThread = class(TThread)
  private
    FEngine: TEngine;
    FReq: TDownloadRequest;
    FOnLine: TEngineLineEvent;
    FOnFinished: TEngineDoneEvent;
    FJobId: string;
    FJobDir: string;
    FPID: Integer;
    FCurLine: string;
    FTerminalSeen: Boolean;
    procedure DoLine;
    procedure DoFinished;
    function WriteFfmeta: string;
    procedure BuildParams(P: TProcess; const FfmetaPath: string);
  protected
    procedure Execute; override;
  public
    constructor Create(AEngine: TEngine; const AReq: TDownloadRequest;
                       AOnLine: TEngineLineEvent; AOnFinished: TEngineDoneEvent);
    procedure Kill;
  end;

constructor TDownloadThread.Create(AEngine: TEngine; const AReq: TDownloadRequest;
  AOnLine: TEngineLineEvent; AOnFinished: TEngineDoneEvent);
begin
  inherited Create(True);
  FreeOnTerminate := True;
  FEngine := AEngine;
  FReq := AReq;
  FOnLine := AOnLine;
  FOnFinished := AOnFinished;
  FJobId := 'job' + FormatDateTime('yyyymmddhhnnsszzz', Now);
  FJobDir := FEngine.TempDir + FJobId;
  FPID := 0;
  Start;
end;

procedure TDownloadThread.Kill;
begin
  KillTree(FPID);
end;

procedure TDownloadThread.DoLine;
begin
  if Assigned(FOnLine) then FOnLine(FCurLine);
end;

procedure TDownloadThread.DoFinished;
begin
  // motorun "meşgul" durumunu bırak (ana iş parçacığında güvenli)
  if FEngine.FDownloadThread = Self then
  begin
    FEngine.FDownloadThread := nil;
    FEngine.FPaused := False;
  end;
  if Assigned(FOnFinished) then FOnFinished();
end;

function TDownloadThread.WriteFfmeta: string;
var
  sb: string;
  fs: TFileStream;
  path: string;

  // ffmetadata özel karakter kaçışı: = ; # \   (Add'dan ÖNCE tanımlı olmalı)
  function EscapeFfmeta(const V: string): string;
  var i: Integer; c: Char; s: string;
  begin
    s := StringReplace(V, #13#10, ' ', [rfReplaceAll]);
    s := StringReplace(s, #13, ' ', [rfReplaceAll]);
    s := StringReplace(s, #10, ' ', [rfReplaceAll]);
    Result := '';
    for i := 1 to Length(s) do
    begin
      c := s[i];
      if c in ['=', ';', '#', '\'] then Result := Result + '\';
      Result := Result + c;
    end;
  end;

  procedure Add(const Key, Val: string);
  begin
    if Trim(Val) <> '' then sb := sb + Key + '=' + EscapeFfmeta(Val) + #10;
  end;

begin
  Result := '';
  if not FReq.Metadata then Exit;

  sb := ';FFMETADATA1' + #10;
  Add('title', FReq.Title);
  Add('artist', FReq.Uploader);
  Add('album_artist', FReq.Uploader);
  if Length(FReq.UploadDate) >= 4 then Add('date', Copy(FReq.UploadDate, 1, 4));
  Add('comment', FReq.Description);

  path := FJobDir + PathDelim + 'meta.ffmeta';
  try
    fs := TFileStream.Create(path, fmCreate);
    try
      if Length(sb) > 0 then fs.WriteBuffer(sb[1], Length(sb));  // UTF-8 baytları, BOM yok
    finally
      fs.Free;
    end;
    Result := path;
  except
    Result := '';
  end;
end;

procedure TDownloadThread.BuildParams(P: TProcess; const FfmetaPath: string);
var
  nm: string;

  function B(const Cond: Boolean): string;
  begin if Cond then Result := '1' else Result := '0'; end;

begin
  nm := FReq.Title;
  if Trim(nm) = '' then nm := 'download';
  nm := SanitizeFileName(nm);

  P.Parameters.Add('run');
  P.Parameters.Add('--url');          P.Parameters.Add(FReq.Url);
  P.Parameters.Add('--bin');          P.Parameters.Add(FEngine.BinDir);
  P.Parameters.Add('--temp');         P.Parameters.Add(ExcludeTrailingPathDelimiter(FEngine.TempDir));
  P.Parameters.Add('--jobid');        P.Parameters.Add(FJobId);
  P.Parameters.Add('--out');          P.Parameters.Add(FReq.OutDir);
  P.Parameters.Add('--name');         P.Parameters.Add(nm);
  P.Parameters.Add('--type');         P.Parameters.Add(FReq.Kind);
  P.Parameters.Add('--quality');      P.Parameters.Add(FReq.Quality);
  P.Parameters.Add('--video-format'); P.Parameters.Add(FReq.VideoFormat);
  P.Parameters.Add('--audio-format'); P.Parameters.Add(FReq.AudioFormat);
  P.Parameters.Add('--metadata');     P.Parameters.Add(B(FReq.Metadata));
  P.Parameters.Add('--thumbnail');    P.Parameters.Add(B(FReq.Thumbnail));
  P.Parameters.Add('--playlist');     P.Parameters.Add(B(FReq.Playlist));
  if FfmetaPath <> '' then begin P.Parameters.Add('--ffmeta'); P.Parameters.Add(FfmetaPath); end;
end;

procedure TDownloadThread.Execute;
var
  P: TProcess;
  buf: array[0..ReadBufSize - 1] of Byte;
  n, avail, nlPos: Integer;
  acc, chunk, line, ffmeta: string;
begin
  acc := '';
  FTerminalSeen := False;

  ForceDirectories(FJobDir);
  ffmeta := WriteFfmeta;   // metadata kapalıysa boş döner

  P := TProcess.Create(nil);
  try
    P.Executable := FEngine.CoreExe;
    P.CurrentDirectory := FEngine.AppDir;
    BuildParams(P, ffmeta);
    ConfigureHidden(P);
    try
      P.Execute;
    except
      on E: Exception do
      begin
        FCurLine := '{"event":"error","message":"core.exe ' + JsonEscape(E.Message) + '"}';
        Synchronize(@DoLine);
        FTerminalSeen := True;
      end;
    end;

    if not FTerminalSeen then
    begin
      FPID := P.ProcessID;
      while True do
      begin
        avail := P.Output.NumBytesAvailable;
        if avail > 0 then
        begin
          n := P.Output.Read(buf, Min(SizeOf(buf), avail));
          if n > 0 then
          begin
            SetString(chunk, PChar(@buf[0]), n);
            acc := acc + chunk;
            repeat
              nlPos := Pos(#10, acc);
              if nlPos = 0 then Break;
              line := TrimRight(Copy(acc, 1, nlPos - 1));   // CR'yi de temizler
              Delete(acc, 1, nlPos);
              if line <> '' then
              begin
                FCurLine := line;
                if (Pos('"event":"done"', line) > 0) or
                   (Pos('"event":"error"', line) > 0) then FTerminalSeen := True;
                Synchronize(@DoLine);
              end;
            until False;
          end;
        end
        else if not P.Running then
          Break
        else
          Sleep(15);
      end;

      // kalan tamponu boşalt
      if Trim(acc) <> '' then
      begin
        FCurLine := TrimRight(acc);
        if FCurLine <> '' then Synchronize(@DoLine);
      end;
      P.WaitOnExit;
    end;
  finally
    P.Free;
  end;

  // done/error görmediysek süreç öldürülmüş demektir -> "canceled"
  if not FTerminalSeen then
  begin
    FCurLine := '{"event":"canceled"}';
    Synchronize(@DoLine);
  end;

  // temp/<jobid> temizle
  if DirectoryExists(FJobDir) then
    DeleteDirectory(FJobDir, False);

  Synchronize(@DoFinished);
end;

{ ===========================================================================
  TEngine
  =========================================================================== }
constructor TEngine.Create(const AAppDir: string);
begin
  inherited Create;
  FAppDir := IncludeTrailingPathDelimiter(AAppDir);
  FDownloadThread := nil;
  FPaused := False;
end;

function TEngine.CoreExe: string;
begin Result := FAppDir + 'core.exe'; end;

function TEngine.BinDir: string;
begin Result := ExcludeTrailingPathDelimiter(FAppDir + 'bin'); end;

function TEngine.TempDir: string;
begin Result := IncludeTrailingPathDelimiter(FAppDir + 'temp'); end;

function TEngine.CoreExists: Boolean;
begin Result := FileExists(CoreExe); end;

function TEngine.GetBusy: Boolean;
begin Result := FDownloadThread <> nil; end;

procedure TEngine.FetchInfo(const Url: string; OnDone: TInfoCallback);
begin
  TInfoThread.Create(Self, Url, OnDone);   // FreeOnTerminate kendini yönetir
end;

procedure TEngine.StartDownload(const Req: TDownloadRequest;
  OnLine: TEngineLineEvent; OnFinished: TEngineDoneEvent);
begin
  if Busy then Exit;
  FDownloadThread := TDownloadThread.Create(Self, Req, OnLine, OnFinished);
end;

procedure TEngine.Cancel;
begin
  if FPaused then Resume;   // askıdaysa önce devam ettir
  if FDownloadThread <> nil then
    TDownloadThread(FDownloadThread).Kill;   // okuma döngüsü EOF alıp 'canceled' üretir
end;

{$IFDEF WINDOWS}
const
  TH32CS_SNAPPROCESS = $00000002;

type
  TPidArray = array of DWORD;

  // Toolhelp32 API — winunits-jedi'ye bağımlı kalmamak için minimal bildirim
  TProcessEntry32 = record
    dwSize:             DWORD;
    cntUsage:           DWORD;
    th32ProcessID:      DWORD;
    th32DefaultHeapID:  PtrUInt;
    th32ModuleID:       DWORD;
    cntThreads:         DWORD;
    th32ParentProcessID: DWORD;
    pcPriClassBase:     LongInt;
    dwFlags:            DWORD;
    szExeFile:          array[0..MAX_PATH-1] of AnsiChar;
  end;

function CreateToolhelp32Snapshot(dwFlags, th32ProcessID: DWORD): THandle;
  stdcall; external 'kernel32.dll' name 'CreateToolhelp32Snapshot';
function Process32First(hSnapshot: THandle; var lppe: TProcessEntry32): LongBool;
  stdcall; external 'kernel32.dll' name 'Process32First';
function Process32Next(hSnapshot: THandle; var lppe: TProcessEntry32): LongBool;
  stdcall; external 'kernel32.dll' name 'Process32Next';

// RootPID ve tüm alt/torun süreçlerinin PID listesini döner (core.exe + yt-dlp + ffmpeg)
function CollectProcessTree(RootPID: DWORD): TPidArray;
var
  snap: THandle;
  e: TProcessEntry32;
  i, oldLen: Integer;
  isChild, known: Boolean;
begin
  SetLength(Result, 1);
  Result[0] := RootPID;
  snap := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if snap = INVALID_HANDLE_VALUE then Exit;
  try
    repeat
      oldLen := Length(Result);
      e.dwSize := SizeOf(e);
      if Process32First(snap, e) then
      repeat
        isChild := False;
        for i := 0 to oldLen - 1 do
          if e.th32ParentProcessID = Result[i] then begin isChild := True; Break; end;
        if not isChild then Continue;
        known := False;
        for i := 0 to High(Result) do
          if Result[i] = e.th32ProcessID then begin known := True; Break; end;
        if not known then
        begin
          SetLength(Result, Length(Result) + 1);
          Result[High(Result)] := e.th32ProcessID;
        end;
      until not Process32Next(snap, e);
    until Length(Result) = oldLen;   // yeni süreç eklenmediyse bitir
  finally
    CloseHandle(snap);
  end;
end;

// Süreç ağacının tamamını askıya alır/devam ettirir (core.exe + yt-dlp.exe + ffmpeg.exe)
procedure SetProcessTreeSuspended(RootPID: DWORD; Suspend: Boolean);
var
  pids: TPidArray;
  i: Integer;
  hProc: THandle;
  hNtdll: HMODULE;
  NtSusp, NtRes: function(ProcHandle: THandle): LongInt; stdcall;
begin
  if RootPID = 0 then Exit;
  hNtdll := GetModuleHandle('ntdll.dll');
  if hNtdll = 0 then Exit;
  if Suspend then
  begin
    Pointer(NtSusp) := GetProcAddress(hNtdll, 'NtSuspendProcess');
    if not Assigned(NtSusp) then Exit;
  end
  else
  begin
    Pointer(NtRes) := GetProcAddress(hNtdll, 'NtResumeProcess');
    if not Assigned(NtRes) then Exit;
  end;

  pids := CollectProcessTree(RootPID);
  for i := 0 to High(pids) do
  begin
    hProc := OpenProcess(PROCESS_SUSPEND_RESUME, False, pids[i]);
    if hProc = 0 then Continue;
    try
      if Suspend then NtSusp(hProc) else NtRes(hProc);
    finally
      CloseHandle(hProc);
    end;
  end;
end;

procedure TEngine.Pause;
var pid: DWORD;
begin
  if FPaused or (FDownloadThread = nil) then Exit;
  pid := DWORD(TDownloadThread(FDownloadThread).FPID);
  if pid = 0 then Exit;
  SetProcessTreeSuspended(pid, True);
  FPaused := True;
end;

procedure TEngine.Resume;
var pid: DWORD;
begin
  if (not FPaused) or (FDownloadThread = nil) then Exit;
  pid := DWORD(TDownloadThread(FDownloadThread).FPID);
  if pid = 0 then Exit;
  SetProcessTreeSuspended(pid, False);
  FPaused := False;
end;
{$ELSE}
procedure TEngine.Pause; begin end;
procedure TEngine.Resume; begin end;
{$ENDIF}

{ ---- geçmiş (data/history.json) ------------------------------------------ }
function TEngine.HistoryFile: string;
begin
  Result := FAppDir + 'data' + PathDelim + 'history.json';
end;

procedure TEngine.AddHistory(const ATitle, AUrl, AFilePath, AStatus: string);
const
  MaxEntries = 500;
var
  Raw, s: string;
  Data: TJSONData;
  Arr: TJSONArray;
  Obj: TJSONObject;
  fs: TFileStream;
begin
  Arr := nil; Data := nil;
  Raw := ReadFileToStringUtf8(HistoryFile);
  if Raw <> '' then
    try
      Data := GetJSON(Raw);
      if Data is TJSONArray then Arr := TJSONArray(Data);
    except
      Data := nil; Arr := nil;
    end;

  if Arr = nil then
  begin
    if Data <> nil then Data.Free;
    Arr := TJSONArray.Create;
    Data := Arr;
  end;

  try
    Obj := TJSONObject.Create;
    Obj.Add('title', ATitle);
    Obj.Add('url', AUrl);
    Obj.Add('file', AFilePath);
    Obj.Add('status', AStatus);
    Obj.Add('date', FormatDateTime('yyyy-mm-dd hh:nn', Now));
    Arr.Insert(0, Obj);                              // en yeni en üstte
    while Arr.Count > MaxEntries do Arr.Delete(Arr.Count - 1);

    ForceDirectories(FAppDir + 'data');
    s := Arr.FormatJSON;
    fs := TFileStream.Create(HistoryFile, fmCreate);
    try
      if Length(s) > 0 then fs.WriteBuffer(s[1], Length(s));   // UTF-8 baytları
    finally
      fs.Free;
    end;
  finally
    Data.Free;
  end;
end;

function TEngine.LoadHistory: THistoryArray;
var
  Raw: string; Data: TJSONData; Arr: TJSONArray; O: TJSONObject; i: Integer;
begin
  SetLength(Result, 0);
  Raw := ReadFileToStringUtf8(HistoryFile);
  if Raw = '' then Exit;
  try Data := GetJSON(Raw); except Exit; end;
  try
    if not (Data is TJSONArray) then Exit;
    Arr := TJSONArray(Data);
    SetLength(Result, Arr.Count);
    for i := 0 to Arr.Count - 1 do
      if Arr.Items[i].JSONType = jtObject then
      begin
        O := TJSONObject(Arr.Items[i]);
        Result[i].Title    := O.Get('title', '');
        Result[i].Url      := O.Get('url', '');
        Result[i].FilePath := O.Get('file', '');
        Result[i].Status   := O.Get('status', '');
        Result[i].Date     := O.Get('date', '');
      end;
  finally
    Data.Free;
  end;
end;

end.
