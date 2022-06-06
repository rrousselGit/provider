// ignore_for_file: public_member_api_docs, lines_longer_than_80_chars
import 'package:example/app.dart';
import 'package:jaspr/jaspr.dart';

/// This is a reimplementation of the default Flutter application using provider + [ChangeNotifier].

void main() {
  runApp(
    /// Providers are above [MyApp] instead of inside it, so that tests
    /// can use [MyApp] while mocking the providers
    App(),
  );
}
