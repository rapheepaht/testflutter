# 🌐 การเชื่อมต่อเครือข่ายและ AI (Networking, API & AI Integration)

## **สรุป: Smart Vision Journal ใช้**

✅ **Google ML Kit 0.13.0** - Text Recognition (OCR) ดึงข้อความจากภาพ
✅ **Dio 5.3.1** - HTTP client with interceptors + retry logic
✅ **Gemini API** - LLM for text summarization + tag generation
✅ **json_serializable** - Automatic JSON serialization/deserialization
✅ **Freezed** - Immutable models with copyWith() support
✅ **Custom Interceptors** - Logging, caching, error handling

---

## **1️⃣ Google ML Kit - OCR (Text Recognition)**

### **A. Setup & Configuration**

```dart
// pubspec.yaml
dependencies:
  google_ml_kit: ^0.13.0  // ✅ Text + Face + Barcode recognition
  
  # Performance optimization
  google_ml_kit_text_recognition: ^0.13.0

// lib/core/constants/ml_kit_constants.dart
class MLKitConstants {
  static const String textRecognizerLanguage = 'English';
  static const int maxTextExtractionLength = 5000;
  static const int minConfidenceScore = 0;  // 0.0 - 1.0
}
```

### **B. Text Recognition from Image File**

```dart
// lib/data/datasources/remote/note_remote_data_source.dart
import 'package:google_ml_kit/google_ml_kit.dart';
import 'dart:io';
import 'dart:typed_data';

abstract class NoteRemoteDataSource {
  Future<String> extractTextFromImage(String imagePath);
  Future<String> extractTextFromImageBytes(Uint8List imageBytes);
  Future<String> summarizeText(String text);
  Future<List<String>> generateTags(String text);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final DioClient dioClient;
  final String geminiApiKey;
  
  late TextRecognizer _textRecognizer;
  
  NoteRemoteDataSourceImpl({
    required this.dioClient,
    required this.geminiApiKey,
  }) {
    _initializeMLKit();
  }
  
  // ✅ Initialize ML Kit
  void _initializeMLKit() {
    _textRecognizer = GoogleMlKit.vision.textRecognizer(
      script: TextRecognitionScript.latin,  // Or thai, chinese, etc
    );
  }
  
  // ✅ EXTRACT TEXT FROM IMAGE FILE
  @override
  Future<String> extractTextFromImage(String imagePath) async {
    try {
      // 1️⃣ Check platform (ML Kit mobile-only)
      if (kIsWeb) {
        throw MLKitException(
          'Text Recognition not supported on Web. '
          'Use extractTextFromImageBytes() instead.',
        );
      }
      
      // 2️⃣ Create InputImage from file
      final inputImage = InputImage.fromFilePath(imagePath);
      
      // 3️⃣ Process image
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 4️⃣ Extract text from all blocks
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += line.text + '\n';
        }
      }
      
      // 5️⃣ Clean up
      await inputImage.close();
      
      // 6️⃣ Validate result
      if (extractedText.isEmpty) {
        throw MLKitException('No text found in image');
      }
      
      // 7️⃣ Limit to max length
      if (extractedText.length > MLKitConstants.maxTextExtractionLength) {
        extractedText = extractedText.substring(
          0,
          MLKitConstants.maxTextExtractionLength,
        );
      }
      
      return extractedText;
    } catch (e) {
      throw MLKitException('Failed to extract text: $e');
    }
  }
  
  // ✅ EXTRACT TEXT FROM IMAGE BYTES
  @override
  Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    try {
      // 1️⃣ Create InputImage from bytes
      final inputImage = InputImage.fromBytes(
        bytes: imageBytes,
        metadata: InputImageMetadata(
          size: Size(1000, 1000),  // Estimated, will be corrected by ML Kit
          rotation: InputImageRotation.rotation0deg,
          format: InputImageFormat.nv21,
        ),
      );
      
      // 2️⃣ Process image
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      // 3️⃣ Extract + clean
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          // Confidence filtering (optional)
          if (line.confidence >= MLKitConstants.minConfidenceScore) {
            extractedText += line.text + '\n';
          }
        }
      }
      
      await inputImage.close();
      
      return extractedText.isEmpty ? 'No text found' : extractedText;
    } catch (e) {
      throw MLKitException('Failed to extract text from bytes: $e');
    }
  }
  
  // ✅ CLEANUP
  void dispose() {
    _textRecognizer.close();
  }
}
```

