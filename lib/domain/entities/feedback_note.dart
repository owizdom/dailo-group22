import 'package:equatable/equatable.dart';

/// A recommendation or complaint sent from the Feedback screen.
/// Stored at `users/{uid}/feedback/{id}`.
class FeedbackNote extends Equatable {
  const FeedbackNote({
    this.id = '',
    required this.message,
    required this.rating,
    required this.createdAt,
  });

  final String id;
  final String message;

  /// 1 (poor) to 5 (great).
  final int rating;
  final DateTime createdAt;

  /// The exact field names stored in Firestore, in ERD order.
  static const fields = ['message', 'rating', 'createdAt'];

  Map<String, Object?> toMap() {
    return {'message': message, 'rating': rating, 'createdAt': createdAt};
  }

  @override
  List<Object?> get props => [id, message, rating, createdAt];
}