pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "avengu/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://devsecops-demo.centralindia.cloudapp.azure.com/"
    applicationURI = "/increment/99"
  }

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
      
      stage('Vulnerability Scan - Docker') {
        steps {
          parallel(
            "Trivy Scan": {
              sh "bash trivy-docker-image-scan.sh"
            },
            "OPA Conftest": {
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-docker-security.rego Dockerfile'
            }
          )
        }
      }                  

      stage('Docker Build and Push') {
        steps {
          withDockerRegistry([credentialsId: "doc-hub", url: ""]) {
            sh 'printenv'
            sh ' sudo docker build -t avengu/numeric-app:""$GIT_COMMIT"" .'
            sh 'docker push avengu/numeric-app:""$GIT_COMMIT""'
          }
        }
      }

      stage('Vulnerability Scan - Kubernetes') {
        steps {
          sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
        }
      }


      // stage('Kubernetes Deployment - DEV') {
      //   steps {
      //     withKubeConfig([credentialsId: 'kubeconfig', serverUrl:'']) {
      //       sh "sed -i 's#replace#avengu/numeric-app:${GIT_COMMIT}#g' k8s_deployment_service.yaml"
      //       sh "kubectl apply -f k8s_deployment_service.yaml"
      //     }
      //   }
      // }

      stage('K8S Deployment - DEV') {
        steps {
          parallel(
            "Deployment": {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "bash k8s-deployment.sh"
              }
            },
            "Rollout Status": {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "bash k8s-deployment-rollout-status.sh"
              }
            }
          )
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