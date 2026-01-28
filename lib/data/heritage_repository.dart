
class HeritageFact {
  final String speakerName;
  final String factText;
  final String? avatarAsset; // Nullable for now, will use placeholder

  HeritageFact({
    required this.speakerName,
    required this.factText,
    this.avatarAsset,
  });
}

class HeritageRepository {
  // Mock singleton
  static final HeritageRepository _instance = HeritageRepository._internal();
  factory HeritageRepository() => _instance;
  HeritageRepository._internal();

  final List<HeritageFact> _mockFacts = [
    HeritageFact(
      speakerName: "Elder Fisherman",
      factText: "The marshes have provided for our families for thousands of years. The reeds you see are used to build our homes, the Mudhif.",
    ),
    HeritageFact(
      speakerName: "Historian",
      factText: "Ancient Sumerians believed these waters were the domain of Enki, God of Wisdom and Water.",
    ),
    HeritageFact(
      speakerName: "Note",
      factText: "Beware of low water levels during the dry season. Navigation becomes treacherous.",
    ),
  ];

  Future<HeritageFact> getRandomFact() async {
    // Simulate network delay
    await Future.delayed(const Duration(milliseconds: 500));
    return (_mockFacts..shuffle()).first;
  }
}
