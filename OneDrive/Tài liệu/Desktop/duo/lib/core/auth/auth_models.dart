class AtmosUser {
  const AtmosUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.coupleId,
    this.partnerId,
  });

  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? coupleId;
  final String? partnerId;

  factory AtmosUser.fromJson(Map<String, dynamic> json) {
    return AtmosUser(
      id: json['id'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String?,
      photoUrl: json['photoUrl'] as String?,
      coupleId: json['coupleId'] as String?,
      partnerId: json['partnerId'] as String?,
    );
  }
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final AtmosUser user;
}