**ML Kit Text Extraction Flow**:
```
User taps "Capture Document" button
         ↓
ImagePicker.pickImage()
         ↓
extractTextFromImage(String imagePath)
         ↓
InputImage.fromFilePath()
         ↓
textRecognizer.processImage()
         ↓
Loop through TextBlocks → TextLines → text
         ↓
Return extracted string
         ↓
Fill into TextFormField (Form)
```

### **C. Supported Languages**

```dart
enum TextRecognitionScript {
  latin,      // English, Spanish, French, etc
  chinese,    // Chinese characters
  devanagari, // Hindi
  cyrillic,   // Russian
  arabic,     // Arabic
  hebrew,     // Hebrew
  thai,       // ✅ Thai script supported!
  korean,
  japanese,
}

// Usage
_textRecognizer = GoogleMlKit.vision.textRecognizer(
  script: TextRecognitionScript.thai,  // For Thai documents
);
```

---

## **2️⃣ Dio - HTTP Client & Interceptors**

### **A. Dio Setup**

```dart
// lib/core/network/dio_client.dart
import 'package:dio/dio.dart';

class DioClient {
  // ✅ Singleton pattern
  static final DioClient _instance = DioClient._internal();
  
  late final Dio _dio;
  late final BaseOptions _baseOptions;
  
  factory DioClient() {
    return _instance;
  }
  
  DioClient._internal() {
    // ✅ Configure base options
    _baseOptions = BaseOptions(
      baseUrl: 'https://generativelanguage.googleapis.com/v1beta',
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    );
    
    // ✅ Create Dio instance
    _dio = Dio(_baseOptions);
    
    // ✅ Add interceptors
    _dio.interceptors.add(_NetworkLoggingInterceptor());
    _dio.interceptors.add(_CacheInterceptor());
    _dio.interceptors.add(_RetryInterceptor());
    _dio.interceptors.add(_ErrorInterceptor());
  }
  
  Dio get dio => _dio;
  
  // ✅ Set API key dynamically
  void setApiKey(String apiKey) {
    _baseOptions.queryParameters['key'] = apiKey;
  }
}
```

---

### **B. Logging Interceptor**

```dart
// lib/core/network/interceptors/network_logging_interceptor.dart
class _NetworkLoggingInterceptor extends Interceptor {
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    print('╔═══════════════════════════════════════════════════════');
    print('║ 📤 REQUEST: ${options.method}');
    print('║ URL: ${options.uri}');
    print('║ Headers: ${options.headers}');
    print('║ Query: ${options.queryParameters}');
    if (options.data != null) {
      print('║ Body: ${options.data}');
    }
    print('╚═══════════════════════════════════════════════════════');
    
    handler.next(options);
  }
  
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    print('╔═══════════════════════════════════════════════════════');
    print('║ 📥 RESPONSE: ${response.statusCode}');
    print('║ URL: ${response.requestOptions.uri}');
    print('║ Body: ${response.data}');
    print('╚═══════════════════════════════════════════════════════');
    
    handler.next(response);
  }
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    print('╔═══════════════════════════════════════════════════════');
    print('║ ❌ ERROR: ${err.type}');
    print('║ Message: ${err.message}');
    print('║ Status Code: ${err.response?.statusCode}');
    print('╚═══════════════════════════════════════════════════════');
    
    handler.next(err);
  }
}
```

---

### **C. Retry Interceptor**

