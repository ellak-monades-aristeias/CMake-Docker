# CMAKE generated file: DO NOT EDIT!
# Generated by "Unix Makefiles" Generator, CMake Version 3.3

# Delete rule output on recipe failure.
.DELETE_ON_ERROR:


#=============================================================================
# Special targets provided by cmake.

# Disable implicit rules so canonical targets will work.
.SUFFIXES:


# Remove some rules from gmake that .SUFFIXES does not remove.
SUFFIXES =

.SUFFIXES: .hpux_make_needs_suffix_list


# Suppress display of executed commands.
$(VERBOSE).SILENT:


# A target that is always out of date.
cmake_force:

.PHONY : cmake_force

#=============================================================================
# Set environment variables for the build.

# The shell in which to execute make rules.
SHELL = /bin/sh

# The CMake executable.
CMAKE_COMMAND = /home/aris/source/cpp/CMake-Docker/build/bin/cmake

# The command to remove a file.
RM = /home/aris/source/cpp/CMake-Docker/build/bin/cmake -E remove -f

# Escaping for special characters.
EQUALS = =

# The top-level source directory on which CMake was run.
CMAKE_SOURCE_DIR = /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate

# The top-level build directory on which CMake was run.
CMAKE_BINARY_DIR = /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build

# Include any dependencies generated for this target.
include CMakeFiles/mylibapp2.dir/depend.make

# Include the progress variables for this target.
include CMakeFiles/mylibapp2.dir/progress.make

# Include the compile flags for this target's objects.
include CMakeFiles/mylibapp2.dir/flags.make

CMakeFiles/mylibapp2.dir/mylibapp.cpp.o: CMakeFiles/mylibapp2.dir/flags.make
CMakeFiles/mylibapp2.dir/mylibapp.cpp.o: ../mylibapp.cpp
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --progress-dir=/home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_1) "Building CXX object CMakeFiles/mylibapp2.dir/mylibapp.cpp.o"
	/usr/bin/c++   $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -o CMakeFiles/mylibapp2.dir/mylibapp.cpp.o -c /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/mylibapp.cpp

CMakeFiles/mylibapp2.dir/mylibapp.cpp.i: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Preprocessing CXX source to CMakeFiles/mylibapp2.dir/mylibapp.cpp.i"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -E /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/mylibapp.cpp > CMakeFiles/mylibapp2.dir/mylibapp.cpp.i

CMakeFiles/mylibapp2.dir/mylibapp.cpp.s: cmake_force
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green "Compiling CXX source to assembly CMakeFiles/mylibapp2.dir/mylibapp.cpp.s"
	/usr/bin/c++  $(CXX_DEFINES) $(CXX_INCLUDES) $(CXX_FLAGS) -S /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/mylibapp.cpp -o CMakeFiles/mylibapp2.dir/mylibapp.cpp.s

CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.requires:

.PHONY : CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.requires

CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.provides: CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.requires
	$(MAKE) -f CMakeFiles/mylibapp2.dir/build.make CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.provides.build
.PHONY : CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.provides

CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.provides.build: CMakeFiles/mylibapp2.dir/mylibapp.cpp.o


# Object files for target mylibapp2
mylibapp2_OBJECTS = \
"CMakeFiles/mylibapp2.dir/mylibapp.cpp.o"

# External object files for target mylibapp2
mylibapp2_EXTERNAL_OBJECTS =

mylibapp2: CMakeFiles/mylibapp2.dir/mylibapp.cpp.o
mylibapp2: CMakeFiles/mylibapp2.dir/build.make
mylibapp2: libmylib.a
mylibapp2: CMakeFiles/mylibapp2.dir/link.txt
	@$(CMAKE_COMMAND) -E cmake_echo_color --switch=$(COLOR) --green --bold --progress-dir=/home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build/CMakeFiles --progress-num=$(CMAKE_PROGRESS_2) "Linking CXX executable mylibapp2"
	$(CMAKE_COMMAND) -E cmake_link_script CMakeFiles/mylibapp2.dir/link.txt --verbose=$(VERBOSE)

# Rule to build all files generated by this target.
CMakeFiles/mylibapp2.dir/build: mylibapp2

.PHONY : CMakeFiles/mylibapp2.dir/build

CMakeFiles/mylibapp2.dir/requires: CMakeFiles/mylibapp2.dir/mylibapp.cpp.o.requires

.PHONY : CMakeFiles/mylibapp2.dir/requires

CMakeFiles/mylibapp2.dir/clean:
	$(CMAKE_COMMAND) -P CMakeFiles/mylibapp2.dir/cmake_clean.cmake
.PHONY : CMakeFiles/mylibapp2.dir/clean

CMakeFiles/mylibapp2.dir/depend:
	cd /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build && $(CMAKE_COMMAND) -E cmake_depends "Unix Makefiles" /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build /home/aris/source/cpp/CMake-Docker/Tests/CMakeDockerCreate/build/CMakeFiles/mylibapp2.dir/DependInfo.cmake --color=$(COLOR)
.PHONY : CMakeFiles/mylibapp2.dir/depend

