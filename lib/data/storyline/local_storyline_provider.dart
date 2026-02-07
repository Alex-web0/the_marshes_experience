import '../../domain/storyline_models.dart';
import 'storyline_data_provider.dart';

/// Local data provider with hardcoded mock storyline data
///
/// This implementation contains all the story content locally in code.
/// Used as the default data source until Firebase or other remote sources are implemented.
class LocalStorylineProvider implements StorylineDataProvider {
  @override
  Future<Map<String, StorylineElement>> loadStorylineElements() async {
    // Simulate async loading (even though data is local)
    await Future.delayed(const Duration(milliseconds: 100));

    final Map<String, StorylineElement> stories = {};

    // Load authentic Al-Chibayish Marshes heritage stories
    final mudhifStory = _createMudhifDiscoveryStory();
    stories[mudhifStory.id] = mudhifStory;

    final buffaloStory = _createBuffaloCompanionStory();
    stories[buffaloStory.id] = buffaloStory;

    final fishermanStory = _createFishermanWisdomStory();
    stories[fishermanStory.id] = fishermanStory;

    final mashhoufStory = _createMashhoufBoatStory();
    stories[mashhoufStory.id] = mashhoufStory;

    final reedsStory = _createReedsHeritageStory();
    stories[reedsStory.id] = reedsStory;

    final tannurStory = _createTannurOvenStory();
    stories[tannurStory.id] = tannurStory;

    final birdStory = _createBirdHuntingStory();
    stories[birdStory.id] = birdStory;

    final floatingLifeStory = _createFloatingLifeStory();
    stories[floatingLifeStory.id] = floatingLifeStory;

    final waterChallengeStory = _createWaterChallengeStory();
    stories[waterChallengeStory.id] = waterChallengeStory;

    final communityGatheringStory = _createCommunityGatheringStory();
    stories[communityGatheringStory.id] = communityGatheringStory;

    // Add more buffalo stories for variety
    final buffaloStory2 = _createBuffaloMilkStory();
    stories[buffaloStory2.id] = buffaloStory2;

    final buffaloStory3 = _createBuffaloSwimmingStory();
    stories[buffaloStory3.id] = buffaloStory3;

    // Add more fisherman stories for variety
    final fishermanStory2 = _createFishermanNetsStory();
    stories[fishermanStory2.id] = fishermanStory2;

    final fishermanStory3 = _createFishermanSeasonsStory();
    stories[fishermanStory3.id] = fishermanStory3;

    // Add short fun fact stories
    final reedFact = _createReedFunFactStory();
    stories[reedFact.id] = reedFact;

    final waterBirdFact = _createWaterBirdFactStory();
    stories[waterBirdFact.id] = waterBirdFact;

    final marshPlantFact = _createMarshPlantStory();
    stories[marshPlantFact.id] = marshPlantFact;

    final boatCraftFact = _createBoatCraftStory();
    stories[boatCraftFact.id] = boatCraftFact;

    final cookingFact = _createMarshCookingStory();
    stories[cookingFact.id] = cookingFact;

    return stories;
  }

  @override
  Future<Map<String, StoryProgress>?> loadPlayerProgress(
      String playerId) async {
    // Local provider doesn't support remote progress loading
    return null;
  }

  @override
  Future<bool> savePlayerProgress(
      String playerId, Map<String, StoryProgress> progress) async {
    // Local provider doesn't support remote progress saving
    return false;
  }

  /// Creates Al-Mudhif (Reed Guesthouse) discovery story
  StorylineElement _createMudhifDiscoveryStory() {
    final explorer = StoryCharacter(
      id: 'explorer_archaeologist',
      name: 'Explorer',
      personality: 'Archaeologist, curious about heritage',
      imagePath: 'assets/team_images/ahmed_sinan.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'You notice a magnificent structure made entirely of reeds rising from the marsh ahead. An explorer from your team is examining its architecture with fascination.',
      characterId: 'explorer_archaeologist',
      choices: [
        StoryChoice(
          id: 'approach',
          text: 'Approach and learn about it',
          nextParagraphId: 'mudhif_explanation',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Continue exploring',
          nextParagraphId: 'missed_opportunity',
        ),
      ],
    );

    final explanation = StoryParagraph(
      id: 'mudhif_explanation',
      text:
          '"This is Al-Mudhif - a traditional reed guesthouse!" the explorer explains. "Takes 4-6 months to build. The whole community works together harvesting reeds. Fun fact: the number of sections is always odd - it\'s a cultural tradition!"',
      characterId: 'explorer_archaeologist',
      choices: [
        StoryChoice(
          id: 'ask_purpose',
          text: 'Ask about its purpose',
          nextParagraphId: 'purpose',
        ),
        StoryChoice(
          id: 'ask_construction',
          text: 'Ask about construction',
          nextParagraphId: 'construction',
        ),
        StoryChoice(
          id: 'ask_fun_fact',
          text: 'Any interesting fun facts?',
          nextParagraphId: 'fun_facts',
        ),
      ],
    );

    final purpose = StoryParagraph(
      id: 'purpose',
      text:
          '"Each Mudhif belongs to a tribal sheikh," the explorer continues. "It\'s used for hospitality, gatherings, decisions, and resolving conflicts. The heart of community life!"',
      characterId: 'explorer_archaeologist',
      choices: [],
    );

    final construction = StoryParagraph(
      id: 'construction',
      text:
          '"Building a Mudhif is a communal effort," the explorer says. "They use marsh reeds, binding them with traditional techniques passed through generations. The arched design is both beautiful and perfectly adapted to the environment!"',
      characterId: 'explorer_archaeologist',
      choices: [
        StoryChoice(
          id: 'more_details',
          text: 'Tell me more!',
          nextParagraphId: 'cooling_system',
        ),
      ],
    );

    final funFacts = StoryParagraph(
      id: 'fun_facts',
      text:
          'The explorer grins. "Oh, lots! Mudhifs can be over 15 meters long! No nails used - all bound with reeds. Some hold up to 300 people! And they stay naturally cool inside despite the desert heat."',
      characterId: 'explorer_archaeologist',
      choices: [
        StoryChoice(
          id: 'how_cool',
          text: 'How does it stay cool?',
          nextParagraphId: 'cooling_system',
        ),
        StoryChoice(
          id: 'impressed',
          text: 'That\'s amazing!',
          nextParagraphId: 'final_thoughts',
        ),
      ],
    );

    final coolingSystem = StoryParagraph(
      id: 'cooling_system',
      text:
          '"The secret\'s in the design!" the explorer explains. "High arched ceiling lets hot air rise and escape, while reed walls let breezes through. Ancient architecture more efficient than modern buildings! Brilliant engineering."',
      characterId: 'explorer_archaeologist',
      choices: [],
    );

    final finalThoughts = StoryParagraph(
      id: 'final_thoughts',
      text:
          '"Incredible, right?" the explorer says proudly. "Every time I study these, I find something new. That\'s why preserving this heritage matters - it\'s living wisdom!"',
      characterId: 'explorer_archaeologist',
      choices: [],
    );

    final missed = StoryParagraph(
      id: 'missed_opportunity',
      text:
          'You continue past the reed structure. The explorer looks disappointed but continues documenting it in their notes.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'mudhif_discovery',
      title: 'The Al-Mudhif Guesthouse',
      description: 'Learn about the traditional reed guesthouse',
      paragraphs: {
        'intro': intro,
        'mudhif_explanation': explanation,
        'purpose': purpose,
        'construction': construction,
        'fun_facts': funFacts,
        'cooling_system': coolingSystem,
        'final_thoughts': finalThoughts,
        'missed_opportunity': missed,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_archaeologist': explorer,
      },
      rewards: {
        'score': 100,
        'storyCount': 1,
      },
    );
  }

