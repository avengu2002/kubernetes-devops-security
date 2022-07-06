pipeline {
  agent any
  environment {
    deploymentName = "devsecops"
    containerName = "devsecops-container"
    serviceName = "devsecops-svc"
    imageName = "avengu/numeric-app:${GIT_COMMIT}"
    applicationURL = "http://devsecops-demo.centralindia.cloudapp.azure.com"
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
          parallel(
            "OPA Scan": {
              sh 'docker run --rm -v $(pwd):/project openpolicyagent/conftest test --policy opa-k8s-security.rego k8s_deployment_service.yaml'
            },
            "Kubesec Scan": {
              sh "bash kubesec-scan.sh"
            }
          )
        }
      }


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
      stage('Integration Tests - DEV') {
        steps {
          script {
            try {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "bash integration-test.sh"
              }
            } catch (e) {
              withKubeConfig([credentialsId: 'kubeconfig']) {
                sh "kubectl -n default rollout undo deploy ${deploymentName}"
              }
              throw e
            }
          }
        }
      }

    stage('Prompte to PROD?') {
      steps {
        timeout(time: 2, unit: 'DAYS') {
          input 'Do you want to Approve the Deployment to Production Environment/Namespace?'
        }
      }
    }

    stage('K8S CIS Benchmark') {
      steps {
        script {

          // parallel(
          //   "Master": {
          //     sh "bash cis-master.sh"
          //   },
          //   "Etcd": {
          //     sh "bash cis-etcd.sh"
          //   },
            // "Kubelet": {
              sh 'docker run --pid=host -v /etc:/etc:ro -v /var:/var:ro -v $(which kubectl):/usr/local/mount-from-host/bin/kubectl -v ~/.kube:/.kube -e KUBECONFIG=/.kube/config -t aquasec/kube-bench:latest  run --version 1.20 --targets node --check 4.2.1,4.2.2 --json | jq .Totals.total_fail'
            // }
          // )

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