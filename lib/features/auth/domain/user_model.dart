class UserModel {
  final String id;
  final String username;
  final String displayName;
  final DateTime createdAt;

  const UserModel({
    required this.id,
    required this.username,
    required this.displayName,
    required this.createdAt,
  });

  factory UserModel.fromProfileMap(Map<String, dynamic> map) {
    final username = (map['username'] as String?)?.trim().toLowerCase() ?? '';
    final rawDisplay = (map['display_name'] as String?)?.trim();
    final displayName = (rawDisplay != null && rawDisplay.isNotEmpty)
        ? rawDisplay
        : (username.isNotEmpty ? username : 'User');

    return UserModel(
      id: map['id'] as String,
      username: username,
      displayName: displayName,
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? displayName,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
