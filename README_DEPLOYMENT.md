## Deployment

#### Elixir-Phoenix sever deployment using ansible-elixir-stack

  * Rebuild of the ansible-elixir project is done only when version is increased. We used git-sha to change the version automatically
  * On deploy, the app is not getting restarted automatically
  * On upgrade (bin/{{app-name}} upgrade "new-version"), the server is restarted
  * bin/{{ app_name}} remote_console is used to debug the server

#### ToDO

  * Use hot code reload when the bug in the ansible-elixir-stack is fixed

#Docker Deployment

## Steps to deploy

  #### Generate artifact
  * docker build -f ./Dockerfile.build . -t recruitx_base
  * docker run --env-file env.list -v $PROJECT_DIR:/opt/app recruitx_base ./build_docker.sh
 
  #### Move artifact to PROJECT_DIR
  * mv _build/docker/rel/recruitx_backend/releases/1.0.0/recruitx_backend.tar.gz .

  #### Start the application
  * docker-compose up
