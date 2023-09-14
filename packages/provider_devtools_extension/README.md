# provider_devtools_extension

This is the Provider DevTools extension. The extension is implemented
as a Flutter web app and is included in `package:provider` under the
`extension/devtools` directory.

To build this extension and update the built assets in `package:provider`,
run the following command:

```sh
cd packages/provider_devtools_extension
flutter pub get &&
dart run devtools_extensions build_and_copy \
  --source=. --dest=../provider/extension/devtools
```
