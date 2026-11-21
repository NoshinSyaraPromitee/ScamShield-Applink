import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
import 'package:scamshield/core/router/routes.dart';

/// Long-press an SMS > Share > ScamShield opens the check screen with the text filled in.
void useShareIntent(GoRouter router) {
  useEffect(() {
    void handle(List<SharedMediaFile> files) {
      final text = files
          .where((f) => f.type == SharedMediaType.text || f.type == SharedMediaType.url)
          .map((f) => f.path)
          .join('\n')
          .trim();
      if (text.isNotEmpty) router.push(Routes.scan, extra: text);
    }

    final subscription = ReceiveSharingIntent.instance.getMediaStream().listen(handle);
    ReceiveSharingIntent.instance.getInitialMedia().then((files) {
      handle(files);
      ReceiveSharingIntent.instance.reset();
    });
    return subscription.cancel;
  }, const []);
}