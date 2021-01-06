# Global variables
NORMAL="\033[m"
MENU="\033[36m"     # Blue
NUMBER="\033[33m"   # Yellow
RED_TEXT="\033[31m" # Red
ENTER_LINE="\033[33m"
arr_params=()
notsorted_arr_params=()
arr_new_params=()
notsorted_arr_new_params=()

#######################################
# Copy template files to actual files
# Globals:
#   jenkins_file
#   settings_file
#   pipeline_properties_file
#   config_properties_file
# Arguments:
#   None
# Returns:
#   None
#######################################
function init_files() {
  config_files=("$jenkins_file" "$settings_file" "$pipeline_properties_file" "$config_properties_file")

  for file in "${config_files[@]}"; do
    if [[ ! -f $file ]]; then
      # removes part of string using shortest path from right to left
      cp -p "${file%.*}.template" "$file"
    else
      echo "$file is already configured"
    fi
  done
}

#######################################
# Shows main menu in command line
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function show_menu() {
  echo -e "${MENU}*********************************************${NORMAL}"
  echo -e "${MENU}**${NUMBER} 1)${MENU} Set parameters ${NORMAL}"
  echo -e "${MENU}**${NUMBER} 2)${MENU} Show parameters ${NORMAL}"
  echo -e "${MENU}**${NUMBER} 3)${MENU} Exit ${NORMAL}"
  echo -e "${MENU}*********************************************${NORMAL}"
  echo -e "${ENTER_LINE}Please choose a menu option and press ${RED_TEXT}enter${NORMAL} ${ENTER_LINE}button \
or just press ${RED_TEXT}enter${NORMAL} ${ENTER_LINE}to exit.${NORMAL}"
  read -r opt

  while [ "${opt}" != "" ]; do
    case $opt in
    1)
      clear
      set_params true
      write_params
      break
      ;;
    2)
      clear
      read_params true
      show_menu
      ;;
    3)
      exit
      ;;
    "\n")
      exit
      ;;
    *)
      clear
      show_menu
      ;;
    esac
  done
}