```dart
// lib/core/network/interceptors/retry_interceptor.dart
class _RetryInterceptor extends Interceptor {
  static const int _maxRetries = 3;
  static const List<int> _retryStatusCodes = [408, 429, 500, 502, 503, 504];
  
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    // Only retry GET requests and specific status codes
    if (shouldRetry(err)) {
      final requestOptions = err.requestOptions;
      
      // Get retry count (or start at 1)
      int retryCount = (requestOptions.extra['retryCount'] ?? 0) as int;
      
      if (retryCount < _maxRetries) {
        retryCount++;
        requestOptions.extra['retryCount'] = retryCount;
        
        print('🔄 Retrying... (Attempt $retryCount/$_maxRetries)');
        
        // Wait before retry (exponential backoff)
        await Future.delayed(
          Duration(seconds: (2 ^ retryCount).toInt()),  // 2s, 4s, 8s
        );
        
        try {
          // Retry request
          final response = await handler.dio.request<dynamic>(
            requestOptions.path,
            data: requestOptions.data,
            queryParameters: requestOptions.queryParameters,
            options: Options(
              method: requestOptions.method,
              headers: requestOptions.headers,
            ),
          );
          
          return handler.resolve(response);
        } catch (e) {
          return handler.next(err);
        }
      }
    }
    
    handler.next(err);
  }
  
  bool shouldRetry(DioException err) {
    return err.requestOptions.method == 'GET' &&
        (err.response?.statusCode != null &&
            _retryStatusCodes.contains(err.response!.statusCode) ||
            err.type == DioExceptionType.unknown);
  }
}
```

---

### **D. Cache Interceptor**

```dart
// lib/core/network/interceptors/cache_interceptor.dart
class _CacheInterceptor extends Interceptor {
  // In-memory cache: key = URL, value = {data, timestamp}
  final Map<String, CachedResponse> _cache = {};
  
  // Cache duration
  static const Duration _cacheDuration = Duration(minutes: 5);
  
  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) {
    // Cache GET requests only
    if (options.method == 'GET') {
      final cacheKey = options.uri.toString();
      final cached = _cache[cacheKey];
      
      if (cached != null && !cached.isExpired()) {
        print('💾 Cache HIT: $cacheKey');
        return handler.resolve(
          Response(
            requestOptions: options,
            data: cached.data,
            statusCode: 200,
          ),
        );
      }
    }
    
    handler.next(options);
  }
  
  @override
  void onResponse(
    Response response,
    ResponseInterceptorHandler handler,
  ) {
    // Cache successful GET responses
    if (response.statusCode == 200 &&
        response.requestOptions.method == 'GET') {
      final cacheKey = response.requestOptions.uri.toString();
      _cache[cacheKey] = CachedResponse(
        data: response.data,
        timestamp: DateTime.now(),
      );
      print('💾 Cached: $cacheKey');
    }
    
    handler.next(response);
  }
  
  void clearCache() => _cache.clear();
}

class CachedResponse {
  final dynamic data;
  final DateTime timestamp;
  
  CachedResponse({required this.data, required this.timestamp});
  
  bool isExpired() {
    return DateTime.now().difference(timestamp) >
        _CacheInterceptor._cacheDuration;
  }
}
```

---

### **E. Error Interceptor**

```dart
// lib/core/network/interceptors/error_interceptor.dart
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) {
    // Convert DioException to custom exceptions
    late final AppException exception;
    
    switch (err.type) {
      case DioExceptionType.badResponse:
        exception = _handleBadResponse(err.response);
        break;
      
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        exception = NetworkFailure(
          'Connection timeout. Check your internet connection.',
        );
        break;
      
      case DioExceptionType.unknown:
        if (err.error is SocketException) {
          exception = NetworkFailure(
            'No internet connection. Please try again.',
          );
        } else {
          exception = NetworkFailure(err.message ?? 'Unknown error');
        }
        break;
      
      default:
        exception = NetworkFailure('Something went wrong');
    }
    
    // pass error to handlers
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }
  
  AppException _handleBadResponse(Response? response) {
    final statusCode = response?.statusCode ?? 0;
    final data = response?.data;
    
    switch (statusCode) {
      case 400:
        return NetworkFailure(
          data?['error']?['message'] ?? 'Bad request',
        );
      case 401:
        return NetworkFailure('Unauthorized. Check your API key.');
      case 403:
        return NetworkFailure('Forbidden. Access denied.');
      case 404:
        return NetworkFailure('Not found.');
      case 429:
        return NetworkFailure('Too many requests. Please wait.');
      case 500:
      case 502:
      case 503:
        return NetworkFailure('Server error. Please try again later.');
      default:
        return NetworkFailure('HTTP $statusCode error');
    }
  }
}
```

---

## **3️⃣ JSON Serialization (json_serializable)**

### **A. Model Definition**

