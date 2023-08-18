# Contains a path to this script, relative to the directory it was called from.
RELATIVE_PATH_TO_SCRIPT="${BASH_SOURCE[0]}"

# The directory that this script is located in.
SCRIPT_DIR=`dirname "${RELATIVE_PATH_TO_SCRIPT}"`

pushd $SCRIPT_DIR

echo "Building the extension flutter web app..."

# Build the foo_devtools_plugin flutter web app
flutter clean
rm -rf build/web

flutter pub get

# Note: for easier debugging, build in profile mode (replace --release with --profile).
flutter build web \
  --web-renderer canvaskit \
  --pwa-strategy=offline-first \
  --profile \
  --no-tree-shake-icons

# Ensure permissions are set correctly on canvaskit binaries.
chmod 0755 build/web/canvaskit/canvaskit.*

# Copy the plugin config into a temp folder so that we do not overwrite it.
mkdir _tmp
cp ../devtools/config.json _tmp/config.json

# Empty the devtools extension directory in preparation for copying in the one we just built.
rm -rf ../devtools/
mkdir ../devtools
mkdir ../devtools/build

echo "Copying the build output into the parent package extension directory ('extension/devtools/build')..."

# Copy the build output of our foo_devtools_plugin flutter web app
cp -a build/web/. ../devtools/build

mv _tmp/config.json ../devtools/config.json
rm -fr _tmp

popd