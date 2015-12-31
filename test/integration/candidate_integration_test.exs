defmodule RecruitxBackend.CandidateIntegrationTest do

    use RecruitxBackend.ConnCase, async: false
    @moduletag :integration
    alias RecruitxBackend.Candidate
    alias RecruitxBackend.Repo

    #TODO :Ignoring the test as api has not been wired to model 
    @doc """
    test "get /candidates returns a list of candidates" do
        candidate = %{"name" => "test", "experience" => Decimal.new(2), "role_id" => 1}
        Repo.insert(Candidate.changeset(%Candidate{}, candidate))

        response = get conn(), "/candidates"

        assert json_response(response, 200) === [candidate]
    end

    test "POST /candidates with valid post parameters" do
        conn = post conn(), "/candidates", [name: "test"]
        assert conn.status == 200
        # TODO: Validate that the count in the table has increased by 1
    end
    """

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