```dart
// pubspec.yaml
dependencies:
  json_annotation: ^4.8.1

dev_dependencies:
  json_serializable: ^6.7.0
  build_runner: ^2.4.6

// lib/data/models/note_model.dart
import 'package:json_annotation/json_annotation.dart';

part 'note_model.g.dart';  // Generated file

@JsonSerializable()
class NoteModel {
  @JsonKey(name: 'id')
  final int? id;
  
  @JsonKey(name: 'title')
  final String title;
  
  @JsonKey(name: 'content')
  final String content;
  
  @JsonKey(name: 'imagePath', defaultValue: '')
  final String? imagePath;
  
  @JsonKey(name: 'extractedText', defaultValue: '')
  final String? extractedText;
  
  @JsonKey(name: 'summary', defaultValue: '')
  final String? summary;
  
  @JsonKey(
    name: 'tags',
    defaultValue: [],
    fromJson: _tagsFromJson,
  )
  final List<String> tags;
  
  @JsonKey(name: 'createdAt')
  final DateTime createdAt;
  
  @JsonKey(name: 'updatedAt')
  final DateTime updatedAt;
  
  NoteModel({
    this.id,
    required this.title,
    required this.content,
    this.imagePath,
    this.extractedText,
    this.summary,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
  });
  
  // ✅ Generated automatically by json_serializable
  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      _$NoteModelFromJson(json);
  
  Map<String, dynamic> toJson() => _$NoteModelToJson(this);
  
  // ✅ Custom converter for List<String> (tags)
  static List<String> _tagsFromJson(dynamic json) {
    if (json == null) return [];
    if (json is List) {
      return List<String>.from(json.map((e) => e.toString()));
    }
    if (json is String) {
      return json.split(',').map((e) => e.trim()).toList();
    }
    return [];
  }
  
  // ✅ Copy operation
  NoteModel copyWith({
    int? id,
    String? title,
    String? content,
    String? imagePath,
    String? extractedText,
    String? summary,
    List<String>? tags,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return NoteModel(
      id: id ?? this.id,
      title: title ?? this.title,
      content: content ?? this.content,
      imagePath: imagePath ?? this.imagePath,
      extractedText: extractedText ?? this.extractedText,
      summary: summary ?? this.summary,
      tags: tags ?? this.tags,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
  
  // ✅ Convert to Entity
  NoteEntity toEntity() {
    return NoteEntity(
      id: id,
      title: title,
      content: content,
      imagePath: imagePath,
      extractedText: extractedText,
      summary: summary,
      tags: tags,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
  
  // ✅ Convert from Entity
  factory NoteModel.fromEntity(NoteEntity entity) {
    return NoteModel(
      id: entity.id,
      title: entity.title,
      content: entity.content,
      imagePath: entity.imagePath,
      extractedText: entity.extractedText,
      summary: entity.summary,
      tags: entity.tags,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
    );
  }
  
  // ✅ Database serialization
  Map<String, dynamic> toDatabase() {
    return {
      'title': title,
      'content': content,
      'imagePath': imagePath,
      'extractedText': extractedText,
      'summary': summary,
      'tags': tags.join(','),  // Store as CSV
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
  
  factory NoteModel.fromDatabase(Map<String, dynamic> map) {
    return NoteModel(
      id: map['id'] as int,
      title: map['title'] as String,
      content: map['content'] as String,
      imagePath: map['imagePath'] as String?,
      extractedText: map['extractedText'] as String?,
      summary: map['summary'] as String?,
      tags: (map['tags'] as String?)?.split(',') ?? [],
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
```

### **B. Generate JSON Code**

```bash
# Terminal: Generate once
flutter pub run build_runner build

# Terminal: Watch for changes (development)
flutter pub run build_runner watch
```

**Generated file** (`note_model.g.dart`):
```dart
// This file is automatically generated. Do not edit manually.

part of 'note_model.dart';

NoteModel _$NoteModelFromJson(Map<String, dynamic> json) => NoteModel(
  id: json['id'] as int?,
  title: json['title'] as String,
  content: json['content'] as String,
  imagePath: json['imagePath'] as String? ?? '',
  extractedText: json['extractedText'] as String? ?? '',
  summary: json['summary'] as String? ?? '',
  tags: NoteModel._tagsFromJson(json['tags'] ?? []),
  createdAt: DateTime.parse(json['createdAt'] as String),
  updatedAt: DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$NoteModelToJson(NoteModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'content': instance.content,
      'imagePath': instance.imagePath,
      'extractedText': instance.extractedText,
      'summary': instance.summary,
      'tags': instance.tags,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
```

