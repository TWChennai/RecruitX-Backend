export var Slot = {
  signup: function(id, api_key) {
    var panelist_experience = this.calculate_years_difference(new Date(), new Date($.cookie("calculated_hire_date")));
    if (confirm("Are you sure, you want to signup?")) {
      $.ajax({
        url: "/panelists",
        method: 'POST',
        data: JSON.stringify({
          "slot_panelist": {
            "slot_id": id,
            "panelist_login_name": $.cookie("username"),
            "panelist_experience": 11,
            "panelist_role": $.cookie("panelist_role")
          }
        }),
        success: function(response) {
          window.location = '/homepage';
        },
        headers: {
          "Authorization": api_key,
          "Content-Type": "application/json"
        }
      });
    }
  },
  calculate_years_difference: function(date1, date2) {
    return Math.round(Math.abs(date1.getTime() - date2.getTime()) / (1000 * 3600 * 24 * 365));
  }
};
