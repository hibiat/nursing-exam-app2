class UserFriendlyErrorMessages {
  static String getErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();

    if (errorStr.contains('firebase') || errorStr.contains('network')) {
      return 'インターネット接続を確認して、もう一度お試しください';
    }
    if (errorStr.contains('permission') || errorStr.contains('auth')) {
      return 'アプリを再起動してお試しください';
    }
    if (errorStr.contains('timeout')) {
      return '読み込みに時間がかかっています。少し待ってからお試しください';
    }

    return '予期しない問題が発生しました。アプリを再起動してお試しください';
  }
}
