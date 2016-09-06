export var Entry = {
  continue: function() {
    var username = document.getElementById("username").value;
    var isnum = /^\d+$/.test(username);
    var error_element = document.getElementById("error")
    if(isnum)
    {
      error_element.innerHTML = "Username cannot be a number!";
      return
    }
    if(!username){
      error_element.innerHTML = "Username Cannot be Empty!";
      return
    }
    document.cookie = "username=" + username;
    window.location = '/login/'
  }
};
