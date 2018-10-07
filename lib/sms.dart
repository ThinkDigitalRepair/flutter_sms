/// An SMS library for flutter
library sms;

import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sms/contact.dart';

typedef OnError(Object error);

/// Represents a device's sim card info
class SimCard {
  int slot;
  String imei;
  SimCardState state;

  SimCard(
      {@required this.slot,
      @required this.imei,
      this.state = SimCardState.Unknown})
      : assert(slot != null),
        assert(imei != null);

  SimCard.fromJson(Map map) {
    if (map.containsKey('slot')) {
      this.slot = map['slot'];
    }
    if (map.containsKey('imei')) {
      this.imei = map['imei'];
    }
    if (map.containsKey('state')) {
      switch (map['state']) {
        case 0:
          this.state = SimCardState.Unknown;
          break;
        case 1:
          this.state = SimCardState.Absent;
          break;
        case 2:
          this.state = SimCardState.PinRequired;
          break;
        case 3:
          this.state = SimCardState.PukRequired;
          break;
        case 4:
          this.state = SimCardState.Locked;
          break;
        case 5:
          this.state = SimCardState.Ready;
          break;
      }
    }
  }
}

class SimCardsProvider {
  static SimCardsProvider _instance;
  final MethodChannel _channel;

  factory SimCardsProvider() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
          "plugins.babariviere.com/simCards", const JSONMethodCodec());
      _instance = new SimCardsProvider._private(methodChannel);
    }
    return _instance;
  }

  SimCardsProvider._private(this._channel);

  Future<List<SimCard>> getSimCards() async {
    final simCards = new List<SimCard>();

    dynamic response = await _channel.invokeMethod('getSimCards', null);
    for (Map map in response) {
      simCards.add(new SimCard.fromJson(map));
    }

    return simCards;
  }
}

enum SimCardState {
  Unknown,
  Absent,
  PinRequired,
  PukRequired,
  Locked,
  Ready,
}

class SmsDb {
  static SmsDb _instance;
  final MethodChannel _channel;

  factory SmsDb() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
          "plugins.babariviere.com/smsDb", const JSONMethodCodec());
      _instance = new SmsDb._private(methodChannel);
    }
    return _instance;
  }

  SmsDb._private(this._channel);

  /// Inserts an SMS into the phone's database.
  /// [message] must include address, body, date, dateSent, read and kind.
  Future insert(SmsMessage message) {
    assert(message.address != null,
        "Could not insert SMS because address is required and cannot be null.");
    assert(message.body != null,
        "Could not insert SMS because body is required and cannot be null.");
    assert(message.date != null,
        "Could not insert SMS because date is required and cannot be null.");
    assert(message.dateSent != null,
        "Could not insert SMS because dateSent is required and cannot be null.");
    assert(message.isRead != null,
        "Could not insert SMS because isRead is required and cannot be null.");
    assert(message.kind != null,
        "Could not insert SMS because kind is required and cannot be null.");
    Map messageMap = message.toMap;
    switch (message.kind) {
      case SmsMessageKind.Sent:
        {
          messageMap['kind'] = 0;
          break;
        }
      case SmsMessageKind.Received:
        {
          messageMap['kind'] = 1;
          break;
        }
      case SmsMessageKind.Draft:
        {
          messageMap['kind'] = 2;
          break;
        }
      default:
        messageMap['kind'] = 2;
    }
    messageMap['read'] = messageMap['read'] == true ? 1 : 0;
    return this._channel.invokeMethod("insert", messageMap);
  }
}

/// A SMS Message
///
/// Used to send message or used to read message.
class SmsMessage implements Comparable<SmsMessage> {
  int _id;
  int _threadId;
  String _address;
  String _body;
  bool _read;
  DateTime _date;
  DateTime _dateSent;
  SmsMessageKind _kind;
  SmsMessageState _state = SmsMessageState.None;
  StreamController<SmsMessageState> _stateStreamController =
      new StreamController<SmsMessageState>();

  SmsMessage(this._address, this._body,
      {int id,
      int threadId,
      bool read,
      DateTime date,
      DateTime dateSent,
      SmsMessageKind kind}) {
    this._id = id;
    this._threadId = threadId;
    this._read = read;
    this._date = date;
    this._dateSent = dateSent;
    this._kind = kind;
  }

