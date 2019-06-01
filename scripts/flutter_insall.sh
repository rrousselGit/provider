cd ..
git clone https://github.com/flutter/flutter.git -b $1
export PATH=$PATH:$PWD/flutter/bin
export PATH=$PATH:$PWD/flutter/bin/cache/dart-sdk/bin
flutter doctor
cd -