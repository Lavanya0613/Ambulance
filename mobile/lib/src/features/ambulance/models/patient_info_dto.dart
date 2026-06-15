class PatientInfoDto {
  final String name;
  final String phoneE164;
  final int? age;
  final String? notes;

  const PatientInfoDto({required this.name, required this.phoneE164, this.age, this.notes});

  factory PatientInfoDto.fromJson(Map<String, dynamic> json) => PatientInfoDto(
        name: json['name'] as String? ?? '',
        phoneE164: json['phoneE164'] as String? ?? '',
        age: (json['age'] as num?)?.toInt(),
        notes: json['notes'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'phoneE164': phoneE164,
        if (age != null) 'age': age,
        if (notes != null) 'notes': notes,
      };
}
