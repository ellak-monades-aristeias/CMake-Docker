/*============================================================================
  CMake - Cross Platform Makefile Generator
  Copyright 2000-2009 Kitware, Inc., Insight Software Consortium

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/
#include "cmCPackDockerGenerator.h"

#include "cmSystemTools.h"
#include "cmMakefile.h"
#include "cmGeneratedFileStream.h"
#include "cmCPackLog.h"

#include <cmsys/SystemTools.hxx>
#include <cmsys/Glob.hxx>

#include <limits.h> // USHRT_MAX
#include <algorithm> // std::sort
#include <sys/stat.h>

//----------------------------------------------------------------------
cmCPackDockerGenerator::cmCPackDockerGenerator()
{
}

//----------------------------------------------------------------------
cmCPackDockerGenerator::~cmCPackDockerGenerator()
{
}

//----------------------------------------------------------------------
int cmCPackDockerGenerator::InitializeInternal()
{
  this->SetOptionIfNotSet("CPACK_PACKAGING_INSTALL_PREFIX", "/usr");
  if (cmSystemTools::IsOff(this->GetOption("CPACK_SET_DESTDIR")))
  {
    this->SetOption("CPACK_SET_DESTDIR", "I_ON");
  }
  return this->Superclass::InitializeInternal();
}

//----------------------------------------------------------------------
int cmCPackDockerGenerator::PackageOnePack(std::string initialTopLevel,
                                           std::string packageName)
{
  cmCPackLogger(cmCPackLog::LOG_OUTPUT, "- Running OnePack" << std::endl);
  int retval = 1;
  // Begin the archive for this pack
  std::string localToplevel(initialTopLevel);
  std::string packageFileName(
        cmSystemTools::GetParentDirectory(toplevel)
        );
  std::string outputFileName(
        std::string(this->GetOption("CPACK_PACKAGE_FILE_NAME"))
        +"-"+packageName + this->GetOutputExtension()
        );

  localToplevel += "/"+ packageName;
  /* replace the TEMP DIRECTORY with the component one */
  this->SetOption("CPACK_TEMPORARY_DIRECTORY",localToplevel.c_str());
  packageFileName += "/"+ outputFileName;
  /* replace proposed CPACK_OUTPUT_FILE_NAME */
  this->SetOption("CPACK_OUTPUT_FILE_NAME",outputFileName.c_str());
  /* replace the TEMPORARY package file name */
  this->SetOption("CPACK_TEMPORARY_PACKAGE_FILE_NAME",
                  packageFileName.c_str());
  // Tell CPackDocker.cmake the name of the component GROUP.
  this->SetOption("CPACK_DOCKER_PACKAGE_COMPONENT",packageName.c_str());
  // Tell CPackDocker.cmake the path where the component is.
  std::string component_path = "/";
  component_path += packageName;
  this->SetOption("CPACK_DOCKER_PACKAGE_COMPONENT_PART_PATH",
                  component_path.c_str());
  if (!this->ReadListFile("CPackDocker.cmake"))
  {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Error while execution CPackDocker.cmake" << std::endl);
    retval = 0;
    return retval;
  }

  cmsys::Glob gl;
  std::string findExpr(this->GetOption("GEN_WDIR"));
  findExpr += "/*";
  gl.RecurseOn();
  if ( !gl.FindFiles(findExpr) )
  {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Cannot find any files in the installed directory" << std::endl);
    return 0;
  }
  packageFiles = gl.GetFiles();

  int res = createDocker();
  if (res != 1)
  {
    retval = 0;
  }
  // add the generated package to package file names list
  packageFileNames.push_back(packageFileName);
  return retval;
}

