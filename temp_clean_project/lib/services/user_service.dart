import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

Future<String> getCurrentUserFullName() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return 'Guest';

  final doc = await FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .get();

  final data = doc.data();
  if (data == null) return user.email ?? 'User';

  return (data['fullName'] as String?) ?? user.email ?? 'User';
}
