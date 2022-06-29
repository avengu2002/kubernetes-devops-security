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
      }   
      stage('Mutation Tests - PIT') {
        steps {
          sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
      }
      stage('SAST - SonarQube') {
        steps {
          withSonarQubeEnv('SonarQube') {
            sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://devsecops-demo.centralindia.cloudapp.azure.com:9000"
          }
          timeout(time: 2, unit: 'MINUTES') {
           script {
            waitForQualityGate abortPipeline: true
           }
          }
        }
      }
      // stage('Vulnerability Scan - Docker ') {
      //   steps {
      //     sh "mvn dependency-check:check"
      //   }
      //   post {
      //     always {
      //       dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
      //     }
      //   }
      // }
      
      stage('Trivy Vulnerability Scan - Docker') {
        steps {
              sh "bash trivy-docker-image-scan.sh"
            }
          
        }
                  

      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "doc-hub", url: ""]) {
            sh 'printenv'
            sh 'docker build -t avengu/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push avengu/numeric-app:""$GIT_COMMIT""'
          }
        }
      }
      stage('Kubernetes Deployment - DEV') {
        steps {
          withKubeConfig([credentialsId: 'kubeconfig', serverUrl:'']) {
            sh "sed -i 's#replace#avengu/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
            sh "kubectl apply -f k8s_deployment_service.yaml"
          }
        }
      }
  }
  post {
  always {
    junit 'target/surefire-reports/*.xml'
    jacoco execPattern: 'target/jacoco.exec'
    pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
    //dependencyCheckPublisher pattern: 'target/dependency-check-report.xml'
  }

  // success {

  // }

  // failure {

  // }
  }
}