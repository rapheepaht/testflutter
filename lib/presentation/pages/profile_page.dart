import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/main.dart' show themeNotifier;
import 'package:testflutter/presentation/bloc/note_bloc.dart';
import 'package:testflutter/presentation/routes/app_router.dart';
import 'package:testflutter/presentation/widgets/tap_scale_widget.dart';

@RoutePage()
class ProfilePage extends StatelessWidget {
  final String email;

  const ProfilePage({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final userName = email.contains('@') ? email.split('@').first : email;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'โปรไฟล์',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [scheme.primaryContainer.withValues(alpha: 0.28), scheme.surface],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.elasticOut,
                        builder: (context, value, child) {
                          return Transform.scale(scale: value, child: child);
                        },
                        child: CircleAvatar(
                          radius: 38,
                          backgroundColor: scheme.primaryContainer,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: scheme.primary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        userName,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        email,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      BlocBuilder<NoteBloc, NoteState>(
                        builder: (context, state) {
                          final noteCount = state is NotesLoaded ? state.notes.length : 0;
                          return _ProfileInfoTile(
                            icon: Icons.sticky_note_2_outlined,
                            title: 'จำนวนโน้ต',
                            subtitle: '$noteCount รายการ',
                          );
                        },
                      ),
                      const Divider(),
                      ValueListenableBuilder<bool>(
                        valueListenable: themeNotifier,
                        builder: (context, isDarkMode, child) {
                          return SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            secondary: Icon(
                              isDarkMode ? Icons.dark_mode : Icons.light_mode,
                              color: scheme.primary,
                            ),
                            title: const Text('โหมดสี'),
                            subtitle: Text(isDarkMode ? 'กำลังใช้โหมดมืด' : 'กำลังใช้โหมดสว่าง'),
                            value: isDarkMode,
                            onChanged: (value) {
                              themeNotifier.value = value;
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'การจัดการบัญชี',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      TapScaleWidget(
                        child: OutlinedButton.icon(
                        onPressed: () {
                          context.router.pushAndPopUntil(
                            const LoginRoute(),
                            predicate: (_) => false,
                          );
                        },
                        icon: const Icon(Icons.logout),
                        label: const Text('ออกจากระบบ'),
                      ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: scheme.primaryContainer,
        child: Icon(icon, color: scheme.primary),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}