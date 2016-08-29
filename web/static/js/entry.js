export var Entry = {
  continue: function() {
    var username = document.getElementById("username").value;
    document.cookie = "username=" + username;
    window.location = '/login/'
  }
};
