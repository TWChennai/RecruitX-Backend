defmodule RecruitxBackend.CandidateControllerTest do
    use RecruitxBackend.ConnCase, async: false

    alias RecruitxBackend.Candidate

    test "get /candidates returns a list of candidates" do
        candidate = %{"name" => "test"}
        Candidate.insert(candidate)

        response = get conn(), "/candidates"

        assert json_response(response, 200) === Candidate.to_json([candidate])
    end

    test "POST /candidates with valid post parameters" do
        conn = post conn(), "/candidates", [name: "test"]
        assert conn.status == 200
    end

    test "POST /candidates with invalid post parameters should return 400(Bad Request)" do
        conn = post conn(), "/candidates", [invalid: "invalid_post_param"]
        assert conn.status == 400
    end

    test "POST /candidates with no post parameters should return 400(Bad Request)" do
        conn = post conn(), "/candidates"
        assert conn.status == 400
    end
end