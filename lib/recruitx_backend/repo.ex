defmodule RecruitxBackend.Repo do
  use Ecto.Repo, otp_app: :recruitx_backend
  use Scrivener, page_size: 10

  Decimal.set_context(%Decimal.Context{Decimal.get_context | precision: 2, rounding: :half_up})
end
