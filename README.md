# RecruitxBackend

#### To start with the codebase
After cloning the git repository, you will need the following pre-requisites
  1. Postgres database: Once this is present, create a user with the correct role/permissions using the following psql invocation:

      `create role recruitx login createdb;`

#### Coding style
  1. Use 2 spaces instead of tabs for all indentation
  2. Run the `credo` hex package to find issues (credo is a static code analyzer)

      `mix credo --strict`

#### Dependencies
Ensure you have installed erlang 18.2.1 is installed before proceeding further, to check the erlang version exec `erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().'  -noshell`, you should get "18" as the output

To install erlang 18.2.1 execute:

```bash
brew unlink erlang
brew install https://github.com/Homebrew/homebrew-core/blob/77f353913f1e0edd7ba592308da2aa70e26570e1/Formula/erlang.rb
```

You have to set following environment variables

```rc
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

#### To start your Phoenix app:
  1. Install dependencies with `mix deps.get`
  2. Create, migrate and seed your database with `mix ecto.setup`
  3. Drop, Create, migrate and seed your database with `mix ecto.reset`
  4. Seed the database with `mix run priv/repo/seeds.exs`
  5. Run `brunch build` to build JS and CSS (Only for Web App)
  6. Start Phoenix endpoint with `mix phoenix.server`. Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
  7. To Run the Phoenix Web App refer to #### Run Web App
  8. To run whatever's necessary before committing: `mix commit`
  9. Run all espec tests with `mix espec --cover`
  10. Run unit tests with `mix espec --exclude integration`
  11. Run integration tests with `mix espec spec/integration/*`

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: http://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
  * JSON API: https://medium.com/@luizvarela1/building-a-phoenix-api-d27902a1450a#.954p7dqx6
