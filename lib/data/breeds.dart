/// Static breed data for common chicken breeds.
/// This is reference data bundled with the app, not persisted to the database.

enum EggColor {
  white,
  cream,
  brown,
  darkBrown,
  chocolate,
  blue,
  green,
  olive,
  pink,
  tinted,
}

enum BreedCategory {
  layer,
  dual,
  meat,
  ornamental,
  bantam,
}

enum Broodiness {
  low,
  moderate,
  high,
}

class Breed {
  final String id;
  final String name;
  final List<String> aka;
  final BreedCategory category;
  final EggColor eggColor;
  final String eggSize;
  final int eggsPerYearMin;
  final int eggsPerYearMax;
  final String temperament;
  final bool coldHardy;
  final bool heatTolerant;
  final Broodiness broodiness;
  final double weightLbsHenMin;
  final double weightLbsHenMax;
  final double weightLbsRoosterMin;
  final double weightLbsRoosterMax;
  final String description;

  const Breed({
    required this.id,
    required this.name,
    this.aka = const [],
    required this.category,
    required this.eggColor,
    required this.eggSize,
    required this.eggsPerYearMin,
    required this.eggsPerYearMax,
    required this.temperament,
    required this.coldHardy,
    required this.heatTolerant,
    required this.broodiness,
    required this.weightLbsHenMin,
    required this.weightLbsHenMax,
    required this.weightLbsRoosterMin,
    required this.weightLbsRoosterMax,
    required this.description,
  });

  /// Average eggs per year (midpoint of range)
  int get eggsPerYearAvg => ((eggsPerYearMin + eggsPerYearMax) / 2).round();

  /// Egg color as display string
  String get eggColorDisplay {
    switch (eggColor) {
      case EggColor.white:
        return 'White';
      case EggColor.cream:
        return 'Cream';
      case EggColor.brown:
        return 'Brown';
      case EggColor.darkBrown:
        return 'Dark Brown';
      case EggColor.chocolate:
        return 'Chocolate';
      case EggColor.blue:
        return 'Blue';
      case EggColor.green:
        return 'Green';
      case EggColor.olive:
        return 'Olive';
      case EggColor.pink:
        return 'Pink';
      case EggColor.tinted:
        return 'Tinted';
    }
  }
}

