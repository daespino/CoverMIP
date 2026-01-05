#/bin/sh

(
  mkdir -p build/Debug;
  cd build/Debug;
  cmake ../.. -DCMAKE_BUILD_TYPE=Debug ; cmake --build . --config Debug -j 16 "$@"
)
