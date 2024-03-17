import 'package:flutter_test/flutter_test.dart';
import 'package:provider/src/shared_instance.dart';

void main() {
  group('SharedInstance', () {

    tearDown(SharedInstance.disposeAll);

    test('acquire creates a new instance if it does not exist', () {
      final instance = SharedInstance.acquire(
        createValue: () => 1,
        acquirer: Object(),
        instanceKey: 'instanceKey',
      );

      expect(instance.value, equals(1));
    });

    test('acquire returns an existing instance if it exists', () {
      final acquirer = Object();
      final instance1 = SharedInstance.acquire(
        createValue: () => 1,
        acquirer: acquirer,
        instanceKey: 'instanceKey',
      );

      final instance2 = SharedInstance.acquire(
        createValue: () => 2,
        acquirer: acquirer,
        instanceKey: 'instanceKey',
      );

      expect(instance1, equals(instance2));
    });

    test('release removes the instance if it is no longer used', () {
      final acquirer = Object();
      final instance = SharedInstance.acquire(
        createValue: () => 1,
        acquirer: acquirer,
        instanceKey: 'instanceKey',
      );

      final isRemoved = instance.release(acquirer);

      expect(isRemoved, isTrue);
    });

    test('release does not remove the instance if it is still used', () {
      final acquirer1 = Object();
      final acquirer2 = Object();
      final instance = SharedInstance.acquire(
        createValue: () => 1,
        acquirer: acquirer1,
        instanceKey: 'instanceKey',
      );
      SharedInstance.acquire(
        createValue: () => 1,
        acquirer: acquirer2,
        instanceKey: 'instanceKey',
      );

      final isRemoved = instance.release(acquirer1);

      expect(isRemoved, isFalse);
    });
  });
}
