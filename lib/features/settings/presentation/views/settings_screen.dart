import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/theme/theme_provider.dart';
import '../controllers/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final settingsNotifier = ref.read(settingsProvider.notifier);
    final themeMode = ref.watch(themeModeProvider);
    final themeModeNotifier = ref.read(themeModeProvider.notifier);
    final theme = Theme.of(context);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 12),
        children: [
          // Theme settings
          _buildSectionHeader(context, 'Tasarım ve Görünüm'),
          SwitchListTile(
            title: const Text('Koyu Tema (Dark Mode)'),
            subtitle: const Text('Göz yormayan koyu renk düzeni'),
            value: isDark,
            onChanged: (val) {
              themeModeNotifier.toggleTheme(val);
            },
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode, color: theme.colorScheme.primary),
          ),
          const Divider(),

          // Notification settings
          _buildSectionHeader(context, 'Bildirimler'),
          SwitchListTile(
            title: const Text('Günlük Hatırlatıcı Bildirimler'),
            subtitle: const Text('Tekrar yapılması gereken günler için uyarı'),
            value: settings.notificationsEnabled,
            onChanged: (val) {
              settingsNotifier.toggleNotifications(val);
            },
            secondary: Icon(
              settings.notificationsEnabled ? Icons.notifications_active : Icons.notifications_off,
              color: theme.colorScheme.primary,
            ),
          ),
          ListTile(
            enabled: settings.notificationsEnabled,
            title: const Text('Bildirim Saati'),
            subtitle: Text(
              'Tekrar hatırlatıcısı her gün saat ${settings.notificationHour.toString().padLeft(2, '0')}:${settings.notificationMinute.toString().padLeft(2, '0')}\'da gönderilir.',
            ),
            trailing: const Icon(Icons.chevron_right),
            leading: Icon(
              Icons.access_time,
              color: settings.notificationsEnabled ? theme.colorScheme.primary : Colors.grey,
            ),
            onTap: () => _pickNotificationTime(context, ref, settings),
          ),
          const Divider(),

          // Backup and Restore settings
          _buildSectionHeader(context, 'Veri Yönetimi (Offline Yedekleme)'),
          ListTile(
            title: const Text('Verileri Dışa Aktar'),
            subtitle: const Text('Hata defterinizi JSON dosyası olarak yedekleyin'),
            leading: Icon(Icons.upload, color: theme.colorScheme.primary),
            trailing: const Icon(Icons.share),
            onTap: () async {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yedek dosyası hazırlanıyor, lütfen bekleyin...')),
              );
              await settingsNotifier.exportBackup();
            },
          ),
          ListTile(
            title: const Text('Verileri İçe Aktar'),
            subtitle: const Text('JSON yedek dosyasından verilerinizi geri yükleyin'),
            leading: Icon(Icons.download, color: theme.colorScheme.primary),
            trailing: const Icon(Icons.open_in_new),
            onTap: () => _confirmImport(context, settingsNotifier),
          ),
          ListTile(
            title: const Text('Tüm Verileri Sıfırla'),
            subtitle: const Text('Tüm yanlışları, notları siler ve varsayılan dersleri kurar'),
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            onTap: () => _confirmDataReset(context, settingsNotifier),
          ),
          const Divider(),

          // About settings
          _buildSectionHeader(context, 'Uygulama Hakkında'),
          ListTile(
            title: const Text('Sürüm'),
            subtitle: const Text('v1.0.0 (Tamamen Offline)'),
            leading: Icon(Icons.info_outline, color: theme.colorScheme.primary),
          ),
          ListTile(
            title: const Text('Geliştirici'),
            subtitle: const Text('Antigravity Software Architect & Senior Flutter Developer'),
            leading: Icon(Icons.code, color: theme.colorScheme.primary),
          ),
          ListTile(
            title: const Text('Kullanım Amacı'),
            subtitle: const Text('Sınava hazırlanan öğrenciler için geliştirilmiş kişisel, istatistiksel yanlış soru analiz ve tekrar defteridir.'),
            leading: Icon(Icons.help_outline, color: theme.colorScheme.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.primary,
          fontWeight: FontWeight.bold,
          fontSize: 12,
          letterSpacing: 0.8,
        ),
      ),
    );
  }

  Future<void> _pickNotificationTime(BuildContext context, WidgetRef ref, SettingsState settings) async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: settings.notificationHour, minute: settings.notificationMinute),
    );

    if (time != null) {
      await ref.read(settingsProvider.notifier).updateNotificationTime(time.hour, time.minute);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hatırlatma saati ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} olarak güncellendi.')),
      );
    }
  }

  void _confirmImport(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Verileri İçe Aktar'),
          content: const Text(
            'Yedek dosyasını geri yüklemek mevcut tüm verilerinizi (dersler, konular, sorular) silecek ve yedektekilerle değiştirecektir. Devam etmek istiyor musunuz?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await notifier.importBackup();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Verileriniz yedekten başarıyla geri yüklendi!'
                          : 'Yükleme başarısız oldu. Lütfen geçerli bir yedek dosyası seçin.',
                    ),
                  ),
                );
              },
              child: const Text('Yükle'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDataReset(BuildContext context, SettingsNotifier notifier) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tüm Verileri Sil'),
          content: const Text(
            'Hata defterindeki tüm yanlış soruları, çözümleri, eklediğiniz dersleri ve istatistikleri kalıcı olarak silmek istediğinizden emin misiniz? Bu işlem geri alınamaz.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await notifier.resetAllData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tüm veriler sıfırlandı ve varsayılan dersler geri yüklendi.')),
                );
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
              child: const Text('Tümünü Sil'),
            ),
          ],
        );
      },
    );
  }
}
