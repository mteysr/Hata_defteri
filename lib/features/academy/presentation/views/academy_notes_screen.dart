import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../domain/models/academy_note_booklet.dart';
import '../../../../core/constants/app_constants.dart';

class AcademyNotesScreen extends StatelessWidget {
  const AcademyNotesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Akademi Ders Notları'),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.history_edu), text: 'Tarih'),
              Tab(icon: Icon(Icons.public), text: 'Coğrafya'),
              Tab(icon: Icon(Icons.gavel), text: 'Vatandaşlık'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildBookletList(context, 'Tarih', theme),
            _buildBookletList(context, 'Coğrafya', theme),
            _buildBookletList(context, 'Vatandaşlık', theme),
          ],
        ),
      ),
    );
  }

  Widget _buildBookletList(BuildContext context, String category, ThemeData theme) {
    final booklets = kAcademyNoteBooklets.where((b) => b.category == category).toList();

    if (booklets.isEmpty) {
      return _buildEmptyState(category, theme);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: booklets.length,
      itemBuilder: (context, index) {
        final booklet = booklets[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => context.push('/academy-notes-viewer', extra: booklet),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          color: theme.colorScheme.primary,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booklet.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${booklet.pageCount} Sayfa • PDF Notu',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    booklet.description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        'Notları Oku',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.chevron_right,
                        color: theme.colorScheme.primary,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String category, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book,
              size: 64,
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Not Bulunmuyor',
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '$category dersine ait güncel konu notları yakında uygulamaya eklenecektir.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
