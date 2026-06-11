<?php
/**
 * EasyDownload — Güncelleme dosyası indirme uç noktası
 *
 * latest.json içindeki "file" alanında yazan kurulum dosyasını ../files/
 * klasöründen akıtır (stream). Böylece indirme adresi (download.php) hep
 * sabit kalır; yeni sürümde sadece latest.json'daki "file" güncellenir.
 *
 * Adres örneği: https://easydownload.net/api/download.php
 */

$cfgPath = __DIR__ . '/latest.json';

if (!is_file($cfgPath)) {
    http_response_code(500);
    exit('Yapılandırma bulunamadı.');
}

$data = json_decode(file_get_contents($cfgPath), true);
$file = isset($data['file']) ? basename((string)$data['file']) : '';

if ($file === '') {
    http_response_code(500);
    exit('Dosya adı tanımlı değil.');
}

$path = __DIR__ . '/../files/' . $file;

if (!is_file($path)) {
    http_response_code(404);
    exit('Güncelleme dosyası bulunamadı.');
}

// Tarayıcı/önbellek karışmasın diye indirmeye zorla
if (ob_get_level()) { ob_end_clean(); }

header('Content-Type: application/octet-stream');
header('Content-Disposition: attachment; filename="' . $file . '"');
header('Content-Length: ' . filesize($path));
header('Cache-Control: no-store, no-cache, must-revalidate');
header('Pragma: no-cache');

readfile($path);
exit;
