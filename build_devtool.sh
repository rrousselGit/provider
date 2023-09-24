pushd packages/provider

rm -rf extension/devtools/build
mkdir extension/devtools/build

popd

pushd packages/provider_devtools_extension

flutter pub get &&
dart run devtools_extensions build_and_copy \
  --source=. \
  --dest=../provider/extension/devtools

popd
