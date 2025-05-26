@echo off
"C:\\Users\\Timo\\AppData\\Local\\Android\\Sdk\\cmake\\3.22.1\\bin\\cmake.exe" ^
  "-HC:\\Users\\Timo\\Hochschule\\6. Semester\\MDMA\\Outdoor-Navigation\\lib\\src" ^
  "-DCMAKE_SYSTEM_NAME=Android" ^
  "-DCMAKE_EXPORT_COMPILE_COMMANDS=ON" ^
  "-DCMAKE_SYSTEM_VERSION=21" ^
  "-DANDROID_PLATFORM=android-21" ^
  "-DANDROID_ABI=x86" ^
  "-DCMAKE_ANDROID_ARCH_ABI=x86" ^
  "-DANDROID_NDK=C:\\Users\\Timo\\AppData\\Local\\Android\\Sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_ANDROID_NDK=C:\\Users\\Timo\\AppData\\Local\\Android\\Sdk\\ndk\\27.0.12077973" ^
  "-DCMAKE_TOOLCHAIN_FILE=C:\\Users\\Timo\\AppData\\Local\\Android\\Sdk\\ndk\\27.0.12077973\\build\\cmake\\android.toolchain.cmake" ^
  "-DCMAKE_MAKE_PROGRAM=C:\\Users\\Timo\\AppData\\Local\\Android\\Sdk\\cmake\\3.22.1\\bin\\ninja.exe" ^
  "-DCMAKE_LIBRARY_OUTPUT_DIRECTORY=C:\\Users\\Timo\\Hochschule\\6. Semester\\MDMA\\Outdoor-Navigation\\android\\build\\intermediates\\cxx\\Debug\\4t6a6h3f\\obj\\x86" ^
  "-DCMAKE_RUNTIME_OUTPUT_DIRECTORY=C:\\Users\\Timo\\Hochschule\\6. Semester\\MDMA\\Outdoor-Navigation\\android\\build\\intermediates\\cxx\\Debug\\4t6a6h3f\\obj\\x86" ^
  "-DCMAKE_BUILD_TYPE=Debug" ^
  "-BC:\\Users\\Timo\\Hochschule\\6. Semester\\MDMA\\Outdoor-Navigation\\android\\.cxx\\Debug\\4t6a6h3f\\x86" ^
  -GNinja
