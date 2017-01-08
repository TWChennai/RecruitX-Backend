defmodule RecruitxBackend.TimexHelperSpec do
  use ESpec.Phoenix, model: RecruitxBackend.TimexHelper

  alias RecruitxBackend.TimexHelper
  alias RecruitxBackend.TimexHelper

  context "compare two times" do
    let :now, do: TimexHelper.utc_now()

    it "should return true if two times are equal" do
      result = TimexHelper.compare(now, now)

      expect(result) |> to(be(true))
    end

    it "should return true if first time is greater than second time" do
      result = TimexHelper.compare((now |> TimexHelper.add(2, :hours)), now)

      expect(result) |> to(be(true))
    end

    it "should return false if first time is less than second time" do
      result = TimexHelper.compare(now, (now |> TimexHelper.add(2, :hours)))

      expect(result) |> to(be(false))
    end
  end
end
