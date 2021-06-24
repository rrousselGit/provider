set -e # abort CI if an error happens
cd $1
flutter packages get
flutter format --set-exit-if-changed lib test
flutter analyze --no-current-package lib test/

# "flutter test" fails if there is a mix of null safe tests and legacy tests
# marked with language version comment. So, run in two batches.

# Null safe tests: without "_legacy_" in the name.
flutter test --no-pub --coverage $(ls test/*_test.dart | grep -v _legacy_)

# Legacy tests: with "_legacy_" in the name.
flutter test --no-pub --coverage --no-sound-null-safety $(ls test/*_legacy_*)


# resets to the original state
cd -
