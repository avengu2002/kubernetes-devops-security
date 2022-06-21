pipeline {
  agent any

  stages {
      stage('Build Artifact') {
            steps {
              sh "mvn clean package -DskipTests=true"
              archiveArtifacts 'target/*.jar'
            }
        }   
      stage('Unit Tests') {
            steps {
              sh "mvn test"
              
            }
            post {
              always {
                junit 'target/surefire-reports/*.xml'
                jacoco execPattern: 'target/jacoco.exec'
              }
            }
      }   
      stage('Docker Build and Push') {
        steps {
            docker.withRegistry([credentialsId: "doc-hub", url: ""]){
              sh 'printenv'
              sh 'docker build -t avengu/numeric-app:""$GIT_COMMIT"" .'
              sh 'docker push avengu/numeric-app:""$GIT_COMMIT""'
          }
        }
      }    
  }
}