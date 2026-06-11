unit updater;

{ ============================================================================
  EasyDownload — Uygulama güncelleme istemcisi

  Sunucu (easydownload.net, cPanel + PHP) ile konuşur:
    * version.php  -> en son sürüm bilgisini JSON döner
    * download.php -> en son kurulum dosyasını indirir

  Ağ erişimi Windows'un yerleşik WinINet (wininet.dll) API'si ile yapılır;
  böylece HTTPS için ek bir OpenSSL DLL'ine GEREK YOKTUR ve projenin
  "Windows birimi olmadan dış Win32 bildirimleri" tarzına uyar.

  Sürüm karşılaştırması metin yerine SAYISAL "version_code" ile yapılır
  (ör. 1.0.2b -> 10002). Yeni sürüm yayınlamak için sunucudaki latest.json
  düzenlenir; istemci tarafında bir şey değişmez.
  ============================================================================ }

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, fpjson, jsonparser;

const
  // --- Bu yapının (build) kimliği ---
  CurrentVersion     = '1.1.0';
  CurrentVersionCode = 10100;       // 1.1.0 ; sonraki sürüm 10101, 10200...

  // --- Sunucu uç noktaları (easydownload.net) ---
  UpdateCheckUrl = 'https://easydownload.net/api/version.php';

type
  TUpdateInfo = record
    Ok: Boolean;          // sorgu başarılı mı (ağ/parsing hatası yoksa True)
    Available: Boolean;   // sunucudaki sürüm daha yeni mi
    Version: string;      // gösterim sürümü, ör. "1.0.3b"
    VersionCode: Integer; // sayısal sürüm
    Url: string;          // indirme adresi (download.php veya doğrudan dosya)
    Notes: string;        // sürüm notları
    Mandatory: Boolean;   // zorunlu güncelleme mi
    Auto: Boolean;        // True: otomatik indir+kur ; False: elle kurulum
                          // (updater'ı değiştiren büyük güncellemelerde False)
    Error: string;        // Ok=False ise hata mesajı
  end;

  // İndirme ilerlemesi geri çağrısı (0..100; Total bilinmiyorsa -1)
  TDownloadProgress = procedure(Received, Total: Int64) of object;

// Sunucuya sorar; CurrentVersionCode ile karşılaştırıp sonucu döner.
function CheckForUpdate: TUpdateInfo;

// Verilen URL'yi DestPath'e indirir. AOnProgress nil olabilir.
function DownloadFile(const Url, DestPath: string;
  AOnProgress: TDownloadProgress; out Err: string): Boolean;

implementation

const
  INTERNET_OPEN_TYPE_PRECONFIG = 0;
  INTERNET_FLAG_RELOAD         = Cardinal($80000000);
  INTERNET_FLAG_NO_CACHE_WRITE = Cardinal($04000000);
  INTERNET_FLAG_SECURE         = Cardinal($00800000);
  INTERNET_FLAG_KEEP_CONNECTION = Cardinal($00400000);
  // Sertifika/yönlendirme toleransı (geliştirme + cPanel paylaşımlı SSL için)
  INTERNET_FLAG_IGNORE_CERT_CN_INVALID   = Cardinal($00001000);
  INTERNET_FLAG_IGNORE_CERT_DATE_INVALID = Cardinal($00002000);

function InternetOpenW(lpszAgent: PWideChar; dwAccessType: Cardinal;
  lpszProxy, lpszProxyBypass: PWideChar; dwFlags: Cardinal): Pointer;
  stdcall; external 'wininet.dll' name 'InternetOpenW';
function InternetOpenUrlW(hInternet: Pointer; lpszUrl: PWideChar;
  lpszHeaders: PWideChar; dwHeadersLength: Cardinal; dwFlags: Cardinal;
  dwContext: PtrUInt): Pointer;
  stdcall; external 'wininet.dll' name 'InternetOpenUrlW';
function InternetReadFile(hFile: Pointer; lpBuffer: Pointer;
  dwNumberOfBytesToRead: Cardinal; var lpdwNumberOfBytesRead: Cardinal): LongBool;
  stdcall; external 'wininet.dll' name 'InternetReadFile';
function InternetCloseHandle(hInternet: Pointer): LongBool;
  stdcall; external 'wininet.dll' name 'InternetCloseHandle';
function HttpQueryInfoW(hRequest: Pointer; dwInfoLevel: Cardinal;
  lpvBuffer: Pointer; var lpdwBufferLength: Cardinal; var lpdwIndex: Cardinal): LongBool;
  stdcall; external 'wininet.dll' name 'HttpQueryInfoW';

const
  HTTP_QUERY_CONTENT_LENGTH = 5;
  HTTP_QUERY_FLAG_NUMBER    = Cardinal($20000000);

{ ---------------------------------------------------------------------------
  WinINet üzerinden bir URL'yi açar (HTTP/HTTPS)
  --------------------------------------------------------------------------- }
function OpenUrl(hInet: Pointer; const Url: string): Pointer;
var flags: Cardinal;
begin
  flags := INTERNET_FLAG_RELOAD or INTERNET_FLAG_NO_CACHE_WRITE or
           INTERNET_FLAG_KEEP_CONNECTION;
  if Pos('https://', LowerCase(Url)) = 1 then
    flags := flags or INTERNET_FLAG_SECURE or
             INTERNET_FLAG_IGNORE_CERT_CN_INVALID or
             INTERNET_FLAG_IGNORE_CERT_DATE_INVALID;
  Result := InternetOpenUrlW(hInet, PWideChar(UnicodeString(Url)), nil, 0, flags, 0);
