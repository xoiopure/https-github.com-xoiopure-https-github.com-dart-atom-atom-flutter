

class User {
  final int id;
  final String userName;

  const User({this.id, this.userName});

  Map<String, dynamic> toJson() {
    return {
      'id' : id,
      'userName' : userName,
    };
  }
}
