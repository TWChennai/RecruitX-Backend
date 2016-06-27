// Brunch automatically concatenates all files in your
// watched paths. Those paths can be configured at
// config.paths.watched in "brunch-config.js".
//
// However, those files will only be executed if
// explicitly imported. The only exception are files
// in vendor, which are never wrapped in imports and
// therefore are always executed.

// Import dependencies
//
// If you no longer want to use a dependency, remember
// to also remove its path from "config.paths.watched".
import "phoenix_html"

// Import local files
//
// Local files can be imported directly using relative
// paths "./socket" or full ones "web/static/js/socket".

// import socket from "./socket"
// TODO: make this tooltip work for interview Page
// $(document).ready(function(){
//    $('[data-toggle="tooltip"]').tooltip();
// });
var Interview = {
  interviewSignup: function interviewSignup(id) {
    alert("clicked signup");
    $.ajax({
      url: "/panelists",
      method: 'POST',
      data: JSON.stringify({
        "interview_panelist": {
          "interview_id": id,
          "panelist_login_name": $.cookie("username"),
          "panelist_experience": 11,
          "panelist_role": $.cookie("panelist_role")
        }
      }),
      success: function(response) {
        window.location = '/web/';
      },
      headers: {
        "Authorization": '<% @api_key%>',
        "Content-Type": "application/json"
      }
    });
  },
  run: function run() {
    console.log("hello");
  }
};

module.exports = {
  Interview: Interview
};
