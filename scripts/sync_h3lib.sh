# This script copies H3Lib files to ios and macos directories

rm -rf h3_flutter_plus/ios/Classes/h3lib
cp -R h3_ffi_plus/c/h3lib h3_flutter_plus/ios/Classes/h3lib

rm -rf h3_flutter_plus/macos/Classes/h3lib
cp -R h3_ffi_plus/c/h3lib h3_flutter_plus/macos/Classes/h3lib

rm -rf h3_flutter_plus/android/src/h3lib
cp -R h3_ffi_plus/c/h3lib h3_flutter_plus/android/src/h3lib

rm -rf h3_flutter_plus/windows/include/h3lib
cp -R h3_ffi_plus/c/h3lib h3_flutter_plus/windows/include/h3lib

rm -rf h3_flutter_plus/linux/include/h3lib
cp -R h3_ffi_plus/c/h3lib h3_flutter_plus/linux/include/h3lib