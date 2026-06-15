class LocationDto {
  final double lat;
  final double lng;
  final String? addressLine;

  const LocationDto({required this.lat, required this.lng, this.addressLine});

  factory LocationDto.fromJson(Map<String, dynamic> json) => LocationDto(
        lat: (json['lat'] as num).toDouble(),
        lng: (json['lng'] as num).toDouble(),
        addressLine: json['addressLine'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'lat': lat,
        'lng': lng,
        if (addressLine != null) 'addressLine': addressLine,
      };
}
