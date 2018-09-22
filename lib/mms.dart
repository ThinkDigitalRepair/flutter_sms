class Mms {}

class MmsQuery {}

class Part {
  ///The identifier of the message which this part belongs to.
  String messageId;
  String contentLocation;
  String contentType;
  String fileName;

  /// The message text
  String text;

  ///The location (on filesystem) of the binary data of the part.
  String data;
}
