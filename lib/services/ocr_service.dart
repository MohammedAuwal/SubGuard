import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final OcrService instance = OcrService._init();
  OcrService._init();

  Future<Map<String, dynamic>?> scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    // Using gallery as offline primary, but keeping architecture open for camera extension
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
      // CRITICAL: Always close the recognizer to prevent memory leaks
      await textRecognizer.close();
    }
  }

  Map<String, dynamic> _parseReceiptData(String text) {
    String possibleName = "";
    double possiblePrice = 0.0;
    String possibleCurrency = "USD";
    String possibleCycle = "Monthly";
    DateTime? possibleDate;

    List<String> lines = text.split('\n');
    if (lines.isNotEmpty) {
      possibleName = lines.take(3).reduce((a, b) => a.length > b.length ? a : b).trim();
    }

    // 1. Price & Currency Detection
    RegExp priceExp = RegExp(r'([$€£₦¥]|R\$|USD|EUR|GBP)?\s*(\d{1,5}(?:[.,]\d{3})*(?:[.,]\d{2}))');
    var priceMatches = priceExp.allMatches(text);
    
    if (priceMatches.isNotEmpty) {
      double maxPrice = 0.0;
      for (var match in priceMatches) {
        String symbol = match.group(1) ?? "";
        String numberStr = match.group(2) ?? "0";
        
        if (numberStr.contains(',') && numberStr.contains('.')) {
          numberStr = numberStr.replaceAll(',', '');
        } else if (numberStr.contains(',') && !numberStr.contains('.')) {
           numberStr = numberStr.replaceAll(',', '.');
        }

        double currentPrice = double.tryParse(numberStr) ?? 0.0;
        if (currentPrice > maxPrice) {
          maxPrice = currentPrice;
          if (symbol.isNotEmpty) {
            possibleCurrency = _mapSymbolToCurrency(symbol);
          }
        }
      }
      possiblePrice = maxPrice;
    }

    // 2. Billing Cycle Detection
    String lowerText = text.toLowerCase();
    if (lowerText.contains('year') || lowerText.contains('annual') || lowerText.contains('anual')) {
      possibleCycle = 'Yearly';
    }

    // 3. Date Detection (YYYY-MM-DD or DD/MM/YYYY or MM/DD/YYYY)
    RegExp dateExp = RegExp(r'\b(\d{4}[-/]\d{1,2}[-/]\d{1,2}|\d{1,2}[-/]\d{1,2}[-/]\d{2,4})\b');
    var dateMatch = dateExp.firstMatch(text);
    if (dateMatch != null) {
      String rawDate = dateMatch.group(0)!;
      // Basic fallback parsing; production requires strict format checking based on locale
      try {
        if (rawDate.contains('/')) {
          List<String> parts = rawDate.split('/');
          if (parts[2].length == 4) { // DD/MM/YYYY or MM/DD/YYYY
            possibleDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
          }
        } else if (rawDate.contains('-')) {
          possibleDate = DateTime.parse(rawDate);
        }
      } catch (e) {
        possibleDate = null;
      }
    }

    return {
      'name': possibleName,
      'price': possiblePrice,
      'currency': possibleCurrency,
      'billingCycle': possibleCycle,
      'date': possibleDate,
    };
  }

  String _mapSymbolToCurrency(String symbol) {
    if (symbol.contains('\$') || symbol == 'USD') return 'USD';
    if (symbol.contains('€') || symbol == 'EUR') return 'EUR';
    if (symbol.contains('£') || symbol == 'GBP') return 'GBP';
    if (symbol.contains('₦')) return 'NGN';
    if (symbol.contains('¥')) return 'JPY';
    if (symbol.contains('R\$')) return 'BRL';
    return 'USD';
  }
}
