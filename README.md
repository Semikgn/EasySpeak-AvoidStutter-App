# EasySpeak-AvoidStutter

![Proje Durumu](https://img.shields.io/badge/status-Geli%C5%9Ftirme_A%C5%9Famas%C4%B1nda-yellow)
![Platform](https://img.shields.io/badge/platform-Flutter%20(Mobil)-blue)
![Backend](https://img.shields.io/badge/backend-FastAPI%20(Python)-purple)
![AI](https://img.shields.io/badge/AI-Google%20Cloud%20STT-orange)

Kullanıcıların konuşma akıcılıklarını analiz etmelerine ve geliştirmelerine yardımcı olmak için tasarlanmış, yapay zeka destekli tam yığın (full-stack) bir mobil uygulama. Bu araç, konuşma kalıpları üzerine detaylı metrikler sunarak bireylerin pratik yapmasına olanak tanır.

## 🎯 Projenin Amacı

Bu proje, bireylere konuşma alışkanlıklarını (duraksamalar, dolgu kelimeler, hız vb.) objektif bir şekilde analiz edebilecekleri özel ve erişilebilir bir araç sağlamayı amaçlamaktadır. Kullanıcılar, kayıtlar yaparak konuşma kalıpları hakkında anında, yapay zeka destekli geri bildirim alabilirler.

## ✨ Temel Özellikler

* **Ses Kaydı:** Doğrudan uygulama üzerinden kısa ses kayıtları yapın.
* **Anında Analiz:** Kaydınızı analiz için sunucuya gönderin ve saniyeler içinde sonuç alın.
* **Tam Transkript:** Google Cloud STT ile oluşturulmuş tam konuşma metni.
* **Detaylı Metrikler:** Konuşma akıcılığınızı anlamak için aşağıdaki metrikleri görün:
    * **Blok Sayısı** (Anormal sessizlikler/duraksamalar)
    * **Sesli Dolgular** ("ııı", "eee" gibi)
    * **Kelime Dolguları** ("şey", "hani" gibi)
    * **Tekrarlar**
    * **Uzatmalar**
    * **Konuşma Hızı** (Dakika başına kelime)

## 🛠️ Teknoloji Mimarisi

Proje, üç ana bileşenden oluşan modern bir mimariye sahiptir:

### 1. 📱 Frontend (Mobil Uygulama)

* **Teknoloji:** Flutter & Dart
* **Kod Adı:** `kekemelik_app` (Değiştirilmesi önerilir)
* **Sorumluluklar:**
    * Mikrofon izinlerini yönetme (`permission_handler`).
    * `.wav` formatında ses kaydı yapma (`record`).
    * Kayıtları önizleme (`just_audio`).
    * Ses dosyasını Backend'e POST isteği ile gönderme (`http`).
    * Analiz sonuçlarını (JSON) alıp kullanıcıya gösterme.

### 2. ⚙️ Backend (API Sunucusu)

* **Teknoloji:** Python, FastAPI, Uvicorn
* **Kod Adı:** `Speech-Analyzer`
* **Sorumluluklar:**
    * `/analyze/` endpoint'i üzerinden gelen ses dosyalarını kabul etme.
    * Gerekirse ses formatını (örn: mono) dönüştürme (`pydub`).
    * Ses dosyasını analiz için Google Cloud STT API'sine gönderme.
    * **Özel Analiz Motoru (`analyze_speech_fluency`):**
        * Google'dan gelen zaman damgalarını ve transkripti kullanarak yukarıda listelenen tüm akıcılık metriklerini hesaplama (`librosa` vb.).
    * Tüm analiz sonuçlarını (metrikler + transkript) JSON formatında Flutter uygulamasına geri gönderme.

### 3. ☁️ Harici Servis

* **Servis:** Google Cloud Speech-to-Text (STT) API
* **Kullanım:** Backend'den gelen ses dosyalarını alıp, metne ve en önemlisi kelime bazında zaman damgalarına ("harita") dönüştürür. Bu "harita", özel analiz motorunun temelini oluşturur.

## 🔄 Sistem Akış Şeması

Aşağıda sistemin uçtan uca nasıl çalıştığının basitleştirilmiş bir özeti bulunmaktadır:
Kullanıcı (Flutter App)] | |
1. Ses kaydını gönderir (.wav) v [Backend Sunucusu (FastAPI)] | |
2. Sesi Google Cloud'a iletir v [Google Cloud STT API] | |
3. Transkript + Zaman Damgaları (JSON) döner v [Backend Sunucusu (FastAPI)] | |
4.  Özel Analiz Motoru çalışır (Metrikler hesaplanır) v [Kullanıcı (Flutter App)] |
    5.  Analiz Sonuçları (JSON) gösterilir. <
  
📊 Güncel Durum

Bu proje şu anda **aktif geliştirme** aşamasındadır.

* ✅ Uçtan uca sistem (Flutter → FastAPI → Google Cloud → Flutter) çalışmaktadır.
* 🟡 Analiz motorunun metrik hesaplamaları (özellikle Tekrar, Uzatma ve Sesli Dolgu algoritmaları) kalibrasyon ve iyileştirme aşamasındadır.
* 🟡 Mobil uygulama arayüzü (UI/UX) temel fonksiyonları sağlamaktadır ve görsel/deneyim zenginleştirmesi beklemektedir.

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler

* Flutter SDK (v3.x.x)
* Python (v3.9+)
* Aktif bir Google Cloud Projesi (Speech-to-Text API etkinleştirilmiş)
* Google Cloud Servis Hesabı Anahtarı (`.json` dosyası)

### 1. Backend (Speech-Analyzer)

1.  Repoyu klonlayın ve backend klasörüne gidin:
    ```bash
    git clone [https://github.com/KULLANICI_ADINIZ/EasySpeak-AvoidStutter.git](https://github.com/KULLANICI_ADINIZ/EasySpeak-AvoidStutter.git)
    cd EasySpeak-AvoidStutter/Speech-Analyzer
    ```
2.  Python sanal ortamı (virtual environment) oluşturun ve aktifleştirin:
    ```bash
    python -m venv venv
    source venv/bin/activate  # Windows için: venv\Scripts\activate
    ```
3.  Gerekli kütüphaneleri yükleyin:
    ```bash
    pip install -r requirements.txt
    ```
4.  Google Cloud servis hesabı `.json` anahtarınızı bu klasöre kopyalayın ve adını kodunuzda belirttiğiniz şekilde (örn: `google-credentials.json`) ayarlayın.
5.  FastAPI sunucusunu başlatın:
    ```bash
    uvicorn main:app --reload
    ```
    Sunucu varsayılan olarak `http://127.0.0.1:8000` adresinde çalışacaktır.

### 2. Frontend (Mobil Uygulama)

1.  Projenin frontend klasörüne gidin:
    ```bash
    cd ../kekemelik_app # veya yeni adıyla
    ```
2.  Flutter paketlerini yükleyin:
    ```bash
    flutter pub get
    ```
3.  **ÖNEMLİ:** Flutter kodunuzda `http` isteğinin yapıldığı yeri bulun ve `http://127.0.0.1:8000/analyze/` adresini, backend'inizin çalıştığı IP adresiyle (veya emülatör için `http://10.0.2.2:8000/`) güncelleyin.
4.  Uygulamayı bir emülatörde veya cihazda çalıştırın:
    ```bash
    flutter run
    ```

## 🤝 Katkıda Bulunma (Contributing)

Bu proje şu anda kişisel bir portföy projesi olarak geliştirilmektedir. Ancak, fikir ve önerilere her zaman açığım. Bir "issue" açabilir veya bir "pull request" gönderebilirsiniz.

## 📜 Lisans

Bu proje [MIT Lisansı](LICENSE) altında lisanslanmıştır. (Henüz bir `LICENSE` dosyanız yoksa, GitHub'ın "Add file" > "Create new file" menüsünden `LICENSE` yazarak MIT şablonunu seçip oluşturabilirsiniz.)
