import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:just_audio/just_audio.dart';
import 'package:record/record.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/utils/logger.dart';
import '../../../shared/widgets/text_input.dart';
import '../application/chat_provider.dart';
import '../data/chat_models.dart';

class ChatPage extends ConsumerStatefulWidget {
  const ChatPage({super.key});

  @override
  ConsumerState<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends ConsumerState<ChatPage> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _composerController = TextEditingController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final AudioRecorder _recorder = AudioRecorder();
  bool _isRecording = false;
  bool _cancelRecording = false;
  bool _assemblyExpanded = false;
  final List<String> _assembledTokens = [];

  @override
  void dispose() {
    _scrollController.dispose();
    _composerController.dispose();
    _audioPlayer.dispose();
    _recorder.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent + 120,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _playMessage(String text) async {
    if (text.trim().isEmpty) return;
    try {
      final response = await ref.read(chatProvider.notifier).tts(text);
      await _audioPlayer.setUrl(response.audioUrl);
      await _audioPlayer.play();
    } catch (e) {
      AppLogger.w('tts play failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('播放失败')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    if (_isRecording || ref.read(chatProvider).isLoading) return;
    if (!await _recorder.hasPermission()) return;
    final path =
        '${Directory.systemTemp.path}/moyu_${DateTime.now().millisecondsSinceEpoch}.wav';
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
      ),
      path: path,
    );
    if (!mounted) return;
    setState(() {
      _isRecording = true;
      _cancelRecording = false;
    });
  }

  void _markRecordingCancel(LongPressMoveUpdateDetails details) {
    if (details.localOffsetFromOrigin.dy < -48 && !_cancelRecording) {
      setState(() => _cancelRecording = true);
    }
  }

  Future<void> _finishRecording() async {
    if (!_isRecording) return;
    final path = await _recorder.stop();
    final shouldCancel = _cancelRecording;
    if (mounted) {
      setState(() {
        _isRecording = false;
        _cancelRecording = false;
      });
    }
    if (path == null || shouldCancel) return;
    await ref.read(chatProvider.notifier).sendAudio(path);
    try {
      await File(path).delete();
    } catch (_) {}
  }

  Future<void> _confirmClear() async {
    final shouldClear = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('清空对话？'),
        content: const Text('清空后将无法恢复这些消息。'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('取消')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('清空')),
        ],
      ),
    );
    if (shouldClear == true && mounted) {
      ref.read(chatProvider.notifier).clearConversation();
    }
  }

  List<String> get _candidateCards {
    final text = _composerController.text.trim();
    if (text.isNotEmpty) {
      final tokens =
          text.split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
      if (tokens.isNotEmpty) return tokens;
    }
    return const ['我', '想', '吃', '苹果'];
  }

  void _toggleAssemblyToken(String token) {
    setState(() {
      if (_assembledTokens.contains(token)) {
        _assembledTokens.remove(token);
      } else {
        _assembledTokens.add(token);
      }
    });
  }

  void _clearAssemblyTokens() {
    setState(_assembledTokens.clear);
  }

  Future<void> _sendAssembly() async {
    if (_assembledTokens.isNotEmpty) {
      final text = _assembledTokens.join(' ');
      _clearAssemblyTokens();
      await ref.read(chatProvider.notifier).retryMessage(text);
      return;
    }
    await ref.read(chatProvider.notifier).sendText();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatProvider);

    ref.listen(chatProvider, (prev, next) {
      if (prev?.messages.length != next.messages.length) {
        _scrollToBottom();
      }
      if (prev?.inputText != next.inputText) {
        _composerController.text = next.inputText;
        _composerController.selection = TextSelection.collapsed(
          offset: next.inputText.length,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.morningMist,
      body: Container(
        color: AppColors.morningMist,
        child: Column(
          children: [
            SafeArea(
              bottom: false,
              child: Container(
                width: double.infinity,
                color: AppColors.pureWhite,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 6, 14, 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _HaloAvatar(onTap: () => context.go('/profile')),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '默语共鸣',
                              style: AppTextStyles.h2.copyWith(
                                fontSize: 19,
                                color: AppColors.calmBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed:
                            state.messages.isEmpty ? null : _confirmClear,
                        icon: const Icon(Icons.delete_outline_rounded),
                        color: AppColors.calmBlue,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: Stack(
                children: [
                  ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                    children: [
                      if (state.messages.isEmpty) ...[
                        const _WelcomeCard(),
                        const SizedBox(height: 14),
                      ],
                      if (state.suggestions.isNotEmpty)
                        _SuggestionStrip(
                          suggestions: state.suggestions,
                          onTap: (text) async {
                            await ref
                                .read(chatProvider.notifier)
                                .sendQuickReply(text);
                          },
                        ),
                      if (state.suggestions.isNotEmpty)
                        const SizedBox(height: 12),
                      ...state.messages.map(
                        (m) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MessageTile(
                            message: m,
                            onRetry: m.retryText == null
                                ? null
                                : () => ref
                                    .read(chatProvider.notifier)
                                    .retryMessage(m.retryText!),
                            onPlay: m.sender == ChatMessageSender.assistant
                                ? () => _playMessage(m.text)
                                : null,
                          ),
                        ),
                      ),
                      if (state.isLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: _TypingIndicator(),
                        ),
                      const SizedBox(height: 10),
                      _AssemblyTray(
                        expanded: _assemblyExpanded,
                        onToggleExpanded: () {
                          setState(
                              () => _assemblyExpanded = !_assemblyExpanded);
                        },
                        candidates: _candidateCards,
                        assembledTokens: _assembledTokens,
                        onToggleToken: _toggleAssemblyToken,
                        onClear: _clearAssemblyTokens,
                        onSend: _sendAssembly,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _ComposerBar(
              controller: _composerController,
              loading: state.isLoading,
              recording: _isRecording,
              cancelRecording: _cancelRecording,
              onChanged: (value) {
                ref.read(chatProvider.notifier).updateInput(value);
              },
              onSubmitted: (_) async {
                await _sendAssembly();
              },
              onSend: () async {
                await _sendAssembly();
              },
              onMicDown: _startRecording,
              onMicMove: _markRecordingCancel,
              onMicUp: _finishRecording,
            ),
          ],
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  const _WelcomeCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.lilacPurple, AppColors.starPurple],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.chat_bubble_rounded,
                color: AppColors.pureWhite),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '今天想怎么说？',
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionStrip extends StatelessWidget {
  const _SuggestionStrip({required this.suggestions, required this.onTap});

  final List<SuggestionItem> suggestions;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('你可以这样说', style: AppTextStyles.caption.copyWith(fontSize: 13)),
        const SizedBox(height: 8),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final item in suggestions)
              ActionChip(
                label: Text(item.text),
                onPressed: () => onTap(item.text),
                backgroundColor: AppColors.pureWhite,
                labelStyle: AppTextStyles.caption.copyWith(fontSize: 13),
              ),
          ],
        ),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  const _MessageTile({required this.message, this.onPlay, this.onRetry});

  final ChatMessage message;
  final VoidCallback? onPlay;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == ChatMessageSender.user;
    return Row(
      mainAxisAlignment:
          isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (!isUser) const _BubbleAvatar(),
        if (!isUser) const SizedBox(width: 10),
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              gradient: isUser
                  ? const LinearGradient(
                      colors: [AppColors.lilacPurple, AppColors.starPurple],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    )
                  : null,
              color: isUser ? null : AppColors.pureWhite,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(22),
                topRight: const Radius.circular(22),
                bottomLeft: Radius.circular(isUser ? 22 : 8),
                bottomRight: Radius.circular(isUser ? 8 : 22),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.starPurple.withValues(alpha: 0.08),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Text(
                  message.text,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 16,
                    color: isUser ? AppColors.pureWhite : AppColors.calmBlue,
                  ),
                ),
                if (message.isError && message.errorText != null) ...[
                  const SizedBox(height: 8),
                  _RetryRow(text: message.errorText!, onRetry: onRetry),
                ],
                if (message.refinedPass != null) ...[
                  const SizedBox(height: 10),
                  _MetaChips(message: message),
                ],
                if (onPlay != null) ...[
                  const SizedBox(height: 4),
                  Align(
                    alignment: Alignment.centerRight,
                    child: InkWell(
                      onTap: onPlay,
                      borderRadius: BorderRadius.circular(16),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.volume_up_outlined,
                          size: 18,
                          color: AppColors.starPurple,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (isUser) const SizedBox(width: 10),
        if (isUser) const _BubbleAvatar(user: true),
      ],
    );
  }
}

class _RetryRow extends StatelessWidget {
  const _RetryRow({required this.text, this.onRetry});

  final String text;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          text,
          style: AppTextStyles.caption
              .copyWith(fontSize: 11, color: AppColors.calmBlue),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: onRetry,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.morningMist,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '重试',
                  style: AppTextStyles.caption
                      .copyWith(fontSize: 11, color: AppColors.starPurple),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _MetaChips extends StatelessWidget {
  const _MetaChips({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final refined = message.refinedPass!;
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final entry in refined.oovMap.entries)
          _TagChip(text: '${entry.key}→${entry.value}', accent: true),
        for (final entry in refined.nmmHints.entries)
          _TagChip(text: '${entry.key} ${nmmHintToEmoji(entry.value)}'),
        if (refined.alignmentOps.isNotEmpty)
          _TagChip(text: '对齐 ${refined.alignmentOps.length}'),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.text, this.accent = false});

  final String text;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: accent
            ? AppColors.paleGolden
            : AppColors.cloudGray.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: AppTextStyles.caption.copyWith(fontSize: 11),
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _BubbleAvatar(),
        const SizedBox(width: 10),
        Container(
          width: 96,
          height: 42,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.pureWhite,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Row(
            children: [
              _Dot(),
              SizedBox(width: 8),
              _Dot(),
              SizedBox(width: 8),
              _Dot(),
            ],
          ),
        ),
      ],
    );
  }
}

class _Dot extends StatelessWidget {
  const _Dot();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: const BoxDecoration(
        color: AppColors.thinCloudGray,
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BubbleAvatar extends StatelessWidget {
  const _BubbleAvatar({this.user = false});

  final bool user;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: user
            ? AppColors.sakuraPink.withValues(alpha: 0.9)
            : AppColors.pureWhite,
        shape: BoxShape.circle,
      ),
      child: user
          ? const Icon(
              Icons.person_rounded,
              size: 14,
              color: AppColors.starPurple,
            )
          : ClipOval(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Image.asset(
                  'assets/svg/yuyu/Yuyu_head.png',
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Icon(
                    Icons.pets_rounded,
                    size: 14,
                    color: AppColors.starPurple,
                  ),
                ),
              ),
            ),
    );
  }
}

class _ComposerBar extends StatelessWidget {
  const _ComposerBar({
    required this.controller,
    required this.loading,
    required this.recording,
    required this.cancelRecording,
    required this.onChanged,
    required this.onSubmitted,
    required this.onSend,
    required this.onMicDown,
    required this.onMicMove,
    required this.onMicUp,
  });

  final TextEditingController controller;
  final bool loading;
  final bool recording;
  final bool cancelRecording;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onSend;
  final VoidCallback onMicDown;
  final ValueChanged<LongPressMoveUpdateDetails> onMicMove;
  final VoidCallback onMicUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.pureWhite,
        boxShadow: [
          BoxShadow(
              color: Color(0x14000000), blurRadius: 12, offset: Offset(0, -2)),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
          child: Row(
            children: [
              Expanded(
                child: AppTextInput(
                  controller: controller,
                  hint: recording
                      ? (cancelRecording ? '松开取消' : '松开发送')
                      : '输入想说的话…',
                  contentFontSize: 16,
                  onChanged: onChanged,
                  onSubmitted: onSubmitted,
                ),
              ),
              const SizedBox(width: 8),
              _RoundActionButton(
                icon: Icons.send_rounded,
                accent: controller.text.trim().isNotEmpty,
                onTap:
                    loading || controller.text.trim().isEmpty ? null : onSend,
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onLongPressStart: (_) => onMicDown(),
                onLongPressMoveUpdate: onMicMove,
                onLongPressEnd: (_) => onMicUp(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color:
                        recording ? AppColors.sakuraPink : AppColors.cloudGray,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    recording ? Icons.graphic_eq_rounded : Icons.mic_rounded,
                    size: 21,
                    color:
                        recording ? AppColors.starPurple : AppColors.calmBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AssemblyTray extends StatelessWidget {
  const _AssemblyTray({
    required this.expanded,
    required this.onToggleExpanded,
    required this.candidates,
    required this.assembledTokens,
    required this.onToggleToken,
    required this.onClear,
    required this.onSend,
  });

  final bool expanded;
  final VoidCallback onToggleExpanded;
  final List<String> candidates;
  final List<String> assembledTokens;
  final ValueChanged<String> onToggleToken;
  final VoidCallback onClear;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pureWhite,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.lightCloudGray),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggleExpanded,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              children: [
                const Icon(Icons.view_module_outlined,
                    size: 18, color: AppColors.starPurple),
                const SizedBox(width: 8),
                Text(
                  'CSL 词卡',
                  style: AppTextStyles.body
                      .copyWith(fontSize: 15, color: AppColors.calmBlue),
                ),
                const Spacer(),
                Text(
                  assembledTokens.isEmpty
                      ? '点选词卡拼装句子'
                      : '已选 ${assembledTokens.length} 张',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
                const SizedBox(width: 8),
                Icon(
                  expanded
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.thinCloudGray,
                ),
              ],
            ),
          ),
          if (expanded) ...[
            const SizedBox(height: 10),
            Text(
              '候选词卡',
              style: AppTextStyles.caption
                  .copyWith(fontSize: 11, color: AppColors.thinCloudGray),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final token in candidates)
                  _TrayChip(
                    label: token,
                    selected: assembledTokens.contains(token),
                    onTap: () => onToggleToken(token),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '已拼装',
              style: AppTextStyles.caption
                  .copyWith(fontSize: 11, color: AppColors.thinCloudGray),
            ),
            const SizedBox(height: 8),
            if (assembledTokens.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10),
                alignment: Alignment.centerLeft,
                child: Text(
                  '还没有选词卡',
                  style: AppTextStyles.caption.copyWith(fontSize: 11),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final token in assembledTokens)
                    _TrayChip(
                      label: token,
                      selected: true,
                      accent: true,
                      onTap: () => onToggleToken(token),
                    ),
                ],
              ),
            const SizedBox(height: 12),
            Row(
              children: [
                TextButton(onPressed: onClear, child: const Text('清空')),
                const Spacer(),
                FilledButton(
                  onPressed: assembledTokens.isEmpty ? null : onSend,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.starPurple,
                    foregroundColor: AppColors.pureWhite,
                  ),
                  child: const Text('发送拼装'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TrayChip extends StatelessWidget {
  const _TrayChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.accent = false,
  });

  final String label;
  final bool selected;
  final bool accent;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? (accent ? AppColors.paleGolden : AppColors.morningMist)
              : AppColors.cloudGray.withValues(alpha: 0.65),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.starPurple.withValues(alpha: 0.25)
                : Colors.transparent,
          ),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            fontSize: 12,
            color: selected ? AppColors.calmBlue : AppColors.thinCloudGray,
          ),
        ),
      ),
    );
  }
}

class _RoundActionButton extends StatelessWidget {
  const _RoundActionButton(
      {required this.icon, this.onTap, this.accent = false});

  final IconData icon;
  final VoidCallback? onTap;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null
          ? AppColors.lightCloudGray
          : accent
              ? AppColors.starPurple
              : AppColors.cloudGray,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: SizedBox(
          width: 52,
          height: 52,
          child: Icon(icon,
              color: accent ? AppColors.pureWhite : AppColors.calmBlue),
        ),
      ),
    );
  }
}

class _HaloAvatar extends StatelessWidget {
  const _HaloAvatar({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [AppColors.lilacPurple, AppColors.starPurple]),
            borderRadius: BorderRadius.circular(22),
          ),
          padding: const EdgeInsets.all(4),
          child: ClipOval(
            child: Image.asset(
              'assets/svg/yuyu/Yuyu_head.png',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) =>
                  const Icon(Icons.pets_rounded, color: AppColors.pureWhite),
            ),
          ),
        ),
      ),
    );
  }
}
