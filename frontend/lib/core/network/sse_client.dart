/*
#运行流程
1. 程序启动，Riverpod 创建全局 SseClient，传入配置齐全的 Dio
2. 聊天页面调用 sseClient.stream ()，发起流式 Post 请求
3. dio 携带请求头 Accept:text/event‑stream，关闭接收超时，建立长连接
4. 后端一小块一小块推送字节流（AI 分段文字）
5. 代码接收二进制 → 转字符串 → 拆分成单行
6. 识别 event 行、data 行；碰到空行就组装成 SseEvent，yield 推送出去
7. UI 层监听 Stream，一段一段展示文字，实现流式打字效果
8. 数据流关闭之后，输出缓存里最后一条消息

# 全部知识点清单
1. dart:convert 内置库：utf8.decode、LineSplitter 换行分割
2. Dio ResponseType.stream 开启字节流响应模式
3. SSE 协议头 Accept: text/event‑stream
4. Stream 数据流、async* 异步生成器、yield 向外产出数据
5. await‑for 循环读取流式字节块
6. SSE 协议规则：event、data、空行作为消息分隔符
7. Riverpod Provider 全局单例，依赖注入 Dio 网络工具
8. 空安全？可空类型判断
 */
import 'dart:convert'; //dart内置工具包，用来字节转字符串、utf-8解码、字符串分割

import 'package:dio/dio.dart'; //网络请求库，前面已经封装好了全局 dio
import 'package:flutter_riverpod/flutter_riverpod.dart'; //用来生成全局 SseClient 单例

import '../../features/chat/data/sse_event.dart'; //自定义 SSE 事件实体类，用来存放解析出来的 event、data 字段
import 'dio_client.dart'; //封装好的 dioProvider 网络工具

//专门用来处理服务端流式推送请求的工具类
class SseClient {
  //构造函数，接收外部传进来已经配置完毕的 Dio 实例（自带拦截器、Token 自动携带、异常处理）
  SseClient(this._dio);
  //私有成员变量，整个类内部共用这一份网络请求对象
  final Dio _dio;

  //最核心：stream () 流式请求方法,返回值 Stream<SseEvent>
  Stream<SseEvent> stream(
    //Stream = Dart 里面的数据流管道，可以源源不断往外吐出一条一条 SseEvent 事件
    String path, {
    Object? data,
    Map<String, dynamic>? queryParameters,
  }) async* {
    //带星号的异步函数，生成器函数，可以使用 `yield` 往外吐出数据。普通 async 搭配 await；async* 搭配 yield。
    final response = await _dio.post<ResponseBody>(
      //入参,普通接口返回 json；SSE 需要返回原始字节流，所以接收类型设置为 ResponseBody
      path, //后端SSE接口地址，例如 `/api/chat/stream`
      data: data, //post 请求需要提交的请求体参数
      queryParameters: queryParameters, //url 后面拼接的 get 查询参数
      options: Options(
        responseType:
            ResponseType.stream, //告诉 dio，不要一次性接收完整响应，开启字节流模式，一块一块接收后端发来的数据
        headers: const {
          'Accept': 'text/event-stream'
        }, //标准 SSE 协议头，告知后端我要开启 SSE 长连接推送
        receiveTimeout: Duration
            .zero, //**关闭接收超时**普通接口 15 秒超时断开；SSE 长连接会一直挂着，超时时间必须设置为 0，不会自动断掉
      ),
    );

    final responseBody = response.data; //后端返回的字节数据流；
    if (responseBody == null) return; //数据流为空，直接结束函数。

    String? currentEvent;
    String? currentData;

//行分割器，SSE 协议规定每一条消息都是多行文本，event: 开头的行表示事件类型，data: 开头的行表示事件数据，空行表示一条消息结束
    const splitter =
        LineSplitter(); //`LineSplitter()` 来自 `dart:convert`，专门用来把一大段文本，按照换行符 `\n` 切割成一行一行字符串。
    /*
    `await‑for` 专门用来循环读取 Stream 数据流 
    后端每次推送一块二进制字节 chunk，代码就循环执行一次。
   */
    await for (final chunk in responseBody.stream) {
      final text = utf8.decode(chunk); //二进制字节 → UTF‑8 格式字符串
      for (final line in splitter.convert(text)) {
        //把整块字符串拆分成单独一行，逐行解析
        if (line.startsWith('event:')) {
          //如果一行开头是 `event:`，存进临时变量 currentEvent
          currentEvent = line;
        } else if (line.startsWith('data:')) {
          //如果一行开头是 `data:`，存进临时变量 currentData
          currentData = line;
        } else if (line.isEmpty &&
            (currentEvent != null || currentData != null)) {
          //读到**空行** = 当前这一条 SSE 消息读取完毕
          yield SseEvent.fromRaw(currentEvent,
              currentData); //async * 生成器专属关键字，向外吐出一条解析完成的 SseEvent 事件
          currentEvent = null; //清空缓存，准备接收下一条事件
          currentData = null; //yield ≈ stream 版本的 return，可以不停往外输出多条数据
        }
      }
    }

    if (currentEvent != null || currentData != null) {
      //循环读完数据流之后，把缓存剩下的数据也输出出去，防止丢失最后一条消息。
      yield SseEvent.fromRaw(currentEvent, currentData);
    }
  }
}

final sseClientProvider = Provider<SseClient>((ref) {
  //利用 Riverpod 创建全局唯一的 SseClient 对象
  return SseClient(ref.watch(dioProvider)); //拿到我们前面封装好的全局 Dio 实例
}); //整个项目所有聊天页面共用同一个 SSE 客户端，自动继承 dio 全部拦截器配置（Token、请求 ID、异常捕获）
