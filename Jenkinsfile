pipeline {
    agent any

    environment {
        DOCKER_IMAGE = "stelabiju/complaintbox"
    }

    stages {
        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/stelabiju/complaintbox-pipeline.git'
            }
        }

        stage('SAST Scan') {
            steps {
                sh '''
                    docker run --rm \
                    -v "$(pwd):/src" \
                    semgrep/semgrep \
                    semgrep scan --config auto /src \
                    || true
                '''
            }
        }

        stage('Dependency Scan') {
            steps {
                sh '''
                    docker run --rm \
                    -v "$(pwd):/app" \
                    aquasec/trivy:latest \
                    fs --skip-version-check /app \
                    || true
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    docker build -t ${DOCKER_IMAGE}:${BUILD_NUMBER} .
                    docker tag ${DOCKER_IMAGE}:${BUILD_NUMBER} ${DOCKER_IMAGE}:v1
                '''
            }
        }

        stage('DAST Scan') {
            steps {
                sh '''
                    docker rm -f complaintbox-dast || true

                    docker run -d \
                    --name complaintbox-dast \
                    -p 8001:8000 \
                    ${DOCKER_IMAGE}:${BUILD_NUMBER}

                    sleep 20

                    docker run --rm \
                    --network host \
                    -v "$(pwd):/zap/wrk:rw" \
                    ghcr.io/zaproxy/zaproxy:stable \
                    zap-baseline.py \
                    -t http://127.0.0.1:8001 \
                    -r zap-report.html \
                    || true

                    docker rm -f complaintbox-dast || true
                '''
            }
            post {
                always {
                    archiveArtifacts artifacts: 'zap-report.html',
                                     allowEmptyArchive: true
                }
            }
        }

        stage('Push Docker Image') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'docker-cred',
                    usernameVariable: 'DOCKER_USER',
                    passwordVariable: 'DOCKER_PASS'
                )]) {
                    sh '''
                        echo "$DOCKER_PASS" | docker login \
                        -u "$DOCKER_USER" --password-stdin

                        docker push ${DOCKER_IMAGE}:${BUILD_NUMBER}
                        docker push ${DOCKER_IMAGE}:v1

                        docker logout
                    '''
                }
            }
        }

        stage('Update Kubernetes Manifest') {
            steps {
                withCredentials([usernamePassword(
                    credentialsId: 'github-cred',
                    usernameVariable: 'GIT_USER',
                    passwordVariable: 'GIT_PASS'
                )]) {
                    sh '''
                        sed -i "s|image: .*|image: ${DOCKER_IMAGE}:${BUILD_NUMBER}|" \
                        k8s/deployment.yaml

                        git config user.name "Jenkins"
                        git config user.email "jenkins@example.com"

                        git add k8s/deployment.yaml

                        git commit -m "Update ComplaintBox image to ${BUILD_NUMBER}" \
                        || echo "No changes to commit"

                        git push https://${GIT_USER}:${GIT_PASS}@github.com/stelabiju/complaintbox-pipeline.git HEAD:main
                    '''
                }
            }
        }
    }

    post {
        always {
            sh 'docker rm -f complaintbox-dast || true'
        }
    }
}
