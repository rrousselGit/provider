import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'common.dart';
import 'inherited_provider_test.dart';

void main() {
  testWidgets("scoped widgets can't be read with Provider.of", (tester) async {
    final scope = Object();

    await tester.pumpWidget(
      Provider<int>(
        create: (_) => 42,
        scope: scope,
        child: Context(),
      ),
    );

    expect(
      // ignore: unnecessary_lambdas
      () => of<int>(), throwsProviderNotFound<int>(),
    );

    expect(Provider.of<int>(context, scope: scope), equals(42));
  });
  testWidgets('one scope can be associated to multiple values', (tester) async {
    final scope = Object();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>(create: (_) => 42, scope: scope),
          Provider<String>(create: (_) => '42', scope: scope),
        ],
        child: Context(),
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(42));
    expect(Provider.of<String>(context, scope: scope), equals('42'));
  });
  testWidgets('nested providers with different scopes', (tester) async {
    final scope = Object();
    final scope2 = Object();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>(create: (_) => 42, scope: scope),
          Provider<int>(create: (_) => 24, scope: scope2),
          Provider<int>(create: (_) => 0),
        ],
        child: Context(),
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(42));
    expect(Provider.of<int>(context, scope: scope2), equals(24));
    expect(Provider.of<int>(context), equals(0));
  });
  testWidgets('Moving with GlobalKey recompute scope', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      Provider<int>(
        key: key,
        create: (_) => 42,
        scope: key,
        child: Context(),
      ),
    );

    expect(Provider.of<int>(context, scope: key), equals(42));
    expect(
      // ignore: unnecessary_lambdas
      () => of<String>(), throwsProviderNotFound<String>(),
    );

    await tester.pumpWidget(
      Provider<String>(
        create: (_) => '42',
        scope: key,
        child: Provider<int>(
          key: key,
          create: (_) => 42,
          scope: key,
          child: Context(),
        ),
      ),
    );

    expect(Provider.of<int>(context, scope: key), equals(42));
    expect(Provider.of<String>(context, scope: key), equals('42'));
  });
  testWidgets('MultiProvider with GlobalKey recompute scope', (tester) async {
    final key = GlobalKey();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>(
            key: key,
            create: (_) => 42,
            scope: key,
          ),
        ],
        child: Context(),
      ),
    );

    expect(Provider.of<int>(context, scope: key), equals(42));
    expect(
      // ignore: unnecessary_lambdas
      () => of<String>(), throwsProviderNotFound<String>(),
    );

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<String>(
            create: (_) => '42',
            scope: key,
          ),
          Provider<int>(
            key: key,
            create: (_) => 42,
            scope: key,
          ),
        ],
        child: Context(),
      ),
    );

    expect(Provider.of<int>(context, scope: key), equals(42));
    expect(Provider.of<String>(context, scope: key), equals('42'));
  });
  testWidgets('correctly rebuilds dependents', (tester) async {
    final scope = Object();
    final scope2 = Object();

    final thirdChild = BuildCount((context) {
      Provider.of<int>(context);
      return Context();
    });
    final secondChild = BuildCount((context) {
      Provider.of<int>(context, scope: scope2);
      return thirdChild;
    });
    final firstChild = BuildCount((context) {
      Provider.of<int>(context, scope: scope);
      return secondChild;
    });

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>.value(value: 42, scope: scope),
          Provider<int>.value(value: 24, scope: scope2),
          Provider<int>.value(value: 0),
        ],
        child: firstChild,
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(42));
    expect(Provider.of<int>(context, scope: scope2), equals(24));
    expect(Provider.of<int>(context), equals(0));

    expect(buildCountOf(firstChild), equals(1));
    expect(buildCountOf(secondChild), equals(1));
    expect(buildCountOf(thirdChild), equals(1));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>.value(value: 420, scope: scope),
          Provider<int>.value(value: 24, scope: scope2),
          Provider<int>.value(value: 0),
        ],
        child: firstChild,
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(420));
    expect(Provider.of<int>(context, scope: scope2), equals(24));
    expect(Provider.of<int>(context), equals(0));

    expect(buildCountOf(firstChild), equals(2));
    expect(buildCountOf(secondChild), equals(1));
    expect(buildCountOf(thirdChild), equals(1));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>.value(value: 420, scope: scope),
          Provider<int>.value(value: 240, scope: scope2),
          Provider<int>.value(value: 0),
        ],
        child: firstChild,
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(420));
    expect(Provider.of<int>(context, scope: scope2), equals(240));
    expect(Provider.of<int>(context), equals(0));

    expect(buildCountOf(firstChild), equals(2));
    expect(buildCountOf(secondChild), equals(2));
    expect(buildCountOf(thirdChild), equals(1));

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<int>.value(value: 420, scope: scope),
          Provider<int>.value(value: 240, scope: scope2),
          Provider<int>.value(value: 10),
        ],
        child: firstChild,
      ),
    );

    expect(Provider.of<int>(context, scope: scope), equals(420));
    expect(Provider.of<int>(context, scope: scope2), equals(240));
    expect(Provider.of<int>(context), equals(10));

    expect(buildCountOf(firstChild), equals(2));
    expect(buildCountOf(secondChild), equals(2));
    expect(buildCountOf(thirdChild), equals(2));
  });

  testWidgets('Scope() not found', (tester) async {
    await tester.pumpWidget(Context());

    expect(
      () => Provider.of<int>(context, scope: 42),
      throwsProviderNotFound<int>(),
    );
  });
  testWidgets('Scope() found but not the `scope` parameter', (tester) async {
    await tester.pumpWidget(
      Provider(
        scope: 'someScope',
        create: (_) => 42,
        child: Context(),
      ),
    );

    expect(
      () => Provider.of<int>(context, scope: 'anotherScope'),
      throwsProviderNotFound<int>(),
    );
  });
  testWidgets('Scope() and `scope` found, but not T', (tester) async {
    await tester.pumpWidget(
      Provider(
        scope: 'someScope',
        create: (_) => 42,
        child: Context(),
      ),
    );

    expect(
      () => Provider.of<String>(context, scope: 'someScope'),
      throwsProviderNotFound<String>(),
    );
  });
}
