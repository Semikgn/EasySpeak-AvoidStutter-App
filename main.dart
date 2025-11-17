import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:http/http.dart' as http;
import 'dart:io';
import 'dart:convert';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Konuşma Pratiğim',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const SpeechPracticeScreen(),
    );
  }
}

class SpeechPracticeScreen extends StatefulWidget {
  const SpeechPracticeScreen({super.key});

  @override
  State<SpeechPracticeScreen> createState() => _SpeechPracticeScreenState();
}

class _SpeechPracticeScreenState extends State<SpeechPracticeScreen> {
  final _record = Record();
  String? _audioPath;
  bool _isRecording = false;
  bool _isPlaying = false;
  String _statusText = "Kayıt yapmaya hazır.";
  final AudioPlayer _audioPlayer = AudioPlayer();
  Map<String, dynamic>? _analysisResults;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  @override
  void dispose() {
    _record.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _checkPermissions() async {
    final status = await Permission.microphone.request();
    if (status.isGranted) {
      setState(() {
        _statusText = "Mikrofon izni verildi.";
      });
    } else {
      setState(() {
        _statusText = "Mikrofon izni reddedildi. Lütfen ayarlardan izin verin.";
      });
    }
  }

  Future<void> _startRecording() async {
    if (await Permission.microphone.isGranted) {
      final appDocDir = await getApplicationDocumentsDirectory();
      _audioPath = '${appDocDir.path}/my_audio.wav';

      await _record.start(
        path: _audioPath!,
        encoder: AudioEncoder.wav,
        samplingRate: 16000, // Google STT için ideal
        numChannels: 1,
      );
      setState(() {
        _isRecording = true;
        _statusText = "Kaydediliyor...";
        _analysisResults = null;
      });
    } else {
      _checkPermissions();
    }
  }

  Future<void> _stopRecording() async {
    final path = await _record.stop();
    setState(() {
      _isRecording = false;
      _audioPath = path;
      _statusText = "Kayıt tamamlandı. ${path != null ? 'Çalabilir veya gönderebilirsiniz.' : ''}";
    });
  }

  Future<void> _playRecording() async {
    if (_audioPath != null && !_isPlaying) {
      try {
        await _audioPlayer.setFilePath(_audioPath!);
        await _audioPlayer.play();
        setState(() {
          _isPlaying = true;
        });
        _audioPlayer.playerStateStream.listen((state) {
          if (state.processingState == ProcessingState.completed) {
            setState(() {
              _isPlaying = false;
            });
          }
        });
      } catch (e) {
        setState(() {
          _statusText = "Kayıt çalınamadı: $e";
        });
      }
    }
  }

  Future<void> _deleteRecording() async {
    if (_audioPath != null) {
      final file = File(_audioPath!);
      if (await file.exists()) {
        await file.delete();
        _audioPath = null;
      }
    }
    setState(() {
      _statusText = "Kayıt silindi.";
      _analysisResults = null;
    });
  }

  Future<void> _sendRecording() async {
    if (_audioPath == null) {
      setState(() {
        _statusText = "Gönderilecek bir kayıt yok.";
      });
      return;
    }

    setState(() {
      _statusText = "Analiz ediliyor...";
    });

    try {
      var request = http.MultipartRequest(
        'POST',
        // BACKEND SUNUCUNUZUN IP ADRESİNİ VEYA ALAN ADINI BURAYA GİRİN
        // Emulator için: http://10.0.2.2:8000/analyze/
        // Gerçek cihaz için: http://<BACKEND_IP_ADRESİ>:8000/analyze/
        // Eğer FastAPI sunucunuz http://127.0.0.1:8000'de çalışıyorsa
        // Android emülatörde 10.0.2.2 olarak erişilir.
        // iOS emülatörde localhost veya 127.0.0.1 olarak erişilir.
        Uri.parse('http://10.0.2.2:8000/analyze/'), 
      );
      request.files.add(await http.MultipartFile.fromPath('file', _audioPath!));

      var response = await request.send();
      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final Map<String, dynamic> data = json.decode(responseData);
        setState(() {
          _analysisResults = data;
          _statusText = "Analiz tamamlandı!";
        });
      } else {
        final errorBody = await response.stream.bytesToString();
        setState(() {
          _statusText = "Analiz hatası: ${response.statusCode} - $errorBody";
        });
      }
    } catch (e) {
      setState(() {
        _statusText = "Bağlantı hatası: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Konuşma Pratiğim'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              _statusText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isRecording ? _stopRecording : _startRecording,
              style: ElevatedButton.styleFrom(
                backgroundColor: _isRecording ? Colors.red : Colors.green,
                padding: const EdgeInsets.symmetric(vertical: 15),
                textStyle: const TextStyle(fontSize: 18),
              ),
              child: Text(_isRecording ? 'Kaydı Durdur' : 'Kayda Başla'),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _audioPath != null && !_isPlaying ? _playRecording : null,
                  child: Text(_isPlaying ? 'Çalınıyor...' : 'Çal'),
                ),
                ElevatedButton(
                  onPressed: _audioPath != null && !_isPlaying ? _deleteRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text('Sil'),
                ),
                ElevatedButton(
                  onPressed: _audioPath != null && !_isRecording && !_isPlaying ? _sendRecording : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text('Gönder'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _analysisResults != null
                  ? SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Analiz Sonuçları:",
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 10),
                          _buildResultCard("Transkript", _analysisResults!["transcript"] ?? "N/A"),
                          _buildResultCard("Blok Sayısı", (_analysisResults!["blocks"] ?? 0).toString()),
                          _buildResultCard("Sesli Dolgu", (_analysisResults!["vocal_fillers"] ?? 0).toString()),
                          _buildResultCard("Kelime Dolgu", (_analysisResults!["word_fillers"] ?? 0).toString()),
                          _buildResultCard("Tekrar", (_analysisResults!["repetitions"] ?? 0).toString()),
                          _buildResultCard("Uzatma", (_analysisResults!["extensions"] ?? 0).toString()),
                          _buildResultCard("Konuşma Hızı (WPM)", (_analysisResults!["speaking_rate"] ?? 0.0).toStringAsFixed(2)),
                        ],
                      ),
                    )
                  : Center(
                      child: Text(
                        _audioPath == null ? "Henüz bir kayıt yapılmadı." : "Lütfen kaydı gönderin.",
                        style: const TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(String title, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 5),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
          ],
        ),
      ),
    );
  }
}