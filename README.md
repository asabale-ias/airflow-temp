# MARS Airflow DAG Example Workflow Pipeline for IAS Jenkins-NG

## How-to Start

1. Use this repo as a Template (Clone or [__Use this template__](https://github.com/integralads/mars-airflow-dag-example/generate) button)
2. Give _Read_ rights to _jenkins-ninja-ro-ias_ Github user
3. Give _Admin_ rights to _RE Admin_ Github group
4. Add your Airflow code to _pipeline_ folder
5. Add your Airflow config files to _config_ folder\
   _!NB_: Config files have to be made for all environments where you are going to deploy your Airflow DAG\
   _!NB_: Config file name "prefix" should be equal to environment name (DEV, STAGING, PROD)
6. If you're going to deploy code from other branches than _Master_ ([read more](https://github.com/integralads/re-documentation/blob/master/jenkins-ng/getting-started.md#ci-as-code-conundrum)) - adjust _.jervis.yaml_ and copy structure to all corresponding branches
7. On-board your repository to Jenkins NG ([read more](https://github.com/integralads/re-documentation/blob/master/jenkins-ng/getting-started.md#declaring-projects-for-your-team)) via PR of changes to [projects.yaml](https://github.com/integralads/jenkins-pipeline-scripts/blob/master/resources/com/integralads/projects.yml)
8. After your PR was merged use [Generate Jenkins Jobs from YAML](https://jenkins.303net.net/job/_jervis_generator/build?delay=0sec) to add your Project to Jenkins-NG Web-UI
9. Enter your project sub-folder at [Jenkins-NG](https://jenkins.303net.net/view/GitHub%20Organizations/) and push _Scan repository now_ -- all branches mentioned in .jervis.yaml should appear on Jenkins-NG
10. Setup workflow job via _script_ or _manually_. Details are below in this document.
11. Now you can build and deploy your code to MARS Airflow infrastructure by pushing "Build with Parameters" in Jenkins-NG under your Project space

## Setup workflow via script

1. In console launch _./params-setup.sh_ and fill parameters. Use BASH for that
2. Don't forget to push changes to git repository
3. If command line parameters usage is preferable then run _./params-setup.sh help_ to get a hint

## Setup workflow via manual script editing

1. Edit "Parameters section" at _cicd-wf-MARS_Jenkinsfile.groovy_ according to your Project
2. Edit version parameter at _gradle.properties_ for _config_ and _pipeline_ if needed
3. Edit _rootProject.name_ in _settings.gradle_
4. (optional) Edit group parameter at gradle.properties for config and pipeline if you want use Gradle from commandline
5. Do not forget to push changes to git repository


_For more information visit Project_ [__Wiki__](https://confluence.integralads.com/display/MODE/MARS+Airflow+DAG+Template+Workflow+Pipeline)\
_To start use this Template press_ [__Use this template__](https://github.com/integralads/mars-airflow-dag-example/generate) button.
