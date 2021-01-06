#!/usr/bin/env bash
#
# Configure repository for specific project.
#
# Script will find all parameters in file .ci/cicd-wf-MARS_Jenkinsfile.groovy
# which are started by "this." and replace their values with ones provided
# by user in all configuration files.
#
# There are two options to provide values: using interactive menu or command line
# parameters. So repository can be conigured by user itself of via any kind
# of automation, e.g. Jenkins.


# Global variables with paths to files to configure
jenkins_file=".ci/cicd-wf-MARS_Jenkinsfile.groovy"
settings_file="settings.gradle"
pipeline_properties_file="pipeline/gradle.properties"
config_properties_file="config/gradle.properties"

# Load library with functions
source params-setup-lib.sh

# Copy templates to actual files which will be used
init_files

# If there is no command line parameters then use menu
if [[ $# -eq 0 ]]; then
  clear
  show_menu
else
# Otherwise use parameters provided in command line
  read_params false
  # Number of passed params have to be equal to number of params in template
  if [[ $# -ne ${#arr_params[@]} ]]; then
    usage
  else
    parse_input "$*"
    write_params
  fi
fi
