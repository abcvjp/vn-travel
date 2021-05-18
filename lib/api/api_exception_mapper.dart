import "api_exception.dart";

abstract class ApiExceptionMapper {
  static String toErrorMessage(Object error) {
    if (error is ApiException) {
      if (error is ConnectionException) {
        return "connection Error";
      } else if (error is ClientErrorException) {
        return "client Error";
      } else if (error is ServerErrorException) {
        return "serverError";
      } else if (error is EmptyResultException) {
        return "emptyResultError";
      } else {
        return "unknown Error";
      }
    } else {
      return "unknown Error";
    }
  }
}
