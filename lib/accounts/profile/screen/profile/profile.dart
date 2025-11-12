import 'package:campus_closet/models/user.dart';
import 'package:flutter/material.dart';
import '../../../../dbase/data.dart';

class ProfileScreen extends StatelessWidget {

  
  // final String name = "Haikal Japri";
  // final String email = "haikal04@graduate.utm.my";
  final user = user1;
<<<<<<< Updated upstream

=======
  final renter = renter1;
  //const ProfileScreen({super.key});
>>>>>>> Stashed changes
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A),
      body: Center(
        child: Container(
          width: 320,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B2A),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize:MainAxisSize.min,
            children: [

              CircleAvatar(
                radius: 45,
                backgroundColor: Colors.blueGrey[700],
                backgroundImage: AssetImage('assets/images/profile_placeholder.png'),
                ),

              const SizedBox(height: 30),
              const SizedBox(height: 10),
              Text(
                "MY PROFILE",
                style: TextStyle(
                  color: const Color(0xFF0D1B2A),
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 12),
              Text(
<<<<<<< Updated upstream
                user.name,
=======
                user1.name,
>>>>>>> Stashed changes
                style: const TextStyle(
                  color:  Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              Text(
<<<<<<< Updated upstream
                user.email,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
=======
                user1.email,
                style: const TextStyle(color: Colors.white, fontSize: 14),
>>>>>>> Stashed changes
              ),

              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0D1B2A),
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/editProfile');
                },
                child: const Text(
                  "Edit Profile",
                  style:  TextStyle(color: Colors.white, fontSize: 16),
                  
                ),
              ),

              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadiusGeometry.circular(12),
                  ),
                ),

                onPressed: () {
                  //Delete Account Logic
                },

                child: const Text(
                  "Delete Account",
                  style: TextStyle(color: Colors.white, fontSize: 16),
                )
              ),


              // === List of Options ===
              _buildProfileOption("Change Password", Icons.lock, context),
              _buildProfileOption("Update Email / Phone", Icons.email, context),
<<<<<<< Updated upstream
              _buildProfileOption("Manage Notifications", Icons.notifications, context),
              _buildProfileOption("View Activity", Icons.history, context),
=======
              _buildProfileOption("Manage Notifications", Icons.notifications,context,),
              _buildProfileOption("View Activity", Icons.history, context),
              _buildProfileOption("Personalization Settings",Icons.color_lens,context,),
>>>>>>> Stashed changes

              const SizedBox(height: 40),
              const Text(
                "Campus Closet © 2025",
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption(String text, IconData icon, BuildContext context) {
    return GestureDetector(
      onTap: () {
<<<<<<< Updated upstream
        // Add navigation for each option
=======
        if (text == "Personalization Settings") {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  CampusClosetApp(renter: renter1, user: user1),
            ),
          );
        }
        else if(text == "Change Password"){
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context)=> ChangePasswordPage())
          );
        }

        else if(text == "Update Email / Phone"){
          Navigator.push(context, MaterialPageRoute(builder: (context)=> UpdateContactPage()));
        }
         else if(text == "Manage Notifications"){
          Navigator.push(context,MaterialPageRoute(builder: (context)=>NotificationsPage()));
         }
         else if(text=="View Activity"){
          Navigator.push(context, MaterialPageRoute(builder: (context)=>ViewActivityPage()));
         }
        
>>>>>>> Stashed changes
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 32),
        child: Row(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(width: 10),
            Text(
              text,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }
}