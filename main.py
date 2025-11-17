import os
import io
import wave
from fastapi import FastAPI, UploadFile, File, HTTPException
from pydub import AudioSegment
from google.cloud import speech
from analyze_speech_fluency import analyze_speech_fluency

app = FastAPI()

# Google Cloud kimlik doğrulama anahtar dosyasının yolu
os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "google-credentials.json"
client = speech.SpeechClient()

@app.post("/analyze/")
async def analyze_audio(file: UploadFile = File(...)):
    if not file.content_type == "audio/wav":
        raise HTTPException(status_code=400, detail="Sadece WAV dosyaları kabul edilir.")

    audio_bytes = await file.read()

    # Pydub ile mono'ya çevirme veya format kontrolü
    try:
        audio = AudioSegment.from_wav(io.BytesIO(audio_bytes))
        if audio.channels > 1:
            audio = audio.set_channels(1)
        
        mono_audio_bytes = io.BytesIO()
        audio.export(mono_audio_bytes, format="wav")
        mono_audio_bytes.seek(0)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Ses işleme hatası: {e}")

    # Google Cloud Speech-to-Text API isteği
    gcs_audio = speech.RecognitionConfig(
        encoding=speech.RecognitionConfig.AudioEncoding.LINEAR16,
        sample_rate_hertz=audio.frame_rate,
        language_code="tr-TR", # Türkçe için
        enable_word_time_offsets=True
    )
    
    gcs_audio_content = speech.RecognitionAudio(content=mono_audio_bytes.read())

    try:
        response = client.recognize(config=gcs_audio, audio=gcs_audio_content)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Google Cloud STT hatası: {e}")

    if not response.results:
        return {
            "transcript": "",
            "blocks": 0,
            "vocal_fillers": 0,
            "word_fillers": 0,
            "repetitions": 0,
            "extensions": 0,
            "speaking_rate": 0
        }

    # Transkripti ve kelime zaman damgalarını çıkar
    full_transcript = " ".join([result.alternatives[0].transcript for result in response.results])
    word_info_map = []
    for result in response.results:
        for word in result.alternatives[0].words:
            word_info_map.append({
                "word": word.word,
                "start_time": word.start_time.total_seconds(),
                "end_time": word.end_time.total_seconds()
            })

    # Analiz motorunu çağır
    analysis_results = analyze_speech_fluency(
        audio_bytes=audio_bytes, # Orijinal ses baytlarını geç, analiz motoru içerde mono'yu handle edebilir
        word_info_map=word_info_map,
        transcript=full_transcript
    )

    return {
        "transcript": full_transcript,
        **analysis_results
    }