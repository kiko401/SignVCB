import 'package:flutter/material.dart';
import 'package:rive/rive.dart';

class YuyuAvatar extends StatefulWidget {
  const YuyuAvatar({
    super.key,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.alignment = Alignment.center,
    this.animationName,
    this.stateMachineName,
    this.antlerStage = 0,
    this.assetPath = 'assets/rive/yuyu.riv',
    this.artboardName = 'yuyu_main',
  }) : assert(animationName != null || stateMachineName != null);

  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;
  final String? animationName;
  final String? stateMachineName;
  final int antlerStage;
  final String assetPath;
  final String artboardName;

  @override
  State<YuyuAvatar> createState() => _YuyuAvatarState();
}

class _YuyuAvatarState extends State<YuyuAvatar> {
  SMINumber? _antlerStageInput;

  @override
  void didUpdateWidget(covariant YuyuAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.antlerStage != oldWidget.antlerStage) {
      _applyAntlerStage();
    }
  }

  void _onInit(Artboard artboard) {
    final stateMachineName = widget.stateMachineName;
    if (stateMachineName == null) return;

    final controller =
        StateMachineController.fromArtboard(artboard, stateMachineName);
    if (controller == null) return;

    artboard.addController(controller);
    _antlerStageInput = controller.getNumberInput('AntlerStage');
    _applyAntlerStage();
  }

  void _applyAntlerStage() {
    _antlerStageInput?.value = widget.antlerStage.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final useStateMachine = widget.stateMachineName != null;

    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: RiveAnimation.asset(
        widget.assetPath,
        artboard: widget.artboardName,
        animations: useStateMachine || widget.animationName == null
            ? const []
            : [widget.animationName!],
        onInit: useStateMachine ? _onInit : null,
        fit: widget.fit,
        alignment: widget.alignment,
      ),
    );
  }
}
