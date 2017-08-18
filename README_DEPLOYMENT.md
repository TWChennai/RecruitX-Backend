## Deployment

  #### Generate artifact
  * docker build -f ./Dockerfile.build . -t recruitx_base
  * docker run --env-file env.list -v $PROJECT_DIR:/opt/app recruitx_base ./build_docker.sh
 
  #### Move artifact to PROJECT_DIR
  * mv _build/docker/rel/recruitx_backend/releases/1.0.0/recruitx_backend.tar.gz .

  #### Start the application
  * docker-compose up