#######################################
# Write new parameters to config files
# Globals:
#   jenkins_file
#   settings_file
#   pipeline_properties_file
#   config_properties_file
#   arr_params
#   arr_new_params
# Arguments:
#   None
# Returns:
#   None
#######################################
function write_params() {
  echo -e "${ENTER_LINE}Save new parameters? (type y/yes)${NORMAL}"
  read -r Answer
  if [[ ! $Answer =~ (Y|y|Yes|yes) ]]; then
    echo "B-bye..."
    exit
  fi

  # Sort arrays to make sure that keys in them are in the same order
  IFS=$'\n'
  arr_new_params=($(sort <<<"${notsorted_arr_new_params[*]}"))
  arr_params=($(sort <<<"${notsorted_arr_params[*]}"))
  unset IFS

# check if assimilator_application variable is set
  for parameter in "${arr_new_params[@]}"; do
    par="${parameter%%:*}"
    par_value="${parameter#*:}"
    if [[ "${par}" == "this.assimilator_application" && "${par_value}" != "empty" ]]; then
      assimilator_in_use="yes"
    fi
  done

  # check if empty params are passed
  for param in "${arr_new_params[@]}"; do
    # Take whole line and remove beginning or ending to get key or value.
    # Use colon as a separator
    KEY="${param%%:*}"
    NEW_VALUE="${param#*:}"
    if [[ "${KEY%%_*}" != "this.assimilator" ||
        ("${KEY%%_*}" == "this.assimilator" && "${assimilator_in_use}" == "yes") ]] ; then
      if [[ -z "${NEW_VALUE#"${NEW_VALUE%%[![:blank:]]*}"}" ]] || [[ "${NEW_VALUE}" == "empty" ]]; then
        echo -e "${RED_TEXT}Parameter $KEY is set as empty!${NORMAL}"
        echo -e "${ENTER_LINE}Do you want to try again? (type y/yes)${NORMAL}"
        read -r paramAnswer
        if [[ $paramAnswer =~ (Y|y|Yes|yes) ]]; then
          show_menu
        else
          echo "B-bye..."
          exit
        fi
      fi
    fi
  done

  # Arrays sorted and should be identical by KEY part.
  # Working with array by index to get current string in config
  # and replace it with new string with new parameter.
  for ((index = 0; index < ${#arr_new_params[@]}; index++)); do
    KEY="${arr_new_params[$index]%%:*}"
    VALUE="${arr_params[$index]#*:}"
    NEW_VALUE="${arr_new_params[$index]#*:}"

    # Following blocks uses sed -i.bak to create files with previous state
    # which will have .bak extension and then remove that files using rm -f.
    # Looks wierd but it's best way to make it working the same way
    # in both MacOS and Linux and don't add redundant files in git repo.

    # Replace values in result .groovy file
    sed -i.bak "s|${KEY} = '${VALUE}'|${KEY} = '${NEW_VALUE}'|g" "$jenkins_file" &&
      rm -f "${jenkins_file}.bak"

    # Replace group in gradle.properties
    if [ "$KEY" == "this.nexus_group" ]; then
      sed -i.bak "s|group = ${VALUE}|group = ${NEW_VALUE}|g" "$pipeline_properties_file" &&
        rm -f "${pipeline_properties_file}.bak"
    fi

    # Replace group in gradle.properties
    if [ "$KEY" == "this.nexus_group_config" ]; then
      sed -i.bak "s|group = ${VALUE}|group = ${NEW_VALUE}|g" "$config_properties_file" &&
        rm -f "${config_properties_file}.bak"
    fi

    # Replace rootProject.name in settings.gradle
    if [ "$KEY" == "this.application" ]; then
      sed -i.bak "s|rootProject.name = '${VALUE}'|rootProject.name = '${NEW_VALUE}'|g" "$settings_file" &&
        rm -f "${settings_file}.bak"
    fi
  done

  echo "Configuration files are updated."
  echo -e "${ENTER_LINE}Do you want commit changes to git? (type y/yes)${NORMAL}"
  read -r gitAnswer
  if [[ $gitAnswer =~ (Y|y|Yes|yes) ]]; then
    git add -A
    git commit -a -m "Configuration files are updated by params-setup.sh"
    exit
  else
    echo "B-bye..."
    exit
  fi
}

#######################################
# Read current parameters from templates
# Globals:
#   jenkins_file
# Arguments:
#   $1 true Send parsed params to stdout
# Returns:
#   None
#######################################
function read_params() {
  unset notsorted_arr_params

  # Read parameters from template and add them to an array as a strings
  while IFS="=" read -r name val; do
    [[ $name == this.* ]] || continue # skip lines not containing 'this.*'
    if ! [[ $name =~ this\.(gradle_params|install_path|app_base_path|config_base_path|environment_choices|classifier_choices|assimilator_install_path) ]]; then
      # Sanitize whitespaces - could be used "${VERSION// }" - but
      KEY="${name%"${name##*[![:space:]]}"}"
      VALUE="${val#"${val%%[![:space:]]*}"}"
      # Remove single quotes
      VALUE="${VALUE//\'/}"
      notsorted_arr_params+=("${KEY%}:${VALUE}")
    fi
  done <"$jenkins_file"

  # Show result in command line
  if [ "$1" == "true" ]; then
    echo -e "${ENTER_LINE}Current parameters values:${NORMAL}"
    for param in "${notsorted_arr_params[@]}"; do
      KEY="${param%%:*}"
      VALUE="${param#*:}"
      printf "%s=%s\n" "$KEY" "$VALUE"
    done
  fi
}

#######################################
# Get new values of parameters from user
# Globals:
#   arr_new_params
# Arguments:
#   $1 true Send parsed params to stdout
# Returns:
#   None
#######################################
function set_params() {
  read_params false
  unset arr_new_params
  unset notsorted_arr_new_params

  for param in "${notsorted_arr_params[@]}"; do
    # check what read_params gave us
    KEY="${param%%:*}"
    VALUE="${param#*:}"

    printf "Set %s [%s]\n" "$KEY" "$VALUE"
    read -r NEW_VALUE
    # user just hit enter - pass to array value from read_params
    if [ -z "${NEW_VALUE#"${NEW_VALUE%%[![:blank:]]*}"}" ]; then
      notsorted_arr_new_params+=("${KEY}:${VALUE}")
    else
      notsorted_arr_new_params+=("${KEY}:${NEW_VALUE}")
    fi
  done

  # Show results in command line
  if [ "$1" == "true" ]; then
    echo "New parameters values:"
    for new_param in "${notsorted_arr_new_params[@]}"; do
      KEY="${new_param%%:*}"
      VALUE="${new_param#*:}"
      printf "%s=%s\n" "$KEY" "$VALUE"
    done
  fi
}

#######################################
# Show description of CLI options
# Globals:
#   None
# Arguments:
#   None
# Returns:
#   None
#######################################
function usage() {
  printf "%s\n" \
    "Usage: $0 --application=<application> --git_url=<git_url> --default_branch=<default_branch>" \
    "--host_tag=<host_tag> --nexus_group=<nexus_group> --nexus_group_config=<config nexus_group> --nexus_url=<nexus_url> " \
    "--assimilator_application=<assimilator_application> --assimilator_git_url=<assimilator_git_url>" \
    "--assimilator_default_branch=<assimilator_default_branch> --assimilator_base_path=<assimilator_base_path> --assimilator_nexus_url=<assimilator_nexus_url>" \
    "--assimilator_nexus_group=<assimilator_nexus_group>" \
    "Extended descriprion of parameters:" \
    "--application=<application>                               - Name of application, the same as artefactId" \
    "--git_url=<git_url>                                       - URL of git repository with Airflow DAG" \
    "--default_branch=<default_branch>                         - Example: origin/master" \
    "--host_tag=<host_tag>                                     - Part of Celery queue without environment, e.g. pet" \
    "--nexus_group=<nexus_group>                               - Group of DAG artefact in Nexus" \
    "--nexus_group_config=<nexus_group_config>                 - Group of DAG's conifg in Nexus" \
    "--nexus_url=<nexus_url>                                   - Example: http://nexus.mars.303net.pvt:8081/nexus" \
    "--assimilator_application=<assimilator_application>       - Name of Assimilator app, the same as artefactId" \
    "--assimilator_git_url=<assimilator_git_url>               - URL of git repository with Assimilator DAG" \
    "--assimilator_default_branch=<assimilator_default_branch> - Example: origin/master" \
    "--assimilator_base_path=<assimilator_base_path>           - Directory with the Gradle script" \
    "--assimilator_nexus_group=<assimilator_nexus_group>       - Group of Assimilator artefact in Nexus" \
    "--assimilator_nexus_url=<assimilator_nexus_url>           - URL of Nexus with Assimilator artefact"
}

#######################################
# Parse options passed from CLI
# Globals:
#   arr_new_params
# Arguments:
#   $1 $* Contains all CLI options
# Returns:
#   None
#######################################
function parse_input() {
  unset notsorted_arr_new_params

  # Generated array must contain values in the same form
  # as it stored in Jenkinsfile
  while [ $# -gt 0 ]; do
    # Remove '--' prefix from param
    VALUE="${1##*--}"

    case "$VALUE" in
    *)
      notsorted_arr_new_params+=("this.${VALUE%%=*}:${VALUE#*=}")
      shift 1
      continue
      ;;
    esac
  done
}
