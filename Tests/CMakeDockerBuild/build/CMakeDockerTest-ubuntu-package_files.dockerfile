# Autogenerated Dockerfile using CPack
FROM ubuntu
MAINTAINER 
LABEL name="cmakedockertest-ubuntu" \ 
      version="0.1.1" \ 
      description="CMakeDockerTest built using CMake"
VOLUME [ "/home/ubuntu" ]
COPY [ "_CPack_Packages/Linux/DOCKER/CMakeDockerTest-ubuntu/package_files" , "/home/ubuntu" ]
WORKDIR [ "/home/ubuntu" ]