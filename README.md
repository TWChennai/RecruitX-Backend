# RecruitxBackend

#### To start with the codebase
After cloning the git repository, you will need the following pre-requisites
  1. Postgres database: Once this is present, create a user with the correct role/permissions using the following psql invocation:

      `create role recruitx login createdb;`

#### Coding style
2 spaces instead of tabs for all indentation

#### To start your Phoenix app:

  1. Install dependencies with

      `mix deps.get`
  2. Create and migrate your database with

      `mix ecto.create && mix ecto.migrate`
  3. To seed the database, run

      `mix run priv/repo/seeds.exs`

     or when you need in production:

      `MIX_ENV=prod mix run priv/repo/seeds.exs`
  4. Start Phoenix endpoint with

      `mix phoenix.server`

     Now you can visit [`localhost:4000`](http://localhost:4000) from your browser.
  5. Run all exunit tests with `mix test`
  6. Run unit tests with `mix test --exclude integration`
  7. Run integration tests with `mix test test/integration/*`

Ready to run in production? Please [check our deployment guides](http://www.phoenixframework.org/docs/deployment).

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: http://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix
