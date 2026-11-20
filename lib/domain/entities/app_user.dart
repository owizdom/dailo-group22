import 'package:equatable/equatable.dart';

import 'dates.dart';
import 'network.dart';

/// A DailO account profile. Stored at `users/{uid}`.
class AppUser extends Equatable {
  const AppUser({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.phone,
    required this.network,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String firstName;
  final String lastName;
  final String email;

  /// The user's own mobile money number, shown in their payment QR code.
  final String phone;
  final Network network;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The exact field names stored in Firestore, in ERD order.
  static const fields = [
    'firstName',
    'lastName',
    'email',
    'phone',
    'network',
    'createdAt',
    'updatedAt',
  ];

  String get fullName => '$firstName $lastName'.trim();

  Map<String, Object?> toMap() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'network': network.wire,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  factory AppUser.fromMap(String uid, Map<String, Object?> map) {
    // A document with no date yet is read as created now.
    final now = DateTime.now();
    return AppUser(
      uid: uid,
      firstName: map['firstName'] as String? ?? '',
      lastName: map['lastName'] as String? ?? '',
      email: map['email'] as String? ?? '',
      phone: map['phone'] as String? ?? '',
      network: Network.fromWire(map['network']),
      createdAt: readDate(map['createdAt'], fallback: now),
      updatedAt: readDate(map['updatedAt'], fallback: now),
    );
  }

  AppUser copyWith({
    String? firstName,
    String? lastName,
    String? phone,
    Network? network,
    DateTime? updatedAt,
  }) {
    return AppUser(
      uid: uid,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      phone: phone ?? this.phone,
      network: network ?? this.network,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
    uid,
    firstName,
    lastName,
    email,
    phone,
    network,
    createdAt,
    updatedAt,
  ];
}
