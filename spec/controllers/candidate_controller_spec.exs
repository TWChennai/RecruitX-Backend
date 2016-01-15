defmodule RecruitxBackend.CandidateControllerSpec do
  use ESpec.Phoenix, controller: RecruitxBackend.CandidateController

  import RecruitxBackend.Factory

  alias RecruitxBackend.Candidate

  describe "index" do
    let :candidates do
      [
        build(:candidate, additional_information: "Candidate addn info1"),
        build(:candidate, additional_information: "Candidate addn info2"),
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

    subject do: action(:show, %{"id" => 1})

    it do: is_expected |> to(be_successful)

    context "not found" do
      before do: allow Repo |> to(accept(:get!, fn(Candidate, 1) -> nil end))
      it "raises exception" do
        expect(fn -> action(:show, %{"id" => 1}) end) |> to(raise_exception)
      end
    end
  end

  describe "create" do
    let :valid_attrs, do: %{"candidate" => fields_for(:candidate, role_id: create(:role).id, additional_information: "info")}
    let :invalid_attrs, do: %{"candidate" => %{}}
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
