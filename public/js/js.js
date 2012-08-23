$(document).ready(function() {
  $("#to").live("change", function() { preview(); });
  $("#message").live("keyup", function() { preview(); });
  $("#cancel").click(function(){ cancel(); });
});

function preview() {
  var to = $("#to").val();
  var message = $("#message").val();
  $("#preview").html(to + " " + message);
}

function cancel() {
  if(window.confirm('本当にshikakunをやめますか?')){
		location.href = "/cancel";
	}
}

/*
$(this).click(function(){});
$("nav#global ul li").live("hover", function(){});
*/

function test(a) {
	if(a == null){ a = "alert!" }
	window.alert(a);
}