/// All breeds bundled with the app
const List<Breed> breeds = [
  // === HIGH PRODUCTION LAYERS ===

  Breed(
    id: 'leghorn_white',
    name: 'White Leghorn',
    aka: ['Leghorn'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Large',
    eggsPerYearMin: 280,
    eggsPerYearMax: 320,
    temperament: 'Active, flighty',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.5,
    weightLbsHenMax: 5.5,
    weightLbsRoosterMin: 6.0,
    weightLbsRoosterMax: 7.5,
    description:
        'The quintessential white egg layer. Leghorns are prolific producers, active foragers, and do well in hot climates. They can be flighty and prefer free-range environments.',
  ),

  Breed(
    id: 'isa_brown',
    name: 'ISA Brown',
    aka: ['Hubbard ISA Brown'],
    category: BreedCategory.layer,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 300,
    eggsPerYearMax: 350,
    temperament: 'Docile, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.5,
    weightLbsHenMax: 5.5,
    weightLbsRoosterMin: 6.0,
    weightLbsRoosterMax: 7.0,
    description:
        'A commercial hybrid bred for maximum egg production. ISA Browns are friendly, hardy, and begin laying early. They are one of the most prolific brown egg layers available.',
  ),

  Breed(
    id: 'golden_comet',
    name: 'Golden Comet',
    aka: ['Gold Sex Link', 'Cinnamon Queen'],
    category: BreedCategory.layer,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 280,
    eggsPerYearMax: 320,
    temperament: 'Docile, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 5.5,
    weightLbsRoosterMin: 6.0,
    weightLbsRoosterMax: 7.5,
    description:
        'A sex-link hybrid known for early maturity and high production. Golden Comets are calm, personable birds that adapt well to various climates and make excellent backyard layers.',
  ),

  Breed(
    id: 'black_star',
    name: 'Black Star',
    aka: ['Black Sex Link'],
    category: BreedCategory.layer,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 280,
    eggsPerYearMax: 300,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.0,
    description:
        'A hardy sex-link cross producing abundant brown eggs. Black Stars are easy to sex at hatch, start laying early, and maintain good production through winter months.',
  ),

  Breed(
    id: 'red_star',
    name: 'Red Star',
    aka: ['Red Sex Link', 'Golden Buff'],
    category: BreedCategory.layer,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 280,
    eggsPerYearMax: 300,
    temperament: 'Docile, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.0,
    description:
        'Another excellent sex-link hybrid bred for egg production. Red Stars are dependable layers with calm dispositions, making them ideal for families and first-time chicken keepers.',
  ),

  // === DUAL PURPOSE AMERICAN CLASSICS ===

  Breed(
    id: 'rhode_island_red',
    name: 'Rhode Island Red',
    aka: ['RIR'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 250,
    eggsPerYearMax: 300,
    temperament: 'Hardy, assertive',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 8.5,
    weightLbsRoosterMax: 9.5,
    description:
        'America\'s most famous dual-purpose breed. Rhode Island Reds are exceptionally hardy, excellent layers, and adapt to nearly any environment. They can be assertive but are generally easy to keep.',
  ),

  Breed(
    id: 'plymouth_rock_barred',
    name: 'Barred Plymouth Rock',
    aka: ['Barred Rock', 'Plymouth Rock'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 250,
    eggsPerYearMax: 280,
    temperament: 'Docile, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 7.0,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 9.0,
    weightLbsRoosterMax: 9.5,
    description:
        'A beloved American heritage breed with distinctive black and white barred plumage. Barred Rocks are dependable layers, cold hardy, and known for their calm, friendly personalities.',
  ),

  Breed(
    id: 'new_hampshire',
    name: 'New Hampshire',
    aka: ['New Hampshire Red'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 220,
    eggsPerYearMax: 280,
    temperament: 'Competitive, vigorous',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 8.5,
    description:
        'Developed from Rhode Island Reds for faster growth and earlier maturity. New Hampshires are robust, good layers, and mature quickly. They can be competitive at the feeder.',
  ),

  Breed(
    id: 'delaware',
    name: 'Delaware',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large to Jumbo',
    eggsPerYearMin: 200,
    eggsPerYearMax: 280,
    temperament: 'Calm, curious',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 8.5,
    description:
        'A striking white bird with black barring on the hackles and tail. Delawares were once a leading meat bird and remain excellent dual-purpose homestead chickens with calm dispositions.',
  ),

  Breed(
    id: 'wyandotte',
    name: 'Wyandotte',
    aka: ['Silver Laced Wyandotte', 'Golden Laced Wyandotte'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 240,
    temperament: 'Docile, calm',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.0,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 9.0,
    description:
        'A beautiful American breed available in many color varieties. Wyandottes have rose combs that resist frostbite, making them excellent cold-weather birds. They are docile and make good mothers.',
  ),

  // === BRITISH HERITAGE ===

  Breed(
    id: 'orpington_buff',
    name: 'Buff Orpington',
    aka: ['Orpington'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 280,
    temperament: 'Docile, friendly, calm',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.high,
    weightLbsHenMin: 7.0,
    weightLbsHenMax: 8.0,
    weightLbsRoosterMin: 9.0,
    weightLbsRoosterMax: 10.0,
    description:
        'A fluffy, golden bird beloved for its gentle disposition. Buff Orpingtons are excellent for families with children, good layers, and often go broody. They tolerate confinement well.',
  ),

  Breed(
    id: 'sussex_speckled',
    name: 'Speckled Sussex',
    aka: ['Sussex'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 250,
    temperament: 'Curious, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 7.0,
    weightLbsHenMax: 8.0,
    weightLbsRoosterMin: 9.0,
    weightLbsRoosterMax: 10.0,
    description:
        'A beautiful heritage breed with mahogany feathers tipped in white and black. Speckled Sussex are curious, friendly birds that forage well and get more speckled with each molt.',
  ),

  Breed(
    id: 'australorp',
    name: 'Australorp',
    aka: ['Black Australorp'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 250,
    eggsPerYearMax: 300,
    temperament: 'Docile, gentle',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 8.5,
    weightLbsRoosterMax: 10.0,
    description:
        'Developed in Australia from Orpingtons, Australorps hold the world record for egg laying (364 eggs in 365 days). They are gentle, beautiful birds with iridescent black plumage.',
  ),

  // === ASIAN BREEDS ===

  Breed(
    id: 'brahma_light',
    name: 'Light Brahma',
    aka: ['Brahma'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Calm, gentle',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 9.0,
    weightLbsHenMax: 10.0,
    weightLbsRoosterMin: 11.0,
    weightLbsRoosterMax: 12.0,
    description:
        'Known as the "King of All Poultry," Brahmas are massive, stately birds with feathered feet. Despite their size, they are exceptionally gentle and handle cold weather beautifully.',
  ),

  Breed(
    id: 'cochin_buff',
    name: 'Buff Cochin',
    aka: ['Cochin'],
    category: BreedCategory.ornamental,
    eggColor: EggColor.brown,
    eggSize: 'Medium',
    eggsPerYearMin: 150,
    eggsPerYearMax: 180,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.high,
    weightLbsHenMin: 8.0,
    weightLbsHenMax: 9.0,
    weightLbsRoosterMin: 10.0,
    weightLbsRoosterMax: 11.0,
    description:
        'Massive, fluffy birds that look like feathered basketballs. Cochins are extremely docile, make excellent broodies, and are often kept as pets. Their abundant feathering requires dry conditions.',
  ),

  Breed(
    id: 'langshan',
    name: 'Langshan',
    aka: ['Black Langshan', 'Croad Langshan'],
    category: BreedCategory.dual,
    eggColor: EggColor.darkBrown,
    eggSize: 'Large',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Gentle, active',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 7.0,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 9.0,
    weightLbsRoosterMax: 10.0,
    description:
        'Tall, elegant birds from China with beautiful black plumage showing green iridescence. Langshans are gentle, good foragers, and lay notably dark brown eggs.',
  ),

  // === BLUE/GREEN EGG LAYERS ===

  Breed(
    id: 'ameraucana',
    name: 'Ameraucana',
    aka: [],
    category: BreedCategory.layer,
    eggColor: EggColor.blue,
    eggSize: 'Medium to Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 250,
    temperament: 'Friendly, docile',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.5,
    weightLbsHenMax: 6.5,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 7.5,
    description:
        'A true breed with muffs and beard that lays beautiful blue eggs. Ameraucanas come in recognized color varieties and breed true, unlike Easter Eggers. Hardy and friendly.',
  ),

  Breed(
    id: 'easter_egger',
    name: 'Easter Egger',
    aka: ['EE', 'Americana (misspelling)'],
    category: BreedCategory.layer,
    eggColor: EggColor.blue,
    eggSize: 'Medium to Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 280,
    temperament: 'Friendly, curious',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 6.0,
    weightLbsRoosterMax: 7.0,
    description:
        'A mixed breed carrying the blue egg gene. Easter Eggers can lay blue, green, olive, or even pink eggs. Each bird is unique in appearance. Hardy, friendly, and excellent layers.',
  ),

  Breed(
    id: 'araucana',
    name: 'Araucana',
    aka: [],
    category: BreedCategory.layer,
    eggColor: EggColor.blue,
    eggSize: 'Medium',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Active, flighty',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 4.5,
    weightLbsHenMax: 5.5,
    weightLbsRoosterMin: 5.5,
    weightLbsRoosterMax: 6.5,
    description:
        'The original blue egg layer from South America, known for being rumpless (no tail) and having ear tufts. True Araucanas are rare due to a lethal gene associated with the tufts.',
  ),

  Breed(
    id: 'cream_legbar',
    name: 'Cream Legbar',
    aka: ['Legbar'],
    category: BreedCategory.layer,
    eggColor: EggColor.blue,
    eggSize: 'Medium',
    eggsPerYearMin: 200,
    eggsPerYearMax: 250,
    temperament: 'Active, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 7.5,
    description:
        'A crested autosexing breed from Britain that lays sky-blue eggs. Cream Legbars are active foragers, good layers, and chicks can be sexed by color at hatch.',
  ),

  Breed(
    id: 'olive_egger',
    name: 'Olive Egger',
    aka: ['OE'],
    category: BreedCategory.layer,
    eggColor: EggColor.olive,
    eggSize: 'Medium to Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 250,
    temperament: 'Varies',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.5,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 8.0,
    description:
        'A cross between blue egg layers and dark brown egg layers, producing olive to khaki colored eggs. Appearance and temperament vary based on parent breeds used.',
  ),

  // === DARK BROWN EGG LAYERS ===

  Breed(
    id: 'marans_black_copper',
    name: 'Black Copper Marans',
    aka: ['Marans', 'BCM'],
    category: BreedCategory.dual,
    eggColor: EggColor.chocolate,
    eggSize: 'Large',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Calm, gentle',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 7.5,
    weightLbsRoosterMax: 8.5,
    description:
        'Famous for laying the darkest brown eggs of any breed. Black Copper Marans have striking black plumage with copper hackles. Egg color fades somewhat through the laying cycle.',
  ),

  Breed(
    id: 'welsummer',
    name: 'Welsummer',
    aka: ['Welsumer'],
    category: BreedCategory.dual,
    eggColor: EggColor.darkBrown,
    eggSize: 'Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Docile, intelligent',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.5,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.0,
    description:
        'A Dutch breed laying beautiful terracotta eggs often with darker speckles. Welsummers are friendly, intelligent birds that forage well. The rooster inspired the Kellogg\'s cereal mascot.',
  ),

  Breed(
    id: 'barnevelder',
    name: 'Barnevelder',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.darkBrown,
    eggSize: 'Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 200,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.5,
    weightLbsHenMax: 6.5,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.0,
    description:
        'A Dutch breed with beautiful double-laced plumage. Barnevelders lay dark brown eggs and are calm, friendly birds suited to backyard flocks. Good layers even through winter.',
  ),

  Breed(
    id: 'penedesenca',
    name: 'Penedesenca',
    aka: [],
    category: BreedCategory.layer,
    eggColor: EggColor.chocolate,
    eggSize: 'Medium',
    eggsPerYearMin: 160,
    eggsPerYearMax: 200,
    temperament: 'Active, flighty',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.5,
    weightLbsHenMax: 5.5,
    weightLbsRoosterMin: 5.5,
    weightLbsRoosterMax: 6.5,
    description:
        'A rare Spanish breed known for extremely dark reddish-brown eggs. Penedesencas have unique carnation combs and are active foragers. They can be flighty and prefer free range.',
  ),

  // === MEDITERRANEAN BREEDS ===

  Breed(
    id: 'minorca',
    name: 'Minorca',
    aka: ['Black Minorca'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Jumbo',
    eggsPerYearMin: 200,
    eggsPerYearMax: 240,
    temperament: 'Active, flighty',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 9.0,
    description:
        'The largest of the Mediterranean breeds, known for laying the largest white eggs. Minorcas have striking black plumage and huge white earlobes. They need warm, dry conditions.',
  ),

  Breed(
    id: 'andalusian',
    name: 'Andalusian',
    aka: ['Blue Andalusian'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, flighty',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 7.5,
    description:
        'A beautiful slate-blue Spanish breed. True blue color requires careful breeding (blue x blue = 50% blue, 25% black, 25% splash). Active birds that do best free ranging.',
  ),

  Breed(
    id: 'ancona',
    name: 'Ancona',
    aka: [],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Large',
    eggsPerYearMin: 220,
    eggsPerYearMax: 280,
    temperament: 'Active, flighty',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.5,
    weightLbsHenMax: 5.0,
    weightLbsRoosterMin: 5.5,
    weightLbsRoosterMax: 6.5,
    description:
        'An Italian breed with striking black plumage tipped with white V-shaped spangles. Anconas are excellent layers, good foragers, and get more white spotting with age.',
  ),

  Breed(
    id: 'hamburg',
    name: 'Hamburg',
    aka: ['Silver Spangled Hamburg'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Small to Medium',
    eggsPerYearMin: 200,
    eggsPerYearMax: 250,
    temperament: 'Active, flighty',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 4.5,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 5.5,
    description:
        'An elegant, small breed available in striking spangled and penciled patterns. Hamburgs are active foragers, excellent layers of small white eggs, and quite flighty.',
  ),

  Breed(
    id: 'campine',
    name: 'Campine',
    aka: ['Golden Campine', 'Silver Campine'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Medium',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, flighty',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 5.0,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 6.0,
    description:
        'A rare Belgian breed with stunning barred plumage. Campines are active foragers and good layers but can be flighty. Roosters and hens have identical plumage (hen-feathered).',
  ),

  Breed(
    id: 'fayoumi',
    name: 'Egyptian Fayoumi',
    aka: ['Fayoumi'],
    category: BreedCategory.layer,
    eggColor: EggColor.tinted,
    eggSize: 'Small',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, wild',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 3.5,
    weightLbsHenMax: 4.0,
    weightLbsRoosterMin: 4.5,
    weightLbsRoosterMax: 5.0,
    description:
        'An ancient Egyptian breed prized for disease resistance and heat tolerance. Fayoumis mature early, forage extensively, and can be quite wild. They fly well and roost in trees.',
  ),

  // === ORNAMENTAL BREEDS ===

  Breed(
    id: 'silkie',
    name: 'Silkie',
    aka: ['Silky'],
    category: BreedCategory.ornamental,
    eggColor: EggColor.cream,
    eggSize: 'Small',
    eggsPerYearMin: 80,
    eggsPerYearMax: 120,
    temperament: 'Docile, calm, friendly',
    coldHardy: false,
    heatTolerant: false,
    broodiness: Broodiness.high,
    weightLbsHenMin: 2.5,
    weightLbsHenMax: 3.0,
    weightLbsRoosterMin: 3.5,
    weightLbsRoosterMax: 4.0,
    description:
        'Unmistakable fluffy birds with hair-like plumage, black skin, and five toes. Silkies are beloved pets, exceptional broodies, and extremely docile. They need protection from wet weather.',
  ),

  Breed(
    id: 'polish_white_crested_black',
    name: 'Polish',
    aka: ['White Crested Black Polish', 'Poland'],
    category: BreedCategory.ornamental,
    eggColor: EggColor.white,
    eggSize: 'Medium',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Gentle, nervous',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 5.0,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 6.0,
    description:
        'Known for their spectacular head crests. Polish chickens come in many color varieties. Their limited vision from the crest makes them nervous, so they do best in calm environments.',
  ),

  Breed(
    id: 'sultan',
    name: 'Sultan',
    aka: [],
    category: BreedCategory.ornamental,
    eggColor: EggColor.white,
    eggSize: 'Small',
    eggsPerYearMin: 50,
    eggsPerYearMax: 80,
    temperament: 'Calm, docile',
    coldHardy: false,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 4.5,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 6.0,
    description:
        'An ornate Turkish breed with crests, beards, muffs, feathered feet, vulture hocks, and five toes. Sultans are purely ornamental and require meticulous care to keep their plumage clean.',
  ),

  Breed(
    id: 'frizzle',
    name: 'Frizzle',
    aka: [],
    category: BreedCategory.ornamental,
    eggColor: EggColor.tinted,
    eggSize: 'Medium',
    eggsPerYearMin: 120,
    eggsPerYearMax: 180,
    temperament: 'Friendly, calm',
    coldHardy: false,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.0,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.0,
    description:
        'Characterized by feathers that curl outward instead of lying flat. Frizzle refers to a feather type, bred into various breeds. Their unusual plumage provides poor insulation.',
  ),

  Breed(
    id: 'houdan',
    name: 'Houdan',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.white,
    eggSize: 'Large',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Active, gentle',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.low,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 8.5,
    description:
        'A French crested breed with mottled black and white plumage, a beard, and five toes. Houdans are active, good layers, and have excellent meat quality.',
  ),

  Breed(
    id: 'crevecoeur',
    name: 'Crèvecoeur',
    aka: ['Crevecoeur'],
    category: BreedCategory.ornamental,
    eggColor: EggColor.white,
    eggSize: 'Medium',
    eggsPerYearMin: 120,
    eggsPerYearMax: 160,
    temperament: 'Gentle, quiet',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.low,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 8.5,
    description:
        'One of the oldest French breeds, with a full crest, beard, and V-comb. Crèvecoeurs are rare, gentle birds originally bred for meat. They require protection from wet weather.',
  ),

  // === MEAT BREEDS ===

  Breed(
    id: 'cornish',
    name: 'Cornish',
    aka: ['Indian Game', 'Cornish Game'],
    category: BreedCategory.meat,
    eggColor: EggColor.brown,
    eggSize: 'Small',
    eggsPerYearMin: 80,
    eggsPerYearMax: 120,
    temperament: 'Assertive, active',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 7.5,
    weightLbsHenMax: 8.0,
    weightLbsRoosterMin: 10.0,
    weightLbsRoosterMax: 11.0,
    description:
        'A heavily muscled British breed, one parent of the commercial Cornish Cross. Standard Cornish are slow-growing but develop excellent breast meat. Poor layers but good mothers.',
  ),

  Breed(
    id: 'jersey_giant',
    name: 'Jersey Giant',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large to Jumbo',
    eggsPerYearMin: 150,
    eggsPerYearMax: 200,
    temperament: 'Calm, gentle',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.low,
    weightLbsHenMin: 10.0,
    weightLbsHenMax: 11.0,
    weightLbsRoosterMin: 13.0,
    weightLbsRoosterMax: 15.0,
    description:
        'The largest purebred chicken breed. Jersey Giants were developed as a turkey alternative. Despite their size, they are gentle and calm. They mature slowly but become impressive birds.',
  ),

  Breed(
    id: 'freedom_ranger',
    name: 'Freedom Ranger',
    aka: ['Red Ranger', 'Color Ranger'],
    category: BreedCategory.meat,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, hardy',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 8.0,
    description:
        'A slower-growing meat bird bred for pasture-based systems. Freedom Rangers are active foragers that thrive outdoors and produce flavorful meat in 9-11 weeks.',
  ),

  // === SPECIALTY/RARE BREEDS ===

  Breed(
    id: 'bielefelder',
    name: 'Bielefelder',
    aka: ['Bielefelder Kennhuhn'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large to Jumbo',
    eggsPerYearMin: 200,
    eggsPerYearMax: 230,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 7.5,
    weightLbsHenMax: 9.0,
    weightLbsRoosterMin: 10.0,
    weightLbsRoosterMax: 12.0,
    description:
        'A German autosexing breed developed in the 1970s. Bielefelders are large, docile, excellent layers, and chicks can be sexed by color at hatch. An outstanding homestead bird.',
  ),

  Breed(
    id: 'swedish_flower_hen',
    name: 'Swedish Flower Hen',
    aka: ['Skånsk Blommehöna'],
    category: BreedCategory.dual,
    eggColor: EggColor.tinted,
    eggSize: 'Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 5.5,
    weightLbsHenMax: 6.5,
    weightLbsRoosterMin: 7.0,
    weightLbsRoosterMax: 8.5,
    description:
        'A Swedish landrace breed with beautiful, random spotted plumage—no two birds look alike. Swedish Flower Hens are hardy, friendly, and excellent foragers.',
  ),

  Breed(
    id: 'icelandic',
    name: 'Icelandic',
    aka: ['Íslenska hænan'],
    category: BreedCategory.dual,
    eggColor: EggColor.tinted,
    eggSize: 'Medium',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, flighty',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 3.5,
    weightLbsHenMax: 4.5,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 6.0,
    description:
        'An ancient landrace from Iceland, isolated for over 1,000 years. Icelandic chickens are extremely cold hardy, excellent foragers, and come in endless color varieties.',
  ),

  Breed(
    id: 'buckeye',
    name: 'Buckeye',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Medium to Large',
    eggsPerYearMin: 180,
    eggsPerYearMax: 220,
    temperament: 'Active, friendly',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.0,
    weightLbsRoosterMin: 8.0,
    weightLbsRoosterMax: 9.0,
    description:
        'The only American breed created entirely by a woman (Nettie Metcalf). Buckeyes have dark mahogany plumage, pea combs for cold tolerance, and are excellent mousers.',
  ),

  Breed(
    id: 'chantecler',
    name: 'Chantecler',
    aka: [],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 200,
    eggsPerYearMax: 240,
    temperament: 'Calm, gentle',
    coldHardy: true,
    heatTolerant: false,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 8.5,
    weightLbsRoosterMax: 9.5,
    description:
        'Canada\'s first chicken breed, developed for extreme cold. Chanteclers have tiny cushion combs and dense plumage. They\'re excellent winter layers and very cold hardy.',
  ),

  Breed(
    id: 'dominique',
    name: 'Dominique',
    aka: ['Dominicker'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Medium',
    eggsPerYearMin: 180,
    eggsPerYearMax: 230,
    temperament: 'Calm, docile',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 5.0,
    weightLbsHenMax: 6.0,
    weightLbsRoosterMin: 6.5,
    weightLbsRoosterMax: 7.5,
    description:
        'America\'s oldest chicken breed, predating the Revolution. Dominiques have barred plumage (similar to but distinct from Barred Rocks) and rose combs. Hardy homestead birds.',
  ),

  Breed(
    id: 'java',
    name: 'Java',
    aka: ['Black Java'],
    category: BreedCategory.dual,
    eggColor: EggColor.brown,
    eggSize: 'Large',
    eggsPerYearMin: 150,
    eggsPerYearMax: 180,
    temperament: 'Calm, docile',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.moderate,
    weightLbsHenMin: 6.5,
    weightLbsHenMax: 7.5,
    weightLbsRoosterMin: 9.0,
    weightLbsRoosterMax: 9.5,
    description:
        'One of the oldest American breeds, foundational to many others including Jersey Giants. Javas are slow to mature but long-lived. The Black variety is critically endangered.',
  ),

  Breed(
    id: 'nankin',
    name: 'Nankin',
    aka: [],
    category: BreedCategory.bantam,
    eggColor: EggColor.cream,
    eggSize: 'Small',
    eggsPerYearMin: 100,
    eggsPerYearMax: 120,
    temperament: 'Calm, friendly',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.high,
    weightLbsHenMin: 1.25,
    weightLbsHenMax: 1.5,
    weightLbsRoosterMin: 1.5,
    weightLbsRoosterMax: 1.75,
    description:
        'One of the oldest true bantam breeds, with no large fowl equivalent. Nankins have golden buff plumage and are exceptional broodies, often used to hatch eggs from other breeds.',
  ),

  Breed(
    id: 'sebright',
    name: 'Sebright',
    aka: ['Golden Sebright', 'Silver Sebright'],
    category: BreedCategory.bantam,
    eggColor: EggColor.cream,
    eggSize: 'Tiny',
    eggsPerYearMin: 60,
    eggsPerYearMax: 80,
    temperament: 'Active, friendly',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 1.25,
    weightLbsHenMax: 1.5,
    weightLbsRoosterMin: 1.5,
    weightLbsRoosterMax: 1.75,
    description:
        'A stunning true bantam with intricate laced plumage. Sebrights are hen-feathered (roosters lack sickle feathers) and prized for exhibition. They can be challenging to breed.',
  ),

  Breed(
    id: 'deathlayer',
    name: 'Westfälische Totleger',
    aka: ['Deathlayer'],
    category: BreedCategory.layer,
    eggColor: EggColor.white,
    eggSize: 'Medium',
    eggsPerYearMin: 200,
    eggsPerYearMax: 250,
    temperament: 'Active, flighty',
    coldHardy: true,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 4.5,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 5.5,
    description:
        'An ancient German breed whose name means "layer unto death"—they maintain production into old age. Striking penciled plumage. Active birds that prefer free range.',
  ),

  Breed(
    id: 'ayam_cemani',
    name: 'Ayam Cemani',
    aka: ['Cemani'],
    category: BreedCategory.ornamental,
    eggColor: EggColor.cream,
    eggSize: 'Medium',
    eggsPerYearMin: 80,
    eggsPerYearMax: 120,
    temperament: 'Friendly, alert',
    coldHardy: false,
    heatTolerant: true,
    broodiness: Broodiness.low,
    weightLbsHenMin: 4.0,
    weightLbsHenMax: 4.5,
    weightLbsRoosterMin: 5.0,
    weightLbsRoosterMax: 5.5,
    description:
        'The "Lamborghini of poultry"—completely black inside and out due to fibromelanosis. Even bones and organs are black. Rare and expensive. Contrary to myth, eggs are cream, not black.',
  ),
];

// === HELPER FUNCTIONS ===

/// Get a breed by its ID, or null if not found
Breed? getBreedById(String id) {
  try {
    return breeds.firstWhere((b) => b.id == id);
  } catch (_) {
    return null;
  }
}

/// Search breeds by name or AKA (returns alphabetically sorted)
List<Breed> searchBreeds(String query) {
  final q = query.toLowerCase().trim();
  List<Breed> results;

  if (q.isEmpty) {
    results = List<Breed>.from(breeds);
  } else {
    results = breeds.where((b) {
      if (b.name.toLowerCase().contains(q)) return true;
      if (b.aka.any((a) => a.toLowerCase().contains(q))) return true;
      return false;
    }).toList();
  }

  results.sort((a, b) => a.name.compareTo(b.name));
  return results;
}

/// Filter breeds by egg color
List<Breed> getBreedsByEggColor(EggColor color) {
  return breeds.where((b) => b.eggColor == color).toList();
}

/// Filter breeds by category
List<Breed> getBreedsByCategory(BreedCategory category) {
  return breeds.where((b) => b.category == category).toList();
}

/// Get breeds that are cold hardy
List<Breed> getColdHardyBreeds() {
  return breeds.where((b) => b.coldHardy).toList();
}

/// Get breeds that are heat tolerant
List<Breed> getHeatTolerantBreeds() {
  return breeds.where((b) => b.heatTolerant).toList();
}

/// Get breeds sorted by egg production (highest first)
List<Breed> getBreedsByProduction() {
  final sorted = List<Breed>.from(breeds);
  sorted.sort((a, b) => b.eggsPerYearAvg.compareTo(a.eggsPerYearAvg));
  return sorted;
}

/// Get breeds that tend to go broody
List<Breed> getBroodyBreeds() {
  return breeds.where((b) => b.broodiness == Broodiness.high).toList();
}

/// Get breeds good for beginners (docile, adaptable to all climates, good layers)
List<Breed> getBeginnerFriendlyBreeds() {
  return breeds.where((b) {
    final isDocile = b.temperament.toLowerCase().contains('docile') ||
        b.temperament.toLowerCase().contains('calm') ||
        b.temperament.toLowerCase().contains('friendly');
    final isAdaptable = b.coldHardy && b.heatTolerant; // Both, not either
    final isGoodLayer = b.eggsPerYearAvg >= 200;
    return isDocile && isAdaptable && isGoodLayer;
  }).toList();
}
