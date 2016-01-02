defmodule RecruitxBackend.CandidateIntegrationTest do

    use RecruitxBackend.ConnCase, async: false
    @moduletag :integration
    alias RecruitxBackend.Candidate
    alias RecruitxBackend.Repo
    alias RecruitxBackend.Role

    test "get /candidates returns a list of candidates" do
        role = Repo.insert!(%Role{name: "test_role"})
        candidate = %{"name" => "test", "experience" => Decimal.new(2), "role_id" => role.id}
        Repo.insert(Candidate.changeset(%Candidate{}, candidate))

        response = get conn(), "/candidates"

        assert json_response(response, 200) === [%{"additional_information" => nil, "experience" => "2.00", "name" => "test"}]
    end

    test "POST /candidates with valid post parameters" do
        initial_candidate_count = List.first Repo.all(from c in Candidate, select: count(c.id))
        role = Repo.insert!(%Role{name: "test_role"})

        conn = post conn(), "/candidates", [name: "test", role_id: role.id, experience: Decimal.new(3)]
        final_candidate_count =  List.first Repo.all(from c in Candidate, select: count(c.id))

        assert conn.status == 200
        assert initial_candidate_count + 1 == final_candidate_count
    end

    test "POST /candidates with invalid post parameters should return 400(Bad Request)" do
        initial_candidate_count = List.first Repo.all(from c in Candidate, select: count(c.id))

        conn = post conn(), "/candidates", [invalid: "invalid_post_param"]
        final_candidate_count = List.first Repo.all(from c in Candidate, select: count(c.id))

        assert conn.status == 400
        assert initial_candidate_count == final_candidate_count
    end

    test "POST /candidates with no post parameters should return 400(Bad Request)" do
        initial_candidate_count = List.first Repo.all(from c in Candidate, select: count(c.id))

        conn = post conn(), "/candidates"
        final_candidate_count = List.first Repo.all(from c in Candidate, select: count(c.id))

        assert conn.status == 400
        assert initial_candidate_count == final_candidate_count
    end
end
