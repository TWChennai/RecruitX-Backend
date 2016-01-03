defmodule RecruitxBackend.CandidateControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  alias RecruitxBackend.Repo
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.Role

  describe "index" do
    let :candidates do
      [
        %Candidate{id: 1, name: "Candidate name1", experience: Decimal.new(1), additional_information: "Candidate addn info1"},
        %Candidate{id: 2, name: "Candidate name2", experience: Decimal.new(2), additional_information: "Candidate addn info2"},
      ]
    end

    before do: allow Repo |> to(accept(:all, fn(_) -> candidates end))
    subject do: action :index

    it do: should be_successful
    it do: should have_http_status(:ok)
    it "should return the array of candidates as a JSON response" do
      response = action(:index)

      expect(response.resp_body) |> to(eq(Poison.encode!(candidates, keys: :atoms!)))
    end
  end

  xdescribe "show" do
    let :candidate, do: %Candidate{id: 1, title: "Candidate title", body: "some body content"}
    before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> candidate end))

    subject do: action :show, %{"id" => 1}
    it do: is_expected |> to(be_successful)

    context "not found" do
      before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> nil end))
      it "raises exception" do
        expect(fn -> action(:show, %{"id" => 1}) end) |> to(raise_exception)
      end
    end
  end

  describe "create" do
    let :role, do: Repo.insert!(%Role{name: "test_role"})
    let :valid_attrs, do: %{name: "some content", experience: Decimal.new(3.3), role_id: role.id, additional_information: "info"}
    let :invalid_attrs, do: %{}
    let :valid_changeset, do: %{:valid? => true}
    let :invalid_changeset, do: %{:valid? => false}

    context "valid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> valid_changeset end))

      subject do: action(:create, valid_attrs)

      it do: should(be_successful)
      it do: should(have_http_status(:ok))
    end

    context "invalid params" do
      before do: allow Repo |> to(accept(:insert, fn(_) -> invalid_changeset end))

      subject do: action(:create, invalid_attrs)

      it do: should(have_http_status(400))
    end
  end
end
