import 'dart:async';
import 'dart:io';

import 'package:google_apis_test/chat_view/chatview.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/data.dart';
import 'package:google_apis_test/firebase_options.dart';
import 'package:google_apis_test/models/theme.dart';
import 'package:uuid/uuid.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(Example());
}

class Example extends StatelessWidget {
  Example({super.key});
  final ChatUser currentUser = ChatUser(
    id: '923099384039',
    name: 'Irfan Ullah',
    profilePhoto: Data.profileImage,
  );

  final ChatUser otherUser = ChatUser(
    id: '923099384040',
    name: 'Basit Ali',
    profilePhoto: Data.profileImage,
  );

  String getChatId() {
    final userIds = [currentUser.id, otherUser.id];
    userIds.sort();
    return userIds.join('_');
  }

  Future<List<Message>> getMessages() async {
    return await FirebaseFirestore.instance
        .collection("messages")
        .doc(getChatId())
        .collection("messages")
        .orderBy('createdAt', descending: false)
        .get()
        .then((snapshot) {
      return snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Chat UI Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xffEE5366),
        colorScheme:
            ColorScheme.fromSwatch(accentColor: const Color(0xffEE5366)),
      ),
      home: FutureBuilder<List<Message>>(
        future: getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          return ChatScreen(
            chatId: getChatId(),
            currentUser: currentUser,
            otherUser: otherUser,
            messageList: snapshot.data ?? [],
          );
        },
      ),
    );
  }
}

class ChatScreen extends StatefulWidget {
  const ChatScreen(
      {super.key,
      required this.chatId,
      required this.currentUser,
      required this.otherUser,
      required this.messageList});
  final String chatId;
  final ChatUser currentUser;
  final ChatUser otherUser;
  final List<Message> messageList;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late StreamSubscription<QuerySnapshot> _subscription;
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;
  late final ChatController _chatController;

  Future<String> uploadFile(String path) async {
    File file = File(path);

    try {
      const Uuid uuid = Uuid();
      final String fileName = uuid.v4();
      Reference storageReference =
          FirebaseStorage.instance.ref().child('uploads/$fileName');
      UploadTask uploadTask = storageReference.putFile(file);
      await uploadTask;

      String downloadURL = await storageReference.getDownloadURL();
      return downloadURL;
    } catch (e) {
      throw Exception(e);
    }
  }

  void _showHideTypingIndicator() {
    _chatController.setTypingIndicator = !_chatController.showTypingIndicator;
  }

  void receiveMessage() async {
    _chatController.addMessage(
      Message(
        id: DateTime.now().toString(),
        message: 'I will schedule the meeting.',
        createdAt: DateTime.now(),
        sentBy: '2',
      ),
    );
    await Future.delayed(const Duration(milliseconds: 500));
    _chatController.addReplySuggestions([
      const SuggestionItemData(text: 'Thanks.'),
      const SuggestionItemData(text: 'Thank you very much.'),
      const SuggestionItemData(text: 'Great.')
    ]);
  }

