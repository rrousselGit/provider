import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:test/test.dart';

// Import your files

// Create a mock class for the observer
class MockChangeNotifierObserver extends Mock
    implements ChangeNotifierObserver {}

void main() {
  group('BaseNotifier Tests', () {
    late MockChangeNotifierObserver mockObserver;
    late BaseNotifier baseNotifier;

    setUp(() {
      // Initialize the mock observer and base notifier before each test
      mockObserver = MockChangeNotifierObserver();
      baseNotifier = BaseNotifier(mockObserver, 'testProvider');
    });

    test('onCreate should be called when BaseNotifier is created', () {
      // Verify if the onCreate method of the observer was called with the correct provider name
      verify(mockObserver.onCreate('testProvider')).called(1);
    });

    test('onChange should be called when updateState is called', () {
      // Update the state and verify if onChange is called
      baseNotifier.updateState('newState');

      // Verify that the onChange method of the observer is called with the correct provider and new state
      verify(mockObserver.onChange('testProvider', 'newState')).called(1);
    });

    test('dispose should call onDispose when BaseNotifier is disposed', () {
      // Dispose of the notifier and verify if onDispose is called
      baseNotifier.dispose();

      verify(mockObserver.onDispose('testProvider')).called(1);
    });

    test('updateState should notify listeners after state change', () {
      // Mock the notifyListeners method to track if it's called
      final listenerCalled = <void Function()>[];
      baseNotifier.addListener(() {
        listenerCalled.add(() {});
      });

      // Update the state and check if listeners are notified
      baseNotifier.updateState('newState');
      expect(listenerCalled, isNotEmpty);
    });

    test('updateState should throw error if observer throws exception', () {
      // Make observer's onChange method throw an exception
      when(mockObserver.onChange('testProvider', 'newState'))
          .thenThrow(Exception('Observer error'));

      // Verify that updateState throws the same exception
      expect(() => baseNotifier.updateState('newState'), throwsException);
    });
  });
}
