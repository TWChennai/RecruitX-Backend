defmodule RecruitxBackend.Repo do
  use Ecto.Repo, otp_app: :recruitx_backend
  use Scrivener, page_size: 10
end