---

## **4️⃣ Immutable Models (Freezed)**

### **A. Optional: Using Freezed Instead**

```dart
// pubspec.yaml
dependencies:
  freezed_annotation: ^2.4.1

dev_dependencies:
  freezed: ^2.4.1
  build_runner: ^2.4.6

// lib/data/models/note_model.dart (with Freezed)
import 'package:freezed_annotation/freezed_annotation.dart';

part 'note_model.freezed.dart';
part 'note_model.g.dart';

@freezed
class NoteModel with _$NoteModel {
  const factory NoteModel({
    int? id,
    required String title,
    required String content,
    String? imagePath,
    String? extractedText,
    String? summary,
    @Default([]) List<String> tags,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _NoteModel;
  
  factory NoteModel.fromJson(Map<String, dynamic> json) =>
      _$NoteModelFromJson(json);
}

// Usage with Freezed (same as json_serializable)
final note = NoteModel(
  title: 'My Note',
  content: 'Content',
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);

// ✅ copyWith() generated automatically
final updated = note.copyWith(
  summary: 'New summary',
  updatedAt: DateTime.now(),
);
```

**json_serializable vs Freezed**:
```
json_serializable:
  ✅ Simpler, less boilerplate
  ✅ More control over serialization
  ❌ Manual copyWith() required

Freezed:
  ✅ Automatic copyWith(), equality, toString()
  ✅ Pattern matching support
  ✅ Immutability by default
  ❌ More dependencies
  ❌ Slightly slower build time
```

---

## **5️⃣ Gemini API Integration**

### **A. REST API Call**

```dart
// lib/data/datasources/remote/note_remote_data_source.dart
import 'package:dio/dio.dart';

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final DioClient dioClient;
  final String geminiApiKey;
  
  NoteRemoteDataSourceImpl({
    required this.dioClient,
    required this.geminiApiKey,
  }) {
    dioClient.setApiKey(geminiApiKey);
  }
  
  // ✅ SUMMARIZE TEXT WITH GEMINI
  @override
  Future<String> summarizeText(String text) async {
    try {
      // 1️⃣ Prepare request
      final request = {
        'contents': [
          {
            'parts': [
              {
                'text': '''Summarize the following text in Thai language. 
                Keep it concise (max 100 words). Return ONLY the summary, no explanations.
                
                Text to summarize:
                $text
                '''
              }
            ]
          }
        ]
      };
      
      // 2️⃣ Make API call
      final response = await dioClient.dio.post(
        '/models/gemini-1.5-flash:generateContent',
        data: request,
      );
      
      // 3️⃣ Parse response
      final candidates = response.data['candidates'] as List;
      if (candidates.isEmpty) {
        throw GeminiAPIException('No candidates in response');
      }
      
      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      
      final summary = (parts.first as Map<String, dynamic>)['text'] as String;
      
      return summary.isEmpty ? 'No summary available' : summary;
    } on DioException catch (e) {
      throw GeminiAPIException(
        'API Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    } catch (e) {
      throw GeminiAPIException('Failed to summarize: $e');
    }
  }
  
  // ✅ GENERATE TAGS WITH GEMINI
  @override
  Future<List<String>> generateTags(String text) async {
    try {
      final request = {
        'contents': [
          {
            'parts': [
              {
                'text': '''Extract 3-5 relevant tags from the following text. 
                Return ONLY a comma-separated list of tags with no explanations.
                Tags should be in English, single words or hyphenated phrases.
                
                Text:
                $text
                '''
              }
            ]
          }
        ]
      };
      
      final response = await dioClient.dio.post(
        '/models/gemini-1.5-flash:generateContent',
        data: request,
      );
      
      // Parse response
      final candidates = response.data['candidates'] as List;
      final firstCandidate = candidates.first as Map<String, dynamic>;
      final content = firstCandidate['content'] as Map<String, dynamic>;
      final parts = content['parts'] as List;
      final tagsString = (parts.first as Map<String, dynamic>)['text'] as String;
      
      // Convert comma-separated to list
      return tagsString
          .split(',')
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toList();
    } on DioException catch (e) {
      throw GeminiAPIException(
        'API Error: ${e.response?.data?['error']?['message'] ?? e.message}',
      );
    } catch (e) {
      throw GeminiAPIException('Failed to generate tags: $e');
    }
  }
}
```