//----------------------------------------------------------------------
int cmCPackDockerGenerator::PackageComponents(bool ignoreGroup)
{
  cmCPackLogger(cmCPackLog::LOG_OUTPUT, "- Running Components" << std::endl);
  int retval = 1;
  /* Reset package file name list it will be populated during the
   * component packaging run*/
  packageFileNames.clear();
  std::string initialTopLevel(this->GetOption("CPACK_TEMPORARY_DIRECTORY"));

  // The default behavior is to have one package by component group
  // unless CPACK_COMPONENTS_IGNORE_GROUP is specified.
  if (!ignoreGroup)
  {
    std::map<std::string, cmCPackComponentGroup>::iterator compGIt;
    for (compGIt=this->ComponentGroups.begin();
         compGIt!=this->ComponentGroups.end(); ++compGIt)
    {
      cmCPackLogger(cmCPackLog::LOG_VERBOSE, "Packaging component group: "
                    << compGIt->first
                    << std::endl);
      // Begin the archive for this group
      retval &= PackageOnePack(initialTopLevel,compGIt->first);
    }
    // Handle Orphan components (components not belonging to any groups)
    std::map<std::string, cmCPackComponent>::iterator compIt;
    for (compIt=this->Components.begin();
         compIt!=this->Components.end(); ++compIt )
    {
      // Does the component belong to a group?
      if (compIt->second.Group==NULL)
      {
        cmCPackLogger(cmCPackLog::LOG_VERBOSE,
                      "Component <"
                      << compIt->second.Name
                      << "> does not belong to any group, package it separately."
                      << std::endl);
        // Begin the archive for this orphan component
        retval &= PackageOnePack(initialTopLevel,compIt->first);
      }
    }
  }
  // CPACK_COMPONENTS_IGNORE_GROUPS is set
  // We build 1 package per component
  else
  {
    std::map<std::string, cmCPackComponent>::iterator compIt;
    for (compIt=this->Components.begin();
         compIt!=this->Components.end(); ++compIt )
    {
      retval &= PackageOnePack(initialTopLevel,compIt->first);
    }
  }
  return retval;
}

//----------------------------------------------------------------------
int cmCPackDockerGenerator::PackageComponentsAllInOne()
{
  cmCPackLogger(cmCPackLog::LOG_OUTPUT, "- Running AllInOne" << std::endl);
  int retval = 1;
  std::string compInstDirName;
  /* Reset package file name list it will be populated during the
   * component packaging run*/
  packageFileNames.clear();
  std::string initialTopLevel(this->GetOption("CPACK_TEMPORARY_DIRECTORY"));

  compInstDirName = "ALL_COMPONENTS_IN_ONE";

  cmCPackLogger(cmCPackLog::LOG_VERBOSE,
                "Packaging all groups in one package..."
                "(CPACK_COMPONENTS_ALL_[GROUPS_]IN_ONE_PACKAGE is set)"
                << std::endl);

  // The ALL GROUPS in ONE package case
  std::string localToplevel(initialTopLevel);
  std::string packageFileName(
        cmSystemTools::GetParentDirectory(toplevel)
        );
  std::string outputFileName(
        std::string(this->GetOption("CPACK_PACKAGE_FILE_NAME"))
        + this->GetOutputExtension()
        );
  // all GROUP in one vs all COMPONENT in one
  localToplevel += "/"+compInstDirName;

  /* replace the TEMP DIRECTORY with the component one */
  this->SetOption("CPACK_TEMPORARY_DIRECTORY",localToplevel.c_str());
  packageFileName += "/"+ outputFileName;
  /* replace proposed CPACK_OUTPUT_FILE_NAME */
  this->SetOption("CPACK_OUTPUT_FILE_NAME",outputFileName.c_str());
  /* replace the TEMPORARY package file name */
  this->SetOption("CPACK_TEMPORARY_PACKAGE_FILE_NAME",
                  packageFileName.c_str());
  // Tell CPackDocker.cmake the path where the component is.
  std::string component_path = "/";
  component_path += compInstDirName;
  this->SetOption("CPACK_DOCKER_PACKAGE_COMPONENT_PART_PATH",
                  component_path.c_str());
  if (!this->ReadListFile("CPackDocker.cmake"))
  {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Error while execution CPackDocker.cmake" << std::endl);
    retval = 0;
    return retval;
  }

  cmsys::Glob gl;
  std::string findExpr(this->GetOption("GEN_WDIR"));
  findExpr += "/*";
  gl.RecurseOn();
  if ( !gl.FindFiles(findExpr) )
  {
    cmCPackLogger(cmCPackLog::LOG_ERROR,
                  "Cannot find any files in the installed directory" << std::endl);
    return 0;
  }
  packageFiles = gl.GetFiles();

  int res = createDocker();
  if (res != 1)
  {
    retval = 0;
  }
  // add the generated package to package file names list
  packageFileNames.push_back(packageFileName);
  return retval;
}

