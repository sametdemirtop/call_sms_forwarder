import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import '../services/firebase_service.dart';

class WebHomeScreen extends StatefulWidget {
  const WebHomeScreen({super.key});

  @override
  State<WebHomeScreen> createState() => _WebHomeScreenState();
}

class _WebHomeScreenState extends State<WebHomeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  List<Map<String, dynamic>> _calls = [];
  List<Map<String, dynamic>> _sms = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupNotifications();
    _loadData();
  }

  Future<void> _setupNotifications() async {
    // Web push notification izni iste
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Token al
    final token = await _firebaseService.getToken();
    print('FCM Token: $token');

    // Foreground bildirimleri dinle
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Bildirim alındı: ${message.notification?.title}');
      _loadData(); // Yeni veri geldiğinde yenile
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Call SMS Forwarder'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
        ],
        bottom: TabBar(
          controller: _tabController,
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [_buildCallsList(), _buildSmsList()],
            ),
    );
  }

  Widget _buildCallsList() {
    if (_calls.isEmpty) {
      return const Center(child: Text('Henüz arama kaydı yok'));
    }

    return ListView.builder(
      itemCount: _calls.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final call = _calls[index];
        final timestamp = call['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(call['timestamp'])
            : DateTime.now();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.phone_in_talk)),
            title: Text(call['caller'] ?? 'Bilinmeyen'),
            subtitle: Text(call['callType'] ?? 'Arama'),
            trailing: Text(
              '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  Widget _buildSmsList() {
    if (_sms.isEmpty) {
      return const Center(child: Text('Henüz SMS kaydı yok'));
    }

    return ListView.builder(
      itemCount: _sms.length,
      padding: const EdgeInsets.all(8),
      itemBuilder: (context, index) {
        final sms = _sms[index];
        final timestamp = sms['timestamp'] != null
            ? DateTime.fromMillisecondsSinceEpoch(sms['timestamp'])
            : DateTime.now();

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.sms)),
            title: Text(sms['sender'] ?? 'Bilinmeyen'),
            subtitle: Text(
              sms['message'] ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: Text(
              '${timestamp.day}/${timestamp.month} ${timestamp.hour}:${timestamp.minute.toString().padLeft(2, '0')}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
