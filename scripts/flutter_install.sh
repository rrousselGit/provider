cd ..
git clone https://github.com/flutter/flutter.git -b $1
# script shells can't export variables. Instead we print the command, and the origin shell execute the command
# https://stackoverflow.com/questions/11076350/how-do-you-export-a-variable-through-shell-script
echo "export PATH=$PATH:$PWD/flutter/bin"
echo "export PATH=$PATH:$PWD/flutter/bin/cache/dart-sdk/bin"
cd -