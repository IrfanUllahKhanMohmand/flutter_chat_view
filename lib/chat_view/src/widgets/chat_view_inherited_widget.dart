import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_view/chatview.dart';

/// This widget for alternative of excessive amount of passing arguments
/// over widgets.
class ChatViewInheritedWidget extends InheritedWidget {
  ChatViewInheritedWidget({
    super.key,
    required super.child,
    required this.featureActiveConfig,
    required this.chatController,
    this.profileCircleConfiguration,
  });
  final FeatureActiveConfig featureActiveConfig;
  final ProfileCircleConfiguration? profileCircleConfiguration;
  final ChatController chatController;
  final GlobalKey chatTextFieldViewKey = GlobalKey();

  static ChatViewInheritedWidget? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ChatViewInheritedWidget>();

  @override
  bool updateShouldNotify(covariant ChatViewInheritedWidget oldWidget) =>
      oldWidget.featureActiveConfig != featureActiveConfig;
}
