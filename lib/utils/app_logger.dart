import 'package:logger/logger.dart';

class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0, // 不显示调用堆栈
      errorMethodCount: 5, // 错误时显示5层调用堆栈
      lineLength: 80, // 每行字符数限制
      colors: true, // 启用颜色
      printEmojis: true, // 启用表情符号
      printTime: true, // 显示时间戳
    ),
  );

  // 调试日志 - 开发时使用
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error: error, stackTrace: stackTrace);
  }

  // 信息日志 - 一般信息
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error: error, stackTrace: stackTrace);
  }

  // 警告日志 - 潜在问题
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error: error, stackTrace: stackTrace);
  }

  // 错误日志 - 错误和异常
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }

  // 致命错误日志 - 严重错误
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error: error, stackTrace: stackTrace);
  }

  // HTTP 请求专用日志方法
  static void httpRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🌐 HTTP 请求');
    buffer.writeln('方法: $method');
    buffer.writeln('URL: $url');

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('请求头:');
      headers.forEach((key, value) {
        // 隐藏敏感信息如 token
        if (key.toLowerCase().contains('authorization')) {
          buffer.writeln('  $key: ${_maskToken(value)}');
        } else {
          buffer.writeln('  $key: $value');
        }
      });
    }

    if (body != null && body.isNotEmpty) {
      buffer.writeln('请求体: $body');
    }

    _logger.i(buffer.toString());
  }

  // HTTP 响应专用日志方法
  static void httpResponse({
    required int statusCode,
    Map<String, String>? headers,
    required String body,
    int? contentLength,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('📥 HTTP 响应');
    buffer.writeln('状态码: $statusCode');

    if (contentLength != null) {
      buffer.writeln('内容长度: $contentLength字节');
    }

    if (headers != null && headers.isNotEmpty) {
      buffer.writeln('响应头: ${headers.keys.join(', ')}');
    }

    // 限制响应体日志长度，避免过长
    if (body.length > 1000) {
      buffer.writeln('响应体 (前1000字符): ${body.substring(0, 1000)}...');
    } else {
      buffer.writeln('响应体: $body');
    }

    if (statusCode >= 200 && statusCode < 300) {
      _logger.i(buffer.toString());
    } else if (statusCode >= 400) {
      _logger.e(buffer.toString());
    } else {
      _logger.w(buffer.toString());
    }
  }

  // HTTP 异常专用日志方法
  static void httpError({
    required String message,
    required dynamic error,
    StackTrace? stackTrace,
    String? url,
    String? method,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('💥 HTTP 请求异常');
    if (method != null && url != null) {
      buffer.writeln('请求: $method $url');
    }
    buffer.writeln('错误: $message');
    buffer.writeln('异常详情: $error');

    _logger.e(buffer.toString(), error: error, stackTrace: stackTrace);
  }

  // 掩码处理敏感信息
  static String _maskToken(String token) {
    if (token.isEmpty) return token;
    if (token.length <= 8) return '*' * token.length;
    return '${token.substring(0, 4)}****${token.substring(token.length - 4)}';
  }
}
