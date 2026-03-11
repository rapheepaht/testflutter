# 🎨 UI, Forms & Animations Documentation

## **สรุป: Smart Vision Journal ใช้**

✅ **Form Validation**: GlobalKey<FormState> + TextFormField validators
✅ **Implicit Animations**: AnimatedContainer (ตอบสนองต่อ state changes)
✅ **Explicit Animations**: Hero Widget (ชื่อเรื่องสไลด์เข้า)
✅ **Complex Animations**: SlideTransition (รายการเลื่อนจากขวา)
✅ **Material Design 3**: ColorScheme + Theme integration

---

## **1️⃣ Form & Validation (CreateNotePage)**

### **A. Form Setup with GlobalKey**

```dart
// lib/presentation/pages/create_note_page.dart
class _CreateNotePageState extends State<CreateNotePage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();  // ← Form key
  late TextEditingController _titleController;
  late TextEditingController _contentController;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.note?.title ?? '');
    _contentController = TextEditingController(text: widget.note?.content ?? '');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  void _saveNote() {
    // ✅ Validate ก่อนบันทึก
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
}
```

### **B. TextFormField with Validators**

```dart
// Title Field
TextFormField(
  controller: _titleController,
  decoration: InputDecoration(
    labelText: 'Title',
    hintText: 'Enter note title',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  // ✅ Validation
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Title is required';  // ❌ Empty check
    }
    if (value.length < 3) {
      return 'Title must be at least 3 characters';  // ❌ Length check
    }
    return null;  // ✅ Valid
  },
)

// Content Field
TextFormField(
  controller: _contentController,
  maxLines: 6,
  onChanged: (_) => setState(() {}),
  decoration: InputDecoration(
    labelText: 'Content',
    hintText: 'Write your note content here...',
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  ),
  validator: (value) {
    if (value == null || value.isEmpty) {
      return 'Content is required';
    }
    if (value.length < 10) {
      return 'Content must be at least 10 characters';
    }
    return null;
  },
)
```

### **C. Form Structure**

```dart
Form(
  key: _formKey,
  child: Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Title field
      TextFormField(
        controller: _titleController,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          return null;
        },
      ),
      
      // Image capture buttons
      Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Capture Document'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _extractAndSummarizeFromImage,
              icon: const Icon(Icons.auto_awesome),
              label: const Text('Extract + Summarize'),
            ),
          ),
        ],
      ),
      
      // Display selected image
      if (_selectedImagePath != null) ...[
        const SizedBox(height: 12),
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
      
      // Content field
      TextFormField(
        controller: _contentController,
        maxLines: 6,
        validator: (value) {
          if (value?.isEmpty ?? true) return 'Required';
          return null;
        },
      ),
      
      // Save button
      ElevatedButton.icon(
        onPressed: _saveNote,  // ← Validate here
        icon: const Icon(Icons.save),
        label: const Text('Save Note'),
      ),
    ],
  ),
)
```

---

## **2️⃣ Animations: Explicit (Hero Widget)**

### **A. Hero Animation on Title**

**Home Page (Source)**:
```dart
// lib/presentation/pages/home_page.dart
Hero(
  tag: 'note-title-${note.id ?? note.title}',  // ← Unique tag
  child: Material(
    color: Colors.transparent,
    child: Text(
      note.title,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(fontWeight: FontWeight.bold),
    ),
  ),
)
```

**Detail Page (Destination)**:
```dart
// lib/presentation/pages/note_detail_page.dart
Hero(
  tag: 'note-title-${widget.note.id ?? widget.note.title}',  // ← Same tag
  child: Material(
    color: Colors.transparent,
    child: Text(
      widget.note.title,
      style: Theme.of(context).textTheme.headlineSmall,
    ),
  ),
)
```

**Result**: เมื่อกดโน้ต ชื่อจะเลื่อนมาจากรายการไปยังหน้ารายละเอียด 🎬

---

## **3️⃣ Animations: Implicit (AnimatedContainer)**

### **A. AnimatedContainer Example**

```dart
// lib/presentation/pages/note_detail_page.dart
class _NoteDetailPageState extends State<NoteDetailPage> {
  bool _expanded = false;  // ← State tracker

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero title (explicit animation)
            Hero(
              tag: 'note-title-${widget.note.id}',
              child: Material(
                color: Colors.transparent,
                child: Text(widget.note.title),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // AnimatedContainer (implicit animation)
            GestureDetector(
              onTap: () => setState(() => _expanded = !_expanded),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),  // ← Animation duration
                curve: Curves.easeInOut,  // ← Easing curve
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  // ← Color changes smoothly
                  color: _expanded
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  // ← Border radius changes smoothly
                  borderRadius: BorderRadius.circular(_expanded ? 20 : 10),
                ),
                child: Text(
                  widget.note.content,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
            
            const SizedBox(height: 12),
            Text(
              'Tap content card to animate',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
```

