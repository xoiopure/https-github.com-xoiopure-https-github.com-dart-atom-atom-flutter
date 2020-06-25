

class User {
  final int id;
  final String userName;

  const User({this.id, this.userName});

  Map<String, dynamic> toJson() {
    Map<String, dynamic> result = {
      'id' : id,
      'userName' : userName,
    };

    return result;
  }
}