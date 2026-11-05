import 'package:json_annotation/json_annotation.dart';
part 'user.g.dart';

@JsonSerializable(checked: true, explicitToJson: true)
class User {
  final int id;
  final String name;
  final String? email;
  final Address? address;
  const User({required this.id, required this.name, this.email, this.address});
  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);
}

@JsonSerializable(checked: true)
class Address {
  final String? street;
  final String? city;
  const Address({this.street, this.city});
  factory Address.fromJson(Map<String, dynamic> json) =>
      _$AddressFromJson(json);
  Map<String, dynamic> toJson() => _$AddressToJson(this);
}
