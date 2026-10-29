class ClientRating {
  final String status;
  final String message;
  final int clientId;
  final int reviewsCount;
  final String clientImage;
  final double avgRating;

  ClientRating({
    required this.status,
    required this.message,
    required this.clientId,
    required this.reviewsCount,
    required this.clientImage,
    required this.avgRating,
  });

  factory ClientRating.fromJson(Map<String, dynamic> json) {
    return ClientRating(
      status: json['status'] ?? '',
      message: json['message'] ?? '',
      clientId: json['client_id'] ?? 0,
      reviewsCount: json['reviews_count'] ?? 0,
      clientImage: json['client_image'] ?? '',
      avgRating: (json['avg_rating'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'message': message,
      'client_id': clientId,
      'reviews_count': reviewsCount,
      'client_image': clientImage,
      'avg_rating': avgRating,
    };
  }
}
