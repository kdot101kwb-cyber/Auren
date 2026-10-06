class TalentSportsCatalog {
  static const List<String> all = [
    'Football','Basketball','Volleyball','Tennis','Table Tennis','Badminton','Squash',
    'Boxing','MMA','Wrestling','Judo','Karate','Taekwondo','Fencing','Kickboxing','Muay Thai',
    'Athletics','Swimming','Diving','Water Polo','Artistic Swimming','Cycling','Mountain Biking','BMX',
    'Motorsport','Formula 1','Rally','Karting','Gymnastics','Rhythmic Gymnastics','Trampoline',
    'Archery','Weightlifting','Powerlifting','Rugby','Cricket','Baseball','Hockey','Handball','Golf',
    'Rowing','Canoeing','Kayaking','Sailing','Surfing','Skateboarding','Climbing','Triathlon',
    'Modern Pentathlon','Equestrian','Shooting Sport','Chess & Mind Sports','Darts','Bowling',
    'American Football','Beach Volleyball','Netball','Sepak Takraw','Kabaddi','Floorball','Paddle',
  ];

  static List<String> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return all;
    return all.where((sport) => sport.toLowerCase().contains(q)).toList();
  }
}
