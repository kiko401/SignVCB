class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.ageGroup,
    this.nickname,
  });

  final int id;
  final String username;
  final String ageGroup;
  final String? nickname;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: (json['username'] as String?) ?? '',
      ageGroup: (json['age_group'] as String?) ?? '',
      nickname: json['nickname'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'username': username,
        'age_group': ageGroup,
        'nickname': nickname,
      };
}

class AuthResponse {
  const AuthResponse({required this.token, required this.user});

  final String token;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: (json['token'] as String?) ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>? ?? const {}),
    );
  }
}
