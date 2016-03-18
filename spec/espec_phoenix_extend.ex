defmodule ESpec.Phoenix.Extend do
  def model do
    quote do
      alias RecruitxBackend.Repo
      import RecruitxBackend.Factory
      import RecruitxBackend.TestHelpers
      import Ecto.Query, only: [from: 2, where: 2, preload: 2]
    end
  end

  def controller do
    quote do
      alias RecruitxBackend.Repo
      import RecruitxBackend.Router.Helpers
      import RecruitxBackend.Factory
      import RecruitxBackend.TestHelpers
      import Ecto.Query, only: [from: 1, from: 2, where: 2]
    end
  end

  def request do
    quote do
      alias RecruitxBackend.Repo
      import RecruitxBackend.Router.Helpers
      import RecruitxBackend.Factory
      import RecruitxBackend.TestHelpers
    end
  end

  def view do
    quote do
      import RecruitxBackend.Router.Helpers
      import RecruitxBackend.Factory
      import RecruitxBackend.TestHelpers
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
