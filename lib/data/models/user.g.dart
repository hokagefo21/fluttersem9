// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

User _$UserFromJson(Map<String, dynamic> json) =>
    $checkedCreate('User', json, ($checkedConvert) {
      final val = User(
        id: $checkedConvert('id', (v) => (v as num).toInt()),
        name: $checkedConvert('name', (v) => v as String),
        email: $checkedConvert('email', (v) => v as String?),
        address: $checkedConvert(
          'address',
          (v) => v == null ? null : Address.fromJson(v as Map<String, dynamic>),
        ),
      );
      return val;
    });

Map<String, dynamic> _$UserToJson(User instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'email': instance.email,
  'address': instance.address?.toJson(),
};

Address _$AddressFromJson(Map<String, dynamic> json) =>
    $checkedCreate('Address', json, ($checkedConvert) {
      final val = Address(
        street: $checkedConvert('street', (v) => v as String?),
        city: $checkedConvert('city', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$AddressToJson(Address instance) => <String, dynamic>{
  'street': instance.street,
  'city': instance.city,
};