**Animation Properties**:
```
- duration: 300ms
- curve: easeInOut (부드러운 시작/끝)
- color: surfaceContainerHighest → primaryContainer
- borderRadius: 10 → 20
```

**User Experience**: 
- 🟦 ฟ้าเข้มเมื่อปกติ
- 🟨 เหลืองอ่อนเมื่อกด
- มุมโค้งเพิ่มเมื่อขยาย

---

## **4️⃣ Animations: Complex (SlideTransition)**

### **A. Slide Animation on List**

```dart
// lib/presentation/pages/home_page.dart
class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  late final AnimationController _animationController;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    
    // Create animation controller
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Define slide animation (right → left)
    _slideAnimation = Tween<Offset>(
      begin: const Offset(1.0, 0.0),  // ← Start: right
      end: Offset.zero,                // ← End: normal position
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    // Start animation
    _animationController.forward();
    
    // Load notes
    context.read<NoteBloc>().add(const GetAllNotesEvent());
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SlideTransition(
        position: _slideAnimation,
        child: ReorderableListView.builder(
          itemCount: state.notes.length,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          onReorder: (oldIndex, newIndex) {
            // Handle reorder
          },
          itemBuilder: (context, index) {
            final note = state.notes[index];
            return Card(
              key: ValueKey('note-${note.id ?? index}'),
              child: ListTile(
                // Note content...
              ),
            );
          },
        ),
      ),
    );
  }
}
```

**Animation Details**:
- **Type**: SlideTransition (ทำให้ widget เลื่อนจากขวาไปซ้าย)
- **Duration**: 500ms
- **Curve**: easeInOut (เร็วกลาง ช้าริม)

---

## **5️⃣ Material Design 3 Integration**

### **A. ColorScheme Usage**

```dart
final scheme = Theme.of(context).colorScheme;

// Apply colors throughout the UI
Container(
  padding: const EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: scheme.primary.withValues(alpha: 0.08),  // ← Primary color shadow
        blurRadius: 20,
        offset: const Offset(0, 8),
      ),
    ],
  ),
)

// Gradient background
Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        scheme.primaryContainer.withValues(alpha: 0.3),
        scheme.surface,
      ],
    ),
  ),
)
```

### **B. Theme Application**

```dart
// lib/main.dart
final baseScheme = ColorScheme.fromSeed(
  seedColor: const Color(0xFF0F766E),  // Teal
  brightness: Brightness.light,
);

ThemeData(
  colorScheme: baseScheme,
  useMaterial3: true,  // ← Enable Material 3
  scaffoldBackgroundColor: const Color(0xFFF5F7F4),
  appBarTheme: AppBarTheme(
    backgroundColor: baseScheme.surface,
    foregroundColor: baseScheme.onSurface,
  ),
  cardTheme: CardThemeData(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(18),
      side: BorderSide(color: baseScheme.outlineVariant),
    ),
  ),
)
```

---

## **6️⃣ Form Interaction with BLoC**

### **A. BLocListener for User Feedback**

```dart
// lib/presentation/pages/create_note_page.dart
BlocListener<NoteBloc, NoteState>(
  listener: (context, state) {
    if (state is TextExtracted) {
      setState(() {
        _extractedText = state.extractedText;
        _contentController.text = state.extractedText;
        _isExtracting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text extracted successfully')),
      );
    } else if (state is TextSummarized) {
      setState(() {
        _summary = state.summary;
        _isAutoSummarizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Text summarized successfully')),
      );
    } else if (state is TagsGenerated) {
      setState(() {
        _tags = state.tags;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tags generated successfully')),
      );
    } else if (state is NoteCreated || state is NoteUpdated) {
      context.maybePop();  // Go back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(
          widget.note == null ? 'Note created' : 'Note updated'
        )),
      );
    } else if (state is NoteError) {
      setState(() {
        _isExtracting = false;
        _isAutoSummarizing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${state.message}')),
      );
    }
  },
  child: // Form widget
)
```

---

## **7️⃣ Reorderable List with Numbering**

### **A. ReorderableListView**

