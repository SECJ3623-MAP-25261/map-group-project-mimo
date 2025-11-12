class User {
  String id;
  String name;
  String email;
  String phone;
  String profileImages;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.profileImages,
  });
}

class Renter {
  String userId;
  int pendingRequests;
  int itemListed;
  int returned;
  int reviews;
  double earnings;

  Renter({
    required this.userId,
    this.pendingRequests = 0,
    this.itemListed = 0,
    this.returned = 0,
    this.reviews = 0,
    this.earnings = 0.0,
  });
}
