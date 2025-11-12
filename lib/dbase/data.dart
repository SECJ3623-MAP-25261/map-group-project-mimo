import '../models/user.dart';

final List<User> dummyUsers = [
  User(
    email: 'haikal04@graduate.utm.my',
    id: '1',
    name: 'Haikal ko',
    phone: '',
    profileImages: '',
  ),
];

/*final user1 = User(
  email: 'haikal04@graduate.utm.my',
  id: '1',
  name: 'Haikal Japri',
  phone: '',
  profileImages: '',
);

final renter1 = Renter(
  userId: user1.id,
  pendingRequests: 2,
  itemListed: 3,
  returned: 1,
  reviews: 5,
  earnings: 150.75,
);*/

final renter1 = Renter(
  userId: dummyUsers.first.id,
  pendingRequests: 2,
  itemListed: 3,
  returned: 1,
  reviews: 5,
  earnings: 150.75,
);