```dart
// lib/presentation/pages/home_page.dart
ReorderableListView.builder(
  itemCount: state.notes.length,
  padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
  onReorder: (oldIndex, newIndex) {
    // Update order in database
  },
  itemBuilder: (context, index) {
    final note = state.notes[index];
    return Card(
      key: ValueKey('note-${note.id ?? index}'),  // ← Required for reorder
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        // Display number with background
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: scheme.primaryContainer,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              '${index + 1}',  // 1️⃣ 2️⃣ 3️⃣
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: scheme.primary,
                fontSize: 16,
              ),
            ),
          ),
        ),
        
        // Title with hero animation
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
        
        // Content preview
        subtitle: Text(
          note.content,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
        
        // Action buttons
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () async {
                await context.pushRoute(
                  CreateNoteRoute(note: note),
                );
                if (mounted) {
                  context.read<NoteBloc>().add(
                    const GetAllNotesEvent(),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {
                context.read<NoteBloc>().add(
                  DeleteNoteEvent(note.id ?? 0),
                );
              },
            ),
            const SizedBox(width: 16),
          ],
        ),
        
        // Navigate to detail on tap
        onTap: () {
          context.pushRoute(NoteDetailRoute(note: note));
        },
      ),
    );
  },
)
```

---

## **📋 Animation Types Summary**

| ชนิด | ตัวอย่าง | ใช้เมื่อไร |
|------|---------|---------|
| **Hero** | ชื่อเรื่องขยับ | Navigation ระหว่าง pages |
| **AnimatedContainer** | สีเปลี่ยน, โค้งเปลี่ยน | State change อย่างง่าย |
| **SlideTransition** | รายการเลื่อนจากขวา | Page load animation |
| **ReorderableListView** | ลากจัดเรียง | User reorder items |

---

## **✅ Form Validation Checklist**

- ✅ GlobalKey<FormState> for form control
- ✅ TextFormField with validator function
- ✅ Check for empty values
- ✅ Check for minimum length
- ✅ Show error messages inline
- ✅ Validate before submit
- ✅ Handle success/error states with BloC
- ✅ Show snackbars for user feedback
- ✅ Clear form after successful submission
- ✅ Support create & edit modes

---

## **🚀 Best Practices**

```dart
// ✅ Good: Separate controllers
@override
void initState() {
  _titleController = TextEditingController(text: widget.note?.title ?? '');
}

@override
void dispose() {
  _titleController.dispose();  // Always clean up!
  super.dispose();
}

// ✅ Good: Validate before submit
if (_formKey.currentState!.validate()) {
  // Submit form
}

// ✅ Good: Use BLoC for state
context.read<NoteBloc>().add(CreateNoteEvent(note));

// ✅ Good: Show feedback with snackbar
ScaffoldMessenger.of(context).showSnackBar(
  const SnackBar(content: Text('Note created')),
);

// ✅ Good: Use Hero for navigation animations
Hero(
  tag: 'unique-id',
  child: Material(color: Colors.transparent, child: widget),
)

// ✅ Good: Use AnimatedContainer for simple state changes
AnimatedContainer(
  duration: const Duration(milliseconds: 300),
  curve: Curves.easeInOut,
  // properties that animate
)
```

---

## **📸 Visual Hierarchy**

```
HomePage (List)
  ├─ SlideTransition (from right)
  ├─ ReorderableListView
  │  └─ Card (numbered list)
  │     ├─ Hero(title)
  │     ├─ Subtitle (preview)
  │     └─ Trailing (edit/delete buttons)
  └─ FloatingActionButton (create)

DetailPage (Show note)
  ├─ Hero(title) ← Same tag from home
  ├─ AnimatedContainer
  │  └─ Tap to expand/collapse
  └─ Image (if exists)

CreatePage (Form)
  ├─ Form (with GlobalKey)
  ├─ TextFormField (Title)
  │  └─ Validator
  ├─ Image picker buttons
  ├─ TextFormField (Content)
  │  └─ Validator
  └─ Save button
```

---

## **🎬 Animation Flow**

```
1. HomePage loads → SlideTransition (list slides from right)
2. User taps note → Hero animation (title moves to detail page)
3. User lands on detail → AnimatedContainer ready
4. User taps content → AnimatedContainer (color & radius change)
5. User edit → CreatePage form with validators
6. User submit form → BLoC event → snackbar feedback
```

---

ดูได้เสร็จแล้ว! Smart Vision Journal ใช้ animations และ forms อย่างสมบูรณ์ 🎨✨
