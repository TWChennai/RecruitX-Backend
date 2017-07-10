# RecruitxBackend [![Build Status](https://semaphoreci.com/api/v1/dineshdiny/recruitx-backend/branches/master/badge.svg)](https://semaphoreci.com/dineshdiny/recruitx-backend)

## Dev Setup

### Erlang and Elixir

#### Using asdf Package Manager
  * Install [asdf](https://github.com/asdf-vm/asdf) (the package manager) that will be used to handle multiple versions of erlang and elixir.

  Note: `brew` installation is not working as expected :(

  ```bash
  git clone https://github.com/asdf-vm/asdf.git ~/.asdf --branch v0.3.0

  # if you are using bash
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.bash_profile
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.bash_profile

  # if you are using zsh
  echo -e '\n. $HOME/.asdf/asdf.sh' >> ~/.zshrc
  echo -e '\n. $HOME/.asdf/completions/asdf.bash' >> ~/.zshrc
  ```

  * Use `~/.tool-versions` file to specify the version of elixir and erlang needs to used system level. asdf can be used to setup project specific tool versions also (please refer [this](https://github.com/asdf-vm/asdf#set-current-version))
  ```
  echo "elixir 1.4.0" >> ~/.tool-versions
  echo "erlang 19.2" >> ~/.tool-versions
  ```

  * Install
  ```bash
  asdf plugin-add erlang https://github.com/asdf-vm/asdf-erlang.git
  asdf plugin-add elixir https://github.com/asdf-vm/asdf-elixir.git
  asdf install
  ```

Note: The versions of tools installed can be found in `.asdf/installs/`

#### Using Brew

  * To install `erlang 19.2` execute:
    ```bash
    brew uninstall --force erlang
    brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/77f353913f1e0edd7ba592308da2aa70e26570e1/Formula/erlang.rb
    brew pin erlang
    ```

  * To install `elixir 1.4.0` execute:
    ```bash
    brew uninstall --force elixir
    brew install https://raw.githubusercontent.com/Homebrew/homebrew-core/f47cde4e2b771b4a8d170038a20ca703d20bdf0d/Formula/elixir.rb
    brew pin elixir
    ```

### Checking Installation
  * To check the erlang version execute:
    ```bash
    erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell
    ```
    You should get "18" as the output.

  * To check the elixir version execute:
    ```bash
    elixir -v
    ```
    You should get "Elixir 1.4.0" as the output.

### Postgres

  * Download and install Postgress App from [here](https://github.com/PostgresApp/PostgresApp/releases/download/9.4.11/Postgres-9.4.11.zip).

  * Add Postgres binaries to PATH

  ```bash
    # if using bash
    echo "export POSTGRES_PATH=\"/Applications/Postgres.app/Contents/Versions/9.4\"" >> ~/.bash_profile
    echo "export PATH=\$PATH:\$POSTGRES_PATH/bin" >> ~/.bash_profile
  ```

  ```bash
    # if using zsh
    echo "export POSTGRES_PATH=\"/Applications/Postgres.app/Contents/Versions/9.4\"" >> ~/.zshrc
    echo "export PATH=\$PATH:\$POSTGRES_PATH/bin" >> ~/.zshrc
  ```

  * Create default user
  ```bash
  createuser -s postgres
  ```

  * Once this is present, create a user with the correct role/permissions using the following psql invocation:
  ```bash
  psql -U postgres -c "CREATE ROLE \"recruitx\" LOGIN CREATEDB;"
  ```

### Other Dependencies

You have to set following environment variables
  ```bash
  export API_KEY="your api key"
  export AWS_DOWNLOAD_URL="download url"
  export AWS_BUCKET="recruitx-feedback-image"

  export AWS_ACCESS_KEY_ID="AWS_ACCESS_KEY"
  export AWS_SECRET_ACCESS_KEY="AWS_SECRET_ACCESS"
  export JIGSAW_URL="JIGSAW_URL"
  export JIGSAW_TOKEN="JIGSAW_TOKEN"

  export SMTP_PORT="smtp port"
  export DEFAULT_FROM_EMAIL_ADDRESS="Your email address"

  ## Space separated list of Email addresses ##
  export DEFAULT_TO_EMAIL_ADDRESSES="email addresses"
  export CONSOLIDATED_FEEDBACK_RECIPIENT_EMAIL_ADDRESSES="email addressess"
  export WEEKLY_SIGNUP_REMINDER_RECIPIENT_EMAIL_ADDRESSES="email addressess"
  export WEEKLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES="email addresses"

  export QR_CODE_URL="QR_CODE_URL"
  export APK_URL="APK_URL"
  export LOGO_URL="LOGO_URL"

  export OKTA_PREVIEW="OKTA_PREVIEW"
  export OKTA_API_KEY="API_KEY"

  export MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES="email address"
  export QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES="email address"

  export MONTHLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES="email address"
  export QUARTERLY_STATUS_UPDATE_RECIPIENT_EMAIL_ADDRESSES="email address"

  export EMAIL_POSTFIX="@company.com"
  ```

### To start your Phoenix app:
  * Install dependencies with `mix deps.get`
  * Create, migrate and seed your database with `mix ecto.setup`
  * Drop, Create, migrate and seed your database with `mix ecto.reset`
  * Seed the database with `mix ecto.seed`
  * Start Phoenix endpoint with `mix phoenix.server`. Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
  * To run whatever's necessary before committing: `mix commit`
  * Run all espec tests with `mix coveralls.html`
  * Run unit tests with `mix espec --exclude integration`
  * Run integration tests with `mix espec spec/integration/*`

## Coding style
  * In general, follow these [guidelines](https://elixirnation.io/references/elixir-style-guide-as-implemented-by-credo)
  * Use 2 spaces instead of tabs for all indentation
  * Run the `credo` hex package to find issues (credo is a static code analyzer)
  ```bash
  mix credo --strict
  ```
