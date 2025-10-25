import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../services/firebase_service.dart';

// Conditional import for web
import 'web_notification_stub.dart'
    if (dart.library.js) 'web_notification_web.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  Timer? _autoRefreshTimer;

  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _sms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
    _startAutoRefresh();
  }

  void _startAutoRefresh() {
    // Her 10 saniyede bir otomatik yenile
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final notifications = await _firebaseService.getAllNotifications();

      _calls = notifications.where((n) => n['type'] == 'call').toList();
      _sms = notifications.where((n) => n['type'] == 'sms').toList();
    } catch (e) {
      print('Veri yükleme hatası: $e');
    }

    setState(() {
      _isLoading = false;
    });
  }

  void _enableNotifications() {
    // Platform-specific implementation
    setupPushNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.call_end, color: Colors.white),
            const SizedBox(width: 8),
            const Text(
              'Call & SMS Dashboard',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF6200EA),
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: [
            Tab(
              icon: const Icon(Icons.phone),
              text: 'Aramalar (${_calls.length})',
            ),
            Tab(
              icon: const Icon(Icons.message),
              text: 'SMS\'ler (${_sms.length})',
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [const Color(0xFF6200EA).withOpacity(0.05), Colors.white],
          ),
        ),
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Veriler yükleniyor...',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [_buildCallsList(), _buildSmsList()],
              ),
      ),
      floatingActionButton: kIsWeb
          ? FloatingActionButton.extended(
              onPressed: _enableNotifications,
              backgroundColor: const Color(0xFF6200EA),
              icon: const Icon(Icons.notifications_active, color: Colors.white),
              label: const Text(
                'Bildirimleri Aç',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              elevation: 6,
            )
          : null,
    );
  }

  Widget _buildCallsList() {
    if (_calls.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.phone_disabled, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz arama kaydı yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _calls.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final call = _calls[index];
        final timestamp = call['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(call['timestamp'])
            : DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF6200EA).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_in_talk,
                color: Color(0xFF6200EA),
                size: 28,
              ),
            ),
            title: Text(
              call['caller'] ?? 'Bilinmeyen',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                call['callType'] ?? 'Arama',
                style: TextStyle(color: Colors.grey[600]),
              ),
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${timestamp.day}/${timestamp.month}/${timestamp.year}',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                const SizedBox(height: 4),
                Text(
                  '${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmsList() {
    if (_sms.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sms_failed, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Henüz SMS kaydı yok',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: _sms.length,
      padding: const EdgeInsets.all(16),
      itemBuilder: (context, index) {
        final sms = _sms[index];
        final timestamp = sms['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(sms['timestamp'])
            : DateTime.now();

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF03A9F4).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.sms,
                        color: Color(0xFF03A9F4),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sms['sender'] ?? 'Bilinmeyen',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${timestamp.day}/${timestamp.month}/${timestamp.year} - ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    sms['message'] ?? '',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
