export var Entry = {
  continue: function() {
    var username = document.getElementById("username").value;
    if(!username){
      var error_element = document.getElementById("error")
      error_element.innerHTML = "Username Cannot be Empty";
      return
    }
    document.cookie = "username=" + username;
    window.location = '/login/'
  }
};
