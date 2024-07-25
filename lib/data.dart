import 'package:google_apis_test/chat_view/chatview.dart';

class Data {
  static const profileImage =
      "https://raw.githubusercontent.com/SimformSolutionsPvtLtd/flutter_showcaseview/master/example/assets/simform.png";
  static final messageList = [
    Message(
      id: '1',
      message: "Hi!",
      createdAt: DateTime.now(),
      sentBy: '923099384039', // userId of who sends the message
      status: MessageStatus.read,
    ),
    Message(
      id: '2',
      message: "Hi!",
      createdAt: DateTime.now(),
      sentBy: '923099384040',
      status: MessageStatus.read,
    ),
    Message(
      id: '3',
      message: "We can meet?I am free",
      createdAt: DateTime.now(),
      sentBy: '923099384039',
      status: MessageStatus.read,
    ),
    Message(
      id: '4',
      message: "Can you write the time and place of the meeting?",
      createdAt: DateTime.now(),
      sentBy: '923099384039',
      status: MessageStatus.read,
    ),
    Message(
      id: '5',
      message: "That's fine",
      createdAt: DateTime.now(),
      sentBy: '923099384040',
      reaction:
          Reaction(reactions: ['\u{2764}'], reactedUserIds: ['923099384039']),
      status: MessageStatus.read,
    ),
    Message(
      id: '8',
      message: "https://bit.ly/3JHS2Wl",
      createdAt: DateTime.now(),
      sentBy: '923099384040',
      reaction: Reaction(
        reactions: ['\u{2764}'],
        reactedUserIds: ['923099384040'],
      ),
      status: MessageStatus.read,
      replyMessage: const ReplyMessage(
        message: "Can you write the time and place of the meeting?",
        replyTo: '923099384039',
        replyBy: '923099384040',
        messageId: '4',
      ),
    ),
    Message(
      id: '9',
      message: "Done",
      createdAt: DateTime.now(),
      sentBy: '923099384039',
      status: MessageStatus.read,
      reaction: Reaction(
        reactions: ['\u{2764}'],
        reactedUserIds: ['923099384040'],
      ),
    ),
    Message(
      id: '10',
      message: "Thank you!!",
      status: MessageStatus.read,
      createdAt: DateTime.now(),
      sentBy: '923099384039',
      reaction: Reaction(
        reactions: ['\u{2764}', '\u{2764}'],
        reactedUserIds: ['923099384040', '923099384039'],
      ),
    ),
    Message(
      id: '11',
      message: "https://miro.medium.com/max/1000/0*s7of7kWnf9fDg4XM.jpeg",
      createdAt: DateTime.now(),
      messageType: MessageType.image,
      sentBy: '923099384039',
      reaction:
          Reaction(reactions: ['\u{2764}'], reactedUserIds: ['923099384040']),
      status: MessageStatus.read,
    ),
    Message(
      id: '12',
      message: "🤩🤩",
      createdAt: DateTime.now(),
      sentBy: '923099384040',
      status: MessageStatus.read,
    ),
  ];
}