//----------------------------------------------------------------------
int cmCPackDockerGenerator::PackageFiles()
{
  cmCPackLogger(cmCPackLog::LOG_OUTPUT, "- Running Package Files" << std::endl);
  int retval = -1;
  std::string prefix = this->GetOption("CPACK_OUTPUT_FILE_PREFIX");
  prefix += "/";
  prefix += this->GetOption("CPACK_OUTPUT_FILE_NAME");
  this->SetOption("CPACK_OUTPUT_FILE_PREFIX", prefix.c_str());
  if (!this->ReadListFile("CPackDocker.cmake")) {
    cmCPackLogger(cmCPackLog::LOG_ERROR, "Error while parsing CPackDocker.cmake" << std::endl);
    retval = 0;
  }
  else {
    return createDocker();
  }
  return retval;
}

int cmCPackDockerGenerator::createDocker()
{
  std::string dockerfilename;
  dockerfilename = this->GetOption("CPACK_TOPLEVEL_DIRECTORY");
  dockerfilename += "/Dockerfile";
  packageFileNames.clear();
  packageFileNames.push_back(dockerfilename);

  const char* docker_base_image =
      this->GetOption("GEN_CPACK_DOCKER_FROM");
  const char* maintainer =
      this->GetOption("GEN_CPACK_DOCKER_MAINTAINER");
  std::string packagemanager = this->getPackageManager();
  cmCPackLogger(cmCPackLog::LOG_DEBUG, "CPackDocker: Package manager " << packagemanager << std::endl);
  std::string packagedepends = this->getDependencies(packagemanager);
  cmCPackLogger(cmCPackLog::LOG_DEBUG, "CPackDocker: Package dependencies " << packagedepends << std::endl);
  {
    // the scope is needed for cmGeneratedFileStream
    cmGeneratedFileStream out(dockerfilename.c_str());
    out << "# Autogenerated Dockerfile using CPack" << "\n";
    out << "FROM " << docker_base_image << "\n";
    out << "MAINTAINER " << maintainer << "\n";
    out << getLabels() << "\n";
    out << getRun("CPACK_DOCKER_RUN_PREDEPENDS") << "\n";
    out << getDependencies(packagemanager) << "\n";
    out << getRun("CPACK_DOCKER_RUN_POSTDEPENDS") << "\n";
    out << getCmd() << "\n";
  }
  // dockerfile
  cmCPackLogger(cmCPackLog::LOG_DEBUG, "CPackDocker: created dockerfile" << std::endl);
  // dockerimage

  return 1;
}

std::string cmCPackDockerGenerator::getLabels()
{
  // Add all labels in one command to minimize docker layers
  std::stringstream labels;
  const char* docker_container_name     = this->GetOption("GEN_CPACK_DOCKER_CONTAINER_NAME");
  const char* docker_container_version  = this->GetOption("GEN_CPACK_DOCKER_CONTAINER_VERSION");
  const char* description               = this->GetOption("GEN_CPACK_DOCKER_CONTAINER_DESCRIPTION");
  const char* website                   = this->GetOption("GEN_CPACK_DOCKER_CONTAINER_HOMEPAGE");
  const char* custom_labels             = this->GetOption("GEN_CPACK_DOCKER_LABEL");
  labels << "LABEL";
  if(docker_container_name && *docker_container_name) {
    labels << " name=\""              << docker_container_name << "\"";
  }
  if(docker_container_version && *docker_container_version) {
    labels << " \\ \n";
    labels << "      version=\""      << docker_container_version << "\"";
  }
  if(description && *description) {
    labels << " \\ \n";
    labels << "      description=\""  << description << "\"";
  }
  if(website && *website) {
    labels << " \\ \n";
    labels << "      website=\""      << website << "\"";
  }
  if(custom_labels && *custom_labels) {
    labels << " \\ \n";
    labels << "      "                << custom_labels << "\"";
  }
  return labels.str();
}

