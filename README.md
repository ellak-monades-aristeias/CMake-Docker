# Docker Integration in CMake/CPack
[![License](http://img.shields.io/badge/License-CC BY--SA 4.0-blue.svg)](https://github.com/ellak-monades-aristeias/CMake-Docker/blob/cpack-docker/LICENSE.md)

## Introduction

[CMake](http://www.cmake.org/) is the most popular open source build tool. It provides the ability to compile source code in a common way on different operating systems, linking dependencies and libraries in an agnostic way to the system and the compiler. Its widespread in the open source community is anything but random/lucky, as it has provided the developers with the ability to address the growing software unified across all platforms (POSIX-compliant, Windows, and OSX). Through modules, CMake provides usability that exceeds the limits of a simple build tool, such as project packaging ([CPack](http://www.cmake.org/Wiki/CMake:Packaging_With_CPack)), easy unit testing, code quality and coverage tools, etc.

[Docker](https://www.docker.com/) allows you to package an application with all of its dependencies into a standardized unit for software development. Docker containers wrap up a piece of software in a complete filesystem that contains everything it needs to run: code, runtime, system tools, system libraries – anything you can install on a server. This guarantees that it will always run the same, regardless of the environment it is running in. At first sight, Docker appears to have many similarities with Virtual Machines, but internally works completely different and does not have many of the disadvantages they have. So far, Docker has been successfully applied in horizontal scaling systems and cloud services. Also, Continuous Integration and Continuous Deployment services have begun to use Docker in place of Virtual Machines.

## Featured Project

[CPack](http://www.cmake.org/Wiki/CMake:Packaging_With_CPack) is one of CMake's modules, that can also work independently, and provides automatic project packaging capabilities in several different package templates. Until this day, CPack provides packaging capabilities for deb packages (debian-based systems), rpm packages (redhat-based systems), simple zip/tar/gz/bz compressed packages and setup files for Windows/OSX. Goal of this project is the integration of Docker in CMake and CPack, initially as new packaging method, and then as a method to change the workflow of the programmer.

* Docker integration in CPack for instant project packaging.
* Docker integration in CMake for project compiling and checking.
	* Automated compilation in different versions and different distributions.
	* Proper project dependencies check.
	* Automated native package building with proper dependencies checking and linking without the need of virtual machines.
	* Easy horizontal scaling and installation on multiple systems.

### Timetable

| Dates     	| Duration | Description 																		                            |
|---------------|----------|----------------------------------------------------------------------------------------------------------------|
| 24/08 - 28/08 | 1 Week   | Feedback from CMake developers community - collecting information regarding usability and development method.  |
| 31/08 - 11/09 | 2 Weeks  | Development of CPack Module.																					|
| 14/09 - 02/10 | 3 Weeks  | Development of CMake Module.											 										|
| 05/09 - 09/10 | 1 Week   | Code checking and Unit Testing.																				| 
| 12/10 - 15/10 | 1 Week   | Documentation and Tutorials.																					| 

### Deliverables

| Deliverable Title 											| Url 						|
|---------------------------------------------------------------|---------------------------|
| Technical report with the answers of developers and work plan.| [google form](https://docs.google.com/forms/d/1zbpWB7Z7Qf7geovARlJWcFFZwVYub9BgpjvQGsdJK38/viewanalytics), [github wiki](https://github.com/ellak-monades-aristeias/CMake-Docker/wiki/Questionnaire-Results) |
| CPack Software Module.										| [cmCPackDockerGenerator.cxx](https://github.com/ellak-monades-aristeias/CMake-Docker/blob/cpack-docker/Source/CPack/cmCPackDockerGenerator.cxx), [cmCPackDockerGenerator.h](https://github.com/ellak-monades-aristeias/CMake-Docker/blob/cpack-docker/Source/CPack/cmCPackDockerGenerator.h), [CPackDocker.cmake](https://github.com/ellak-monades-aristeias/CMake-Docker/blob/cpack-docker/Modules/CPackDocker.cmake) |
| CMake Software Module.										| [CMakeDocker.cmake](https://github.com/ellak-monades-aristeias/CMake-Docker/blob/cpack-docker/Modules/CMakeDocker.cmake)|
| Documentation/tutorials with code samples.					| [CPackComponentsDOCKER](https://github.com/ellak-monades-aristeias/CMake-Docker/tree/cpack-docker/Tests/CPackComponentsDOCKER), [CMakeDockerCreate](https://github.com/ellak-monades-aristeias/CMake-Docker/tree/cpack-docker/Tests/CMakeDockerCreate), [CMakeDockerBuild](https://github.com/ellak-monades-aristeias/CMake-Docker/tree/cpack-docker/Tests/CMakeDockerBuild) |

## Usability

This project is expected to have great usability in the field of software development. It should significantly influence the community of software maintainers (Package Maintainers) and the software development community (Software Developers). Specifically small development teams will be able to provide packages for all distributions and operating systems easily and to test their software without having to maintain many virtual systems.

## Promotion

The initial promotion step will be contacting the developers of CMake and other big programming communities. Then the project will spread to the open source community through the integration in the official program (either as a standalone plugin or officially supported), and also through documentation and tutorials with code snippets allowing quick learning and easy usage.