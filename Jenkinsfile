pipeline {
    agent any

    environment {
        git_repo_url = 'https://github.com/alonstani/flask-app.git'
        branch_name = 'master'
        git_credentials_id = 'git-credential-id'  // Add your credentials ID here
        dockerhub_repo = 'inyouk/flask-app'  // Your Docker Hub repository
        dockerhub_credentials_id = 'docker-credential-id'  // Jenkins credentials ID for Docker Hub
    }

    triggers {
        pollSCM('* * * * *')
    }

    stages {
        stage('Clean up') {
            steps {
                sh '''
                    docker ps -q | xargs -r docker stop
                    docker ps -a -q | xargs -r docker rm
                '''
            }
        }

        stage('Clone code') {
            steps {
                sh 'rm -rf flask-app'
                sh 'git clone ${git_repo_url}'
                sh 'ls flask-app'  // This should list the directory contents after cloning
            }
        }

        stage('Build') {
            steps {
                sh '''
                    cd flask-app
                    ls -l  # List the contents of the flask-app directory to confirm docker-compose.yml is there
                    docker-compose build 
                '''
            }
        }

        stage('Run') {
            steps {
                sh '''
                    cd flask-app
                    ls -l  # Again, confirm that docker-compose.yml is present
                    docker-compose up -d
                    sleep 10 
                    echo "Listing all containers after docker-compose up:"
                    docker ps  # List all running containers after starting the services
                    if ! docker ps -q --filter "name=flask-app"; then
                        echo "flask-app container did not start." 
                        docker ps -a  # List all containers, including stopped ones
                        exit 1 
                    fi
                '''
            }
        }

        stage('Test') {
            steps {
                sh 'sleep 5'  // Allow the container some time to initialize
                sh '''
                    echo "Listing all running containers:"
                    docker ps --format "table {{.ID}}\t{{.Image}}\t{{.Names}}"  # Show container IDs, images, and names
                    cd flask-app  # Ensure we are in the correct directory
                    
                    # Check if docker-compose.yaml exists
                    if [ ! -f docker-compose.yaml ]; then
                        echo "docker-compose.yaml not found in flask-app directory."
                        exit 1
                    fi
                    
                   # Check if the flask-app container is running (by name)
                    if ! docker ps -q --filter "name=flask-app_flask-app_1"; then
                        echo "flask-app container is not running."
                        exit 1
                    fi
                '''
                sh '''
                    # Check the container logs
                    if ! docker logs flask-app_flask-app_1; then
                        echo "Container logs check failed"
                        exit 1 
                    fi    
                '''
                sh '''
                    # Test if the app is reachable via curl
                    if ! curl -f http://localhost:5000; then 
                        echo "App is not reachable."
                        docker logs flask-app_flask-app_1  # Show the logs for the flask-app container
                        exit 1 
                    fi
                '''
            }
        }

        // New stage to push Docker image to Docker Hub
        stage('Push Docker Image to Docker Hub') {
            steps {
                script {
                    // Login to Docker Hub using Jenkins credentials
                    withCredentials([usernamePassword(credentialsId: "${dockerhub_credentials_id}", usernameVariable: 'DOCKER_USERNAME', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh '''
                            # Log in to Docker Hub
                            echo "${DOCKER_PASSWORD}" | docker login --username ${DOCKER_USERNAME} --password-stdin
                            
                            # Tag the image with your Docker Hub repository
                            cd flask-app
                            IMAGE_TAG="${dockerhub_repo}:${branch_name}-latest"  # Tag with the branch name and "latest"
                            docker tag flask-app ${dockerhub_repo}:${branch_name}-latest  # Correct tagging format
                            
                            # Push the image to Docker Hub
                            docker push ${dockerhub_repo}:${branch_name}-latest
                        '''
                    }
                }
            }
        }

        // New stage to push changes to Git (optional, if you want to commit and push code to GitHub)
        stage('Push Code to Git') {
            steps {
                script {
                    // Configuring Git credentials
                    withCredentials([usernamePassword(credentialsId: "${git_credentials_id}", usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                        sh '''
                            # Configure git with credentials
                            git config --global user.email "alonstani95@gmail.com"
                            git config --global user.name "inyouk"
                            
                            cd flask-app
                            git add .  # Stage changes
                            git commit -m "Automated commit from Jenkins"
                            git push https://${GIT_USERNAME}:${GIT_PASSWORD}@${git_repo_url.replace('https://', '')} ${branch_name}
                        '''
                    }
                }
            }
        }
    }
}





