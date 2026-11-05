extension StringExtensions on String {
  String toTitleCase() {
    if (isEmpty) return this;
    return split(' ').map((word) {
      if (word.isEmpty) return word;
      if (_isMinorWord(word) && this != word) {
        return word.toLowerCase();
      }
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  bool _isMinorWord(String word) {
    const minorWords = {'a', 'an', 'the', 'of', 'in', 'on', 'to', 'and', 'or', 'for', 'with', 'at', 'by'};
    return minorWords.contains(word.toLowerCase());
  }
}
