#include <iostream>
#include "cover_constants.h"
namespace CoverPOC{
namespace Version {
  const int kInit = [](){
    std::cout << "Starting CoverPOC::Version::0.1\n";
    return 1;
    }();
}}
