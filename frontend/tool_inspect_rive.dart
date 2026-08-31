import 'package:rive/rive.dart';

Future<void> main() async {
  for (final asset in ['assets/rive/yuyu.riv', 'assets/rive/yuyu.riv']) {
    final file = await RiveFile.asset(asset);
    print('FILE: $asset');
    for (final artboard in file.artboards) {
      print('  artboard: ${artboard.name}');
      print('    animations: ${artboard.animations.map((a) => a.name).toList()}');
      print('    stateMachines: ${artboard.stateMachines.map((s) => s.name).toList()}');
    }
  }
}
