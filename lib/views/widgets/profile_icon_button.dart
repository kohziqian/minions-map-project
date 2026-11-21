import 'package:flutter/material.dart';

import '../profile/profile_page.dart';

// Small person icon for profile page on top corner
class ProfileIconButton extends StatelessWidget {
  const ProfileIconButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Profile',
      icon: const Icon(Icons.account_circle_outlined),
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ProfilePage()),
        );
      },
    );
  }
}
