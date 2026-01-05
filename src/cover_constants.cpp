#include "cover_constants.h"

#include <iostream>
namespace CoverPOC {
namespace Version {
const int kInit = []() {
  std::cout << "Starting CoverPOC::Version::0.1\n";
  return 1;
}();
}  // namespace Version
}  // namespace CoverPOC
