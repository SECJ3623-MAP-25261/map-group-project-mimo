class AppConstants {
  // Filter categories
  static const List categories = [
    'all',
    'Shirt',
    'Pants',
    'Dress',
    'Jacket',
    'Traditional Wear',
    'Sportswear',
    'Formal',
    'Accessories',
    'Presentation',
    'Convocation',
    'Dinner',
    'Other',
  ];

  // Grid settings
  static const int gridCrossAxisCount = 4;
  static const double gridChildAspectRatio = 0.62;
  static const double gridCrossAxisSpacing = 16.0;
  static const double gridMainAxisSpacing = 16.0;

  // Validation
  static const int maxNameLength = 100;
  static const int maxDescriptionLength = 500;
  static const double minPrice = 0.0;
  static const double maxPrice = 10000.0;

  // Firebase collections
  static const String itemsCollection = 'items';
  static const String reviewsCollection = 'reviews';
  static const String bookingsCollection = 'bookings';
  static const String usersCollection = 'users';
  static const String chatsCollection = 'chats';
}