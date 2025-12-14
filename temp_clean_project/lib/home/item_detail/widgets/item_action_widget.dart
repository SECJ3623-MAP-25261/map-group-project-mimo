// lib/sprint2/Booking Rentee/item_action_widget.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:profile_managemenr/constants/app_colors.dart';
import 'package:profile_managemenr/sprint2/Rentee/Booking%20Rentee/booking.dart';
import 'package:profile_managemenr/sprint2/chatMessaging/item_chat_screen.dart';
import 'package:profile_managemenr/services/user_service.dart';

class ItemActionsWidget extends StatelessWidget {
  final Map item; // masih Map (dynamic) — tak apa

  const ItemActionsWidget({Key? key, required this.item}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final renterId = item['renterId'] as String?;
    final renterName = item['renterName'] as String? ?? 'Renter';

    // 💡 CAST ITEM KE Map<String, dynamic> SEBELUM HANTAR
    final Map<String, dynamic> safeItem = (item).cast<String, dynamic>();

    if (user != null && renterId != null && renterId != user.uid) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                // ✅ Hantar safeItem (Map<String, dynamic>)
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BookingScreen(itemData: safeItem),
                  ),
                );
              },
              icon: const Icon(Icons.calendar_today),
              label: const Text('Book Now'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final sorted = [user.uid, renterId]..sort();
                final chatId = '${item['id']}|${sorted[0]}|${sorted[1]}';
                final renteeName = await getCurrentUserFullName();

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ItemChatScreen(
                      chatId: chatId,
                      itemId: item['id'],
                      itemName: item['name'] ?? 'Item',
                      renterId: renterId,
                      renterName: renterName,
                      renteeId: user.uid,
                      renteeName: renteeName,
                      itemImages: item['images'],
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Message Renter'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentColor,
                side: const BorderSide(color: AppColors.accentColor),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      );
    } else if (renterId == user?.uid) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.accentColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.accentColor),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'This is your item',
                style: TextStyle(color: AppColors.accentColor),
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          children: [
            Icon(Icons.login, color: Colors.orange),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'Please log in to book or message',
                style: TextStyle(color: Colors.orange),
              ),
            ),
          ],
        ),
      );
    }
  }
}