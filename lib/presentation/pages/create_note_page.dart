import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:testflutter/domain/entities/note_entity.dart';
import 'package:testflutter/presentation/bloc/note_bloc.dart';

@RoutePage()
class CreateNotePage extends StatefulWidget {
  final NoteEntity? note;

  const CreateNotePage({super.key, this.note});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? _selectedImagePath;
  String? _extractedText;
  String? _summary;
  List<String> _tags = [];
  bool _isExtracting = false;
  bool _isAutoSummarizing = false;
  bool _autoSummarizeAfterExtract = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
    _selectedImagePath = widget.note?.imagePath;
    _extractedText = widget.note?.extractedText;
    _summary = widget.note?.summary;
    _tags = widget.note?.tags ?? [];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImagePath = pickedFile.path;
        _isExtracting = true;
      });

      if (kIsWeb) {
        final imageBytes = await pickedFile.readAsBytes();
        final mimeType = _inferMimeType(pickedFile.name);
        if (mounted) {
          context.read<NoteBloc>().add(
                ExtractTextBytesEvent(imageBytes, mimeType),
              );
        }
        return;
      }

      if (mounted) {
        context.read<NoteBloc>().add(ExtractTextEvent(pickedFile.path));
      }
    }
  }

  void _extractAndSummarizeFromImage() {
    _autoSummarizeAfterExtract = true;
    _pickImage();
  }

  void _summarizeContent() {
    final textToSummarize = _extractedText ?? _contentController.text;
    if (textToSummarize.isNotEmpty) {
      context.read<NoteBloc>().add(SummarizeTextEvent(textToSummarize));
    }
  }

  void _generateTags() {
    final textForTags = _summary ?? _extractedText ?? _contentController.text;
    if (textForTags.isNotEmpty) {
      context.read<NoteBloc>().add(GenerateTagsEvent(textForTags));
    }
  }

  void _saveNote() {
    if (_formKey.currentState!.validate()) {
      final note = NoteEntity(
        id: widget.note?.id,
        title: _titleController.text,
        content: _contentController.text,
        imagePath: _selectedImagePath,
        extractedText: _extractedText,
        summary: _summary,
        tags: _tags,
        createdAt: widget.note?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.note == null) {
        context.read<NoteBloc>().add(CreateNoteEvent(note));
      } else {
        context.read<NoteBloc>().add(UpdateNoteEvent(note));
      }
    }
  }

  String _inferMimeType(String fileName) {
    final lowerCaseName = fileName.toLowerCase();
    if (lowerCaseName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerCaseName.endsWith('.webp')) {
      return 'image/webp';
    }
    if (lowerCaseName.endsWith('.gif')) {
      return 'image/gif';
    }
    return 'image/jpeg';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.note == null ? 'สร้างจดโน้ต' : 'แก้ไขจดโน้ต',
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is TextExtracted) {
            setState(() {
              _extractedText = state.extractedText;
              _contentController.text = state.extractedText;
              _isExtracting = false;
            });

            if (_autoSummarizeAfterExtract && state.extractedText.trim().isNotEmpty) {
              setState(() {
                _autoSummarizeAfterExtract = false;
                _isAutoSummarizing = true;
              });
              context.read<NoteBloc>().add(SummarizeTextEvent(state.extractedText));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ สแกนข้อความสำเร็จ กำลังสรุป...')),
              );
            } else {
              setState(() {
                _autoSummarizeAfterExtract = false;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('✅ สแกนข้อความสำเร็จ')),
              );
            }
          } else if (state is TextSummarized) {
            setState(() {
              _summary = state.summary;
              _isAutoSummarizing = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ สรุปข้อความสำเร็จ')),
            );
          } else if (state is TagsGenerated) {
            setState(() {
              _tags = state.tags;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('✅ สร้างแท็กสำเร็จ')),
            );
          } else if (state is NoteCreated || state is NoteUpdated) {
            context.maybePop(widget.note == null ? 'created' : 'updated');
          } else if (state is NoteError) {
            setState(() {
              _isExtracting = false;
              _isAutoSummarizing = false;
              _autoSummarizeAfterExtract = false;
            });
            final rawMessage = state.message;
            final displayMessage = rawMessage.startsWith('API Error: ')
                ? rawMessage.replaceFirst('API Error: ', '')
                : rawMessage;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(displayMessage)),
            );
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [scheme.primaryContainer.withValues(alpha: 0.3), scheme.surface],
            ),
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: scheme.primary.withValues(alpha: 0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _titleController,
                            style: TextStyle(color: scheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'หัวเรื่อง',
                              hintText: 'ป้อนหัวเรื่องจดโน้ต',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'ต้องระบุหัวเรื่อง';
                              }
                              if (value.length < 3) {
                                return 'หัวเรื่องต้องมีอย่างน้อย 3 ตัวอักษร';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_isExtracting || _isAutoSummarizing) ? null : _pickImage,
                                  icon: const Icon(Icons.upload_file),
                                  label: Text(_isExtracting ? 'กำลังสแกน...' : 'อัปโหลดรูปเพื่อสแกน'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: (_isExtracting || _isAutoSummarizing)
                                      ? null
                                      : _extractAndSummarizeFromImage,
                                  icon: const Icon(Icons.auto_awesome),
                                  label: Text(
                                    _isAutoSummarizing ? 'กำลังสรุป...' : 'สแกน + สรุป',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 48),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          if (_selectedImagePath != null) ...[
                            const SizedBox(height: 12),
                            if (kIsWeb)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: scheme.surfaceContainerHighest,
                                  border: Border.all(color: scheme.outlineVariant),
                                ),
                                child: Text(
                                  '✅ เลือกรูปภาพสำเร็จ',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                              )
                            else
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  _selectedImagePath as dynamic,
                                  height: 200,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                          ],
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _contentController,
                            style: TextStyle(color: scheme.onSurface),
                            maxLines: 6,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'เนื้อหา',
                              hintText: 'ข้อความจากรูปจะถูกใส่ที่นี่อัตโนมัติ หรือวางข้อความเองได้',
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'ต้องระบุเนื้อหา';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _contentController.text.isEmpty ? null : _summarizeContent,
                                  icon: const Icon(Icons.summarize),
                                  label: const Text('สรุป'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 46),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  onPressed: _contentController.text.isEmpty ? null : _generateTags,
                                  icon: const Icon(Icons.label),
                                  label: const Text('สร้างแท็ก'),
                                  style: ElevatedButton.styleFrom(
                                    minimumSize: const Size(double.infinity, 46),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (_summary != null) ...[
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'สรุป',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              const SizedBox(height: 8),
                              Text(_summary ?? ''),
                            ],
                          ),
                        ),
                      ),
                    ],
                    if (_tags.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Text(
                        'แท็ก',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _tags
                            .map(
                              (tag) => Chip(
                                label: Text(tag),
                                onDeleted: () {
                                  setState(() {
                                    _tags.remove(tag);
                                  });
                                },
                              ),
                            )
                            .toList(),
                      ),
                    ],
                    const SizedBox(height: 24),
                    BlocBuilder<NoteBloc, NoteState>(
                      builder: (context, state) {
                        return ElevatedButton(
                          onPressed: state is NoteLoading ? null : _saveNote,
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 48),
                          ),
                          child: state is NoteLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(widget.note == null ? 'สร้างจดโน้ต' : 'อัปเดตจดโน้ต'),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