  @override
  void initState() {
    _chatController = ChatController(
      initialMessageList: widget.messageList,
      scrollController: ScrollController(),
      currentUser: widget.currentUser,
      otherUsers: [
        widget.otherUser,
      ],
    );
    _subscription = FirebaseFirestore.instance
        .collection('messages')
        .doc(widget.chatId)
        .collection('messages')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          final message = Message.fromJson(data);
          if (message.sentBy != widget.currentUser.id) {
            _chatController.addMessage(message);
          }
        }
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ChatView(
        chatController: _chatController,
        onSendTap: _onSendTap,
        featureActiveConfig: const FeatureActiveConfig(
          lastSeenAgoBuilderVisibility: true,
          receiptsBuilderVisibility: true,
        ),
        chatViewState: ChatViewState.hasMessages,
        chatViewStateConfig: ChatViewStateConfiguration(
          loadingWidgetConfig: ChatViewStateWidgetConfiguration(
            loadingIndicatorColor: theme.outgoingChatBubbleColor,
          ),
          onReloadButtonTap: () {},
        ),
        typeIndicatorConfig: TypeIndicatorConfiguration(
          flashingCircleBrightColor: theme.flashingCircleBrightColor,
          flashingCircleDarkColor: theme.flashingCircleDarkColor,
        ),
        appBar: ChatViewAppBar(
          elevation: theme.elevation,
          backGroundColor: theme.appBarColor,
          profilePicture: Data.profileImage,
          backArrowColor: theme.backArrowColor,
          chatTitle: "Chat view",
          chatTitleTextStyle: TextStyle(
            color: theme.appBarTitleTextStyle,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.25,
          ),
          userStatus: "online",
          userStatusTextStyle: const TextStyle(color: Colors.grey),
          actions: [
            IconButton(
              onPressed: _onThemeIconTap,
              icon: Icon(
                isDarkTheme
                    ? Icons.brightness_4_outlined
                    : Icons.dark_mode_outlined,
                color: theme.themeIconColor,
              ),
            ),
            IconButton(
              tooltip: 'Toggle TypingIndicator',
              onPressed: _showHideTypingIndicator,
              icon: Icon(
                Icons.keyboard,
                color: theme.themeIconColor,
              ),
            ),
            IconButton(
              tooltip: 'Simulate Message receive',
              onPressed: receiveMessage,
              icon: Icon(
                Icons.supervised_user_circle,
                color: theme.themeIconColor,
              ),
            ),
          ],
        ),
        chatBackgroundConfig: ChatBackgroundConfiguration(
          messageTimeIconColor: theme.messageTimeIconColor,
          messageTimeTextStyle: TextStyle(color: theme.messageTimeTextColor),
          defaultGroupSeparatorConfig: DefaultGroupSeparatorConfiguration(
            textStyle: TextStyle(
              color: theme.chatHeaderColor,
              fontSize: 17,
            ),
          ),
          backgroundColor: theme.backgroundColor,
        ),
        sendMessageConfig: SendMessageConfiguration(
          imagePickerIconsConfig: ImagePickerIconsConfiguration(
            cameraIconColor: theme.cameraIconColor,
            galleryIconColor: theme.galleryIconColor,
          ),
          imagePickerConfiguration: ImagePickerConfiguration(
            onImagePicked: (path) async {
              if (path != null) {
                try {
                  return await uploadFile(path);
                } catch (e) {
                  debugPrint(e.toString());
                  return null;
                }
              } else {
                return null;
              }
            },
          ),
          replyMessageColor: theme.replyMessageColor,
          defaultSendButtonColor: theme.sendButtonColor,
          replyDialogColor: theme.replyDialogColor,
          replyTitleColor: theme.replyTitleColor,
          textFieldBackgroundColor: theme.textFieldBackgroundColor,
          closeIconColor: theme.closeIconColor,
          textFieldConfig: TextFieldConfiguration(
            onMessageTyping: (status) {
              /// Do with status
              debugPrint(status.toString());
            },
            compositionThresholdTime: const Duration(seconds: 1),
            textStyle: TextStyle(color: theme.textFieldTextColor),
          ),
          micIconColor: theme.replyMicIconColor,
          voiceRecordingConfiguration: VoiceRecordingConfiguration(
              backgroundColor: theme.waveformBackgroundColor,
              recorderIconColor: theme.recordIconColor,
              waveStyle: WaveStyle(
                showMiddleLine: false,
                waveColor: theme.waveColor ?? Colors.white,
                extendWaveform: true,
              ),
              onVoiceRecorded: (path) async {
                if (path != null) {
                  try {
                    return await uploadFile(path);
                  } catch (e) {
                    debugPrint(e.toString());
                    return null;
                  }
                } else {
                  return null;
                }
              }),
        ),
        chatBubbleConfig: ChatBubbleConfiguration(
          outgoingChatBubbleConfig: ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              backgroundColor: theme.linkPreviewOutgoingChatColor,
              bodyStyle: theme.outgoingChatLinkBodyStyle,
              titleStyle: theme.outgoingChatLinkTitleStyle,
            ),
            receiptsWidgetConfig:
                const ReceiptsWidgetConfig(showReceiptsIn: ShowReceiptsIn.all),
            color: theme.outgoingChatBubbleColor,
          ),
          inComingChatBubbleConfig: ChatBubble(
            linkPreviewConfig: LinkPreviewConfiguration(
              linkStyle: TextStyle(
                color: theme.inComingChatBubbleTextColor,
                decoration: TextDecoration.underline,
              ),
              backgroundColor: theme.linkPreviewIncomingChatColor,
              bodyStyle: theme.incomingChatLinkBodyStyle,
              titleStyle: theme.incomingChatLinkTitleStyle,
            ),
            textStyle: TextStyle(color: theme.inComingChatBubbleTextColor),
            onMessageRead: (message) {
              /// send your message reciepts to the other client
              debugPrint('Message Read');
            },
            senderNameTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            color: theme.inComingChatBubbleColor,
          ),
        ),
        replyPopupConfig: ReplyPopupConfiguration(
          backgroundColor: theme.replyPopupColor,
          buttonTextStyle: TextStyle(color: theme.replyPopupButtonColor),
          topBorderColor: theme.replyPopupTopBorderColor,
        ),
        reactionPopupConfig: ReactionPopupConfiguration(
          shadow: BoxShadow(
            color: isDarkTheme ? Colors.black54 : Colors.grey.shade400,
            blurRadius: 20,
          ),
          backgroundColor: theme.reactionPopupColor,
          userReactionCallback: (message, emoji) async {
            await FirebaseFirestore.instance
                .collection("messages")
                .doc(widget.chatId)
                .collection("messages")
                .doc(message.id)
                .update({
              'reaction': {
                'reactions': message.reaction.reactions,
                'reactedUserIds': message.reaction.reactedUserIds,
              }
            });
            debugPrint("Reaction: $emoji Message: ${message.toJson()}");
          },
        ),
        messageConfig: MessageConfiguration(
          messageReactionConfig: MessageReactionConfiguration(
            backgroundColor: theme.messageReactionBackGroundColor,
            borderColor: theme.messageReactionBackGroundColor,
            reactedUserCountTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            reactionCountTextStyle:
                TextStyle(color: theme.inComingChatBubbleTextColor),
            reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
              backgroundColor: theme.backgroundColor,
              reactedUserTextStyle: TextStyle(
                color: theme.inComingChatBubbleTextColor,
              ),
              reactionWidgetDecoration: BoxDecoration(
                color: theme.inComingChatBubbleColor,
                boxShadow: [
                  BoxShadow(
                    color: isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                    offset: const Offset(0, 20),
                    blurRadius: 40,
                  )
                ],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
          imageMessageConfig: ImageMessageConfiguration(
            margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
            shareIconConfig: ShareIconConfiguration(
              defaultIconBackgroundColor: theme.shareIconBackgroundColor,
              defaultIconColor: theme.shareIconColor,
            ),
          ),
        ),
        profileCircleConfig: const ProfileCircleConfiguration(
          profileImageUrl: Data.profileImage,
        ),
        repliedMessageConfig: RepliedMessageConfiguration(
          backgroundColor: theme.repliedMessageColor,
          verticalBarColor: theme.verticalBarColor,
          repliedMsgAutoScrollConfig: RepliedMsgAutoScrollConfig(
            enableHighlightRepliedMsg: true,
            highlightColor: Colors.pinkAccent.shade100,
            highlightScale: 1.1,
          ),
          textStyle: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.25,
          ),
          replyTitleTextStyle: TextStyle(color: theme.repliedTitleTextColor),
        ),
        swipeToReplyConfig: SwipeToReplyConfiguration(
          replyIconColor: theme.swipeToReplyIconColor,
        ),
        replySuggestionsConfig: ReplySuggestionsConfig(
          itemConfig: SuggestionItemConfig(
            decoration: BoxDecoration(
              color: theme.textFieldBackgroundColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.outgoingChatBubbleColor ?? Colors.white,
              ),
            ),
            textStyle: TextStyle(
              color: isDarkTheme ? Colors.white : Colors.black,
            ),
          ),
          onTap: (item) {
            _onSendTap(item.text, const ReplyMessage(), MessageType.text);
          },
        ),
      ),
    );
  }

  Future<void> _onSendTap(
    String message,
    ReplyMessage replyMessage,
    MessageType messageType,
  ) async {
    Uuid uuid = const Uuid();
    final String id = uuid.v4();
    final msg = Message(
      id: id,
      message: message,
      createdAt: DateTime.now(),
      sentBy: widget.currentUser.id,
      replyMessage: replyMessage,
      messageType: messageType,
    );
    _chatController.addMessage(msg);
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(widget.chatId)
        .collection("messages")
        .doc(id)
        .set(msg.toJson());
    Future.delayed(const Duration(milliseconds: 300), () {
      _chatController.initialMessageList.last.setStatus =
          MessageStatus.undelivered;
    });
    Future.delayed(const Duration(seconds: 1), () {
      _chatController.initialMessageList.last.setStatus = MessageStatus.read;
    });
  }

  void _onThemeIconTap() {
    setState(() {
      if (isDarkTheme) {
        theme = LightTheme();
        isDarkTheme = false;
      } else {
        theme = DarkTheme();
        isDarkTheme = true;
      }
    });
  }
}
