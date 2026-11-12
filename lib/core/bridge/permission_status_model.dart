class PermissionStatusModel {
  final bool mic;
  final bool phone;
  final bool notification;
  final bool accessibility;
  final bool batteryIgnored;

  const PermissionStatusModel({
    required this.mic,
    required this.phone,
    required this.notification,
    required this.accessibility,
    required this.batteryIgnored,
  });

  factory PermissionStatusModel.initial() {
    return const PermissionStatusModel(
      mic: false,
      phone: false,
      notification: false,
      accessibility: false,
      batteryIgnored: false,
    );
  }

  factory PermissionStatusModel.fromMap(Map<dynamic, dynamic>? map) {
    if (map == null) return PermissionStatusModel.initial();
    return PermissionStatusModel(
      mic: map['mic'] == true,
      phone: map['phone'] == true,
      notification: map['notification'] == true,
      accessibility: map['accessibility'] == true,
      batteryIgnored: map['batteryIgnored'] == true,
    );
  }

  bool get areCorePermissionsGranted => mic && phone && notification;

  bool get isAllGranted =>
      mic && phone && notification && accessibility && batteryIgnored;

  PermissionStatusModel copyWith({
    bool? mic,
    bool? phone,
    bool? notification,
    bool? accessibility,
    bool? batteryIgnored,
  }) {
    return PermissionStatusModel(
      mic: mic ?? this.mic,
      phone: phone ?? this.phone,
      notification: notification ?? this.notification,
      accessibility: accessibility ?? this.accessibility,
      batteryIgnored: batteryIgnored ?? this.batteryIgnored,
    );
  }
}
