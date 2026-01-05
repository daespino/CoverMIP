// This is an example
#include <cstdlib>
#include <format>
#include <iostream>

#include "cover_constants.h"
#include "gurobi_c.h"

using namespace CoverPOC;

int main(int argc, char** argv) {
  (void)argc;
  (void)argv;
  std::cout << std::format("kInit={}\n", Version::kInit);
  std::cout << std::format(
    "Linked gurobi {}.{}.{}\n", GRB_VERSION_MAJOR, GRB_VERSION_MINOR,
    GRB_VERSION_TECHNICAL);
  return EXIT_SUCCESS;
}
