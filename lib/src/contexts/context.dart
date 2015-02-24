part of w_service;

class Context {

    String _id;
    String get id => _id;

    Map<String, dynamic> meta;

    String _timestamp;
    String get timestamp => _timestamp;

    Context(this._id) {
        meta = new Map<String, dynamic>();
        _timestamp = new DateTime.now().toIso8601String();
    }

}