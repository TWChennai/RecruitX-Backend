# RecruitxBackend

#### To start with the codebase
After cloning the git repository, you will need the following pre-requisites
  1. Postgres database: Once this is present, create a user with the correct role/permissions using the following psql invocation:

      `create role recruitx login createdb;`

#### Coding style
  1. Use 2 spaces instead of tabs for all indentation
  2. Run the `credo` hex package to find issues (credo is a static code analyzer)

      `mix credo --strict`

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

#### Run Web App
  1. Set up the OKTA_PREVIEW environment to your okta preview (with TW account)
  2. Add a new app - SWA, give login url as http://localhost:4000/login
  3. Click on the app open it to run it

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: http://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
  * JSON API: https://medium.com/@luizvarela1/building-a-phoenix-api-d27902a1450a#.954p7dqx6
