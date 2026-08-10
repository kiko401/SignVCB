import 'package:uuid/uuid.dart'; //第三方依赖包，专门用来生成唯一标识字符串。

class UuidGenerator {
  const UuidGenerator._();

  static const Uuid _uuid = Uuid();

  static String v4() => _uuid
      .v4(); //- v4 = 随机型 UUID, 返回类似：`550e8400‑e29b‑41d4‑a716‑446655440000` 的 36 位随机字符串
}
