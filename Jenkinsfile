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
      stage('Mutation Tests - PIT') {
        steps {
          sh "mvn org.pitest:pitest-maven:mutationCoverage"
        }
        post {
          always {
            pitmutation mutationStatsFile: '**/target/pit-reports/**/mutations.xml'
          }
        }
      }
      stage('SAST - SonarQube') {
        steps {
          sh "mvn sonar:sonar -Dsonar.projectKey=numeric-application -Dsonar.host.url=http://devsecops-demo.centralindia.cloudapp.azure.com:9000 -Dsonar.login=980c84695ca555483382eae1c84a7ae87ba04c53"
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
}