cd $1
set -e # abort CI if an error happens
flutter packages get
flutter format --set-exit-if-changed lib test
flutter analyze --no-current-package lib test/
flutter test --no-pub --coverage
# resets to the original state
set +e
cd -