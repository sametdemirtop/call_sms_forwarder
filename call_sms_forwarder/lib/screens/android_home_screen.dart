import 'package:flutter/material.dart';
import '../services/sms_service.dart';
import '../services/call_service.dart';
import '../services/queue_service.dart';

class AndroidHomeScreen extends StatefulWidget {
  const AndroidHomeScreen({super.key});

  @override
  State<AndroidHomeScreen> createState() => _AndroidHomeScreenState();
}

class _AndroidHomeScreenState extends State<AndroidHomeScreen> {
  // Use late final to initialize only once
  late final SmsService _smsService;
  late final CallService _callService;
  late final QueueService _queueService;

  bool _isRunning = false;
  String _status = 'Durduruldu';
  int _queueCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    // Initialize services (singleton pattern ensures single instance)
    _smsService = SmsService();
    _callService = CallService();
    _queueService = QueueService();

    // Delay initialization to prevent blocking the first frame
    // Simply mark as loaded after a short delay, don't do any heavy work
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        // Load queue count AFTER UI is fully rendered
        _updateQueueCount();
      }
    });
  }

  Future<void> _updateQueueCount() async {
    try {
      final queue = await _queueService.getQueue();
      if (mounted) {
        setState(() {
          _queueCount = queue.length;
        });
      }
    } catch (e) {
      print('Queue count update error: $e');
      if (mounted) {
        setState(() {
          _queueCount = 0;
        });
      }
    }
  }

  Future<void> _startService() async {
    try {
      print('🚀 ========================================');
      print('🚀 SERVİS BAŞLATILIYOR...');
      print('🚀 ========================================');

      // Önce SMS izinlerini iste (bu zaten telefon iznini de içeriyor)
      print('📝 SMS izinleri isteniyor...');
      final smsPermission = await _smsService.requestPermissions();
      print('📝 SMS izin sonucu: $smsPermission');

      if (!smsPermission) {
        _showError('SMS izinleri reddedildi!');
        return;
      }

      // Telefon izni için try-catch (SMS izni ile birlikte verilmiş olabilir)
      bool callPermission = false;
      try {
        print('📞 Telefon izinleri isteniyor...');
        callPermission = await _callService.requestPermissions();
        print('📞 Telefon izin sonucu: $callPermission');
      } catch (e) {
        print('Call permission error (might be already granted): $e');
        callPermission = true; // SMS izni ile birlikte verilmiş varsay
      }

      if (!callPermission) {
        _showError('Arama izinleri reddedildi!');
        return;
      }

      print('✅ Tüm izinler verildi!');
      print('🎬 Dinleyiciler başlatılıyor...');

      // Servisleri başlat
      _smsService.startListening();
      _callService.startListening();
      _queueService.startQueueProcessor();

      print('✅ Tüm servisler başlatıldı!');
      print('📡 SMS ve aramaları dinlemeye hazır!');
      print('🚀 ========================================');

      setState(() {
        _isRunning = true;
        _status = 'Çalışıyor';
      });

      _showSuccess('Servis başlatıldı!');
    } catch (e) {
      print('❌ Start service error: $e');
      _showError('Servis başlatılamadı: ${e.toString()}');
    }
  }

  Future<void> _stopService() async {
    // Servisleri durdur
    _smsService.stopListening();
    _callService.stopListening();
    _queueService.stopQueueProcessor();

    setState(() {
      _isRunning = false;
      _status = 'Durduruldu';
    });
    _showSuccess('Servis durduruldu!');
  }

  @override
  void dispose() {
    // Cleanup
    if (_isRunning) {
      _smsService.stopListening();
      _callService.stopListening();
      _queueService.stopQueueProcessor();
    }
    super.dispose();
  }

  Future<void> _processQueue() async {
    await _queueService.processQueue();
    await _updateQueueCount();
    _showSuccess('Kuyruk işlendi!');
  }

  Future<void> _clearQueue() async {
    await _queueService.clearQueue();
    await _updateQueueCount();
    _showSuccess('Kuyruk temizlendi!');
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call SMS Forwarder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: _isLoading
          ? const SizedBox.shrink() // Boş alan, hiçbir şey render etme
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Icon(
                            _isRunning ? Icons.check_circle : Icons.cancel,
                            size: 64,
                            color: _isRunning ? Colors.green : Colors.red,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Durum: $_status',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _isRunning ? null : _startService,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Servisi Başlat'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: _isRunning ? _stopService : null,
                    icon: const Icon(Icons.stop),
                    label: const Text('Servisi Durdur'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(16),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          Text(
                            'Kuyrukta Bekleyen: $_queueCount',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _processQueue,
                                  child: const Text('Kuyruğu Gönder'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _clearQueue,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: const Text('Kuyruğu Temizle'),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Bilgi',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              '• Gelen SMS ve aramalar otomatik olarak Firebase\'e gönderilir',
                            ),
                            const Text('• İnternet yoksa kuyrukta bekletilir'),
                            const Text(
                              '• İnternet gelince otomatik gönderilir',
                            ),
                            const Text(
                              '• Web arayüzünden bildirimleri görebilirsiniz',
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
