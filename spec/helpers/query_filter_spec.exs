defmodule RecruitxBackend.QueryFilterSpec do
  use ESpec.Phoenix, model: RecruitxBackend.QueryFilter

  alias RecruitxBackend.Candidate
  alias RecruitxBackend.QueryFilter
  alias RecruitxBackend.Repo

  before do: Repo.delete_all(Candidate)

  it "should filter fields when their values are passed as arrays" do
    c1 = create(:candidate)
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{role_id: [c1.role_id]}

    [result1] = QueryFilter.filter(query, filters, model) |> Repo.all

    expect(result1.role_id) |> to(eql(c1.role_id))
  end

  it "should filter fields when their values are not passed as arrays" do
    c1 = create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{role_id: c1.role_id}

    [result1] = QueryFilter.filter(query, filters, model) |> Repo.all

    expect(result1.role_id) |> to(eql(c1.role_id))
  end

  it "should filter multiple fields when their values are passed as arrays" do
    c1 = create(:candidate)
    c2 = create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{role_id: [c1.role_id], first_name: [c1.first_name, c2.first_name]}

    [result1] = QueryFilter.filter(query, filters, model) |> Repo.all

    expect(result1.first_name) |> to(eql(c1.first_name))
  end

  it "should filter fields when their values are strings" do
    c1 = create(:candidate)
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{first_name: [c1.first_name]}

    [result1] = QueryFilter.filter(query, filters, model) |> Repo.all

    expect(result1.first_name) |> to(eql(c1.first_name))
  end

  it "should filter fields with like matches when their values are strings" do
    c1 = create(:candidate)
    c2 = create(:candidate, first_name: "#{c1.first_name}extension")
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{first_name: ["#{c1.first_name}%"]}

    [result1, result2] = QueryFilter.filter(query, filters, model) |> Repo.all

    expect(result1.first_name) |> to(eql(c1.first_name))
    expect(result2.first_name) |> to(eql(c2.first_name))
  end

  it "should not modify query when invalid fields are passed" do
    create(:candidate)
    query = Ecto.Query.from c in Candidate
    model = Candidate
    filters = %{dummy: ['a']}

    result_query = QueryFilter.filter(query, filters, model)

    expect(result_query) |> to(eql(query))
  end
end
