enum ApiErrorCode {
  authInvalid, //登录失败
  rateLimited, //请求过于频繁
  engineTimeout, //引擎超时
  engineUnavailable, //引擎不可用
  asrFailed, //语音识别失败
  validationError, //参数验证错误
  internalError, //内部错误
  unknown, //未知错误
}
