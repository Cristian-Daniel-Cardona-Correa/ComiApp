import 'dart:convert';

/// Nivel culinario del usuario
enum CookingExperience {
  principiante,
  intermedio,
  avanzado,
}

extension CookingExperienceExt on CookingExperience {
  String get label {
    switch (this) {
      case CookingExperience.principiante:
        return 'Principiante';
      case CookingExperience.intermedio:
        return 'Intermedio';
      case CookingExperience.avanzado:
        return 'Avanzado';
    }
  }

  static CookingExperience fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'avanzado':
        return CookingExperience.avanzado;
      case 'intermedio':
        return CookingExperience.intermedio;
      case 'principiante':
      default:
        return CookingExperience.principiante;
    }
  }
}

/// Preferencias dietéticas y alergias
class DietaryPreferences {
  final bool isVegetarian;
  final bool isVegan;
  final bool isGlutenFree;
  final bool isDairyFree;
  final List<String> allergies;
  final CookingExperience experience;

  const DietaryPreferences({
    this.isVegetarian = false,
    this.isVegan = false,
    this.isGlutenFree = false,
    this.isDairyFree = false,
    this.allergies = const [],
    this.experience = CookingExperience.principiante,
  });

  DietaryPreferences copyWith({
    bool? isVegetarian,
    bool? isVegan,
    bool? isGlutenFree,
    bool? isDairyFree,
    List<String>? allergies,
    CookingExperience? experience,
  }) {
    return DietaryPreferences(
      isVegetarian: isVegetarian ?? this.isVegetarian,
      isVegan: isVegan ?? this.isVegan,
      isGlutenFree: isGlutenFree ?? this.isGlutenFree,
      isDairyFree: isDairyFree ?? this.isDairyFree,
      allergies: allergies ?? this.allergies,
      experience: experience ?? this.experience,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isVegetarian': isVegetarian,
      'isVegan': isVegan,
      'isGlutenFree': isGlutenFree,
      'isDairyFree': isDairyFree,
      'allergies': allergies,
      'experience': experience.name,
    };
  }

  factory DietaryPreferences.fromMap(Map<String, dynamic> map) {
    return DietaryPreferences(
      isVegetarian: map['isVegetarian'] as bool? ?? false,
      isVegan: map['isVegan'] as bool? ?? false,
      isGlutenFree: map['isGlutenFree'] as bool? ?? false,
      isDairyFree: map['isDairyFree'] as bool? ?? false,
      allergies: List<String>.from(map['allergies'] ?? const []),
      experience: CookingExperienceExt.fromString(map['experience'] as String?),
    );
  }
}

/// Modelo de usuario en comiAPP
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final DietaryPreferences preferences;
  final List<String> favoriteRecipeIds;
  final bool hasAcceptedPrivacyConsent;
  final DateTime createdAt;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.preferences = const DietaryPreferences(),
    this.favoriteRecipeIds = const [],
    this.hasAcceptedPrivacyConsent = false,
    required this.createdAt,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    DietaryPreferences? preferences,
    List<String>? favoriteRecipeIds,
    bool? hasAcceptedPrivacyConsent,
    DateTime? createdAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      preferences: preferences ?? this.preferences,
      favoriteRecipeIds: favoriteRecipeIds ?? this.favoriteRecipeIds,
      hasAcceptedPrivacyConsent:
          hasAcceptedPrivacyConsent ?? this.hasAcceptedPrivacyConsent,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'photoUrl': photoUrl,
      'preferences': preferences.toMap(),
      'favoriteRecipeIds': favoriteRecipeIds,
      'hasAcceptedPrivacyConsent': hasAcceptedPrivacyConsent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as String,
      name: map['name'] as String? ?? 'Cocinero comiAPP',
      email: map['email'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      preferences: map['preferences'] != null
          ? DietaryPreferences.fromMap(
              Map<String, dynamic>.from(map['preferences']))
          : const DietaryPreferences(),
      favoriteRecipeIds:
          List<String>.from(map['favoriteRecipeIds'] ?? const []),
      hasAcceptedPrivacyConsent:
          map['hasAcceptedPrivacyConsent'] as bool? ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  String toJson() => json.encode(toMap());

  factory UserProfile.fromJson(String source) =>
      UserProfile.fromMap(json.decode(source) as Map<String, dynamic>);
}
