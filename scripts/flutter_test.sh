set -e # abort CI if an error happens
cd $1
flutter packages get
flutter format --set-exit-if-changed lib test
flutter analyze --no-current-package lib test/
flutter test --no-pub --coverage $(ls test/*_test.dart | grep -v _legacy_)
flutter test --no-pub --coverage --no-sound-null-safety $(ls test/*_legacy_test.dart)
# resets to the original state
cd -
