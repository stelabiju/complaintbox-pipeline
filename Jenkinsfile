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
}