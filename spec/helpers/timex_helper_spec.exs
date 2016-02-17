defmodule RecruitxBackend.TimexHelperSpec do
  use ESpec.Phoenix, model: RecruitxBackend.TimexHelper

  alias Timex.Date
  alias RecruitxBackend.TimexHelper

  context "compare two times" do
    let :now, do: Date.now()

    it "should return true if two times are equal" do
      result = TimexHelper.compare(now, now)

      expect(result) |> to(be(true))
    end

    it "should return true if first time is greater than second time" do
      result = TimexHelper.compare((now |> Date.shift(hours: 2)), now)

      expect(result) |> to(be(true))
    end

    it "should return false if first time is less than second time" do
      result = TimexHelper.compare(now, (now |> Date.shift(hours: 2)))

      expect(result) |> to(be(false))
    end
  end

end