  /// Read message from JSON
  ///
  /// Format:
  ///
  /// ```json
  /// {
  ///   "address": "phone-number-here",
  ///   "body": "text message here"
  /// }
  /// ```
  SmsMessage.fromJson(Map data) {
    this._address = data["address"];
    this._body = data["body"];
    if (data.containsKey("_id")) {
      this._id = data["_id"];
    }
    if (data.containsKey("thread_id")) {
      this._threadId = data["thread_id"];
    }
    if (data.containsKey("read")) {
      this._read = data["read"] as int == 1;
    }
    if (data.containsKey("kind")) {
      this._kind = SmsMessageKind.values[data["kind"]];
    }
    if (data.containsKey("date")) {
      this._date = new DateTime.fromMillisecondsSinceEpoch(data["date"]);
    }
    if (data.containsKey("date_sent")) {
      this._dateSent =
          new DateTime.fromMillisecondsSinceEpoch(data["date_sent"]);
    }
  }

  /// Get address, alias phone number
  String get address => this._address;

  /// Get message body
  String get body => this._body;

  /// Get date
  DateTime get date => this._date;

  /// Set message date
  set date(DateTime date) => this._date = date;

  /// Get date sent
  DateTime get dateSent => this._dateSent;

  /// Get message id
  int get id => this._id;

  /// Check if message is read
  bool get isRead => this._read;

  /// Get message kind
  SmsMessageKind get kind => this._kind;

  /// Set message kind
  set kind(SmsMessageKind kind) => this._kind = kind;

  Stream<SmsMessageState> get onStateChanged => _stateStreamController.stream;

  /// Get sender, alias phone number
  String get sender => this._address;

  /// Get message state
  get state => this._state;

  set state(SmsMessageState state) {
    if (this._state != state) {
      this._state = state;
      _stateStreamController.add(state);
    }
  }

  /// Get thread id
  int get threadId => this._threadId;

  /// Convert SMS to map
  Map get toMap {
    Map res = {};
    if (_address != null) {
      res["address"] = _address;
    }
    if (_body != null) {
      res["body"] = _body;
    }
    if (_id != null) {
      res["_id"] = _id;
    }
    if (_threadId != null) {
      res["thread_id"] = _threadId;
    }
    if (_read != null) {
      res["read"] = _read;
    }
    if (_date != null) {
      res["date"] = _date.millisecondsSinceEpoch;
    }
    if (_dateSent != null) {
      res["dateSent"] = _dateSent.millisecondsSinceEpoch;
    }
    if (_kind != null) {
      res["kind"] = _kind.index;
    }
    return res;
  }

  @override
  int compareTo(SmsMessage other) {
    return other._id - this._id;
  }

  @override
  bool operator ==(other) =>
      other is SmsMessage &&
          this.threadId == other.threadId &&
          this.body == other.body &&
          this.address == other.address &&
          this.date == other.date &&
          this.dateSent == other.dateSent;

  @override
  int get hashCode => hashValues(threadId, body, address, date, dateSent);

  @override
  String toString() => toMap.toString();
}

enum SmsMessageKind {
  Sent,
  Received,
  Draft,
  Outbox,
  Failed,
  Queued
}

enum SmsMessageState {
  Sending,
  Sent,
  Delivered,
  None,
}

/// A SMS query
class SmsQuery {
  static SmsQuery _instance;
  final MethodChannel _channel;

