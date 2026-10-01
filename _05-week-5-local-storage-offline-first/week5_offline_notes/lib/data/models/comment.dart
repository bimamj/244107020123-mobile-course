class Comment {
  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  // Null-safe fromJson uses the `as Type?` casting combined with the `??` 
  // fallback operator. This prevents app crashes if the API omits a field 
  // or explicitly returns a null value.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: json['postId'] as int? ?? 0,
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown Name',
      email: json['email'] as String? ?? 'Unknown Email',
      body: json['body'] as String? ?? '',
    );
  }
}