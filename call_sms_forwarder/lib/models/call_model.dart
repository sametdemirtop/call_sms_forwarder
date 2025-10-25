class CallModel {
  final String caller;
  final String callType;
  final DateTime timestamp;

  CallModel({
    required this.caller,
    required this.callType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'caller': caller,
      'callType': callType,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'type': 'call',
    };
  }

  factory CallModel.fromJson(Map<String, dynamic> json) {
    return CallModel(
      caller: json['caller'] ?? '',
      callType: json['callType'] ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] ?? 0),
    );
  }
}