  factory SmsQuery() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
          "plugins.babariviere.com/querySMS", const JSONMethodCodec());
      _instance = new SmsQuery._private(methodChannel);
    }
    return _instance;
  }

  SmsQuery._private(this._channel);

  /// Get all SMS
  Future<List<SmsMessage>> get getAllSms async {
    return this.querySms(
        kinds: [SmsQueryKind.Sent, SmsQueryKind.Inbox, SmsQueryKind.Draft]);
  }

  /// Get all threads
  Future<List<SmsThread>> get getAllThreads async {
    List<SmsMessage> messages = await this.getAllSms;
    Map<int, List<SmsMessage>> filtered = {};
    messages.forEach((msg) {
      if (!filtered.containsKey(msg.threadId)) {
        filtered[msg.threadId] = [];
      }
      filtered[msg.threadId].add(msg);
    });
    List<SmsThread> threads = <SmsThread>[];
    for (var k in filtered.keys) {
      final thread = new SmsThread.fromMessages(filtered[k]);
      await thread.findContact();
      threads.add(thread);
    }
    return threads;
  }

  /// Query a list of SMS
  Future<List<SmsMessage>> querySms(
      {int start,
      int count,
      String address,
      int threadId,
      List<SmsQueryKind> kinds: const [SmsQueryKind.Inbox],
      bool sort: true}) async {
    List<SmsMessage> result = [];
    for (var kind in kinds) {
      result
        ..addAll(await this._querySmsWrapper(
          start: start,
          count: count,
          address: address,
          threadId: threadId,
          kind: kind,
        ));
    }
    if (sort == true) {
      result.sort((a, b) => a.compareTo(b));
    }
    return (result);
  }

  /// Query multiple thread by id
  Future<List<SmsThread>> queryThreads(List<int> threadsId,
      {List<SmsQueryKind> kinds: const [SmsQueryKind.Inbox]}) async {
    List<SmsThread> threads = <SmsThread>[];
    for (var id in threadsId) {
      final messages = await this.querySms(threadId: id, kinds: kinds);
      final thread = new SmsThread.fromMessages(messages);
      await thread.findContact();
      threads.add(thread);
    }
    return threads;
  }

  /// Wrapper for query only one kind
  Future<List<SmsMessage>> _querySmsWrapper(
      {int start,
      int count,
      String address,
      int threadId,
      SmsQueryKind kind: SmsQueryKind.Inbox}) async {
    Map arguments = {};
    if (start != null && start >= 0) {
      arguments["start"] = start;
    }
    if (count != null && count > 0) {
      arguments["count"] = count;
    }
    if (address != null && address.isNotEmpty) {
      arguments["address"] = address;
    }
    if (threadId != null && threadId >= 0) {
      arguments["thread_id"] = threadId;
    }
    String function;
    SmsMessageKind msgKind;
    if (kind == SmsQueryKind.Inbox) {
      function = "getInbox";
      msgKind = SmsMessageKind.Received;
    } else if (kind == SmsQueryKind.Sent) {
      function = "getSent";
      msgKind = SmsMessageKind.Sent;
    } else {
      function = "getDraft";
      msgKind = SmsMessageKind.Draft;
    }
    return await _channel.invokeMethod(function, arguments).then((dynamic val) {
      List<SmsMessage> list = [];
      for (Map data in val) {
        SmsMessage msg = new SmsMessage.fromJson(data);
        msg.kind = msgKind;
        list.add(msg);
      }
      return list;
    });
  }
}

enum SmsQueryKind { Inbox, Sent, Draft }

/// A SMS receiver that creates a stream of SMS
///
///
/// Usage:
///
/// ```dart
/// var receiver = SmsReceiver();
/// receiver.onSmsReceived.listen((SmsMessage msg) => ...);
/// ```
class SmsReceiver {
  static SmsReceiver _instance;
  final EventChannel _channel;
  Stream<SmsMessage> _onSmsReceived;

  factory SmsReceiver() {
    if (_instance == null) {
      final EventChannel eventChannel = const EventChannel(
          "plugins.babariviere.com/recvSMS", const JSONMethodCodec());
      _instance = new SmsReceiver._private(eventChannel);
    }
    return _instance;
  }

  SmsReceiver._private(this._channel);

  /// Create a stream that collect received SMS
  Stream<SmsMessage> get onSmsReceived {
    if (_onSmsReceived == null) {
      print("Creating sms receiver");
      _onSmsReceived = _channel.receiveBroadcastStream().map((dynamic event) {
        SmsMessage msg = new SmsMessage.fromJson(event);
        msg.kind = SmsMessageKind.Received;
        return msg;
      });
    }
    return _onSmsReceived;
  }
}

/// A SMS sender
class SmsSender {
  static SmsSender _instance;
  final MethodChannel _channel;
  final EventChannel _stateChannel;
  Map<int, SmsMessage> _sentMessages;
  int _sentId = 0;
  final StreamController<SmsMessage> _deliveredStreamController =
      new StreamController<SmsMessage>();

  factory SmsSender() {
    if (_instance == null) {
      final MethodChannel methodChannel = const MethodChannel(
          "plugins.babariviere.com/sendSMS", const JSONMethodCodec());
      final EventChannel stateChannel = const EventChannel(
          "plugins.babariviere.com/statusSMS", const JSONMethodCodec());

      _instance = new SmsSender._private(methodChannel, stateChannel);
    }
    return _instance;
  }

