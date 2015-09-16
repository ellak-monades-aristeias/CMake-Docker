/*============================================================================
  CMake - Cross Platform Makefile Generator
  Copyright 2000-2009 Kitware, Inc.

  Distributed under the OSI-approved BSD License (the "License");
  see accompanying file Copyright.txt for details.

  This software is distributed WITHOUT ANY WARRANTY; without even the
  implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
  See the License for more information.
============================================================================*/

#ifndef cmCPackDockerGenerator_h
#define cmCPackDockerGenerator_h


#include "cmCPackGenerator.h"

/** \class cmCPackDockerGenerator
 * \brief A generator for Docker packages
 *
 */
class cmCPackDockerGenerator : public cmCPackGenerator
{
public:
  cmCPackTypeMacro(cmCPackDockerGenerator, cmCPackGenerator);

  /**
   * Construct generator
   */
  cmCPackDockerGenerator();
  virtual ~cmCPackDockerGenerator();

  static bool CanGenerate()
    {
#ifdef __APPLE__
    // on MacOS disable CPackDocker
    return false;
#else
    // legacy behavior on other systems
    return true;
#endif
    }
protected:
  virtual int InitializeInternal();
  /**
   * This method factors out the work done in component packaging case.
   */
  int PackageOnePack(std::string initialToplevel, std::string packageName);
  /**
   * The method used to package files when component
   * install is used. This will create one
   * archive for each component group.
   */
  int PackageComponents(bool ignoreGroup);
  /**
   * Special case of component install where all
   * components will be put in a single installer.
   */
  int PackageComponentsAllInOne();
  virtual int PackageFiles();
  virtual const char* GetOutputExtension() { return ""; }
  virtual bool SupportsComponentInstallation() const;
  virtual std::string GetComponentInstallDirNameSuffix(
      const std::string& componentName);

private:
  int createDocker();
  std::string getRun(const std::string &option);
  std::string getPackageManager();
  std::string getLabels();
  std::string getVersionCorrect(const std::string &input, const std::string &packagemanager);
  std::string cleanCache(const std::string &packagemanager);
  std::string getDependencies(const std::string &packagemanager);
  std::vector<std::string> packageFiles;

};

#endif
