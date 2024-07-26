import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_view/chatview.dart';
import 'package:video_player/video_player.dart';
import 'reaction_widget.dart';
import 'share_icon.dart';

class VideoMessageView extends StatefulWidget {
  const VideoMessageView({
    super.key,
    required this.message,
    required this.isMessageBySender,
    this.videoMessageConfig,
    this.messageReactionConfig,
    this.highlightVideo = false,
    this.highlightScale = 1.2,
  });

  /// Provides message instance of chat.
  final Message message;

  /// Represents current message is sent by current user.
  final bool isMessageBySender;

  /// Provides configuration for video message appearance.
  final ImageMessageConfiguration? videoMessageConfig;

  /// Provides configuration of reaction appearance in chat bubble.
  final MessageReactionConfiguration? messageReactionConfig;

  /// Represents flag of highlighting video when user taps on replied video.
  final bool highlightVideo;

  /// Provides scale of highlighted video when user taps on replied video.
  final double highlightScale;

  String get videoUrl => message.message;

  @override
  State<VideoMessageView> createState() => _VideoMessageViewState();
}

class _VideoMessageViewState extends State<VideoMessageView> {
  late VideoPlayerController _controller;
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  Future<void> _initializeVideoPlayer() async {
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));

    await _controller.initialize();
    _controller.addListener(() {
      if (_controller.value.position >= _controller.value.duration) {
        setState(() {
          _controller.seekTo(Duration.zero);
          _isPlaying = false;
        });
      }
    });

    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _controller.play();
      } else {
        _controller.pause();
      }
    });
  }

  void _openVideoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          insetPadding: EdgeInsets.zero,
          child: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                ),
                IconButton(
                  icon: Icon(
                    _isPlaying ? Icons.pause : Icons.play_arrow,
                    color: Colors.black,
                    size: 30,
                  ),
                  onPressed: _togglePlayPause,
                ),
              ],
            ),
          ),
        );
      },
    ).then((_) {
      // Reset the video when the dialog is closed
      _controller.seekTo(Duration.zero);
      _isPlaying = false;
    });
  }

  Widget get iconButton => ShareIcon(
        shareIconConfig: widget.videoMessageConfig?.shareIconConfig,
        imageUrl: widget.videoUrl,
      );

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: widget.isMessageBySender
          ? MainAxisAlignment.end
          : MainAxisAlignment.start,
      children: [
        if (widget.isMessageBySender) iconButton,
        Stack(
          children: [
            GestureDetector(
              onTap: () => _openVideoDialog(context),
              child: Transform.scale(
                scale: widget.highlightVideo ? widget.highlightScale : 1.0,
                alignment: widget.isMessageBySender
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Container(
                  padding:
                      widget.videoMessageConfig?.padding ?? EdgeInsets.zero,
                  margin: widget.videoMessageConfig?.margin ??
                      EdgeInsets.only(
                        top: 6,
                        right: widget.isMessageBySender ? 6 : 0,
                        left: widget.isMessageBySender ? 0 : 6,
                        bottom: widget.message.reaction.reactions.isNotEmpty
                            ? 15
                            : 0,
                      ),
                  height: widget.videoMessageConfig?.height ?? 200,
                  width: widget.videoMessageConfig?.width ?? 150,
                  child: ClipRRect(
                    borderRadius: widget.videoMessageConfig?.borderRadius ??
                        BorderRadius.circular(14),
                    child: _controller.value.isInitialized
                        ? AspectRatio(
                            aspectRatio: _controller.value.aspectRatio,
                            child: VideoPlayer(_controller),
                          )
                        : const Center(child: CircularProgressIndicator()),
                  ),
                ),
              ),
            ),
            if (widget.message.reaction.reactions.isNotEmpty)
              ReactionWidget(
                isMessageBySender: widget.isMessageBySender,
                reaction: widget.message.reaction,
                messageReactionConfig: widget.messageReactionConfig,
              ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: _togglePlayPause,
                child: Center(
                  child: AnimatedCrossFade(
                    duration: const Duration(milliseconds: 300),
                    firstChild: const Icon(
                      Icons.pause_circle_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                    secondChild: const Icon(
                      Icons.play_circle_outline,
                      color: Colors.white,
                      size: 50,
                    ),
                    crossFadeState: _isPlaying
                        ? CrossFadeState.showFirst
                        : CrossFadeState.showSecond,
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!widget.isMessageBySender) iconButton,
      ],
    );
  }
}
