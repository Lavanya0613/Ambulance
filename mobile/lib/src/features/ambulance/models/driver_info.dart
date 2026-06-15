class DriverInfo {
  final String vendorDriverRef;
  final String name;
  final String? phoneE164;
  final String? vehicleNumber;
  final String? ambulanceType;

  const DriverInfo({
    required this.vendorDriverRef,
    required this.name,
    this.phoneE164,
    this.vehicleNumber,
    this.ambulanceType,
  });

  factory DriverInfo.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const DriverInfo(vendorDriverRef: '', name: '');
    }
    return DriverInfo(
      vendorDriverRef: json['vendorDriverRef'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phoneE164: json['phoneE164'] as String?,
      vehicleNumber: json['vehicleNumber'] as String?,
      ambulanceType: json['ambulanceType'] as String?,
    );
  }
}
