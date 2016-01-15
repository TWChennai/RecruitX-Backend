Code.require_file("#{__DIR__}/phoenix_helper.exs")

ESpec.start

ESpec.configure fn(config) ->
  config.before fn ->
    # Random seed generation from: http://neo.com/2014/02/24/pseudo-random-number-generation-in-elixir/
    << a :: 32, b :: 32, c :: 32 >> = :crypto.rand_bytes(12)
    :random.seed(a, b, c)
    # Get a new random number using: `:random.uniform`

    Faker.start
    #restart transactions
    Ecto.Adapters.SQL.restart_test_transaction(RecruitxBackend.Repo, [])
  end

  # config.finally fn(shared) ->
  # end
end
