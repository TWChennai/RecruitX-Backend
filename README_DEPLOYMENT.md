#Deployment

#### Elixir-Phoenix sever deployment using ansible-elixir-stack

  * Rebuild of the ansible-elixir project is done only when version is increased. We used git-sha to change the version automatically
  * On deploy, the app is not getting restarted automatically
  * On upgrade (bin/{{app-name}} upgrade "new-version"), the server is restarted
  * bin/{{ app_name}} remote_console is used to debug the server

#### ToDO

  * Use hot code reload when the bug in the ansible-elixir-stack is fixed
