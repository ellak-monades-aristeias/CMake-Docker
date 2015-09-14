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

  /* Are we in the component packaging case */
  if (WantsComponentInstallation()) {
    // CASE 1 : COMPONENT ALL-IN-ONE package
    // If ALL GROUPS or ALL COMPONENTS in ONE package has been requested
    // then the package file is unique and should be open here.
    if (componentPackageMethod == ONE_PACKAGE)
    {
      return PackageComponentsAllInOne();
    }
    // CASE 2 : COMPONENT CLASSICAL package(s) (i.e. not all-in-one)
    // There will be 1 package for each component group
    // however one may require to ignore component group and
    // in this case you'll get 1 package for each component.
    else
    {
      return PackageComponents(componentPackageMethod ==
                               ONE_PACKAGE_PER_COMPONENT);
    }
  }
  // CASE 3 : NON COMPONENT package.
  else
  {
    if (!this->ReadListFile("CPackDocker.cmake"))
    {
      cmCPackLogger(cmCPackLog::LOG_ERROR,
                    "Error while execution CPackDocker.cmake" << std::endl);
      retval = 0;
    }
    else
    {
      packageFiles = files;
      return createDocker();
    }
  }
  return retval;
}

int cmCPackDockerGenerator::createDocker()
{
  std::string dockerfilename;
  dockerfilename = this->GetOption("GEN_WDIR");
  dockerfilename += "/Dockerfile";

  std::string docker_pkg_name = cmsys::SystemTools::LowerCase(
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_NAME") );
  const char* docker_pkg_version =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_VERSION");
  const char* docker_base_image =
      this->GetOption("GEN_CPACK_DOCKER_BASE_IMAGE");
  const char* maintainer =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_MAINTAINER");
  const char* description =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_DESCRIPTION");
  const char* website =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_HOMEPAGE");
  const char* packagemanager =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_MANAGER");
  const char* packagedepends =
      this->GetOption("GEN_CPACK_DOCKER_PACKAGE_DEPENDS");
  { // the scope is needed for cmGeneratedFileStream
    cmGeneratedFileStream out(dockerfilename.c_str());
    out << "# Autogenerated Dockerfile using CPack" << "\n";
    out << "# Package " << docker_pkg_name << "\n";
    out << "FROM " << docker_base_image << "\n";
    out << "MAINTAINER " << maintainer << "\n";
    out << "LABEL \\ \n";
    out << "    version=\"" << docker_pkg_version << "\" \\ \n";
    out << "    description=\"" << description << "\" \\ \n";
    out << "    website=\"" << website << "\" \n";
    if (packagedepends && *packagedepends)
    {
      std::stringstream depends(packagedepends);
      std::string depend;
      std::vector<std::string> vec_depends;
      while(std::getline(depends, depend, ' '))
      {
         vec_depends.push_back(depend);
      }
      out << "RUN " << packagemanager << " update && " <<
             packagemanager << " install -y \\ \n";
      // Iterate all the dependencies and append new line character except the last
      for (size_t i = 0; i < vec_depends.size() - 1; ++i)
      {
        out << "    " << vec_depends[i] << "\\ \n";
      }
      out << "    " << *(vec_depends.end()) << "\n";
    }
    out << std::endl;
  }
  // dockerfile

  // dockerimage

  return 1;
}

std::string cmCPackDockerGenerator::getPackageManager()
{
  std::string cmd("docker run ubuntu yum &> /dev/null ;");
  std::string output;
  int retval = -1;
  int res = cmSystemTools::RunSingleCommand(cmd.c_str(), &output, &output,
      &retval, this->GetOption("GEN_WDIR"), this->GeneratorVerbose, 0);
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
