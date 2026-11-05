import 'package:json_annotation/json_annotation.dart';
part 'post.g.dart';

@JsonSerializable(checked: true)
class Post {
  final int id;
  final int userId;
  final String title;
  final String body;
  @JsonKey(defaultValue: false)
  final bool local;
  const Post({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    this.local = false,
  });
  factory Post.fromJson(Map<String, dynamic> json) => _$PostFromJson(json);
  Map<String, dynamic> toJson() => _$PostToJson(this);
}
