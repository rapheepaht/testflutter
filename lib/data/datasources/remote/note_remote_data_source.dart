import 'package:flutter/foundation.dart';
import 'dart:typed_data';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:testflutter/core/error/exceptions.dart';

abstract class NoteRemoteDataSource {
  Future<String> extractTextFromImage(String imagePath);
  Future<String> extractTextFromImageBytes(Uint8List imageBytes, String mimeType);
  Future<String> summarizeText(String text);
  Future<List<String>> generateTags(String text);
}

class NoteRemoteDataSourceImpl implements NoteRemoteDataSource {
  final String geminiApiKey;
  late final GenerativeModel _textModel;
  late final GenerativeModel _visionModel;

  NoteRemoteDataSourceImpl({
    required this.geminiApiKey,
  }) {
    _textModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
    );
    _visionModel = GenerativeModel(
      model: 'gemini-1.5-flash',
      apiKey: geminiApiKey,
    );
  }

  @override
  Future<String> extractTextFromImage(String imagePath) async {
    if (kIsWeb) {
      throw MLKitException(
        'โหมดเว็บไม่ได้ใช้ ML Kit แล้ว ให้ใช้อัปโหลดรูปผ่านปุ่มสแกนบนหน้าเพิ่มโน้ตแทน',
      );
    }

    try {
      final textRecognizer = GoogleMlKit.vision.textRecognizer();
      final inputImage = InputImage.fromFilePath(imagePath);
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      
      String extractedText = '';
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          extractedText += '${line.text}\n';
        }
      }

      await textRecognizer.close();
      return extractedText.trim();
    } catch (e) {
      throw MLKitException('Failed to extract text: $e');
    }
  }

  @override
  Future<String> extractTextFromImageBytes(Uint8List imageBytes, String mimeType) async {
    if (geminiApiKey.isEmpty) {
      throw const GeminiAPIException(
        'ยังไม่ได้ตั้งค่า GEMINI_API_KEY จึงสแกนข้อความจากรูปบนเว็บไม่ได้',
      );
    }

    try {
      final response = await _visionModel.generateContent([
        Content.multi([
          TextPart(
            'อ่านข้อความทั้งหมดจากรูปนี้ให้ครบถ้วน แล้วตอบกลับมาเป็นข้อความล้วนเท่านั้น '
            'ห้ามเพิ่มคำอธิบาย ห้ามสรุป ห้ามแต่งข้อความ',
          ),
          DataPart(mimeType, imageBytes),
        ]),
      ]);

      final extractedText = response.text?.trim() ?? '';
      if (extractedText.isEmpty) {
        throw const GeminiAPIException('ไม่พบข้อความที่อ่านได้จากรูปภาพนี้');
      }

      return extractedText;
    } catch (e) {
      throw GeminiAPIException(_mapGeminiError(
        e,
        fallback:
            'สแกนข้อความจากรูปไม่สำเร็จ กรุณาวางข้อความเองในช่องเนื้อหา แล้วค่อยกดสรุปหรือสร้างแท็ก',
      ));
    }
  }

  @override
  Future<String> summarizeText(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw const GeminiAPIException('ไม่มีข้อความสำหรับสรุป');
    }

    if (geminiApiKey.isEmpty) {
      return _buildLocalSummary(normalizedText);
    }

    try {
      final response = await _textModel.generateContent([
        Content.text(
          'สรุปข้อความต่อไปนี้เป็นภาษาไทยแบบละเอียดพอสมควร โดยจัดรูปแบบให้อ่านง่าย '
          'และคงใจความสำคัญเดิมไว้\n'
          '- เริ่มด้วยภาพรวมสั้น ๆ 1 ย่อหน้า\n'
          '- ตามด้วยประเด็นสำคัญ 3 ถึง 5 ข้อ\n'
          '- ปิดท้ายด้วยข้อสรุปหรือสาระสำคัญอีก 1 ย่อหน้า\n'
          '- ห้ามสั้นเกินไปและห้ามตอบนอกเนื้อหา\n\n$normalizedText',
        ),
      ]);

      final summary = response.text?.trim() ?? '';
      if (summary.isEmpty) {
        return _buildLocalSummary(normalizedText);
      }

      return summary;
    } catch (e) {
      if (_isQuotaExceededError(e)) {
        return _buildLocalSummary(normalizedText);
      }
      return _buildLocalSummary(normalizedText);
    }
  }

  @override
  Future<List<String>> generateTags(String text) async {
    final normalizedText = text.trim();
    if (normalizedText.isEmpty) {
      throw const GeminiAPIException('ไม่มีข้อความสำหรับสร้างแท็ก');
    }

    if (geminiApiKey.isEmpty) {
      return _buildLocalTags(normalizedText);
    }

    try {
      final response = await _textModel.generateContent([
        Content.text(
          'อ่านข้อความต่อไปนี้ แล้วสร้างแท็กภาษาไทย 4 ถึง 6 แท็กที่สะท้อน “ประเด็นสำคัญ” '
          'หรือ “หัวข้อหลัก” ของเนื้อหา ไม่เอาคำทั่วไป ไม่เอาคำซ้ำ และให้ใช้วลีสั้น ๆ ที่สื่อความหมายชัดเจน\n'
          'ถ้าข้อความเป็นสรุป ให้แตกแท็กจากสรุปนั้นโดยตรง\n'
          'ตอบกลับเป็นรายการคั่นด้วยเครื่องหมายจุลภาคเท่านั้น\n\n$normalizedText',
        ),
      ]);

      final rawTags = response.text?.trim() ?? '';
      final tags = rawTags
          .split(RegExp(r'[,\n]'))
          .map((tag) => _normalizeTag(tag))
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .take(6)
          .toList();

      if (tags.isEmpty) {
        return _buildLocalTags(normalizedText);
      }

      return tags;
    } catch (e) {
      if (_isQuotaExceededError(e)) {
        return _buildLocalTags(normalizedText);
      }
      return _buildLocalTags(normalizedText);
    }
  }

  String _mapGeminiError(Object error, {required String fallback}) {
    if (_isQuotaExceededError(error)) {
      return 'โควต้า Gemini ของคีย์นี้หมดแล้ว จึงสแกนรูปบนเว็บไม่ได้ตอนนี้ '
          'ให้วางข้อความเองในช่องเนื้อหา แล้วใช้ปุ่มสรุปหรือสร้างแท็กแทน';
    }

    final message = error.toString();
    if (message.contains('api key') || message.contains('API key')) {
      return 'API key ไม่ถูกต้องหรือยังไม่ได้ตั้งค่า';
    }

    return fallback;
  }

  bool _isQuotaExceededError(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('quota') ||
        message.contains('resource_exhausted') ||
        message.contains('rate limit') ||
        message.contains('429');
  }

  String _buildLocalSummary(String text) {
    final normalized = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) {
      return 'ภาพรวม\n$normalized\n\nประเด็นสำคัญ\n- $normalized\n\nข้อสรุป\nข้อความนี้มีสาระสำคัญตามที่แสดงข้างต้น';
    }

    final sentences = normalized
        .split(RegExp(r'(?<=[.!?])\s+|\n+'))
        .where((sentence) => sentence.trim().isNotEmpty)
        .toList();

    if (sentences.isNotEmpty) {
      final overview = sentences.take(2).join(' ');
      final keyPoints = sentences.skip(2).take(3).toList();
      final closing = sentences.length > 5
          ? sentences.last
          : 'ข้อความนี้เน้นประเด็นสำคัญตามรายการด้านบนและสามารถนำไปใช้ต่อได้ทันที';

      final bulletSection = keyPoints.isEmpty
          ? '- ${overview.length > 120 ? '${overview.substring(0, 120)}...' : overview}'
          : keyPoints
              .map((point) => '- ${point.length > 140 ? '${point.substring(0, 140)}...' : point}')
              .join('\n');

      return 'ภาพรวม\n'
          '${overview.length > 220 ? '${overview.substring(0, 220)}...' : overview}\n\n'
          'ประเด็นสำคัญ\n'
          '$bulletSection\n\n'
          'ข้อสรุป\n'
          '${closing.length > 180 ? '${closing.substring(0, 180)}...' : closing}';
    }

    final preview = normalized.length > 220 ? '${normalized.substring(0, 220)}...' : normalized;
    return 'ภาพรวม\n$preview\n\nประเด็นสำคัญ\n- $preview\n\nข้อสรุป\nข้อความนี้มีเนื้อหาที่ควรอ่านต่อจากต้นฉบับเพื่อเก็บรายละเอียดเพิ่มเติม';
  }

  List<String> _buildLocalTags(String text) {
    final cleanedText = text
        .replaceAll('ภาพรวม', '')
        .replaceAll('ประเด็นสำคัญ', '')
        .replaceAll('ข้อสรุป', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    final sentences = cleanedText
        .split(RegExp(r'(?<=[.!?])\s+|\n+|\-\s+'))
        .map((sentence) => sentence.trim())
        .where((sentence) => sentence.length >= 12)
        .toList();

    final phraseTags = <String>[];
    for (final sentence in sentences) {
      final normalizedSentence = sentence.replaceAll(RegExp(r'^[•\-\d.\s]+'), '').trim();
      if (normalizedSentence.isEmpty) {
        continue;
      }

      final words = normalizedSentence.split(RegExp(r'\s+'));
      if (words.length >= 2) {
        phraseTags.add(words.take(3).join(' '));
      } else {
        phraseTags.add(normalizedSentence);
      }
    }

    final normalizedTags = phraseTags
        .map(_normalizeTag)
        .where((tag) => tag.isNotEmpty)
        .toSet()
        .take(6)
        .toList();

    return normalizedTags.isNotEmpty ? normalizedTags : ['ประเด็นหลัก', 'สรุปเนื้อหา', 'ใจความสำคัญ'];
  }

  String _normalizeTag(String tag) {
    return tag
        .replaceAll('#', '')
        .replaceAll(RegExp(r'^[•\-\d.\s]+'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
