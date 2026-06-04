import 'package:flutter/material.dart';
import '../models/review_model.dart';
import '../models/technician_model.dart';

class ReviewProvider extends ChangeNotifier {
  List<Review> _reviews = [];

  List<Review> get reviews => _reviews;
  
  List<Review> getTechnicianReviews(String technicianId) {
    return _reviews.where((r) => r.technicianId == technicianId).toList();
  }
  
  double getTechnicianAverageRating(String technicianId) {
    final techReviews = getTechnicianReviews(technicianId);
    if (techReviews.isEmpty) return 0;
    final sum = techReviews.fold<double>(0, (total, review) => total + review.rating);
    return sum / techReviews.length;
  }

  Future<void> addReview({
    required String bookingId,
    required String technicianId,
    required String userId,
    required String userName,
    required double rating,
    required String comment,
  }) async {
    final review = Review(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      bookingId: bookingId,
      technicianId: technicianId,
      userId: userId,
      userName: userName,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );
    
    _reviews.add(review);
    notifyListeners();
  }
  
  // Update technician rating (mock)
  Future<void> updateTechnicianRating(Technician technician) async {
    // In real app, update in database
    notifyListeners();
  }
}