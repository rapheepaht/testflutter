import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';
import 'package:testflutter/presentation/routes/app_router.dart';
import 'package:testflutter/main.dart' show themeNotifier;

@RoutePage()
class HomePage extends StatefulWidget {
  final String email;
  const HomePage({super.key, this.email = 'user@example.com'});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));

    _animationController.forward();
    context.read<NoteBloc>().add(const GetAllNotesEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'จดโน้ตเฉยๆไม่มีอะไรพิเศษ',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
        actions: [
          // 🌓 Theme Toggle Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: ValueListenableBuilder<bool>(
                valueListenable: themeNotifier,
                builder: (context, isDarkMode, child) {
                  return IconButton(
                    icon: Icon(
                      isDarkMode ? Icons.light_mode : Icons.dark_mode,
                      size: 24,
                    ),
                    tooltip: isDarkMode ? 'สว่าง' : 'มืด',
                    onPressed: () {
                      themeNotifier.value = !themeNotifier.value;
                    },
                  );
                },
              ),
            ),
          ),
          // Profile Icon
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  context.pushRoute(ProfileRoute(email: widget.email));
                },
                child: Tooltip(
                  message: widget.email,
                  child: const Icon(Icons.account_circle_outlined),
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocListener<NoteBloc, NoteState>(
              listener: (context, state) {
                if (state is NoteDeleted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note deleted successfully')),
                  );
                  context.read<NoteBloc>().add(const GetAllNotesEvent());
                } else if (state is NoteError) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${state.message}')),
                  );
                }
              },
              child: BlocBuilder<NoteBloc, NoteState>(
                builder: (context, state) {
                  if (state is NoteLoading) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is NotesLoaded) {
                    if (state.notes.isEmpty) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [scheme.primaryContainer.withValues(alpha: 0.35), scheme.surface],
                          ),
                        ),
                      );
                    }

                    return Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [scheme.primaryContainer.withValues(alpha: 0.3), scheme.surface],
                        ),
                      ),
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: ReorderableListView.builder(
                          itemCount: state.notes.length,
                          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
                          onReorder: (oldIndex, newIndex) {
                            // Handle reorder - in real app, save to database
                          },
                          itemBuilder: (context, index) {
                            final note = state.notes[index];
                            return Card(
                              key: ValueKey('note-${note.id ?? index}'),
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: scheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: scheme.primary,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                title: Hero(
                                  tag: 'note-title-${note.id ?? note.title}',
                                  child: Material(
                                    color: Colors.transparent,
                                    child: Text(
                                      note.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ),
                                subtitle: Text(
                                  note.content,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit),
                                      onPressed: () async {
                                        final result = await context.pushRoute(CreateNoteRoute(note: note));
                                        if (mounted) {
                                          if (result == 'updated') {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('✅ อัปเดตจดโน้ตสำเร็จ')),
                                            );
                                          }
                                          context.read<NoteBloc>().add(const GetAllNotesEvent());
                                        }
                                      },
                                    ),
                                    SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red),
                                      onPressed: () {
                                        context.read<NoteBloc>().add(DeleteNoteEvent(note.id ?? 0));
                                      },
                                    ),
                                    SizedBox(width: 16),
                                  ],
                                ),
                                onTap: () {
                                  context.pushRoute(NoteDetailRoute(note: note));
                                },
                              ),
                            );
                          },
                        ),
                      ),
                    );
                  } else if (state is NoteError) {
                    return Center(
                      child: Text('Error: ${state.message}'),
                    );
                  }

                  return const SizedBox();
                },
              ),
            ),
          ),
          // ✅ Create Note Button ด้านล่าง
          BlocBuilder<NoteBloc, NoteState>(
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.all(24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Theme.of(context).colorScheme.primary,
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        iconSize: 48,
                        color: Theme.of(context).colorScheme.primary,
                        icon: const Icon(Icons.add_box_rounded),
                        onPressed: () async {
                          final result = await context.pushRoute(CreateNoteRoute());
                          if (mounted) {
                            if (result == 'created') {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('✅ สร้างจดโน้ตสำเร็จ')),
                              );
                            }
                            context.read<NoteBloc>().add(const GetAllNotesEvent());
                          }
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Create Note',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
