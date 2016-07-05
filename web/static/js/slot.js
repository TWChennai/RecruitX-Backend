export var Slot = {
  signup: function(id, api_key) {
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
};
