import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final OcrService instance = OcrService._init();
  OcrService._init();

  Future<Map<String, String>?> scanReceipt() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image == null) return null;

    final InputImage inputImage = InputImage.fromFilePath(image.path);
    final TextRecognizer textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);
    
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    // Basic heuristic extraction (in production this requires robust regex)
    String text = recognizedText.text;
    String possiblePrice = "0.00";
    String possibleName = "Unknown";

    RegExp priceExp = RegExp(r'\$?\d+\.\d{2}');
    var priceMatch = priceExp.firstMatch(text);
    if (priceMatch != null) {
      possiblePrice = priceMatch.group(0)?.replaceAll('\$', '') ?? "0.00";
    }

    if (text.isNotEmpty) {
      possibleName = text.split('\n').first; // Just an example heuristic
    }

    return {
      'name': possibleName,
      'price': possiblePrice,
    };
  }
}
