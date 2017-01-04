Code.require_file("#{__DIR__}/phoenix_helper.exs")

{:ok, _} = Application.ensure_all_started(:ex_machina)

ESpec.start

ESpec.configure fn(config) ->
  config.before fn(tags) ->
    Decimal.set_context(%Decimal.Context{Decimal.get_context | precision: 2, rounding: :half_up})

    Faker.start

    :ok = Ecto.Adapters.SQL.Sandbox.checkout(RecruitxBackend.Repo)
    unless tags[:async], do: Ecto.Adapters.SQL.Sandbox.mode(RecruitxBackend.Repo, {:shared, self()})
  end

  config.finally fn(_shared) ->
    Ecto.Adapters.SQL.Sandbox.checkin(RecruitxBackend.Repo, [])
  end
end
