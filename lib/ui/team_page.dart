import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TeamPage extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback? onButtonSound;

  const TeamPage({
    required this.onBack,
    this.onButtonSound,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 28),
                    onPressed: () {
                      onButtonSound?.call();
                      onBack();
                    },
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'OUR TEAM',
                    style: GoogleFonts.pixelifySans(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
            ),

            // Team members list
            Expanded(
              child: ListView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                children: [
                  _buildTeamCard(
                    name: 'Alex Johnson',
                    role: 'Project Lead & Game Designer',
                    color: Colors.blue,
                    avatar: '🎮',
                  ),
                  _buildTeamCard(
                    name: 'Sarah Al-Hashimi',
                    role: 'Heritage Researcher',
                    color: Colors.amber,
                    avatar: '📚',
                  ),
                  _buildTeamCard(
                    name: 'Omar Khalil',
                    role: 'Lead Developer',
                    color: Colors.cyan,
                    avatar: '💻',
                  ),
                  _buildTeamCard(
                    name: 'Layla Abbas',
                    role: 'UI/UX Designer',
                    color: Colors.purple,
                    avatar: '🎨',
                  ),
                  _buildTeamCard(
                    name: 'Mohammed Razaq',
                    role: 'Sound Designer',
                    color: Colors.green,
                    avatar: '🎵',
                  ),
                  _buildTeamCard(
                    name: 'Fatima Hassan',
                    role: '2D Artist & Animator',
                    color: Colors.pink,
                    avatar: '✨',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamCard({
    required String name,
    required String role,
    required Color color,
    required String avatar,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    color.withOpacity(0.8),
                    color.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  avatar,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
            ),
            const SizedBox(width: 20),
            // Name and role
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    role,
                    style: GoogleFonts.pixelifySans(
                      fontSize: 14,
                      color: color.withOpacity(0.9),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