std::string cmCPackDockerGenerator::getRun(const std::string &option)
{
  const char* cstr = this->GetOption(option);
  if(cstr && *cstr) {
    std::vector<std::string> run_strings;
    cmSystemTools::ExpandListArgument(std::string(cstr), run_strings);
    std::stringstream output;
    output << "# " << option << "\n";
    for (size_t i = 0; i < run_strings.size(); ++i) {
      if (i == 0)
        output << "RUN " << run_strings[i];
      else {
        output << " \\ \n";
        output << "    " << run_strings[i];
      }
    }
    return output.str();
  }
  return std::string();
}

std::string cmCPackDockerGenerator::getPackageManager()
{
  const char* packagemanager = this->GetOption("GEN_CPACK_DOCKER_PACKAGE_MANAGER");
  if (packagemanager && *packagemanager) {
    return std::string(packagemanager);
  }
  std::string base_cmd("docker run ");
  base_cmd.append(this->GetOption("GEN_CPACK_DOCKER_FROM"));
  base_cmd.append(" ");
  // Try apt-get
  {
    std::string cmd = base_cmd;
    cmd.append("apt-get --version");
    std::string output;
    int retval = -1;
    int res = cmSystemTools::RunSingleCommand(cmd.c_str(), &output, &output,
        &retval, this->GetOption("GEN_WDIR"), this->GeneratorVerbose, 0);
    if (!res)
      cmCPackLogger(cmCPackLog::LOG_ERROR, "Problem running " << cmd << std::endl);
    if (!retval) {
      return (std::string("apt-get"));
    }
  }
  // Try yum
  {
    std::string cmd = base_cmd;
    cmd.append("yum --version");
    std::string output;
    int retval = -1;
    int res = cmSystemTools::RunSingleCommand(cmd.c_str(), &output, &output,
        &retval, this->GetOption("GEN_WDIR"), this->GeneratorVerbose, 0);
    if (!res)
      cmCPackLogger(cmCPackLog::LOG_ERROR, "Problem running " << cmd << std::endl);
    if (!retval) {
      return (std::string("yum"));
    }
  }
  // Try pacman
  {
    std::string cmd = base_cmd;
    cmd.append("pacman -Sc"); // pacman return non-zero exit code on version query(!?)
    std::string output;
    int retval = -1;
    int res = cmSystemTools::RunSingleCommand(cmd.c_str(), &output, &output,
        &retval, this->GetOption("GEN_WDIR"), this->GeneratorVerbose, 0);
    if (!res)
      cmCPackLogger(cmCPackLog::LOG_ERROR, "Problem running " << cmd << std::endl);
    if (!retval) {
      return (std::string("pacman"));
    }
  }
  // Could not determine, output error
  cmCPackLogger(cmCPackLog::LOG_ERROR, "CPackDocker: Could not automatically determine the package manager" << std::endl);
  return std::string();
}

std::string cmCPackDockerGenerator::getPackageManagerInstall(const std::string &packagemanager)
{
  const char* package_manager_install = this->GetOption("GEN_CPACK_DOCKER_PACKAGE_MANAGER_INSTALL");
  std::stringstream output;
  if (package_manager_install && *package_manager_install) {
    output << "RUN " << package_manager_install;
    return output.str();
  }
  if(packagemanager.compare("apt-get") == 0) {
    output << "RUN " << packagemanager << " update && " << packagemanager << " install -y";
    return output.str();
  }
  if(packagemanager.compare("yum") == 0) {
    output << "RUN " << packagemanager << " update -y && " << packagemanager << " install -y";
    return output.str();
  }
  if(packagemanager.compare("pacman") == 0) {
    output << "RUN " << packagemanager << " -Syu -- noconfirm && " << packagemanager << " -S --noconfirm";
    return output.str();
  }
  cmCPackLogger(cmCPackLog::LOG_ERROR, "CPackDocker: Could not automatically determine the package manager install command" << std::endl);
  return std::string();
}

