import 'package:material_ui/material_ui.dart';

import '../../../core/theme/app_colors.dart';

/// Accent color palette for decks, derived deterministically from deck ID.
/// Not stored in database — purely UI concern.
const _deckAccentColors = [
  AppColors.purple,
  AppColors.orange,
  AppColors.teal,
  AppColors.lime,
  AppColors.sky,
  AppColors.coral,
];

/// Returns a deterministic accent color for a deck based on its ID hash.
Color deckColorFromId(String id) {
  return _deckAccentColors[id.hashCode.abs() % _deckAccentColors.length];
}

class DeckModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final DateTime createdAt;
  final DateTime updatedAt;

  const DeckModel({
    required this.id,
    required this.userId,
    required this.title,
    this.description = '',
    required this.createdAt,
    required this.updatedAt,
  });

  /// Deterministic accent color derived from [id] hash.
  /// Not stored in DB — purely a UI convenience.
  Color get color => deckColorFromId(id);

  /// Creates a [DeckModel] from a Supabase row map.
  factory DeckModel.fromMap(Map<String, dynamic> map) {
    return DeckModel(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      description: (map['description'] as String?) ?? '',
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Map for inserting a new deck into Supabase.
  /// Requires [userId] to satisfy RLS `decks_insert_own` policy.
  Map<String, dynamic> toInsertMap() {
    return {
      'user_id': userId,
      'title': title.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
    };
  }

  /// Map for updating an existing deck in Supabase.
  /// Only title and description are user-editable.
  Map<String, dynamic> toUpdateMap() {
    return {
      'title': title.trim(),
      'description': description.trim().isEmpty ? null : description.trim(),
    };
  }

  DeckModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DeckModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