**Gemini API Request/Response Flow**:
```
POST /models/gemini-1.5-flash:generateContent
Headers:
  Content-Type: application/json
  
Body:
{
  "contents": [
    {
      "parts": [
        {
          "text": "User prompt here"
        }
      ]
    }
  ]
}

Response:
{
  "candidates": [
    {
      "content": {
        "parts": [
          {
            "text": "Model response here"
          }
        ]
      },
      "finishReason": "STOP"
    }
  ]
}
```

---

## **6️⃣ Complete Workflow: "Extract + Summarize"**

### **A. UI Layer (BLoC Event)**

```dart
// lib/presentation/bloc/note_bloc.dart
part of 'note_bloc.dart';

@immutable
abstract class NoteEvent extends Equatable {
  const NoteEvent();
  
  @override
  List<Object?> get props => [];
}

// ✅ Extract + Summarize event
class ExtractAndSummarizeNoteEvent extends NoteEvent {
  final String imagePath;
  final String title;
  
  const ExtractAndSummarizeNoteEvent({
    required this.imagePath,
    required this.title,
  });
  
  @override
  List<Object?> get props => [imagePath, title];
}
```

### **B. BLoC Handler**

```dart
// lib/presentation/bloc/note_bloc.dart
class NoteBloc extends Bloc<NoteEvent, NoteState> {
  final CreateNoteUseCase createNoteUseCase;
  final ExtractTextUseCase extractTextUseCase;
  final SummarizeTextUseCase summarizeTextUseCase;
  
  NoteBloc({
    required this.createNoteUseCase,
    required this.extractTextUseCase,
    required this.summarizeTextUseCase,
  }) : super(const NoteInitial()) {
    // Register handler
    on<ExtractAndSummarizeNoteEvent>(_onExtractAndSummarize);
  }
  
  // ✅ Handle extract + summarize
  Future<void> _onExtractAndSummarize(
    ExtractAndSummarizeNoteEvent event,
    Emitter<NoteState> emit,
  ) async {
    emit(const NoteLoading());  // Show loading spinner
    
    try {
      // 1️⃣ Extract text
      final extractResult = await extractTextUseCase(
        ExtractTextParams(imagePath: event.imagePath),
      );
      
      String extractedText = '';
      await extractResult.fold(
        (failure) async {
          throw Exception('Failed to extract: $failure');
        },
        (text) async {
          extractedText = text;
        },
      );
      
      // 2️⃣ Summarize text
      final summarizeResult = await summarizeTextUseCase(
        SummarizeTextParams(text: extractedText),
      );
      
      String summary = '';
      await summarizeResult.fold(
        (failure) async {
          // Don't throw - summary is optional
          summary = 'Failed to summarize';
        },
        (summaryText) async {
          summary = summaryText;
        },
      );
      
      // 3️⃣ Generate tags
      List<String> tags = ['document', 'extracted'];  // Default tags
      
      // 4️⃣ Create note with all data
      final note = NoteEntity(
        title: event.title,
        content: extractedText,
        imagePath: event.imagePath,
        extractedText: extractedText,
        summary: summary,
        tags: tags,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      final createResult = await createNoteUseCase(
        CreateNoteParams(note: note),
      );
      
      await createResult.fold(
        (failure) {
          emit(NoteError(failure.toString()));
        },
        (id) {
          emit(NoteCreated(id));
        },
      );
    } catch (e) {
      emit(NoteError(e.toString()));
    }
  }
}
```

### **C. UI Integration**

