defmodule RecruitxBackend.CandidateControllerTest do
    use RecruitxBackend.ConnCase

    test "GET /candidate" do
        conn = get conn(), "/candidate"

        assert conn.status == 200
        assert json_response(conn, 200) === %{"name" => "hello"}
    end



end