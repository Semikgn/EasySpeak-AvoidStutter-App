import io
import librosa
import numpy as np
from pydub import AudioSegment

def analyze_speech_fluency(audio_bytes: bytes, word_info_map: list, transcript: str):
    blocks = 0
    vocal_fillers = 0
    word_fillers = 0
    repetitions = 0
    extensions = 0
    speaking_rate = 0 # Hedef: Dakika başına kelime

    # Ses dosyasını yükle (librosa için)
    try:
        audio = AudioSegment.from_wav(io.BytesIO(audio_bytes))
        if audio.channels > 1:
            audio = audio.set_channels(1) # Mono'ya çevir
        
        # pydub AudioSegment'ten librosa'ya uygun hale getirme
        # librosa.load doğrudan dosya nesnesinden okuyabildiği için tekrar kayıt etmeye gerek yok
        # librosa.load'a dosya nesnesi verilirken genellikle sample_rate de belirtilir.
        y, sr = librosa.load(io.BytesIO(audio.export(format="wav").read()), sr=None)
    except Exception as e:
        print(f"Librosa ile ses yükleme hatası: {e}")
        y = np.array([])
        sr = 0

    # ----- Blok Sayısı Hesaplanması (Basit Yaklaşım) -----
    # Kelimeler arasındaki boşlukları analiz et
    if word_info_map:
        total_speaking_time = word_info_map[-1]["end_time"] if word_info_map else 0
        total_words = len(word_info_map)

        for i in range(len(word_info_map) - 1):
            current_word_end = word_info_map[i]["end_time"]
            next_word_start = word_info_map[i+1]["start_time"]
            silence_duration = next_word_start - current_word_end
            
            # 0.5 saniyeden uzun sessizlikleri blok olarak varsayalım
            if silence_duration > 0.5: 
                blocks += 1

        # ----- Konuşma Hızı Hesaplanması -----
        if total_speaking_time > 0:
            speaking_rate = (total_words / total_speaking_time) * 60
        
    # ----- Kelime Dolguları Hesaplanması -----
    filler_words = ["şey", "yani", "hani", "dediğim gibi", "işte"] 
    for word_data in word_info_map:
        if word_data["word"].lower() in filler_words:
            word_fillers += 1

    # ----- Sesli Dolgular, Tekrarlar, Uzatmalar (Kalibrasyon Bekliyor) -----
    # Bu kısımlar sizin belirttiğiniz gibi kalibrasyon ve iyileştirme gerektiriyor.
    # Aşağıdaki örnekler başlangıç noktalarıdır ve basitleştirilmiştir.
    # Gerçek uygulamada çok daha sofistike ses analizi teknikleri gerektirir.

    if y.size > 0:
        # Sesli Dolgular için enerji eşikleri ve zamanlama
        # Enerji tabanlı sesli dolgu tespiti:
        # Kelime aralarındaki yüksek enerji bölgeleri (sessizlik olmaması gereken yerler)
        
        # Tekrarlar ve Uzatmalar için basit bir yaklaşım:
        # Kelimelerin kendi içindeki süresi ve/veya fonetik analizi gerekir.
        # Şimdilik yer tutucu olarak bırakıyorum.
        pass

    # Kalibrasyon ve iyileştirme için bu kısımları odaklanılacak.
    # Şu anki halleri temsili ve basitleştirilmiş.
    
    return {
        "blocks": blocks,
        "vocal_fillers": vocal_fillers,
        "word_fillers": word_fillers,
        "repetitions": repetitions, # Mevcut haliyle hep 0 dönecek
        "extensions": extensions,   # Mevcut haliyle hep 0 dönecek
        "speaking_rate": round(speaking_rate, 2)
    }