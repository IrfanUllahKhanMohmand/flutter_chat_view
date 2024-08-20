import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_view/chatview.dart';
import 'package:google_apis_test/data.dart';
import 'package:google_apis_test/models/theme.dart';
import 'package:uuid/uuid.dart';

// ignore: must_be_immutable
class ChatScreen extends StatelessWidget {
  ChatScreen(
      {super.key,
      required this.chatId,
      required this.currentUser,
      required this.otherUser});
  final String chatId;
  final ChatUser currentUser;
  final ChatUser otherUser;

  late final ChatController _chatController;
  AppTheme theme = LightTheme();
  bool isDarkTheme = false;

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
      sentBy: currentUser.id,
      replyMessage: replyMessage,
      messageType: messageType,
    );
    _chatController.addMessage(msg);
    await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatId)
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
    if (isDarkTheme) {
      theme = LightTheme();
      isDarkTheme = false;
    } else {
      theme = DarkTheme();
      isDarkTheme = true;
    }
  }

  Future<List<Message>> getMessages() async {
    return await FirebaseFirestore.instance
        .collection("messages")
        .doc(chatId)
        .collection("messages")
        .orderBy('createdAt', descending: false)
        .get()
        .then((snapshot) {
      return snapshot.docs.map((e) => Message.fromJson(e.data())).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    FirebaseFirestore.instance
        .collection('messages')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .listen((QuerySnapshot snapshot) {
      for (var change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          final message = Message.fromJson(data);
          if (message.sentBy != currentUser.id) {
            _chatController.addMessage(message);
          }
        } else if (change.type == DocumentChangeType.modified) {
          Map<String, dynamic> data = change.doc.data() as Map<String, dynamic>;
          final message = Message.fromJson(data);
          print(message.toJson());
          _chatController.replaceMessage(message);
        }
      }
    });
    return Scaffold(
      body: FutureBuilder<List<Message>>(
        future: getMessages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }
          _chatController = ChatController(
            initialMessageList: snapshot.data ?? [],
            scrollController: ScrollController(),
            currentUser: currentUser,
            otherUsers: [
              otherUser,
            ],
          );
          return ChatView(
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
              chatTitle: otherUser.name,
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
                // IconButton(
                //   tooltip: 'Simulate Message receive',
                //   onPressed: receiveMessage,
                //   icon: Icon(
                //     Icons.supervised_user_circle,
                //     color: theme.themeIconColor,
                //   ),
                // ),
              ],
            ),
            chatBackgroundConfig: ChatBackgroundConfiguration(
              messageTimeIconColor: theme.messageTimeIconColor,
              messageTimeTextStyle:
                  TextStyle(color: theme.messageTimeTextColor),
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
              enableVideoPicker: true,
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
                receiptsWidgetConfig: const ReceiptsWidgetConfig(
                    showReceiptsIn: ShowReceiptsIn.all),
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
                    .doc(chatId)
                    .collection("messages")
                    .doc(message.id)
                    .update(message.toJson());
              },
            ),
            messageConfig: MessageConfiguration(
              customMessageBuilder: (p0) {
                return Text(p0.message);
              },
              customMessageReplyViewBuilder: (state) {
                return Text(state.message);
              },
              messageReactionConfig: MessageReactionConfiguration(
                backgroundColor: theme.messageReactionBackGroundColor,
                borderColor: theme.messageReactionBackGroundColor,
                reactedUserCountTextStyle:
                    TextStyle(color: theme.inComingChatBubbleTextColor),
                reactionCountTextStyle:
                    TextStyle(color: theme.inComingChatBubbleTextColor),
                reactionsBottomSheetConfig: ReactionsBottomSheetConfiguration(
                  reactedUserCallback: (reactedUser, reaction) {},
                  backgroundColor: theme.backgroundColor,
                  reactedUserTextStyle: TextStyle(
                    color: theme.inComingChatBubbleTextColor,
                  ),
                  reactionWidgetDecoration: BoxDecoration(
                    color: theme.inComingChatBubbleColor,
                    boxShadow: [
                      BoxShadow(
                        color:
                            isDarkTheme ? Colors.black12 : Colors.grey.shade200,
                        offset: const Offset(0, 20),
                        blurRadius: 40,
                      )
                    ],
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              imageMessageConfig: ImageMessageConfiguration(
                margin:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
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
              replyTitleTextStyle:
                  TextStyle(color: theme.repliedTitleTextColor),
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
          );
        },
      ),
    );
  }
}