std::string cmCPackDockerGenerator::getDependencies(const std::string &packagemanager)
{
  const char* depend_cstr = this->GetOption("GEN_CPACK_DOCKER_PACKAGE_DEPENDS");
  if(depend_cstr && *depend_cstr) {
    std::vector<std::string> dependencies;
    cmSystemTools::ExpandListArgument(std::string(depend_cstr), dependencies);
    std::sort(dependencies.begin(), dependencies.end());
    std::stringstream output;
    output << "# Installing Dependencies\n";
    output << this->getPackageManagerInstall(packagemanager);
    for (size_t i = 0; i < dependencies.size(); ++i) {
      output << " \\ \n";
      output << "    " << getVersionCorrect(dependencies[i], packagemanager);
    }
    output << " \\ \n" << this->cleanCache(packagemanager);
    return output.str();
  }
  return std::string();
}

std::string cmCPackDockerGenerator::getVersionCorrect(const std::string &input, const std::string &packagemanager)
{
  std::stringstream input_str(input);
  std::string segment;
  std::vector<std::string> seglist;
  while(std::getline(input_str, segment, '='))
  {
     seglist.push_back(segment);
  }
  if(seglist.size() == 2) {
    if(packagemanager.compare("apt-get") == 0) {
      // apt-get uses '=' for version definition
      std::string output;
      output = seglist[0];
      output += "=";
      output += seglist[1];
      return output;
    }
    if(packagemanager.compare("yum") == 0) {
      // yum uses '-' for version definition
      std::string output;
      output = seglist[0];
      output += "-";
      output += seglist[1];
      return output;
    }
    if(packagemanager.compare("pacman") == 0) {
      // pacman does not support version definition
      std::string output;
      output = seglist[0];
      return output;
    }
    cmCPackLogger(cmCPackLog::LOG_WARNING, "CPackDocker: Cannot determine the version definition operator for this package manager" << std::endl);
    return input;
  }
  if(seglist.size() == 1) {
    return input;
  }
  else {
    cmCPackLogger(cmCPackLog::LOG_ERROR, "CPackDocker: Too many definition operators for a single dependency" << std::endl);
    return input;
  }
}

std::string cmCPackDockerGenerator::cleanCache(const std::string &packagemanager)
{
  if(packagemanager.compare("apt-get") == 0) {
    return std::string("	&& rm -rf /var/lib/apt/lists/*");
  }
  if(packagemanager.compare("yum") == 0) {
    return std::string("	&& yum clean all");
  }
  if(packagemanager.compare("pacman") == 0) {
    return std::string("	&& pacman -Sc");
  }
  cmCPackLogger(cmCPackLog::LOG_WARNING, "CPackDocker: Cannot determine how to clear the package manager cache" << std::endl);
  return std::string();
}

std::string cmCPackDockerGenerator::getCmd()
{
  const char* cstr = this->GetOption("GEN_CPACK_DOCKER_CMD");
  if(cstr && *cstr) {
    std::vector<std::string> cmd_strings;
    cmSystemTools::ExpandListArgument(std::string(cstr), cmd_strings);
    std::stringstream output;
    for (size_t i = 0; i < cmd_strings.size(); ++i) {
      if (i == 0)
        output << "CMD [ \"" << cmd_strings[i] << "\" ";
      else {
        output << ", \"" << cmd_strings[i] << "\" ";
      }
    }
    output << "]";
    return output.str();
  }
  return std::string();
}

bool cmCPackDockerGenerator::SupportsComponentInstallation() const
{
  if (IsOn("CPACK_DOCKER_COMPONENT_INSTALL"))
    return true;
  return false;
}

std::string cmCPackDockerGenerator::GetComponentInstallDirNameSuffix(
    const std::string& componentName)
{
  if (componentPackageMethod == ONE_PACKAGE_PER_COMPONENT)
    return componentName;

  if (componentPackageMethod == ONE_PACKAGE)
    return std::string("ALL_COMPONENTS_IN_ONE");

  // We have to find the name of the COMPONENT GROUP
  // the current COMPONENT belongs to.
  std::string groupVar = "CPACK_COMPONENT_" +
                         cmSystemTools::UpperCase(componentName) + "_GROUP";
  if (NULL != GetOption(groupVar))
    return std::string(GetOption(groupVar));
  return componentName;
}