end;

{ ---------------------------------------------------------------------------
  Bir URL'yi metin olarak indirir (küçük JSON yanıtları için)
  --------------------------------------------------------------------------- }
function HttpGetString(const Url: string; out Body: string; out Err: string): Boolean;
var
  hInet, hUrl: Pointer;
  buf: array[0..4095] of Byte;
  n: Cardinal;
  s: AnsiString;
begin
  Result := False;
  Body := '';
  Err := '';
  hInet := InternetOpenW('EasyDownload-Updater', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hInet = nil then begin Err := 'İnternet bağlantısı başlatılamadı.'; Exit; end;
  try
    hUrl := OpenUrl(hInet, Url);
    if hUrl = nil then begin Err := 'Sunucuya ulaşılamadı.'; Exit; end;
    try
      repeat
        n := 0;
        if not InternetReadFile(hUrl, @buf[0], SizeOf(buf), n) then
        begin Err := 'Yanıt okunamadı.'; Exit; end;
        if n > 0 then
        begin
          // Ham baytları (UTF-8) kod sayfası dönüşümü olmadan ekle
          SetString(s, PAnsiChar(@buf[0]), n);
          Body := Body + s;
        end;
      until n = 0;
      Result := True;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hInet);
  end;
end;

{ ---------------------------------------------------------------------------
  Sürüm kontrolü
  --------------------------------------------------------------------------- }
function CheckForUpdate: TUpdateInfo;
var
  body, err: string;
  jd: TJSONData;
  jo: TJSONObject;
begin
  // Yönetilen (string) alanlar içerdiği için FillChar yerine tek tek başlat
  Result.Ok          := False;
  Result.Available   := False;
  Result.Version     := CurrentVersion;
  Result.VersionCode := CurrentVersionCode;
  Result.Url         := '';
  Result.Notes       := '';
  Result.Mandatory   := False;
  Result.Auto        := True;
  Result.Error       := '';

  if not HttpGetString(UpdateCheckUrl, body, err) then
  begin
    Result.Ok := False;
    Result.Error := err;
    Exit;
  end;

  jd := nil;
  try
    try
      jd := GetJSON(body);
    except
      on E: Exception do
      begin
        Result.Ok := False;
        Result.Error := 'Sunucu yanıtı çözümlenemedi.';
        Exit;
      end;
    end;

    if not (jd is TJSONObject) then
    begin
      Result.Ok := False;
      Result.Error := 'Geçersiz sunucu yanıtı.';
      Exit;
    end;

    jo := TJSONObject(jd);
    Result.Ok          := True;
    Result.Version     := jo.Get('version', CurrentVersion);
    Result.VersionCode := jo.Get('version_code', CurrentVersionCode);
    Result.Url         := jo.Get('url', '');
    Result.Notes       := jo.Get('notes', '');
    Result.Mandatory   := jo.Get('mandatory', False);
    Result.Auto        := jo.Get('auto', True);
    Result.Available   := Result.VersionCode > CurrentVersionCode;
  finally
    jd.Free;
  end;
end;

{ ---------------------------------------------------------------------------
  Dosya indirme (kurulum/exe için) — ilerleme bildirimiyle
  --------------------------------------------------------------------------- }
function DownloadFile(const Url, DestPath: string;
  AOnProgress: TDownloadProgress; out Err: string): Boolean;
var
  hInet, hUrl: Pointer;
  fs: TFileStream;
  buf: array[0..16383] of Byte;
  n, idx, lenLen, dwLen: Cardinal;
  total, received: Int64;
begin
  Result := False;
  Err := '';
  total := -1;
  received := 0;
  dwLen := 0;

  hInet := InternetOpenW('EasyDownload-Updater', INTERNET_OPEN_TYPE_PRECONFIG, nil, nil, 0);
  if hInet = nil then begin Err := 'İnternet bağlantısı başlatılamadı.'; Exit; end;
  try
    hUrl := OpenUrl(hInet, Url);
    if hUrl = nil then begin Err := 'İndirme bağlantısı kurulamadı.'; Exit; end;
    try
      // Toplam boyut (varsa) — HTTP_QUERY_FLAG_NUMBER 32-bit DWORD döner
      lenLen := SizeOf(dwLen);
      idx := 0;
      if HttpQueryInfoW(hUrl, HTTP_QUERY_CONTENT_LENGTH or HTTP_QUERY_FLAG_NUMBER,
        @dwLen, lenLen, idx) then
        total := dwLen
      else
        total := -1;

      try
        fs := TFileStream.Create(DestPath, fmCreate);
      except
        on E: Exception do
        begin Err := 'Hedef dosya oluşturulamadı: ' + E.Message; Exit; end;
      end;
      try
        repeat
          n := 0;
          if not InternetReadFile(hUrl, @buf[0], SizeOf(buf), n) then
          begin Err := 'İndirme sırasında okuma hatası.'; Exit; end;
          if n > 0 then
          begin
            fs.WriteBuffer(buf[0], n);
            Inc(received, n);
            if Assigned(AOnProgress) then AOnProgress(received, total);
          end;
        until n = 0;
        Result := received > 0;
        if not Result then Err := 'İndirilen dosya boş.';
      finally
        fs.Free;
      end;
    finally
      InternetCloseHandle(hUrl);
    end;
  finally
    InternetCloseHandle(hInet);
  end;
end;

end.
