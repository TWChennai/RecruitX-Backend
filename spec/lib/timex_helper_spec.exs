defmodule RecruitxBackend.TimexHelperSpec do
  use ESpec.Phoenix, model: RecruitxBackend.TimexHelper

  alias RecruitxBackend.TimexHelper

  context "compare two times" do
    let :now, do: TimexHelper.utc_now()

    it "should return true if two times are equal" do
      result = TimexHelper.compare(now(), now())

      expect(result) |> to(be(true))
    end

    it "should return true if first time is greater than second time" do
      result = TimexHelper.compare(TimexHelper.add(now(), 1, :minutes), now())

      expect(result) |> to(be(true))
    end

    it "should return false if first time is less than second time" do
      result = TimexHelper.compare(now(), TimexHelper.add(now(), 1, :minutes))

      expect(result) |> to(be(false))
    end
  end

  context "add utc timezone by default" do
    it "should add if not present" do
      result = TimexHelper.add_timezone_if_not_present(%{start_time: "2017-01-20 09:20:00"})

      expect(result) |> to(be(%{start_time: "2017-01-20T09:20:00Z"}))
    end

    it "should not add if present" do
      result = TimexHelper.add_timezone_if_not_present(%{start_time: "2017-01-20T09:20:00Z"})

      expect(result) |> to(be(%{start_time: "2017-01-20T09:20:00Z"}))
    end

    it "should not add if present" do
      now = TimexHelper.utc_now()
      result = TimexHelper.add_timezone_if_not_present(%{start_time: now})

      expect(result) |> to(be(%{start_time: now}))
    end
  end
end
