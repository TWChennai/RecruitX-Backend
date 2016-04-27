defmodule RecruitxBackend.Repo do
  use Ecto.Repo, otp_app: :recruitx_backend
  use Scrivener, page_size: 10

  Decimal.set_context(%Decimal.Context{Decimal.get_context | precision: 2, rounding: :half_up})

  def custom_insert, do: &(__MODULE__.insert(&1))
  def custom_update, do: &(__MODULE__.update(&1))
end