  SmsSender._private(this._channel, this._stateChannel) {
    _stateChannel.receiveBroadcastStream().listen(this._onSmsStateChanged);

    _sentMessages = new Map<int, SmsMessage>();
  }

  Stream<SmsMessage> get onSmsDelivered => _deliveredStreamController.stream;

  /// Send an SMS
  ///
  /// Take a message in argument + 2 functions that will be called on success or on error
  ///
  /// This function will not set automatically thread id, you have to do it
  Future<SmsMessage> sendSms(SmsMessage msg, {SimCard simCard}) async {
    if (msg == null || msg.address == null || msg.body == null) {
      if (msg == null) {
        throw ("no given message");
      } else if (msg.address == null) {
        throw ("no given address");
      } else if (msg.body == null) {
        throw ("no given body");
      }
      return null;
    }

    msg.state = SmsMessageState.Sending;
    Map map = msg.toMap;
    this._sentMessages.putIfAbsent(this._sentId, () => msg);
    map['sentId'] = this._sentId;
    if (simCard != null) {
      map['subId'] = simCard.slot;
    }
    this._sentId += 1;

    if (simCard != null) {
      map['simCard'] = simCard.imei;
    }

    await _channel.invokeMethod("sendSMS", map);
    msg.date = new DateTime.now();

    return msg;
  }

  void _onSmsStateChanged(dynamic stateChange) {
    int id = stateChange['sentId'];
    if (_sentMessages.containsKey(id)) {
      switch (stateChange['state']) {
        case 'sent':
          {
            _sentMessages[id].state = SmsMessageState.Sent;
            break;
          }
        case 'delivered':
          {
            _sentMessages[id].state = SmsMessageState.Delivered;
            _deliveredStreamController.add(_sentMessages[id]);
            _sentMessages.remove(id);
            break;
          }
      }
    }
  }
}

/// A SMS thread
class SmsThread extends Iterable {
  int _id;
  String _address;
  Contact _contact;
  List<SmsMessage> _messages = [];
  bool _hasAttachment;
  DateTime _date;

  SmsThread(int id,
      {String address,
      List<SmsMessage> messages,
      DateTime date,
      bool hasAttachment})
      : this._id = id,
        this._address = address,
        this._messages = messages != null ? messages : [],
        this._date = date,
        this._hasAttachment = hasAttachment;

  /// Create a thread from a list of message, the id will be taken from
  /// the first message
  SmsThread.fromMessages(List<SmsMessage> messages) {
    if (messages == null || messages.length == 0) {
      return;
    }
    this._id = messages[0].threadId;

    for (var msg in messages) {
      if (msg.threadId == _id && msg.address != null) {
        this._address = msg.address;
        break;
      }
    }

    for (var msg in messages) {
      if (msg.threadId == _id) {
        this._messages.add(msg);
      }
    }
  }

  /// Get address
  String get address => this._address;

  /// Get contact info
  Contact get contact => this._contact;

  /// Set contact info
  set contact(Contact contact) => this._contact = contact;

  set date(DateTime date) => this._date = date;

  DateTime get date => _date;

  /// Get thread id
  int get id => this._id;

  int get messageCount => _messages.length;

  /// Get messages from thread
  List<SmsMessage> get messages => this._messages;

  /// Set messages in thread
  set messages(List<SmsMessage> messages) => this._messages = messages;

  ///the last sms in your thread. This is usually the visible text in an SMS app.
  String get snippet {
    if (messages.last != null) {
      String lastMessage = messages.last.body;
      if (lastMessage.length > 45)
        return lastMessage.substring(0, 44);
      else
        return lastMessage;
    } else
      return "";
  }

  /// Get thread id (for compatibility)
  int get threadId => this._id;

  /// Add a message at the end
  void addMessage(SmsMessage msg) {
    if (msg.threadId == _id) {
      _messages.add(msg);
      if (this._address == null) {
        this._address = msg.address;
      }
    }
  }

  /// Add a message at the start
  void addNewMessage(SmsMessage msg) {
    if (msg.threadId == _id) {
      _messages.insert(0, msg);
      if (this._address == null) {
        this._address = msg.address;
      }
    }
  }

  /// Set contact through contact query
  Future findContact() async {
    ContactQuery query = new ContactQuery();
    Contact contact = await query.queryContact(this._address);
    if (contact != null) {
      this._contact = contact;
    }
  }

  @override
  Iterator get iterator => messages.iterator;
}
