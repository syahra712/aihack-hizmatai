class AppConstants {
  static const appName = 'Hizmat AI';
  static const tagline = "Ghar ki koi bhi zaroorat?";
  static const taglineGradient = 'HizmatAI pe chhod do.';
  static const subtitle = '6 AI agents orchestrated via Google ADK — understands Roman Urdu, Urdu, English & mixed input.';
  static const splashDuration = Duration(milliseconds: 2500);

  static const cities = ['Karachi', 'Lahore', 'Islamabad'];

  static const samplePrompts = [
    SamplePrompt(
      label: 'Roman Urdu',
      text: 'Bhai mujhe Karachi mein bijli wala chahiye abhi',
      lang: 'roman_urdu',
    ),
    SamplePrompt(
      label: 'Urdu',
      text: 'کراچی میں پلمبر چاہیے کل صبح 10 بجے',
      lang: 'urdu',
    ),
    SamplePrompt(
      label: 'English',
      text: 'I need a house cleaning service in Lahore tomorrow at 3pm',
      lang: 'english',
    ),
    SamplePrompt(
      label: 'Mixed',
      text: 'AC repair karwani hai, Islamabad mein — کوئی اچھا ملے؟',
      lang: 'mixed',
    ),
  ];
}

class SamplePrompt {
  final String label;
  final String text;
  final String lang;
  const SamplePrompt({required this.label, required this.text, required this.lang});
}
