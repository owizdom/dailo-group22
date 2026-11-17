import 'package:equatable/equatable.dart';

import 'dates.dart';
import 'network.dart';

/// Someone the user pays. Stored at `users/{uid}/recipients/{id}`.
class Recipient extends Equatable {
  const Recipient({
    required this.id,
    required this.name,
    required this.phone,
    required this.network,
    this.isFavorite = false,
    this.lastPaidAt,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Empty until Firestore assigns one.
  final String id;
  final String name;

  /// Always in the `07XXXXXXXX` form.
  final String phone;
  final Network network;
  final bool isFavorite;

  /// Null until the first confirmed payment. Recents are sorted by this.
  final DateTime? lastPaidAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The longest name the server accepts (see firestore.rules).
  static const maxNameLength = 60;

  /// The exact field names stored in Firestore, in ERD order.
  static const fields = [
    'name',
    'phone',
    'network',
    'isFavorite',
    'lastPaidAt',
    'createdAt',
    'updatedAt',
  ];

  /// What to show as the title: the saved name, or the number when the
  /// recipient was typed in and never named.
  String get displayName => name.isEmpty ? phone : name;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'phone': phone,
      'network': network.wire,
      'isFavorite': isFavorite,
      'lastPaidAt': lastPaidAt,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory Recipient.fromMap(String id, Map<String, Object?> map) {
    // A document with no date yet is read as created now.
    final now = DateTime.now();
    return Recipient(
      id: id,
      name: map['name'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      network: Network.fromWire(map['network']),
      isFavorite: map['isFavorite'] as bool? ?? false,
      lastPaidAt: readDateOrNull(map['lastPaidAt']),
      createdAt: readDate(map['createdAt'], fallback: now),
      updatedAt: readDate(map['updatedAt'], fallback: now),
    );
  }

  Recipient copyWith({
    String? id,
    String? name,
    String? phone,
    Network? network,
    bool? isFavorite,
    DateTime? lastPaidAt,
    DateTime? updatedAt,
  }) {
    return Recipient(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      network: network ?? this.network,
      isFavorite: isFavorite ?? this.isFavorite,
      lastPaidAt: lastPaidAt ?? this.lastPaidAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    phone,
    network,
    isFavorite,
    lastPaidAt,
    createdAt,
    updatedAt,
  ];
}
