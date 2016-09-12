export var Slot = {
  cancel: function() {
    var error_element = document.getElementById("slotSignupError");
    error_element.innerHTML = "";
    error_element.className = "";
  },
  signup: function(id, api_key) {
    var error_element = document.getElementById("slotSignupError");
    var panelist_experience = this.calculate_years_difference(new Date(), new Date($.cookie("calculated_hire_date")));
    $.ajax({
      url: "/panelists",
      method: 'POST',
      data: JSON.stringify({
        "slot_panelist": {
          "slot_id": id,
          "panelist_login_name": $.cookie("username"),
          "panelist_experience": panelist_experience,
          "panelist_role": $.cookie("panelist_role")
        }
      }),
      success: function(response) {
        window.location = '/my_interviews';
      },
      headers: {
        "Authorization": api_key,
        "Content-Type": "application/json"
      },
      error: function(error) {
        error_element.innerHTML = "Something went wrong! Please try again later!";
        error_element.className += "alert alert-danger";
      },
    });
  },
  calculate_years_difference: function(date1, date2) {
    return Math.round(Math.abs(date1.getTime() - date2.getTime()) / (1000 * 3600 * 24 * 365));
  }
};
