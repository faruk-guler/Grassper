import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:url_launcher/url_launcher.dart';
import '../providers/note_provider.dart';
import '../core/constants.dart';
import '../core/strings.dart';
import 'archive_screen.dart';
import 'trash_screen.dart';
import '../core/enums.dart';

class ProfileSettingsScreen extends StatefulWidget {
  const ProfileSettingsScreen({super.key});

  @override
  State<ProfileSettingsScreen> createState() => _ProfileSettingsScreenState();
}

class _ProfileSettingsScreenState extends State<ProfileSettingsScreen> {
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<NoteProvider>(context, listen: false);
    _emailController = TextEditingController(text: provider.backupEmail);
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<NoteProvider>(context);
    final theme = Theme.of(context);

    // Update controller if provider value changes externally (e.g. from backup)
    if (_emailController.text != provider.backupEmail && provider.backupEmail != null) {
       _emailController.text = provider.backupEmail!;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.profileSettings, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: theme.textTheme.bodyLarge?.color,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Profile Avatar
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null && mounted) {
                    final bytes = await image.readAsBytes();
                    final base64String = base64Encode(bytes);
                    if (mounted) {
                      context.read<NoteProvider>().setProfilePicture(base64String);
                    }
                  }
                },
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    shape: BoxShape.circle,
                    border: Border.all(color: theme.dividerColor, width: 2),
                    image: provider.profilePictureBase64 != null
                        ? DecorationImage(
                            image: MemoryImage(base64Decode(provider.profilePictureBase64!)),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: provider.profilePictureBase64 == null
                      ? Icon(Icons.add_a_photo, size: 40, color: theme.iconTheme.color)
                      : null,
                ),
              ),
              if (provider.profilePictureBase64 != null)
                TextButton(
                  onPressed: () {
                    provider.removeProfilePicture();
                  },
                  child: Text(AppStrings.removePhoto, style: const TextStyle(color: AppColors.danger)),
                ),
              const SizedBox(height: 32),

              // Settings Form
              _buildSettingGroup(
                context,
                label: 'Görünüm ve Kullanım',
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Ayna Modu',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: provider.isLeftHanded,
                            onChanged: (val) => provider.toggleLeftHandedMode(),
                            activeColor: theme.primaryColor,
                          ),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Not Görünümü (Grid)',
                              style: TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: provider.isGridView,
                            onChanged: (val) => provider.toggleViewMode(),
                            activeColor: theme.primaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.language,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<AppLanguage>(
                      value: provider.language,
                      isExpanded: true,
                      dropdownColor: theme.scaffoldBackgroundColor,
                      items: [
                        DropdownMenuItem(
                          value: AppLanguage.tr,
                          child: Text(AppStrings.turkish),
                        ),
                        DropdownMenuItem(
                          value: AppLanguage.en,
                          child: Text(AppStrings.english),
                        ),
                      ],
                      onChanged: (lang) {
                        if (lang != null) {
                          provider.setLanguage(lang);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.backupEmail,
                child: TextField(
                  controller: _emailController,
                  onChanged: (value) => provider.setBackupEmail(value),
                  decoration: InputDecoration(
                    hintText: AppStrings.emailHint,
                    filled: true,
                    fillColor: theme.cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.emailBackup,
                child: ElevatedButton.icon(
                  onPressed: () {
                    if (provider.backupEmail == null || provider.backupEmail!.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.enterEmailFirst)),
                      );
                    } else {
                      provider.syncToEmail();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(AppStrings.syncStarting)),
                      );
                    }
                  },
                  icon: const Icon(Icons.sync),
                  label: Text(AppStrings.syncNow),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.cardColor,
                    foregroundColor: theme.textTheme.bodyLarge?.color,
                    elevation: 0,
                    side: BorderSide(color: theme.dividerColor),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.dailyAutoBackup,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              AppStrings.dailyAutoBackup,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Switch(
                            value: provider.autoBackupEnabled,
                            onChanged: (val) => provider.setAutoBackup(val),
                            activeColor: theme.primaryColor,
                          ),
                        ],
                      ),
                      if (provider.autoBackupEnabled) ...[
                        const Divider(),
                        Text(
                          '${AppStrings.lastAutoBackup}${provider.lastAutoBackupTime != null ? provider.lastAutoBackupTime!.toString().split('.')[0] : AppStrings.never}',
                          style: TextStyle(
                            fontSize: 12,
                            color: theme.iconTheme.color?.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.weekStartDay,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: theme.cardColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.dividerColor),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StartingDayOfWeek>(
                      value: provider.startingDayOfWeek,
                      isExpanded: true,
                      dropdownColor: theme.scaffoldBackgroundColor,
                      items: [
                        DropdownMenuItem(
                          value: StartingDayOfWeek.monday,
                          child: Text(AppStrings.monday),
                        ),
                        DropdownMenuItem(
                          value: StartingDayOfWeek.sunday,
                          child: Text(AppStrings.sunday),
                        ),
                      ],
                      onChanged: (day) {
                        if (day != null) {
                          provider.setStartingDayOfWeek(day);
                        }
                      },
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              _buildSettingGroup(
                context,
                label: AppStrings.dataBackup,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final result = await provider.importNotes();
                          if (!mounted) return;
                          if (result >= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppStrings.importSuccess(result))),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(AppStrings.importFailed)),
                            );
                          }
                        },
                        icon: const Icon(Icons.upload),
                        label: Text(AppStrings.importNotes),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          elevation: 0,
                          side: BorderSide(color: theme.dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => provider.exportNotes(),
                        icon: const Icon(Icons.download),
                        label: Text(AppStrings.exportNotes),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.cardColor,
                          foregroundColor: theme.textTheme.bodyLarge?.color,
                          elevation: 0,
                          side: BorderSide(color: theme.dividerColor),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const Divider(height: 48),

              // Navigation Tiles for Archive and Trash
              _buildNavigationTile(
                context,
                icon: Icons.archive_outlined,
                title: AppStrings.archivedNotes,
                subtitle: AppStrings.noteCount(provider.notes.where((n) => n.isArchived).length),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArchiveScreen())),
              ),
              const SizedBox(height: 12),
              _buildNavigationTile(
                context,
                icon: Icons.delete_outline,
                title: AppStrings.trash,
                subtitle: AppStrings.noteCount(provider.trash.length),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const TrashScreen())),
                isDanger: true,
              ),

              const SizedBox(height: 48),

              // About Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: theme.dividerColor),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppStrings.appName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.dividerColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            AppStrings.appVersion,
                            style: const TextStyle(
                              fontSize: 12,
                               fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      AppStrings.appDescription,
                      style: TextStyle(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: AppStrings.madeByPrefix,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                          const WidgetSpan(
                            child: Icon(Icons.favorite, color: Colors.red, size: 16),
                            alignment: PlaceholderAlignment.middle,
                          ),
                          TextSpan(
                            text: ' ${AppStrings.madeWithLove}',
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      textAlign: TextAlign.start,
                    ),
                    const SizedBox(height: 16),
                    Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('https://farukguler.com'), mode: LaunchMode.externalApplication),
                      child: Text(
                        'farukguler.com',
                        style: TextStyle(
                          color: theme.primaryColor.withValues(alpha: 0.7),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => launchUrl(Uri.parse('https://github.com/faruk-guler/Grassper'), mode: LaunchMode.externalApplication),
                      child: Text(
                        'github.com/faruk-guler/Grassper',
                        style: TextStyle(
                          color: theme.primaryColor.withValues(alpha: 0.7),
                          fontSize: 13,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavigationTile(BuildContext context, {
    required IconData icon, 
    required String title, 
    required String subtitle, 
    required VoidCallback onTap,
    bool isDanger = false,
  }) {
    final theme = Theme.of(context);
    final color = isDanger ? AppColors.danger : theme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(subtitle, style: TextStyle(color: theme.iconTheme.color, fontSize: 12)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: theme.dividerColor),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingGroup(BuildContext context, {required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).iconTheme.color,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
