<div align="right">
  <a href="README.ar.md">العربية</a> | 
  <a href="README.az.md">Azərbaycanca</a> | 
  <a href="README.de.md">Deutsch</a> | 
  <a href="../../README.md">English</a> | 
  <a href="README.es.md">Español</a> | 
  <a href="README.fr.md">Français</a> | 
  <a href="README.it.md">Italiano</a> | 
  <strong>Português</strong> | 
  <a href="README.ru.md">Русский</a> | 
  <a href="../README/README.tr.md">Türkçe</a>
</div>

# <img src="../../assets/logos/logo512.png" width="32" height="32" valign="middle"> EasyDownload

O EasyDownload é um aplicativo de desktop gratuito, sem anúncios, leve (lightweight) e de código aberto que permite baixar vídeos/músicas do YouTube e YouTube Music na mais alta qualidade em segundos.

<div align="center">

[![GitHub Release](https://img.shields.io/github/v/release/operseus/easydownload?style=flat-square&color=33ccff)](https://github.com/operseus/easydownload/releases)
[![GitHub License](https://img.shields.io/github/license/operseus/easydownload?style=flat-square&color=33ff99)](https://github.com/operseus/easydownload/blob/main/LICENSE)
[![GitHub Repo Size](https://img.shields.io/github/repo-size/operseus/easydownload?style=flat-square&color=ff66cc)](https://github.com/operseus/easydownload)
[![GitHub Stars](https://img.shields.io/github/stars/operseus/easydownload?style=flat-square&color=yellow)](https://github.com/operseus/easydownload/stargazers)

</div>

<div align="center">
  <img src="../screenshots/tabs.gif" alt="Interface do EasyDownload" width="700" style="border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.25);">
</div>

---

## 🚀 Funcionalidades

* **Suporte à melhor qualidade de vídeo:** Baixe vídeos sem perder sua qualidade original até a resolução 4K nos formatos MP4, WebM ou MKV.
* **Conversor de áudio avançado:** Converta vídeos do YouTube ou links do YouTube Music para o formato MP3 de alta qualidade com um único clique.
* **Incorporar informações de mídia (Embed Info):** Integre automaticamente metadados como foto de capa, nome do artista e título do vídeo nos arquivos baixados.
* **Fila avançada e histórico:** Adicione várias tarefas de download à fila, assista-as sendo baixadas em sequência em segundo plano e gerencie facilmente seus downloads antigos na guia de histórico.
* **Baixo consumo de recursos:** Otimizado para consumir o mínimo de RAM e CPU, ele nunca deixará seu sistema lento ao ser executado em segundo plano ou durante o download.
* **Suporte multilíngue:** Uso localizado com opções de inglês, turco, alemão, francês, espanhol e muitos outros idiomas.

---

## 📸 Pré-visualizações no aplicativo

### 🔹 Painel de download e menu de configurações avançadas

| ⚡ Fase de download (`downloading.gif`) | ⚙️ Menu de configurações (`settings.gif`) |
| :---: | :---: |
| Pesquise links, busque informações do vídeo e acompanhe o progresso do download em tempo real. | Gerencie fontes, limites de download simultâneo e notificações. |
| <img src="../screenshots/downloading.gif" alt="Tela de download" width="340" style="border-radius: 6px;"> | <img src="../screenshots/settings.gif" alt="Menu de configurações" width="340" style="border-radius: 6px;"> |

---

### 🔹 Excelente desempenho e leveza
Ao contrário dos aplicativos modernos, o EasyDownload quase não consome recursos do sistema. Os dados do gerenciador de tarefas em sua clareza original estão abaixo:

#### 📊 Modo ocioso (`taskmanager-idle.png`)
Quando o aplicativo está em segundo plano ou em modo de espera, ele consome apenas **~5,2 MB de RAM** e 0% de CPU.
<img src="../screenshots/taskmanager-idle.png" alt="Modo de desempenho ocioso" width="600" style="border-radius: 6px; border: 1px solid #30363d;">

#### 📥 Durante o download (`taskmanager-downloading.png`)
Mesmo durante o download ativo, oferece desempenho ultraleve, consumindo apenas **~12,9 MB de RAM**.
<img src="../screenshots/taskmanager-downloading.png" alt="Modo de desempenho durante o download" width="600" style="border-radius: 6px; border: 1px solid #30363d;">

---

## 🎨 Temas personalizáveis

Para escolher a opção que melhor se adapta aos seus olhos, o aplicativo oferece 4 diferentes opções de temas integrados: Midnight, Dark, Light e Sepia. Você pode ver a transição fluida entre os temas abaixo:

<div align="center">
  <img src="../screenshots/thames/thame.gif" alt="Transição de temas do EasyDownload" width="700" style="border-radius: 8px; box-shadow: 0 4px 12px rgba(0,0,0,0.2);">
</div>

---

## 📦 Download e instalação

Você pode acessar diretamente as versões estáveis mais recentes, pacotes portáteis e versões anteriores do aplicativo na página [**GitHub Releases**](https://github.com/operseus/easydownload/releases).

* 📥 **Instalação recomendada (Assistente):** Baixe a versão estável mais recente `EasyDownload-Setup-x.x.x.exe` e conclua a instalação em segundos.
* 🚀 **Versão portátil:** Se você não quiser deixar rastros no seu sistema, baixe o arquivo `EasyDownload-x.x.x-portable.zip`, extraia-o para qualquer pasta e execute-o diretamente sem instalação.

---

## 🛠 Estrutura do projeto

Este repositório abriga os códigos do site do aplicativo, versões e ferramentas de infraestrutura:
* 📁 `webserver/` - Códigos-fonte do site promocional do EasyDownload e integração da API de atualização automática.
* 📁 `versions/` - Códigos-fonte compilados das versões do EasyDownload.
* 📁 `releases/` - Arquivos de distribuição e fontes compilados das versões do EasyDownload.
* 📁 `docs/` - Documentação e arquivos README regionais relacionados ao EasyDownload.

---

## 📜 License

This project is developed as open-source and is completely free. For usage rules, distribution permissions, and details, you can check the [**LICENSE**](https://github.com/operseus/easydownload/blob/main/LICENSE) file.

## Credits & Third-Party Licenses
This project utilizes the following third-party tools and libraries:
- [yt-dlp](https://github.com/yt-dlp/yt-dlp) - Unlicense (public domain)
- [FFmpeg](https://ffmpeg.org) - LGPL/GPL
- [Inno Setup](https://jrsoftware.org/) - Modified BSD License
- [Lazarus IDE](https://www.lazarus-ide.org/) - Modified LGPL / GPL

---