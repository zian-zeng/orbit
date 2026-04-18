class StudentPreferenceExtractor {
  const StudentPreferenceExtractor();

  List<String> extractFromTexts(Iterable<String> texts) {
    final labels = <String>{};
    for (final text in texts) {
      labels.addAll(extractFromText(text));
    }
    return labels.toList(growable: false)..sort();
  }

  List<String> extractFromText(String text) {
    final normalized = text.toLowerCase();
    final labels = <String>{};

    if (_matches(normalized, [
      RegExp(r'\bvegan\b'),
      RegExp(r'\bplant[- ]based\b'),
    ])) {
      labels.add('vegan');
      labels.add('plant_based');
    }
    if (_matches(normalized, [RegExp(r'\bvegetarian\b')])) {
      labels.add('vegetarian');
    }
    if (_matches(normalized, [RegExp(r'\bhalal\b')])) {
      labels.add('halal');
    }
    if (_matches(normalized, [RegExp(r'\bkosher\b')])) {
      labels.add('kosher');
    }
    if (_matches(normalized, [
      RegExp(r'\bgluten[- ]free\b'),
      RegExp(r'\bceliac\b'),
    ])) {
      labels.add('gluten_free');
    }
    if (_matches(normalized, [
      RegExp(r'\ballerg(y|ies|ic)\b'),
      RegExp(r'\bnut[- ]free\b'),
      RegExp(r'\bdairy[- ]free\b'),
    ])) {
      labels.add('food_allergy');
    }
    if (_matches(normalized, [
      RegExp(r'\bcommut(e|er|ing)\b'),
      RegExp(r'\bshuttle\b'),
      RegExp(r'\bparking\b'),
    ])) {
      labels.add('commuter');
      labels.add('campus_navigation');
    }
    if (_matches(normalized, [
      RegExp(r'\binternational student\b'),
      RegExp(r'\bvisa\b'),
      RegExp(r'\bf[- ]1\b'),
    ])) {
      labels.add('international_student');
    }

    return labels.toList(growable: false)..sort();
  }

  bool _matches(String text, Iterable<RegExp> patterns) {
    return patterns.any((pattern) => pattern.hasMatch(text));
  }
}
