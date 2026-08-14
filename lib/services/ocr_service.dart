import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final OcrService instance = OcrService._init();
  OcrService._init();

  Future<Map<String, dynamic>?> scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image == null) return null;

    final InputImage inputImage = InputImage.fromFilePath(image.path);
    final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
      String text = recognizedText.text;

      if (text.trim().isEmpty) return null;
      return _parseReceiptData(text);
    } finally {
      await textRecognizer.close();
    }
  }

  static final List<MapEntry<RegExp, String>> _labelPatterns = [
    MapEntry(RegExp(r'^\s*receipt\s*(no\.?|number|#)\s*[:\-]?\s*', caseSensitive: false), 'receiptNo'),
    MapEntry(RegExp(r'^\s*transaction\s*(id|no\.?|number|ref\.?|reference)\s*[:\-]?\s*', caseSensitive: false), 'transactionId'),
    MapEntry(RegExp(r'^\s*(customer|subscriber|billed\s*to|name)\s*[:\-]?\s*', caseSensitive: false), 'customer'),
    MapEntry(RegExp(r'^\s*(service|merchant|vendor|product|plan)\s*[:\-]?\s*', caseSensitive: false), 'service'),
    MapEntry(RegExp(r'^\s*(date|billing\s*date|receipt\s*date|issued|payment\s*date)\s*[:\-]?\s*', caseSensitive: false), 'date'),
    MapEntry(RegExp(r'^\s*(total|amount|amount\s*due|grand\s*total)\s*[:\-]?\s*', caseSensitive: false), 'total'),
    MapEntry(RegExp(r'^\s*(billing\s*cycle|cycle|frequency|period)\s*[:\-]?\s*', caseSensitive: false), 'billingCycle'),
  ];

  Map<String, dynamic> _parseReceiptData(String text) {
    final List<String> rawLines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    final Map<String, String> fields = {};

    for (int i = 0; i < rawLines.length; i++) {
      final line = rawLines[i];
      for (final entry in _labelPatterns) {
        final match = entry.key.firstMatch(line);
        if (match != null) {
          String value = line.substring(match.end).trim();
          if (value.isEmpty && i + 1 < rawLines.length) {
            value = rawLines[i + 1].trim();
          }
          if (value.isNotEmpty && !fields.containsKey(entry.value)) {
            fields[entry.value] = value;
          }
          break;
        }
      }
    }

    String possibleName = fields['service'] ?? fields['customer'] ?? '';
    if (possibleName.isEmpty) {
      final candidateLines = rawLines.take(3).where((l) {
        final lower = l.toLowerCase();
        return !lower.contains('receipt') && !lower.contains('transaction');
      }).toList();
      if (candidateLines.isNotEmpty) {
        possibleName = candidateLines.reduce((a, b) => a.length > b.length ? a : b).trim();
      }
    }

    double possiblePrice = 0.0;
    String possibleCurrency = 'USD';

    RegExp priceExp = RegExp(r'([$€£₦¥]|R\$|USD|EUR|GBP|NGN)?\s*(\d{1,7}(?:[.,]\d{3})*(?:[.,]\d{2})?)');

    if (fields.containsKey('total')) {
      final match = priceExp.firstMatch(fields['total']!);
      if (match != null) {
        final parsed = _parseAmount(match.group(1) ?? '', match.group(2) ?? '0');
        possiblePrice = parsed.amount;
        possibleCurrency = parsed.currency;
      }
    }

    if (possiblePrice == 0.0) {
      var priceMatches = priceExp.allMatches(text);
      double maxPrice = 0.0;
      String detectedCurrency = possibleCurrency;
      for (var match in priceMatches) {
        final parsed = _parseAmount(match.group(1) ?? '', match.group(2) ?? '0');
        if (parsed.amount > maxPrice) {
          maxPrice = parsed.amount;
          if ((match.group(1) ?? '').isNotEmpty) {
            detectedCurrency = parsed.currency;
          }
        }
      }
      possiblePrice = maxPrice;
      possibleCurrency = detectedCurrency;
    }

    String possibleCycle = 'Monthly';
    final cycleSource = (fields['billingCycle'] ?? text).toLowerCase();
    if (cycleSource.contains('year') || cycleSource.contains('annual') || cycleSource.contains('anual')) {
      possibleCycle = 'Yearly';
    }

    DateTime? possibleDate = _extractDate(fields['date'] ?? text);
    // If a labeled date field was found but couldn't be parsed, retry against
    // the full text as a fallback rather than silently defaulting elsewhere.
    if (possibleDate == null && fields.containsKey('date')) {
      possibleDate = _extractDate(text);
    }

    return {
      'name': possibleName,
      'price': possiblePrice,
      'currency': possibleCurrency,
      'billingCycle': possibleCycle,
      'date': possibleDate,
      'receiptNo': fields['receiptNo'] ?? '',
      'transactionId': fields['transactionId'] ?? '',
      'customer': fields['customer'] ?? '',
    };
  }

  _ParsedAmount _parseAmount(String symbol, String numberStr) {
    String cleaned = numberStr;
    if (cleaned.contains(',') && cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '');
    } else if (cleaned.contains(',') && !cleaned.contains('.')) {
      cleaned = cleaned.replaceAll(',', '.');
    }
    final amount = double.tryParse(cleaned) ?? 0.0;
    final currency = symbol.isNotEmpty ? _mapSymbolToCurrency(symbol) : 'USD';
    return _ParsedAmount(amount, currency);
  }

  static const Map<String, int> _monthNames = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'sept': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  DateTime? _extractDate(String source) {
    // 1. Numeric formats: YYYY-MM-DD, DD/MM/YYYY, MM/DD/YYYY, etc.
    RegExp numericDateExp = RegExp(r'\b(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b');
    var numericMatch = numericDateExp.firstMatch(source);
    if (numericMatch != null) {
      String rawDate = numericMatch.group(0)!;
      try {
        if (rawDate.contains('/')) {
          List<String> parts = rawDate.split('/');
          if (parts[2].length == 4) {
            return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          } else if (parts[0].length == 4) {
            return DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
          }
        } else if (rawDate.contains('-')) {
          if (rawDate.split('-')[0].length == 4) {
            return DateTime.parse(rawDate);
          } else {
            List<String> parts = rawDate.split('-');
            if (parts[2].length == 4) {
              return DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
            }
          }
        }
      } catch (_) {
        // fall through to month-name matching below
      }
    }

    // 2. Month-name formats: "May 26, 2025", "26 May 2025", "May 26 2025"
    final monthGroup = _monthNames.keys.map((m) => RegExp.escape(m)).join('|');
    RegExp monthFirstExp = RegExp(
      r'\b(' + monthGroup + r')\.?\s+(\d{1,2})(?:st|nd|rd|th)?,?\s+(\d{4})\b',
      caseSensitive: false,
    );
    var monthFirstMatch = monthFirstExp.firstMatch(source);
    if (monthFirstMatch != null) {
      final monthKey = monthFirstMatch.group(1)!.toLowerCase();
      final day = int.tryParse(monthFirstMatch.group(2) ?? '');
      final year = int.tryParse(monthFirstMatch.group(3) ?? '');
      final month = _monthNames[monthKey];
      if (month != null && day != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    RegExp dayFirstExp = RegExp(
      r'\b(\d{1,2})(?:st|nd|rd|th)?\s+(' + monthGroup + r')\.?,?\s+(\d{4})\b',
      caseSensitive: false,
    );
    var dayFirstMatch = dayFirstExp.firstMatch(source);
    if (dayFirstMatch != null) {
      final day = int.tryParse(dayFirstMatch.group(1) ?? '');
      final monthKey = dayFirstMatch.group(2)!.toLowerCase();
      final year = int.tryParse(dayFirstMatch.group(3) ?? '');
      final month = _monthNames[monthKey];
      if (month != null && day != null && year != null) {
        try {
          return DateTime(year, month, day);
        } catch (_) {}
      }
    }

    return null;
  }

  String _mapSymbolToCurrency(String symbol) {
    if (symbol.contains('\$') || symbol == 'USD') return 'USD';
    if (symbol.contains('€') || symbol == 'EUR') return 'EUR';
    if (symbol.contains('£') || symbol == 'GBP') return 'GBP';
    if (symbol.contains('₦') || symbol == 'NGN') return 'NGN';
    if (symbol.contains('¥')) return 'JPY';
    if (symbol.contains('R\$')) return 'BRL';
    return 'USD';
  }
}

class _ParsedAmount {
  final double amount;
  final String currency;
  _ParsedAmount(this.amount, this.currency);
}
