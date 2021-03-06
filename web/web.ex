defmodule RecruitxBackend.Web do
  @moduledoc """
  A module that keeps using definitions for controllers,
  views and so on.

  This can be used in your application as:

      use RecruitxBackend.Web, :controller
      use RecruitxBackend.Web, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below.
  """

  def model do
    quote do
      use Ecto.Schema

      alias RecruitxBackend.Repo
      import Ecto
      import Ecto.Changeset
      import Ecto.Query, only: [from: 1, from: 2, where: 2, where: 3, preload: 3]

      def all, do: Repo.all(__MODULE__)
      def count, do: Repo.aggregate(__MODULE__, :count, :id)
      def max(key), do: Repo.aggregate(__MODULE__, :max, key) || 0
      def is_not_nil(value), do: !is_nil(value)
    end
  end

  def controller do
    quote do
      use Phoenix.Controller

      alias RecruitxBackend.Repo
      import Ecto
      import Ecto.Query, only: [from: 1, from: 2, preload: 2, order_by: 2]

      import RecruitxBackend.Router.Helpers
      import RecruitxBackend.Gettext
    end
  end

  def view do
    quote do
      use Phoenix.View, root: "web/templates"

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_csrf_token: 0, get_flash: 2, view_module: 1]

      import RecruitxBackend.Router.Helpers
      import RecruitxBackend.ErrorHelpers
      import RecruitxBackend.Gettext
    end
  end

  def router do
    quote do
      use Phoenix.Router
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
