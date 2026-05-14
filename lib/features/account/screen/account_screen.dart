import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/app_photo_store.dart';
import '../../../services/backup_service.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  static const _nameKey = 'account_name';
  static const _emailKey = 'account_email';
  static const _bioKey = 'account_bio';
  static const _createdKey = 'account_created_at';

  final AppPhotoStore _photoStore = const AppPhotoStore();
  final BackupService _backupService = const BackupService();
  String _name = 'Guest User';
  String _email = 'guest@gpscamera.local';
  String _bio = '';
  DateTime _createdAt = DateTime.now();
  int _photoCount = 0;
  int _locationCount = 0;
  bool _backupEnabled = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final photos = await _photoStore.loadPhotos();
    final createdRaw = prefs.getString(_createdKey);
    if (createdRaw == null) {
      await prefs.setString(_createdKey, DateTime.now().toIso8601String());
    }
    if (!mounted) return;
    setState(() {
      _name = prefs.getString(_nameKey) ?? 'Guest User';
      _email = prefs.getString(_emailKey) ?? 'guest@gpscamera.local';
      _bio = prefs.getString(_bioKey) ?? '';
      _createdAt = DateTime.tryParse(createdRaw ?? '') ?? DateTime.now();
      _photoCount = photos.length;
      _locationCount = photos.map((p) => p.locationInfo.address).toSet().length;
    });
  }

  Future<void> _editProfile() async {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);
    final bioController = TextEditingController(text: _bio);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 44, child: Text(_initials, style: const TextStyle(fontSize: 28))),
                const Positioned(
                  right: 0,
                  bottom: 0,
                  child: CircleAvatar(radius: 16, child: Icon(Icons.camera_alt, size: 16)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
            TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
            TextField(
              controller: bioController,
              maxLength: 100,
              decoration: const InputDecoration(labelText: 'Bio / note'),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nameKey, nameController.text.trim().isEmpty ? 'Guest User' : nameController.text.trim());
    await prefs.setString(_emailKey, emailController.text.trim());
    await prefs.setString(_bioKey, bioController.text.trim());
    await _load();
  }

  String get _initials {
    final parts = _name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'G';
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(title: const Text('Account'), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(colors: [Color(0xFF2B2B2B), Color(0xFF111111)]),
              border: Border.all(color: Colors.white12),
            ),
            child: Column(
              children: [
                CircleAvatar(radius: 46, backgroundColor: AppColors.primary, child: Text(_initials, style: const TextStyle(fontSize: 30, color: Colors.white))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_name, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
                    IconButton(onPressed: _editProfile, icon: const Icon(Icons.edit, color: Colors.white70)),
                  ],
                ),
                Text(_email, style: const TextStyle(color: Colors.white70)),
                if (_bio.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 8), child: Text(_bio, style: const TextStyle(color: Colors.white70))),
                TextButton(onPressed: _editProfile, child: const Text('Edit Profile')),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withValues(alpha: .15), borderRadius: BorderRadius.circular(12)),
                  child: const Text("You're using Guest Mode — sign in to back up your photos.", style: TextStyle(color: Colors.amber)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _stat('📸', 'Photos Taken', _photoCount.toString()),
              _stat('📍', 'Locations', _locationCount.toString()),
              _stat('🗓️', 'Member Since', DateFormat('MMM yyyy').format(_createdAt)),
            ],
          ),
          const SizedBox(height: 16),
          _tile(Icons.cloud_upload, 'Backup & Sync', () => _showBackup()),
          _tile(Icons.photo_library, 'My Photos', () => Navigator.pushNamed(context, AppConstants.routeGallery)),
          _tile(Icons.location_on, 'Saved Locations', () => Navigator.pushNamed(context, AppConstants.routeLocations)),
          _tile(Icons.privacy_tip, 'Privacy Policy', () => _placeholder('Privacy Policy')),
          _tile(Icons.star_rate, 'Rate the App', () => _placeholder('Rate the App')),
          _tile(Icons.help_outline, 'Help & Support', () => _placeholder('Help & Support')),
          _tile(Icons.logout, 'Sign Out', _signOut),
        ],
      ),
    );
  }

  Widget _stat(String emoji, String label, String value) => Expanded(
        child: Card(
          color: const Color(0xFF1D1D1D),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(children: [Text(emoji), Text(value, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)), Text(label, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11))]),
          ),
        ),
      );

  Widget _tile(IconData icon, String title, VoidCallback onTap) => Card(
        child: ListTile(leading: Icon(icon), title: Text(title), trailing: const Icon(Icons.chevron_right), onTap: onTap),
      );

  void _placeholder(String title) => showModalBottomSheet<void>(
        context: context,
        builder: (_) => SizedBox(height: 180, child: Center(child: Text('$title coming soon'))),
      );

  void _showBackup() => showModalBottomSheet<void>(
        context: context,
        builder: (_) => StatefulBuilder(builder: (context, setSheetState) {
          return SafeArea(
            child: SwitchListTile(
              title: const Text('Auto-backup photos to Firebase Storage'),
              subtitle: const Text('Sign in with Google to enable cloud backup.'),
              value: _backupEnabled,
              onChanged: (value) async {
                setSheetState(() => _backupEnabled = value);
                if (value) {
                  final photos = await _photoStore.loadPhotos();
                  await _backupService
                      .uploadPhotosForUser(userId: 'guest', photos: photos)
                      .last;
                }
              },
            ),
          );
        }),
      );

  Future<void> _signOut() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Sign Out')),
        ],
      ),
    );
    if (confirm != true) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_nameKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_bioKey);
    if (mounted) Navigator.popUntil(context, (route) => route.isFirst);
  }
}
