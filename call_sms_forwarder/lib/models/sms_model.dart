class SmsModel {
  final String sender;
  final String message;
  final DateTime timestamp;

  SmsModel({
    required this.sender,
    required this.message,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'message': message,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': 'sms',
    };
  }

  factory SmsModel.fromJson(Map<String, dynamic> json) {
    return SmsModel(
      sender: json['sender'] ?? '',
      message: json['message'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }
}
