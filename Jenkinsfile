pipeline {
    agent any

    environment {
        IMAGE = "stelabiju/complaintbox:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('SAST Scan') {
            steps {
                sh 'docker run --rm -v "$WORKSPACE:/src" semgrep/semgrep semgrep scan --config auto /src'
            }
        }

        stage('Configuration Scan') {
            steps {
                sh 'docker run --rm -v "$WORKSPACE:/src" aquasec/trivy:latest config /src'
            }
        }

        stage('Build Docker Image') {
            steps {
                sh 'docker build -t $IMAGE .'
            }
        }

        stage('Django Check') {
            steps {
                sh 'docker run --rm $IMAGE python manage.py check'
            }
        }

        stage('DAST Scan') {
            steps {
                sh '''
                    docker rm -f complaintbox-dast || true
                    docker run -d --name complaintbox-dast -p 8001:8000 $IMAGE
                    sleep 10
                    docker run --rm --add-host=host.docker.internal:host-gateway -v "$WORKSPACE:/zap/wrk:rw" ghcr.io/zaproxy/zaproxy:stable zap-baseline.py -t http://host.docker.internal:8001 -r zap-report.html
                '''
            }
            post {
                always {
                    sh 'docker rm -f complaintbox-dast || true'
                }
            }
        }

        stage('Push to Docker Hub') {
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker-cred', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASS')]) {
                    sh 'echo "$DOCKER_PASS" | docker login -u "$DOCKER_USER" --password-stdin'
                    sh 'docker push $IMAGE'
                    sh 'docker logout'
                }
            }
        }
    }

    post {
        always {
            archiveArtifacts artifacts: 'zap-report.html', allowEmptyArchive: true
        }
    }
}