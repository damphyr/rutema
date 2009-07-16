function toggleFolding(){
	$(".scenario_output").hide();
	$(".scenario_error").hide();
	$(".scenario_output").parents("td").prepend("<a class=\"output_link\" href='' title='read the output log'>output</a>");
	$(".scenario_error").parents("td").prepend("<a class=\"error_link\" href='' title='read the error log'>errors</a>");
	$("a.output_link").click(function(event){
		$(this).parents("td").children(".scenario_output").toggle();
		// Stop the link click from doing its normal thing
		event.preventDefault();
	});
	$("a.error_link").click(function(event){
		$(this).parents("td").children(".scenario_error").toggle();
		// Stop the link click from doing its normal thing
		event.preventDefault();
	});
};