class RankingEntry {
  final int position;
  final int idUser;
  final String username;
  final String name;
  final String lastname;
  final String? profilePicture;
  final int fointsSeason;

  RankingEntry({
    required this.position,
    required this.idUser,
    required this.username,
    required this.name,
    required this.lastname,
    this.profilePicture,
    required this.fointsSeason,
  });

  factory RankingEntry.fromJson(Map<String, dynamic> json) {
    return RankingEntry(
      position:       json['position'],
      idUser:         json['id_user'],
      username:       json['username'],
      name:           json['name'],
      lastname:       json['lastname'],
      profilePicture: json['profile_picture'],
      fointsSeason:   json['foints_season'],
    );
  }

  // Iniciales para el avatar cuando no hay foto de perfil
  String get initials {
    final n = name.isNotEmpty ? name[0].toUpperCase() : '';
    final l = lastname.isNotEmpty ? lastname[0].toUpperCase() : '';
    return '$n$l';
  }

  String get fullName => '$name $lastname';

  // Top 3 reciben medalla en la UI
  bool get isTopThree => position <= 3;
}