  /// Creates Buffalo companion story with authentic marsh heritage
  StorylineElement _createBuffaloCompanionStory() {
    final buffalo = StoryCharacter(
      id: 'marsh_buffalo',
      name: 'Abu Ghazal',
      personality: 'Wise water buffalo, loyal companion',
      imagePath: 'assets/images/buffalo_avatar.png',
    );

    final explorer = StoryCharacter(
      id: 'explorer_photogrammetry',
      name: 'Explorer',
      personality: 'Photogrammetry expert, documenting heritage',
      imagePath: 'assets/team_images/hussain.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'A majestic water buffalo stands in the shallow waters. An explorer is setting up camera equipment nearby. "Look at this beauty!" they call out. "Each buffalo here has a distinct name - this one is called Abu Ghazal."',
      characterId: 'explorer_photogrammetry',
      choices: [
        StoryChoice(
          id: 'learn_more',
          text: 'Learn about buffalo herding',
          nextParagraphId: 'buffalo_importance',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Keep moving',
          nextParagraphId: 'brief_goodbye',
        ),
      ],
    );

    final importance = StoryParagraph(
      id: 'buffalo_importance',
      text:
          '"Buffalo are more than livestock here - they\'re family," the explorer explains while photographing. "They provide milk, help with transport, and are deeply integrated into marsh life. The bond between herders and their buffalo is incredible."',
      characterId: 'explorer_photogrammetry',
      choices: [
        StoryChoice(
          id: 'buffalo_facts',
          text: 'Tell me more about buffalo',
          nextParagraphId: 'buffalo_facts',
        ),
        StoryChoice(
          id: 'buffalo_speaks',
          text: 'Listen to Abu Ghazal',
          nextParagraphId: 'buffalo_wisdom',
          requirements: {'fishCount': 3},
        ),
        StoryChoice(
          id: 'thanks',
          text: 'Thank Hussain',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final buffaloFacts = StoryParagraph(
      id: 'buffalo_facts',
      text:
          'The explorer adjusts the camera. "Water buffalo can hold their breath underwater for minutes! They love submerging to stay cool. Each family\'s buffalo has a name - some hold naming ceremonies for calves. Abu Ghazal means \'Father of the Gazelle\' - named for his graceful movements as a calf!"',
      characterId: 'explorer_photogrammetry',
      choices: [
        StoryChoice(
          id: 'naming_ceremony',
          text: 'Tell me about naming ceremonies',
          nextParagraphId: 'naming_tradition',
        ),
        StoryChoice(
          id: 'buffalo_speaks',
          text: 'Listen to Abu Ghazal',
          nextParagraphId: 'buffalo_wisdom',
          requirements: {'fishCount': 3},
        ),
      ],
    );

    final namingTradition = StoryParagraph(
      id: 'naming_tradition',
      text:
          '"Beautiful tradition!" the explorer shares. "When a calf is born, the family observes its personality and behavior for days, then chooses a name that reflects its character. It\'s very serious - the name stays for life and everyone remembers it!"',
      characterId: 'explorer_photogrammetry',
      choices: [
        StoryChoice(
          id: 'profound',
          text: 'That\'s profound',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final buffaloWisdom = StoryParagraph(
      id: 'buffalo_wisdom',
      text:
          'Abu Ghazal looks at you with knowing eyes. In a mystical moment, you understand his thoughts: "I\'ve lived in these waters many years. The marsh gives us life - reeds feed us, water sustains us. We\'re guardians of this ancient place. When humans respect the water, it provides. This is the old way, the true way."',
      characterId: 'marsh_buffalo',
      choices: [
        StoryChoice(
          id: 'grateful',
          text: 'Thank you for sharing',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The explorer finishes the photographs. "These images will help preserve the memory of marsh life for future generations," they say with satisfaction.',
      characterId: 'explorer_photogrammetry',
      choices: [],
    );

    final goodbye = StoryParagraph(
      id: 'brief_goodbye',
      text:
          'You wave to the explorer and Abu Ghazal as you continue your journey through the marshes.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'buffalo_companion',
      title: 'Abu Ghazal the Buffalo',
      description: 'Meet a water buffalo and learn about their role',
      paragraphs: {
        'intro': intro,
        'buffalo_importance': importance,
        'buffalo_facts': buffaloFacts,
        'naming_tradition': namingTradition,
        'buffalo_wisdom': buffaloWisdom,
        'ending': ending,
        'brief_goodbye': goodbye,
      },
      startParagraphId: 'intro',
      characters: {
        'marsh_buffalo': buffalo,
        'explorer_photogrammetry': explorer,
      },
      rewards: {
        'score': 150,
        'storyCount': 1,
      },
    );
  }

  /// Creates Fisherman wisdom story with authentic traditions
  StorylineElement _createFishermanWisdomStory() {
    final fisherman = StoryCharacter(
      id: 'marsh_fisherman',
      name: 'Sheikh Hassan',
      personality: 'Experienced fisherman, keeper of traditions',
      imagePath: 'assets/images/fisherman_avatar.png',
    );

    final explorer = StoryCharacter(
      id: 'explorer_3d',
      name: 'Explorer',
      personality: '3D modeling expert, preserving heritage digitally',
      imagePath: 'assets/team_images/salih_waleed.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An experienced fisherman sits in his mashhuf, the traditional marsh boat. An explorer is creating a 3D scan of the boat. The fisherman waves you over. "Come, let me tell you about our traditions," he calls out.',
      characterId: 'marsh_fisherman',
      choices: [
        StoryChoice(
          id: 'join',
          text: 'Join them in the boat',
          nextParagraphId: 'fishing_traditions',
        ),
        StoryChoice(
          id: 'decline',
          text: 'Politely decline',
          nextParagraphId: 'decline_ending',
        ),
      ],
    );

    final traditions = StoryParagraph(
      id: 'fishing_traditions',
      text:
          '"Fishing is more than a job - it\'s our heritage," Sheikh Hassan explains. "My father fished these waters, and his father before him. We know every channel, every season for different fish. But things are changing - water levels are declining."',
      characterId: 'marsh_fisherman',
      choices: [
        StoryChoice(
          id: 'ask_boat',
          text: 'Ask about the mashhuf',
          nextParagraphId: 'about_mashhuf',
        ),
        StoryChoice(
          id: 'ask_techniques',
          text: 'What fishing techniques do you use?',
          nextParagraphId: 'fishing_techniques',
        ),
        StoryChoice(
          id: 'ask_challenges',
          text: 'Ask about challenges',
          nextParagraphId: 'challenges',
        ),
      ],
    );

    final aboutMashhuf = StoryParagraph(
      id: 'about_mashhuf',
      text:
          '"The mashhuf is the lifeline of the marshes!" he says proudly. "Once, it was the main transport for fishing and moving around the wetlands. This boat has been in my family for generations. This explorer is helping preserve it digitally so future generations can see it."',
      characterId: 'marsh_fisherman',
      choices: [
        StoryChoice(
          id: 'boat_stories',
          text: 'Any stories about this boat?',
          nextParagraphId: 'boat_stories',
        ),
      ],
    );

    final fishingTechniques = StoryParagraph(
      id: 'fishing_techniques',
      text:
          'Sheikh Hassan\'s eyes light up. "We use traditional reed traps - \'gargour\' - woven by hand. Fish swim in but can\'t escape! Also hand nets and spears for big fish. Each season brings different types - spring bunni, summer shabbout. You must know the water\'s moods!"',
      characterId: 'marsh_fisherman',
      choices: [
        StoryChoice(
          id: 'seasonal_wisdom',
          text: 'Tell me about the seasons',
          nextParagraphId: 'seasonal_knowledge',
        ),
        StoryChoice(
          id: 'ask_boat',
          text: 'Ask about the mashhuf',
          nextParagraphId: 'about_mashhuf',
        ),
      ],
    );

    final seasonalKnowledge = StoryParagraph(
      id: 'seasonal_knowledge',
      text:
          '"The marsh teaches patience," he says wisely. "Winter: cold water, slow fish, different baits. Spring: migration and breeding - careful fishing. Summer: fish go deeper. Autumn: harvest abundance. My grandfather taught me: \'The marsh provides for those who listen to its rhythms.\'"',
      characterId: 'marsh_fisherman',
      choices: [],
    );

    final boatStories = StoryParagraph(
      id: 'boat_stories',
      text:
          'The fisherman smiles. "This mashhuf saved my father in a storm. It carried my bride on our wedding - decorated with flowers and reeds. My children learned to swim holding its side. It\'s not just wood and pitch - it\'s family memory made solid." The explorer nods, documenting carefully.',
      characterId: 'marsh_fisherman',
      choices: [],
    );

    final challenges = StoryParagraph(
      id: 'challenges',
      text:
          'Sheikh Hassan\'s expression grows serious. "The marshes face many challenges now - declining water levels, environmental stress, reduced tourism. But we persist. This is our home, our identity. The marshes are not just a place - they are a way of life."',
      characterId: 'marsh_fisherman',
      choices: [],
    );

    final decline = StoryParagraph(
      id: 'decline_ending',
      text:
          'You thank them but continue on your way. The explorer waves goodbye as they continue their documentation work.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'fisherman_wisdom',
      title: 'Sheikh Hassan\'s Wisdom',
      description: 'Learn fishing traditions from an experienced fisherman',
      paragraphs: {
        'intro': intro,
        'fishing_traditions': traditions,
        'fishing_techniques': fishingTechniques,
        'seasonal_knowledge': seasonalKnowledge,
        'about_mashhuf': aboutMashhuf,
        'boat_stories': boatStories,
        'challenges': challenges,
        'decline_ending': decline,
      },
      startParagraphId: 'intro',
      characters: {
        'marsh_fisherman': fisherman,
        'explorer_3d': explorer,
      },
      triggerRequirements: {'fishCount': 2},
      rewards: {
        'score': 200,
        'storyCount': 1,
      },
    );
  }

  /// Creates Mashhuf boat heritage story
  StorylineElement _createMashhoufBoatStory() {
    final explorer = StoryCharacter(
      id: 'explorer_lead',
      name: 'Explorer',
      personality: 'Heritage preservation coordinator',
      imagePath: 'assets/team_images/adil_alqabaa.png',
    );

    final para1 = StoryParagraph(
      id: 'para1',
      text:
          'An explorer examines a beautifully crafted mashhuf boat. "Did you know traditional weddings used to take place on boats like this?" they share. "The mashhuf is more than transportation - it\'s woven into the fabric of marsh culture."',
      characterId: 'explorer_lead',
      choices: [
        StoryChoice(
          id: 'learn_more',
          text: 'Learn more about boats',
          nextParagraphId: 'para2',
        ),
        StoryChoice(
          id: 'wedding_details',
          text: 'Tell me about boat weddings!',
          nextParagraphId: 'wedding_traditions',
        ),
      ],
    );

    final weddingTraditions = StoryParagraph(
      id: 'wedding_traditions',
      text:
          '"Beautiful tradition!" the explorer says. "Bride and groom rowed through marshes in decorated mashhuf - flowers, fabrics, lanterns. Whole village lines the waterways singing! Some weddings had flotillas following the couple. A community celebration lasting days."',
      characterId: 'explorer_lead',
      choices: [
        StoryChoice(
          id: 'boat_making',
          text: 'How are these boats made?',
          nextParagraphId: 'boat_construction',
        ),
        StoryChoice(
          id: 'floating_houses',
          text: 'What about floating houses?',
          nextParagraphId: 'para3',
        ),
      ],
    );

    final para2 = StoryParagraph(
      id: 'para2',
      text:
          '"These boats are crafted using traditional techniques," the explorer explains. "They\'re perfectly designed for shallow marsh waters. Families would travel between floating houses, fish, and even host celebrations - all from these vessels."',
      characterId: 'explorer_lead',
      choices: [
        StoryChoice(
          id: 'construction_details',
          text: 'How are they built?',
          nextParagraphId: 'boat_construction',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Ask about floating houses',
          nextParagraphId: 'para3',
        ),
      ],
    );

    final boatConstruction = StoryParagraph(
      id: 'boat_construction',
      text:
          'The explorer kneels, running a hand along the hull. "Masters shape wood planks - poplar or willow. Joined and sealed with bitumen pitch for waterproofing. Flat bottom glides through shallow water. Takes weeks to build, but well-maintained ones last generations!"',
      characterId: 'explorer_lead',
      choices: [
        StoryChoice(
          id: 'impressed',
          text: 'Incredible craftsmanship',
          nextParagraphId: 'para3',
        ),
      ],
    );

    final para3 = StoryParagraph(
      id: 'para3',
      text:
          '"Ah, Al-Chibisha - the floating houses!" the explorer says enthusiastically. "They rise and fall with water levels. Built on platforms made from reeds and mud, some even have small gardens! Families would live their entire lives on these floating islands - cooking, sleeping, raising children. It\'s ingenious architecture perfectly adapted to the marsh environment."',
      characterId: 'explorer_lead',
      choices: [
        StoryChoice(
          id: 'learn_more_chibisha',
          text: 'Tell me more about Al-Chibisha',
          nextParagraphId: 'chibisha_details',
        ),
      ],
    );

    final chibishaDetails = StoryParagraph(
      id: 'chibisha_details',
      text:
          '"Incredible homes!" the explorer continues. "Built with reed bundles tied together for a floating platform, then reed houses on top. During floods, the whole structure rises with water - perfectly safe! Some had buffalo on adjacent platforms. We\'re documenting all this."',
      characterId: 'explorer_lead',
      choices: [],
    );

    return StorylineElement(
      id: 'mashhuf_heritage',
      title: 'The Mashhuf Boat',
      description: 'Discover the traditional boat of the marshes',
      paragraphs: {
        'para1': para1,
        'wedding_traditions': weddingTraditions,
        'para2': para2,
        'boat_construction': boatConstruction,
        'para3': para3,
        'chibisha_details': chibishaDetails,
      },
      startParagraphId: 'para1',
      characters: {
        'explorer_lead': explorer,
      },
      rewards: {
        'score': 75,
        'storyCount': 1,
      },
    );
  }

  /// Creates reeds and papyrus heritage story
  StorylineElement _createReedsHeritageStory() {
    final explorer1 = StoryCharacter(
      id: 'explorer_writer1',
      name: 'Explorer',
      personality: 'Content writer, documenting stories and traditions',
      imagePath: 'assets/team_images/reem_salam.png',
    );

    final explorer2 = StoryCharacter(
      id: 'explorer_writer2',
      name: 'Explorer',
      personality: 'Content writer, collecting local knowledge',
      imagePath: 'assets/team_images/ahmed_sinan.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'Two explorers are interviewing a local woman weaving reed mats. "The reeds are everything to us," the woman explains. "We build our houses with them, feed our buffalo, even make traditional pastries."',
      characterId: 'explorer_writer1',
      choices: [
        StoryChoice(
          id: 'listen',
          text: 'Listen to the interview',
          nextParagraphId: 'reed_uses',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Continue exploring',
          nextParagraphId: 'brief_end',
        ),
      ],
    );

    final reedUses = StoryParagraph(
      id: 'reed_uses',
      text:
          'One explorer takes notes as the woman continues: "Reeds and papyrus have sustained our communities for centuries. We harvest them carefully, ensuring they grow back. The buffalo love to eat them, and we use them for building, crafts, and even traditional foods. Nothing goes to waste in the marshes."',
      characterId: 'explorer_writer2',
      choices: [
        StoryChoice(
          id: 'ask_crafts',
          text: 'What crafts do you make?',
          nextParagraphId: 'reed_crafts',
        ),
        StoryChoice(
          id: 'ask_ecology',
          text: 'Are reeds important for the ecosystem?',
          nextParagraphId: 'ecological_importance',
        ),
        StoryChoice(
          id: 'ask_future',
          text: 'Ask about the future',
          nextParagraphId: 'hopes_and_fears',
        ),
      ],
    );

    final reedCrafts = StoryParagraph(
      id: 'reed_crafts',
      text:
          'The woman shows her work proudly. "We weave floor mats, baskets for goods, roof panels, decorations. See this pattern? Each family has traditional designs from mother to daughter for generations. Also reed boats, fences, musical instruments! Girls learn at six or seven."',
      characterId: 'explorer_writer1',
      choices: [
        StoryChoice(
          id: 'patterns',
          text: 'The patterns are beautiful!',
          nextParagraphId: 'pattern_meanings',
        ),
        StoryChoice(
          id: 'future',
          text: 'Do young people still learn this?',
          nextParagraphId: 'hopes_and_fears',
        ),
      ],
    );

    final ecologicalImportance = StoryParagraph(
      id: 'ecological_importance',
      text:
          'The explorer\'s eyes widen. The woman nods. "Oh yes! Reeds clean water - filter impurities. Shelter for birds, fish, insects. Roots hold soil and prevent erosion. When they decompose, they enrich the water. The marshes wouldn\'t exist without reeds - they ARE the marshes!"',
      characterId: 'explorer_writer2',
      choices: [
        StoryChoice(
          id: 'amazed',
          text: 'I had no idea they were so important',
          nextParagraphId: 'reed_wisdom',
        ),
      ],
    );

    final patternMeanings = StoryParagraph(
      id: 'pattern_meanings',
      text:
          '"Thank you!" the woman beams. "This zigzag represents water flowing. These diamonds are fish. The cross pattern symbolizes the four directions where the marsh extends. Every design tells a story - about our lives, our environment, our history. When you see a woven mat, you\'re reading our culture!"',
      characterId: 'explorer_writer1',
      choices: [],
    );

    final reedWisdom = StoryParagraph(
      id: 'reed_wisdom',
      text:
          '"My grandmother used to say: \'Respect the reeds, for they are our teachers,\'" the woman shares. "\'They bend in storms but don\'t break. They give everything - food, shelter, beauty - and ask only for water and sun. If we live like the reeds, we will always survive.\'"',
      characterId: 'explorer_writer2',
      choices: [],
    );

    final hopesAndFears = StoryParagraph(
      id: 'hopes_and_fears',
      text:
          'One explorer asks the important question: "What do you hope for the future?" The woman smiles. "We want the world to know about our marshes, our culture. Some young people are leaving, forgetting the old ways. But others are eager to learn. Projects like yours - documenting our heritage - give us hope that our children\'s children will remember who we are and where we came from."',
      characterId: 'explorer_writer1',
      choices: [],
    );

    final briefEnd = StoryParagraph(
      id: 'brief_end',
      text: 'You wave to the writers and continue through the reed channels.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'reeds_heritage',
      title: 'Reeds & Papyrus',
      description: 'Learn how reeds sustain marsh life',
      paragraphs: {
        'intro': intro,
        'reed_uses': reedUses,
        'reed_crafts': reedCrafts,
        'pattern_meanings': patternMeanings,
        'ecological_importance': ecologicalImportance,
        'reed_wisdom': reedWisdom,
        'hopes_and_fears': hopesAndFears,
        'brief_end': briefEnd,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_writer1': explorer1,
        'explorer_writer2': explorer2,
      },
      triggerRequirements: {'storyCount': 1},
      rewards: {
        'score': 125,
        'storyCount': 1,
      },
    );
  }

  /// Creates traditional clay oven (Tannur) story
  StorylineElement _createTannurOvenStory() {
    final explorer = StoryCharacter(
      id: 'explorer_archaeologist2',
      name: 'Explorer',
      personality: 'Archaeologist, interested in daily life traditions',
      imagePath: 'assets/team_images/adil_alqabaa.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'You spot an explorer watching a local woman tending to a clay oven. \"This is a Tannur,\" the explorer explains. \"It\'s a traditional clay oven made entirely by hand using red clay from the marsh. Watch how she bakes the bread!\"',
      characterId: 'explorer_archaeologist2',
      choices: [
        StoryChoice(
          id: 'learn_more',
          text: 'Learn about the Tannur',
          nextParagraphId: 'tannur_explanation',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Continue on your way',
          nextParagraphId: 'brief_end',
        ),
      ],
    );

    final explanation = StoryParagraph(
      id: 'tannur_explanation',
      text:
          '\"Women build these ovens themselves,\" the explorer shares. \"They collect clay, shape it into a dome, and let it dry in the sun. The Tannur gets extremely hot inside - perfect for baking traditional flatbread. The bread is slapped onto the inner walls and peels off when ready. It\'s been done this way for generations!\"',
      characterId: 'explorer_archaeologist2',
      choices: [
        StoryChoice(
          id: 'ask_bread',
          text: 'What kind of bread?',
          nextParagraphId: 'bread_types',
        ),
        StoryChoice(
          id: 'ask_technique',
          text: 'How do they make it?',
          nextParagraphId: 'building_technique',
        ),
      ],
    );

    final breadTypes = StoryParagraph(
      id: 'bread_types',
      text:
          'The woman speaks up proudly: \"We bake Khubz - traditional flatbread. Also Samoon, and sometimes special breads for celebrations. The Tannur gives the bread a unique smoky flavor you can\'t get from modern ovens. My grandmother taught me, her mother taught her, going back countless generations.\"',
      characterId: 'explorer_archaeologist2',
      choices: [],
    );

    final buildingTechnique = StoryParagraph(
      id: 'building_technique',
      text:
          '\"Building a Tannur is an art,\" the explorer explains. \"The clay must be the right consistency - not too wet, not too dry. They shape it carefully, smoothing the inside surface. Some women add straw to the clay for strength. Once built, a good Tannur can last for years, providing daily bread for the entire family!\"',
      characterId: 'explorer_archaeologist2',
      choices: [],
    );

    final briefEnd = StoryParagraph(
      id: 'brief_end',
      text: 'You wave and continue through the marshes.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'tannur_oven',
      title: 'The Traditional Tannur',
      description: 'Discover the traditional clay oven',
      paragraphs: {
        'intro': intro,
        'tannur_explanation': explanation,
        'bread_types': breadTypes,
        'building_technique': buildingTechnique,
        'brief_end': briefEnd,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_archaeologist2': explorer,
      },
      rewards: {
        'score': 80,
        'storyCount': 1,
      },
    );
  }

  /// Creates bird hunting tradition story
  StorylineElement _createBirdHuntingStory() {
    final explorer = StoryCharacter(
      id: 'explorer_wildlife',
      name: 'Explorer',
      personality: 'Wildlife documentarian',
      imagePath: 'assets/team_images/hussain.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer with binoculars points to birds flying overhead. \"The marshes are a birdwatcher\'s paradise! Over 300 species of birds visit here. For centuries, bird hunting has been a traditional livelihood alongside fishing.\"',
      characterId: 'explorer_wildlife',
      choices: [
        StoryChoice(
          id: 'learn_birds',
          text: 'Tell me about the birds',
          nextParagraphId: 'bird_diversity',
        ),
        StoryChoice(
          id: 'pass',
          text: 'Continue exploring',
          nextParagraphId: 'goodbye',
        ),
      ],
    );

    final birdDiversity = StoryParagraph(
      id: 'bird_diversity',
      text:
          '\"It\'s incredible!\" the explorer says excitedly. \"We have herons, egrets, kingfishers, pelicans, flamingos, and countless migratory species. The marshes are on major bird migration routes between Europe, Asia, and Africa. Some stay year-round, others just pass through. It\'s a vital ecosystem!\"',
      characterId: 'explorer_wildlife',
      choices: [
        StoryChoice(
          id: 'ask_hunting',
          text: 'What about bird hunting?',
          nextParagraphId: 'hunting_tradition',
        ),
        StoryChoice(
          id: 'ask_conservation',
          text: 'Are they protected now?',
          nextParagraphId: 'conservation',
        ),
      ],
    );

    final huntingTradition = StoryParagraph(
      id: 'hunting_tradition',
      text:
          '\"Bird hunting is an ancient tradition here,\" the explorer explains. \"Hunters use traditional methods - nets, traps, even trained falcons in some cases. They know which birds to hunt and which to protect. It\'s about balance - taking only what\'s needed, respecting the natural cycles. Modern conservation efforts work with local hunters to ensure sustainability.\"',
      characterId: 'explorer_wildlife',
      choices: [],
    );

    final conservation = StoryParagraph(
      id: 'conservation',
      text:
          '\"There\'s growing awareness about conservation,\" the explorer shares. \"Some species are now protected. Locals are becoming guides for birdwatchers instead of hunters. Ecotourism is growing. The marshes are recognized as an Important Bird Area internationally. It\'s about finding balance between tradition and preservation.\"',
      characterId: 'explorer_wildlife',
      choices: [],
    );

    final goodbye = StoryParagraph(
      id: 'goodbye',
      text: 'The explorer waves as you continue your journey.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'bird_hunting',
      title: 'Birds of the Marshes',
      description: 'Learn about bird life and traditional hunting',
      paragraphs: {
        'intro': intro,
        'bird_diversity': birdDiversity,
        'hunting_tradition': huntingTradition,
        'conservation': conservation,
        'goodbye': goodbye,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_wildlife': explorer,
      },
      triggerRequirements: {'fishCount': 1},
      rewards: {
        'score': 100,
        'storyCount': 1,
      },
    );
  }

  /// Creates floating life story - alternative perspective on Al-Chibisha
  StorylineElement _createFloatingLifeStory() {
    final explorer = StoryCharacter(
      id: 'explorer_architectural',
      name: 'Explorer',
      personality: 'Architectural researcher',
      imagePath: 'assets/team_images/salih_waleed.png',
    );

    final localResident = StoryCharacter(
      id: 'marsh_resident',
      name: 'Um Ali',
      personality: 'Elder woman who grew up on floating houses',
      imagePath: 'assets/images/fisherman_avatar.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer is interviewing an elderly woman on a small floating platform. \"I grew up on Al-Chibisha,\" the woman says. \"A floating house - my whole childhood was lived on water!\"',
      characterId: 'marsh_resident',
      choices: [
        StoryChoice(
          id: 'listen',
          text: 'Listen to her story',
          nextParagraphId: 'childhood_memories',
        ),
        StoryChoice(
          id: 'leave',
          text: 'Continue your journey',
          nextParagraphId: 'brief_end',
        ),
      ],
    );

    final memories = StoryParagraph(
      id: 'childhood_memories',
      text:
          '\"We lived our entire lives on floating islands!\" Um Ali recalls. \"Our house, our garden, our animals - all on reed platforms. When the water rose in spring, we rose with it. When it fell, we fell. We were part of the water\'s rhythm. My children learned to swim before they could walk!\"',
      characterId: 'marsh_resident',
      choices: [
        StoryChoice(
          id: 'daily_life',
          text: 'What was daily life like?',
          nextParagraphId: 'daily_routine',
        ),
        StoryChoice(
          id: 'ask_challenges',
          text: 'Was it difficult?',
          nextParagraphId: 'challenges',
        ),
      ],
    );

    final dailyLife = StoryParagraph(
      id: 'daily_routine',
      text:
          '\"Every morning, my mother would bake bread in the Tannur,\" Um Ali smiles. \"My father would take the mashhuf to check his fish traps. We children would help feed the buffalo on the adjacent platform. Neighbors would row by to chat. It was a beautiful life - simple, connected to nature, peaceful.\"',
      characterId: 'marsh_resident',
      choices: [],
    );

    final challenges = StoryParagraph(
      id: 'challenges',
      text:
          'The explorer speaks: \"Living on water requires constant maintenance. The reed platforms need repairs. Strong winds can be dangerous. But Um Ali\'s generation mastered it - they knew every technique, every safety measure. It\'s knowledge that\'s slowly being lost as younger people move to land-based villages.\"',
      characterId: 'explorer_architectural',
      choices: [],
    );

    final briefEnd = StoryParagraph(
      id: 'brief_end',
      text: 'You respectfully continue on your way.',
      characterId: null,
      choices: [],
    );

    return StorylineElement(
      id: 'floating_life',
      title: 'Life on Al-Chibisha',
      description: 'Hear memories of life on floating houses',
      paragraphs: {
        'intro': intro,
        'childhood_memories': memories,
        'daily_routine': dailyLife,
        'challenges': challenges,
        'brief_end': briefEnd,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_architectural': explorer,
        'marsh_resident': localResident,
      },
      rewards: {
        'score': 110,
        'storyCount': 1,
      },
    );
  }

  /// Creates water level challenge story
  StorylineElement _createWaterChallengeStory() {
    final explorer = StoryCharacter(
      id: 'explorer_environmental',
      name: 'Explorer',
      personality: 'Environmental researcher',
      imagePath: 'assets/team_images/adil_alqabaa.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer is measuring water levels with scientific equipment. \"The marshes face serious challenges,\" they say solemnly. \"Water levels have been declining. Let me show you what\'s happening.\"',
      characterId: 'explorer_environmental',
      choices: [
        StoryChoice(
          id: 'learn',
          text: 'Learn about the challenges',
          nextParagraphId: 'water_decline',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Maybe another time',
          nextParagraphId: 'understanding',
        ),
      ],
    );

    final waterDecline = StoryParagraph(
      id: 'water_decline',
      text:
          '\"Water levels are declining due to multiple factors,\" the explorer explains. \"Upstream dams, reduced rainfall, climate change, increased water consumption. Areas that were once deep water are now dry land. Fish populations are affected. Buffalo have less grazing area. It\'s impacting everyone who depends on the marshes.\"',
      characterId: 'explorer_environmental',
      choices: [
        StoryChoice(
          id: 'solutions',
          text: 'What can be done?',
          nextParagraphId: 'hope',
        ),
        StoryChoice(
          id: 'impact',
          text: 'How does this affect people?',
          nextParagraphId: 'human_impact',
        ),
      ],
    );

    final humanImpact = StoryParagraph(
      id: 'human_impact',
      text:
          '\"Fishing becomes harder - less water means fewer fish. Buffalo herding is more difficult. Some families have had to abandon floating houses and move to land. Tourism decreases. But the marsh people are resilient - they\'ve adapted to changes for thousands of years. They\'re not giving up.\"',
      characterId: 'explorer_environmental',
      choices: [],
    );

    final hope = StoryParagraph(
      id: 'hope',
      text:
          '\"There\'s hope,\" the explorer says with determination. \"Conservation efforts are increasing. International recognition helps. Local communities are organizing. Water management is improving. And projects like ours - documenting this heritage - raise awareness globally. If people know about the marshes, they\'ll fight to save them.\"',
      characterId: 'explorer_environmental',
      choices: [],
    );

    final understanding = StoryParagraph(
      id: 'understanding',
      text:
          'The explorer nods understandingly. \"It\'s heavy information. But awareness is the first step to change.\"',
      characterId: 'explorer_environmental',
      choices: [],
    );

    return StorylineElement(
      id: 'water_challenges',
      title: 'The Water Crisis',
      description: 'Learn about environmental challenges facing the marshes',
      paragraphs: {
        'intro': intro,
        'water_decline': waterDecline,
        'human_impact': humanImpact,
        'hope': hope,
        'understanding': understanding,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_environmental': explorer,
      },
      triggerRequirements: {'storyCount': 2},
      rewards: {
        'score': 150,
        'storyCount': 1,
      },
    );
  }

  /// Creates community gathering at Mudhif story
  StorylineElement _createCommunityGatheringStory() {
    final explorer = StoryCharacter(
      id: 'explorer_cultural',
      name: 'Explorer',
      personality: 'Cultural anthropologist',
      imagePath: 'assets/team_images/reem_salam.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'You notice many boats gathered near a large Mudhif. An explorer approaches you. \"There\'s a community gathering happening! This is rare - you\'re witnessing something special. The sheikh is mediating a dispute between two families.\"',
      characterId: 'explorer_cultural',
      choices: [
        StoryChoice(
          id: 'observe',
          text: 'Observe respectfully',
          nextParagraphId: 'gathering',
        ),
        StoryChoice(
          id: 'leave',
          text: 'Give them privacy',
          nextParagraphId: 'respect',
        ),
      ],
    );

    final gathering = StoryParagraph(
      id: 'gathering',
      text:
          '\"The Mudhif is where important community decisions happen,\" the explorer whispers. \"Disputes are resolved, marriages are arranged, tribal matters are discussed. The sheikh listens to all sides. Everyone has a voice. It\'s ancient wisdom - resolving conflicts through dialogue, not violence. This tradition has kept marsh communities harmonious for generations.\"',
      characterId: 'explorer_cultural',
      choices: [
        StoryChoice(
          id: 'hospitality',
          text: 'What about hospitality?',
          nextParagraphId: 'marsh_hospitality',
        ),
        StoryChoice(
          id: 'watch',
          text: 'Continue watching',
          nextParagraphId: 'resolution',
        ),
      ],
    );

    final hospitality = StoryParagraph(
      id: 'marsh_hospitality',
      text:
          '\"Hospitality is sacred in marsh culture!\" the explorer explains warmly. \"Any traveler can enter the Mudhif and be welcomed. Tea is offered, food is shared, stories are exchanged. It doesn\'t matter if you\'re friend or stranger - hospitality is given freely. This generosity despite hardship is what makes marsh people extraordinary.\"',
      characterId: 'explorer_cultural',
      choices: [],
    );

    final resolution = StoryParagraph(
      id: 'resolution',
      text:
          'The families emerge from the Mudhif, shaking hands and embracing. The dispute is resolved peacefully. The explorer smiles. \"This is the Mudhif\'s true purpose - bringing people together, finding common ground, preserving community bonds. It\'s beautiful, isn\'t it?\"',
      characterId: 'explorer_cultural',
      choices: [],
    );

    final respect = StoryParagraph(
      id: 'respect',
      text:
          'The explorer nods approvingly. \"Respecting their privacy shows understanding of marsh culture. Well done.\"',
      characterId: 'explorer_cultural',
      choices: [],
    );

    return StorylineElement(
      id: 'community_gathering',
      title: 'The Mudhif Gathering',
      description: 'Witness a traditional community gathering',
      paragraphs: {
        'intro': intro,
        'gathering': gathering,
        'marsh_hospitality': hospitality,
        'resolution': resolution,
        'respect': respect,
      },
      startParagraphId: 'intro',
      characters: {
        'explorer_cultural': explorer,
      },
      triggerRequirements: {'storyCount': 1},
      rewards: {
        'score': 130,
        'storyCount': 1,
      },
    );
  }

  /// Buffalo milk story - short with fun facts
  StorylineElement _createBuffaloMilkStory() {
    final explorer = StoryCharacter(
      id: 'explorer_dairy',
      name: 'Explorer',
      personality: 'Nutrition researcher',
      imagePath: 'assets/team_images/hussain.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer watches a family milking their buffalo. "Did you know buffalo milk has 58% more calcium than cow milk? It\'s richer, creamier, and makes the best yogurt!"',
      characterId: 'explorer_dairy',
      choices: [
        StoryChoice(
          id: 'learn',
          text: 'Tell me more!',
          nextParagraphId: 'facts',
        ),
        StoryChoice(
          id: 'continue',
          text: 'Thanks for sharing',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final facts = StoryParagraph(
      id: 'facts',
      text:
          '"Buffalo milk is packed with protein and fat - perfect for making cheese and butter. Families here produce fresh dairy daily. The buffalo trust their herders completely during milking!"',
      characterId: 'explorer_dairy',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Fascinating!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The explorer smiles. "Preserving these traditions keeps heritage alive!"',
      characterId: 'explorer_dairy',
      choices: [],
    );

    return StorylineElement(
      id: 'buffalo_milk_story',
      title: 'Buffalo Dairy Tradition',
      description: 'Learn about traditional buffalo milk production',
      paragraphs: {
        'intro': intro,
        'facts': facts,
        'ending': ending,
      },
      startParagraphId: 'intro',
      characters: {'explorer_dairy': explorer},
      rewards: {'score': 80, 'storyCount': 1},
    );
  }

  /// Buffalo swimming story - short fun fact
  StorylineElement _createBuffaloSwimmingStory() {
    final explorer = StoryCharacter(
      id: 'explorer_animal',
      name: 'Explorer',
      personality: 'Wildlife observer',
      imagePath: 'assets/team_images/ahmed_sinan.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'Several buffalo are fully submerged with only their noses above water! An explorer laughs. "Water buffalo can stay underwater for 2-3 minutes! They love it - it keeps them cool and protects from insects."',
      characterId: 'explorer_animal',
      choices: [
        StoryChoice(
          id: 'more',
          text: 'Why do they do this?',
          nextParagraphId: 'facts',
        ),
        StoryChoice(
          id: 'bye',
          text: 'Amazing!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final facts = StoryParagraph(
      id: 'facts',
      text:
          '"In the scorching heat, buffalo mud-bathe and submerge themselves. The mud protects their skin from sunburn! They\'re excellent swimmers - some can even swim across channels carrying people!"',
      characterId: 'explorer_animal',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Incredible creatures!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text: 'You watch the buffalo peacefully cooling off in the marsh waters.',
      characterId: 'explorer_animal',
      choices: [],
    );

    return StorylineElement(
      id: 'buffalo_swimming_story',
      title: 'Buffalo Swimming Facts',
      description: 'Discover how water buffalo stay cool in the marshes',
      paragraphs: {'intro': intro, 'facts': facts, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_animal': explorer},
      rewards: {'score': 70, 'storyCount': 1},
    );
  }

  /// Fisherman nets story - short tradition
  StorylineElement _createFishermanNetsStory() {
    final explorer = StoryCharacter(
      id: 'explorer_nets',
      name: 'Explorer',
      personality: 'Traditional crafts documenter',
      imagePath: 'assets/team_images/salih_waleed.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'A fisherman repairs his nets with expert hands. An explorer observes closely. "Traditional fishing nets here are handwoven from natural fibers. Each knot tells a story of generations!"',
      characterId: 'explorer_nets',
      choices: [
        StoryChoice(
          id: 'learn',
          text: 'How are they made?',
          nextParagraphId: 'facts',
        ),
        StoryChoice(
          id: 'thanks',
          text: 'Keep sailing',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final facts = StoryParagraph(
      id: 'facts',
      text:
          '"Net-making takes weeks to master! Fishermen use specific knot patterns passed down for centuries. The mesh size depends on target fish - smaller for shabout, larger for biny fish. It\'s pure craftsmanship!"',
      characterId: 'explorer_nets',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'True artistry',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The fisherman continues his work, each knot preserving ancient wisdom.',
      characterId: 'explorer_nets',
      choices: [],
    );

    return StorylineElement(
      id: 'fisherman_nets_story',
      title: 'The Art of Net Making',
      description: 'Learn traditional fishing net craftsmanship',
      paragraphs: {'intro': intro, 'facts': facts, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_nets': explorer},
      rewards: {'score': 75, 'storyCount': 1},
    );
  }

  /// Fisherman seasons story - fishing calendar
  StorylineElement _createFishermanSeasonsStory() {
    final explorer = StoryCharacter(
      id: 'explorer_ecology',
      name: 'Explorer',
      personality: 'Ecological researcher',
      imagePath: 'assets/team_images/reem_salam.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer checks notes by the water. "Marsh fishermen follow nature\'s calendar! Spring brings shabout fish spawning, summer means biny fish peak, autumn brings migratory birds that signal fishing changes!"',
      characterId: 'explorer_ecology',
      choices: [
        StoryChoice(
          id: 'seasons',
          text: 'Tell me about the seasons',
          nextParagraphId: 'facts',
        ),
        StoryChoice(
          id: 'move',
          text: 'Continue exploring',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final facts = StoryParagraph(
      id: 'facts',
      text:
          '"Fishermen read water temperature, moon phases, and bird behavior to predict fish movements. Winter brings cooler water - fish gather in deeper channels. This knowledge is passed orally through generations!"',
      characterId: 'explorer_ecology',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Nature\'s wisdom',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The marsh ecosystem and human tradition exist in beautiful harmony.',
      characterId: 'explorer_ecology',
      choices: [],
    );

    return StorylineElement(
      id: 'fisherman_seasons_story',
      title: 'Fishing Seasons & Nature',
      description: 'Understand the seasonal fishing calendar',
      paragraphs: {'intro': intro, 'facts': facts, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_ecology': explorer},
      rewards: {'score': 85, 'storyCount': 1},
    );
  }

  /// Reed fun fact - quick story
  StorylineElement _createReedFunFactStory() {
    final explorer = StoryCharacter(
      id: 'explorer_botanist',
      name: 'Explorer',
      personality: 'Plant researcher',
      imagePath: 'assets/team_images/adil_alqabaa.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer examines tall reeds swaying in the breeze. "These reeds can grow 6 meters tall! They filter water, provide oxygen, and create habitat for countless species. Plus, they\'re used to build everything from boats to houses!"',
      characterId: 'explorer_botanist',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Nature\'s gift!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text: 'The reeds rustle softly, a foundation of marsh life.',
      characterId: 'explorer_botanist',
      choices: [],
    );

    return StorylineElement(
      id: 'reed_fact_story',
      title: 'Amazing Reed Facts',
      description: 'Quick facts about marsh reeds',
      paragraphs: {'intro': intro, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_botanist': explorer},
      rewards: {'score': 50, 'storyCount': 1},
    );
  }

  /// Water bird fact story
  StorylineElement _createWaterBirdFactStory() {
    final explorer = StoryCharacter(
      id: 'explorer_birds',
      name: 'Explorer',
      personality: 'Ornithologist',
      imagePath: 'assets/team_images/hussain.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'Flocks of birds soar overhead! An explorer points excitedly. "Over 200 bird species visit the marshes! African sacred ibis, marbled teal, and herons all nest here. It\'s a crucial stopover on migration routes!"',
      characterId: 'explorer_birds',
      choices: [
        StoryChoice(
          id: 'more',
          text: 'Which birds are most common?',
          nextParagraphId: 'details',
        ),
        StoryChoice(
          id: 'end',
          text: 'Beautiful sight!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final details = StoryParagraph(
      id: 'details',
      text:
          '"The marshes are home to the rare Basra reed warbler! Cormorants dive for fish, herons wade through shallows. During winter, thousands of migratory ducks arrive from Siberia!"',
      characterId: 'explorer_birds',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Amazing diversity!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'Birds fill the sky, a testament to the marshes\' ecological importance.',
      characterId: 'explorer_birds',
      choices: [],
    );

    return StorylineElement(
      id: 'water_bird_fact_story',
      title: 'Marsh Birds',
      description: 'Learn about bird species in the marshes',
      paragraphs: {'intro': intro, 'details': details, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_birds': explorer},
      rewards: {'score': 60, 'storyCount': 1},
    );
  }

  /// Marsh plant fact
  StorylineElement _createMarshPlantStory() {
    final explorer = StoryCharacter(
      id: 'explorer_plants',
      name: 'Explorer',
      personality: 'Botanist',
      imagePath: 'assets/team_images/reem_salam.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'An explorer photographs floating plants. "Marshes are nature\'s water purifiers! Plants here absorb pollutants, produce oxygen, and prevent erosion. Papyrus reeds have been used since ancient Mesopotamian times!"',
      characterId: 'explorer_plants',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Nature\'s filter!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The marsh ecosystem works tirelessly, filtering and sustaining life.',
      characterId: 'explorer_plants',
      choices: [],
    );

    return StorylineElement(
      id: 'marsh_plant_story',
      title: 'Marsh Plant Power',
      description: 'Discover how marsh plants purify water',
      paragraphs: {'intro': intro, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_plants': explorer},
      rewards: {'score': 55, 'storyCount': 1},
    );
  }

  /// Boat craft story
  StorylineElement _createBoatCraftStory() {
    final explorer = StoryCharacter(
      id: 'explorer_craft',
      name: 'Explorer',
      personality: 'Traditional crafts expert',
      imagePath: 'assets/team_images/ahmed_sinan.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'A craftsman shapes a new mashhuf boat from bundled reeds. An explorer documents the process. "Building a mashhuf takes 3-4 weeks! Each boat is waterproofed with natural bitumen - a technique used for 5,000 years!"',
      characterId: 'explorer_craft',
      choices: [
        StoryChoice(
          id: 'how',
          text: 'How is it made?',
          nextParagraphId: 'process',
        ),
        StoryChoice(
          id: 'thanks',
          text: 'Impressive!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final process = StoryParagraph(
      id: 'process',
      text:
          '"First, reeds are harvested and dried. Then they\'re bundled tightly and shaped into the boat\'s curve. Bitumen seals the gaps. Each boat is unique - shaped by the craftsman\'s hands!"',
      characterId: 'explorer_craft',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'True craftsmanship',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text:
          'The craftsman continues, preserving ancient boatbuilding traditions.',
      characterId: 'explorer_craft',
      choices: [],
    );

    return StorylineElement(
      id: 'boat_craft_story',
      title: 'Ancient Boatbuilding',
      description: 'Learn 5,000-year-old boat building techniques',
      paragraphs: {'intro': intro, 'process': process, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_craft': explorer},
      rewards: {'score': 65, 'storyCount': 1},
    );
  }

  /// Marsh cooking story
  StorylineElement _createMarshCookingStory() {
    final explorer = StoryCharacter(
      id: 'explorer_culinary',
      name: 'Explorer',
      personality: 'Food culture researcher',
      imagePath: 'assets/team_images/adil_alqabaa.png',
    );

    final intro = StoryParagraph(
      id: 'intro',
      text:
          'Delicious aromas waft from a traditional tannur oven! An explorer inhales deeply. "Marsh cuisine uses fresh fish, rice, and buffalo milk. The famous \'timman mash\' combines rice with fish - flavored with cardamom and saffron!"',
      characterId: 'explorer_culinary',
      choices: [
        StoryChoice(
          id: 'dishes',
          text: 'What other dishes?',
          nextParagraphId: 'dishes',
        ),
        StoryChoice(
          id: 'thanks',
          text: 'Sounds delicious!',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final dishes = StoryParagraph(
      id: 'dishes',
      text:
          '"Fresh shabout fish is grilled over reed fires. Buffalo yogurt is served daily. Bread baked in tannur ovens has a unique smoky flavor. Tea is the ultimate hospitality symbol!"',
      characterId: 'explorer_culinary',
      choices: [
        StoryChoice(
          id: 'end',
          text: 'Heritage on a plate',
          nextParagraphId: 'ending',
        ),
      ],
    );

    final ending = StoryParagraph(
      id: 'ending',
      text: 'Food traditions carry the marshes\' story through generations.',
      characterId: 'explorer_culinary',
      choices: [],
    );

    return StorylineElement(
      id: 'marsh_cooking_story',
      title: 'Marsh Cuisine',
      description: 'Explore traditional marsh foods and cooking',
      paragraphs: {'intro': intro, 'dishes': dishes, 'ending': ending},
      startParagraphId: 'intro',
      characters: {'explorer_culinary': explorer},
      rewards: {'score': 70, 'storyCount': 1},
    );
  }
}
