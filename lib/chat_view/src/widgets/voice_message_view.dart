import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:google_apis_test/chat_view/chatview.dart';
import 'package:google_apis_test/chat_view/src/models/voice_message_configuration.dart';
import 'package:google_apis_test/chat_view/src/widgets/reaction_widget.dart';

class VoiceMessageView extends StatefulWidget {
  const VoiceMessageView({
    super.key,
    required this.screenWidth,
    required this.message,
    required this.isMessageBySender,
    this.inComingChatBubbleConfig,
    this.outgoingChatBubbleConfig,
    this.onMaxDuration,
    this.messageReactionConfig,
    this.config,
  });

  final VoiceMessageConfiguration? config;
  final double screenWidth;
  final Message message;
  final Function(int)? onMaxDuration;
  final bool isMessageBySender;
  final MessageReactionConfiguration? messageReactionConfig;
  final ChatBubble? inComingChatBubbleConfig;
  final ChatBubble? outgoingChatBubbleConfig;

  @override
  State<VoiceMessageView> createState() => _VoiceMessageViewState();
}

class _VoiceMessageViewState extends State<VoiceMessageView> {
  late AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration? _duration;
  Duration? _position;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    await _audioPlayer.setReleaseMode(ReleaseMode.stop);
    await _audioPlayer.setSource(UrlSource(widget.message.message));

    _duration = await _audioPlayer.getDuration();
    widget.onMaxDuration?.call(_duration?.inMilliseconds ?? 0);

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (mounted) {
        setState(() {
          _position = pos;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '0:00';
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return '$twoDigitMinutes:$twoDigitSeconds';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: widget.screenWidth * 0.7),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: widget.config?.decoration ??
                BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: widget.isMessageBySender
                      ? widget.outgoingChatBubbleConfig?.color
                      : widget.inComingChatBubbleConfig?.color,
                ),
            padding: widget.config?.padding ??
                const EdgeInsets.symmetric(horizontal: 8),
            margin: widget.config?.margin ??
                EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical:
                      widget.message.reaction.reactions.isNotEmpty ? 15 : 0,
                ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: _playOrPause,
                  icon: Icon(
                    _playerState == PlayerState.playing
                        ? Icons.pause
                        : Icons.play_arrow,
                    color: Colors.white,
                  ),
                ),
                Expanded(
                  child: Slider(
                    thumbColor: Colors.pink,
                    activeColor: Colors.grey,
                    inactiveColor: Colors.white,
                    value: _position?.inMilliseconds.toDouble() ?? 0.0,
                    max: _duration?.inMilliseconds.toDouble() ?? 1.0,
                    onChanged: (value) {
                      final position = Duration(milliseconds: value.toInt());
                      _audioPlayer.seek(position);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Text(
                    '${_formatDuration(_position)} / ${_formatDuration(_duration)}',
                    style: const TextStyle(fontSize: 16.0),
                  ),
                ),
              ],
            ),
          ),
          if (widget.message.reaction.reactions.isNotEmpty)
            ReactionWidget(
              isMessageBySender: widget.isMessageBySender,
              reaction: widget.message.reaction,
              messageReactionConfig: widget.messageReactionConfig,
            ),
        ],
      ),
    );
  }

  void _playOrPause() {
    if (_playerState == PlayerState.playing) {
      _audioPlayer.pause();
    } else {
      _audioPlayer.resume();
    }
  }
}
