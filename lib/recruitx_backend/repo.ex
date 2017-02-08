defmodule RecruitxBackend.Repo do
  use Ecto.Repo, otp_app: :recruitx_backend
  use Scrivener, page_size: 10

  Decimal.set_context(%Decimal.Context{Decimal.get_context | precision: 2, rounding: :half_up})

  # TODO: Remove these methods when the codebase has been converted to use Ecto.Multi
  def custom_insert, do: &(__MODULE__.insert(&1))
  def custom_update, do: &(__MODULE__.update(&1))
end