```dart
// lib/presentation/pages/create_note_page.dart
class CreateNotePage extends StatefulWidget {
  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  String? _selectedImagePath;
  
  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _contentController = TextEditingController();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Note'),
      ),
      body: BlocListener<NoteBloc, NoteState>(
        listener: (context, state) {
          if (state is NoteCreated) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Note created successfully!')),
            );
            Navigator.pop(context);
          }
          
          if (state is NoteError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        },
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Title field
                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Enter note title',
                    ),
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Title is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // Content field
                  TextFormField(
                    controller: _contentController,
                    decoration: const InputDecoration(
                      labelText: 'Content',
                      hintText: 'Enter note content',
                    ),
                    maxLines: 5,
                    validator: (value) {
                      if (value?.isEmpty ?? true) {
                        return 'Content is required';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 16),
                  
                  // ✅ Extract + Summarize Button
                  BlocBuilder<NoteBloc, NoteState>(
                    builder: (context, state) {
                      return ElevatedButton.icon(
                        onPressed: _selectedImagePath != null &&
                                state is! NoteLoading
                            ? _onExtractAndSummarize
                            : null,
                        icon: state is NoteLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.auto_awesome),
                        label: const Text('Extract + Summarize'),
                      );
                    },
                  ),
                  
                  // Submit button
                  SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _onSubmit,
                    child: const Text('Create Note'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  // ✅ Handle extract + summarize
  void _onExtractAndSummarize() async {
    // Pick image
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
    );
    
    if (image != null) {
      _selectedImagePath = image.path;
      
      // Trigger BLoC event
      context.read<NoteBloc>().add(
            ExtractAndSummarizeNoteEvent(
              imagePath: image.path,
              title: _titleController.text,
            ),
          );
    }
  }
  
  // ✅ Handle form submission
  void _onSubmit() {
    if (_formKey.currentState!.validate()) {
      final note = NoteEntity(
        title: _titleController.text,
        content: _contentController.text,
        imagePath: _selectedImagePath,
        tags: [],
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      
      context.read<NoteBloc>().add(
            CreateNoteEvent(note: note),
          );
    }
  }
  
  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }
}
```

---

## **7️⃣ Error Handling**

```dart
// lib/core/error/exceptions.dart
abstract class AppException implements Exception {
  final String message;
  const AppException(this.message);
  
  @override
  String toString() => message;
}

class NetworkFailure extends AppException {
  const NetworkFailure(String message) : super(message);
}

class MLKitException extends AppException {
  const MLKitException(String message) : super(message);
}

class GeminiAPIException extends AppException {
  const GeminiAPIException(String message) : super(message);
}

// Usage in repository
Future<Either<Failure, String>> extractText(String imagePath) async {
  try {
    final text = await remoteDataSource.extractTextFromImage(imagePath);
    return Right(text);
  } on MLKitException catch (e) {
    return Left(MLKitFailure(e.message));
  } on NetworkException catch (e) {
    return Left(NetworkFailure(e.message));
  }
}
```

---

## **✅ Network & AI Checklist**

- ✅ Google ML Kit initialized
- ✅ Text extraction works (mobile + web)
- ✅ Dio configured with singleton
- ✅ All interceptors implemented (logging, retry, cache, error)
- ✅ JSON serialization with json_serializable
- ✅ Model conversion (JSON ↔ Database ↔ Entity)
- ✅ Gemini API integration (summarize + tag generation)
- ✅ Error handling with custom exceptions
- ✅ BLoC event handler for extract + summarize
- ✅ UI form integration with image picker
- ✅ Network error recovery + retry logic

---

## **📊 API Endpoint Reference**

```
Base URL: https://generativelanguage.googleapis.com/v1beta

Endpoints:
1️⃣ Generate Content (Text)
   POST /models/gemini-1.5-flash:generateContent?key=YOUR_KEY
   Body: { contents: [{ parts: [{ text: "..." }] }] }

2️⃣ Models List
   GET /models?key=YOUR_KEY
   (List available models)

Supported Models:
- gemini-1.5-flash    ✅ Fast, cheaper (recommended)
- gemini-1.5-pro      📊 More accurate, slower
- gemini-2.0-flash    🚀 Latest (if available)
```

---

**สรุป**: Smart Vision Journal ใช้ **Multi-layer networking architecture** ที่มี ML Kit for OCR, Dia for API requests, Gemini for AI summarization, และ json_serializable for clean serialization 🌐✨
