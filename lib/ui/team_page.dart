import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

class TeamMember {
  final String name;
  final String role;
  final String color;
  final String avatar;
  final String? imagePath;
  final String? link;

  TeamMember({
    required this.name,
    required this.role,
    required this.color,
    required this.avatar,
    this.imagePath,
    this.link,
  });

  factory TeamMember.fromJson(Map<String, dynamic> json) {
    return TeamMember(
      name: json['name'] as String,
      role: json['role'] as String,
      color: json['color'] as String,
      avatar: json['avatar'] as String,
      imagePath: json['imagePath'] as String?,
      link: json['link'] as String?,
    );
  }
}

class TeamPage extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onButtonSound;

  const TeamPage({
    required this.onBack,
    this.onButtonSound,
    super.key,
  });

  @override
  State<TeamPage> createState() => _TeamPageState();
}

class _TeamPageState extends State<TeamPage> {
  List<TeamMember> _teamMembers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTeamData();
  }

  Future<void> _loadTeamData() async {
    try {
      final String response = await rootBundle.loadString('team.json');
      final List<dynamic> data = json.decode(response);
      setState(() {
        _teamMembers = data.map((json) => TeamMember.fromJson(json)).toList();
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading team data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _launchUrl(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch $urlString');
    }
  }

  Color _getColorFromString(String colorName) {
    switch (colorName.toLowerCase()) {
      case 'blue':
        return Colors.blue;
      case 'amber':
        return Colors.amber;
      case 'cyan':
        return Colors.cyan;
      case 'purple':
        return Colors.purple;
      case 'green':
        return Colors.green;
      case 'pink':
        return Colors.pink;
      case 'orange':
        return Colors.orange;
      case 'teal':
        return Colors.teal;
      case 'indigo':
        return Colors.indigo;
      case 'red':
        return Colors.red;
      default:
        return Colors.blue;
    }
  }

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
                      widget.onButtonSound?.call();
                      widget.onBack();
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
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white,
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 10),
                      itemCount: _teamMembers.length,
                      itemBuilder: (context, index) {
                        final member = _teamMembers[index];
                        return _buildTeamCard(
                          member: member,
                          color: _getColorFromString(member.color),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showImageDialog(
      BuildContext context, String imagePath, String name, Color color) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withOpacity(0.8),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: ScaleTransition(
              scale: CurvedAnimation(
                parent: animation,
                curve: Curves.easeOutBack,
              ),
              child: Container(
                margin: const EdgeInsets.all(40),
                decoration: BoxDecoration(
                  color: const Color(0xFF0A1628),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: color.withOpacity(0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: color.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header with name and close button
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.pixelifySans(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close,
                                color: Colors.white, size: 28),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    // Large image
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Image.asset(
                            imagePath,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildTeamCard({
    required TeamMember member,
    required Color color,
  }) {
    final bool hasLink = member.link != null && member.link!.isNotEmpty;

    Widget cardContent = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.12),
            color.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withOpacity(0.2),
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 300;

            if (isSmallScreen) {
              // Column layout for small screens
              return Column(
                children: [
                  // Avatar - either image or emoji icon
                  GestureDetector(
                    onTap: member.imagePath != null
                        ? () {
                            widget.onButtonSound?.call();
                            _showImageDialog(
                                context, member.imagePath!, member.name, color);
                          }
                        : null,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: member.imagePath == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.8),
                                  color.withOpacity(0.4),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: member.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                member.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color.withOpacity(0.8),
                                          color.withOpacity(0.4),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        member.avatar,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                member.avatar,
                                style: const TextStyle(fontSize: 32),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Name and role
                  Column(
                    children: [
                      Text(
                        member.name,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        member.role,
                        style: GoogleFonts.pixelifySans(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.85),
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      // Chevron icon if clickable
                      if (hasLink) ...[
                        const SizedBox(height: 8),
                        Icon(
                          Icons.chevron_right,
                          color: color.withOpacity(0.7),
                          size: 32,
                        ),
                      ],
                    ],
                  ),
                ],
              );
            } else {
              // Row layout for larger screens
              return Row(
                children: [
                  // Avatar - either image or emoji icon
                  GestureDetector(
                    onTap: member.imagePath != null
                        ? () {
                            widget.onButtonSound?.call();
                            _showImageDialog(
                                context, member.imagePath!, member.name, color);
                          }
                        : null,
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: member.imagePath == null
                            ? LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  color.withOpacity(0.8),
                                  color.withOpacity(0.4),
                                ],
                              )
                            : null,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: color.withOpacity(0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: member.imagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.asset(
                                member.imagePath!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          color.withOpacity(0.8),
                                          color.withOpacity(0.4),
                                        ],
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        member.avatar,
                                        style: const TextStyle(fontSize: 32),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            )
                          : Center(
                              child: Text(
                                member.avatar,
                                style: const TextStyle(fontSize: 32),
                              ),
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
                          member.name,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          member.role,
                          style: GoogleFonts.pixelifySans(
                            fontSize: 16,
                            color: Colors.white.withOpacity(0.85),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Chevron icon if clickable
                  if (hasLink)
                    Icon(
                      Icons.chevron_right,
                      color: color.withOpacity(0.7),
                      size: 32,
                    ),
                ],
              );
            }
          },
        ),
      ),
    );

    // Wrap in GestureDetector if there's a link
    if (hasLink) {
      return GestureDetector(
        onTap: () {
          widget.onButtonSound?.call();
          _launchUrl(member.link!);
        },
        child: cardContent,
      );
    }

    return cardContent;
  }
}
