defmodule RecruitxBackend.QueryFilterSpec do
  use ESpec.Phoenix, model: RecruitxBackend.QueryFilter

  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.Interview
  alias RecruitxBackend.Candidate
  alias RecruitxBackend.CandidateSkill
  alias RecruitxBackend.Repo

  before do: Repo.delete_all Interview
  before do: Repo.delete_all CandidateSkill
  before do: Repo.delete_all Candidate

  it "should filter fields when their values are passed as arrays" do
    c1 = create(:candidate)
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{role_id: [c1.role_id]}

    [result1] = QueryFilter.filter_new(query, filters, model) |> Repo.all

    expect(result1.role_id) |> to(eql(c1.role_id))
  end

  it "should filter multiple fields when their values are passed as arrays" do
    c1 = create(:candidate)
    c2 = create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{role_id: [c1.role_id], name: [c1.name, c2.name]}

    [result1] = QueryFilter.filter_new(query, filters, model) |> Repo.all

    expect(result1.name) |> to(eql(c1.name))
  end

  it "should filter fields when their values are strings" do
    c1 = create(:candidate)
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{name: [c1.name]}

    [result1] = QueryFilter.filter_new(query, filters, model) |> Repo.all

    expect(result1.name) |> to(eql(c1.name))
  end

  it "should filter fields with like matches when their values are strings" do
    c1 = create(:candidate)
    c2 = create(:candidate, name: "#{c1.name}extension")
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{name: ["#{c1.name}%"]}

    [result1, result2] = QueryFilter.filter_new(query, filters, model) |> Repo.all

    expect(result1.name) |> to(eql(c1.name))
    expect(result2.name) |> to(eql(c2.name))
  end

  it "should not modify query when invalid fields are passed" do
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{dummy: ['a']}

    result_query = QueryFilter.filter_new(query, filters, model)

    expect(result_query) |> to(eql(query))
  end
end
