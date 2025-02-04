
def release_version
pipeline {
  environment {
    PROJECT = "sandbox-io-289003"
    APP_NAME = "kazre-app"
    FE_SVC_NAME = "${APP_NAME}-frontend"
    CLUSTER = "jenkins-cd"
    CLUSTER_ZONE = "us-east1-d"
    IMAGE_TAG = "gcr.io/${PROJECT}/${APP_NAME}:${env.BRANCH_NAME}.${env.BUILD_NUMBER}"
    JENKINS_CRED = "${PROJECT}"  
    REPO = "kazrethomas/spring-boot-docker"
  }

  agent {
    kubernetes {
      label 'my-agent'
      defaultContainer 'jnlp'
      yaml """
apiVersion: v1
kind: Pod
metadata:
labels:
  component: ci
spec:
  # Use service account that can deploy to all namespaces
  serviceAccountName: cd-jenkins
  containers:
  - name:  maven
    image:  maven
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
  - name: kubectl
    image: dtzar/helm-kubectl:3.11
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
  - name: git
    image: jlrigau/maven-git
    imagePullPolicy: IfNotPresent
    command:
    - cat
    tty: true
  - name: kaniko
    image: gcr.io/kaniko-project/executor:v1.6.0-debug
    imagePullPolicy: Always
    command:
    - sleep
    args:
    - 99d
"""
}
  }
  stages {
    stage('Release') {
      when {
                branch 'master'
            }
      steps {
        container('git') {
        withCredentials([string(credentialsId: 'kazre-credentials', variable: 'TOKEN')]) {
          script {

        release_version  = sh (
                script: "git log --format='%s' --max-count=1 origin/master | grep --only-matching 'v\\?[0-9]\\+\\.[0-9]\\+\\(\\.[0-9]\\+\\)\\?'",
                 returnStdout: true
                   ).trim()
          }          
          sh '''#!/bin/bash
            git config --global user.name "kazrethomas"
            git config --global user.email "kazre.thomas@cod-it.tech"
            git config --global user.password "$TOKEN"
            git config --global --add safe.directory '*'
            LAST_LOG=$(git log --format='%H' --max-count=1 origin/master)
            echo "LAST_LOG:$LAST_LOG"
            LAST_MERGE=$(git log --format='%H' --merges --max-count=1 origin/master)
            echo "LAST_MERGE:$LAST_MERGE"
            LAST_MSG=$(git log --format='%s' --max-count=1 origin/master)
            echo "LAST_MSG:$LAST_MSG"
            VERSION=$(echo $LAST_MSG | grep --only-matching 'v\\?[0-9]\\+\\.[0-9]\\+\\(\\.[0-9]\\+\\)\\?')
            echo "VERSION:$VERSION"
            
            if [[ $LAST_LOG == $LAST_MERGE && -n $VERSION ]]
            then
                DATA='{
                    "tag_name": "'$VERSION'",
                    "target_commitish": "master",
                    "name": "'$VERSION'",
                    "body": "'$LAST_MSG'",
                    "draft": false,
                    "prerelease": false
                }'
                curl --header "Accept: application/vnd.github+json" --header "Authorization: Bearer $TOKEN" --data "$DATA" "https://api.github.com/repos/$REPO/releases"
            fi

            mvn versions:set -DnewVersion=1.0=$VERSION
            mvn install -DskipTests
            '''
          }
        }
      }
    }
    stage('Compilation') {
       steps {
        container('maven') {
         dir("spring-boot-app") {
          sh "ls"
          sh "mvn  versions:set -DnewVersion=${release_version}"
          sh "mvn clean install -DskipTests"
          }
        }
      }
    }
    stage('Build and push image with Google Container Registry') {
      steps {
        container('kaniko') {
          dir("spring-boot-app") {
            // No access to docker deamon so kaniko is the best option to build docker within kubernetes jenkins agent
            // The equivilant to docker build, tag and push
           sh "/kaniko/executor -f `pwd`/Dockerfile -c `pwd` --insecure --skip-tls-verify --cache=true --destination=gcr.io/${PROJECT}/${APP_NAME}:${release_version}"
          }
        }
      }
    }
    stage('Deploy to kubernetes') {
      steps {
        container('kubectl') {
          dir("spring-boot-app") {
            // No access to docker deamon so kaniko is the best option to build docker within kubernetes jenkins agent
            // The equivilant to docker build, tag and push
             sh "helm template  kazre ./kazre-helm/ --set image.tag=${release_version}.${env.BUILD_NUMBER} | kubectl apply -f - "
        }
      }
    }
  }
  }
}
