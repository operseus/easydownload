<?php
/**
 * EasyDownload — Sürüm kontrol uç noktası
 *
 * İstemci (uygulama) buraya GET ile gelir; en son sürüm bilgisini JSON döner.
 * Yeni sürüm yayınlamak için yalnızca latest.json düzenlenir (bu dosyaya
 * dokunmaya gerek yok).
 *
 * Adres örneği: https://easydownload.net/api/version.php
 */

header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Access-Control-Allow-Origin: *');

$cfgPath = __DIR__ . '/latest.json';

if (!is_file($cfgPath)) {
    http_response_code(500);
    echo json_encode(['error' => 'latest.json bulunamadı']);
    exit;
}

$raw  = file_get_contents($cfgPath);
$data = json_decode($raw, true);

if (!is_array($data)) {
    http_response_code(500);
    echo json_encode(['error' => 'latest.json geçersiz']);
    exit;
}

// Alanları normalize et + güvenli varsayılanlar ver
$out = [
    'version'      => isset($data['version'])      ? (string)$data['version']      : '0.0.0',
    'version_code' => isset($data['version_code']) ? (int)$data['version_code']    : 0,
    'url'          => isset($data['url'])          ? (string)$data['url']          : '',
    'notes'        => isset($data['notes'])        ? (string)$data['notes']        : '',
    'mandatory'    => isset($data['mandatory'])    ? (bool)$data['mandatory']      : false,
    // auto=true: uygulama otomatik indirip kurar. false: elle kurulum
    // (örn. güncelleme motorunu da değiştiren büyük sürümlerde false yapın).
    'auto'         => isset($data['auto'])         ? (bool)$data['auto']           : true,
];

echo json_encode($out, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
