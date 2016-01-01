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
        role = Repo.insert!(%Role{name: "test_role"})

        conn = post conn(), "/candidates", [name: "test", role_id: role.id, experience: Decimal.new(3)]

        assert conn.status == 200
        # TODO: Validate that the count in the table has increased by 1
    end

    test "POST /candidates with invalid post parameters should return 400(Bad Request)" do
        conn = post conn(), "/candidates", [invalid: "invalid_post_param"]

        assert conn.status == 400
        # TODO: Validate that the count in the table has remained the same
    end

    test "POST /candidates with no post parameters should return 400(Bad Request)" do
        conn = post conn(), "/candidates"

        assert conn.status == 400
        # TODO: Validate that the count in the table has remained the same
    end
end
