class User {
  final String username;
  final String email;
  final String? avatar;

  User({
    required this.username,
    required this.email,
    this.avatar,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      username: json['username'],
      email: json['email'],
      avatar: json['avatar'],
    );
  }
}
