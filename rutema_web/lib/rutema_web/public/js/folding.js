function toggleFolding(container,container_parent,prepend_txt,link){
	$(container).hide();
	$(container).parents(container_parent).prepend(prepend_txt);
	$(link).click(function(event){
		$(this).parents(container_parent).children(container).toggle();
		// Stop the link click from doing its normal thing
		event.preventDefault();
	});
};

function setupFolding()
{
	toggleFolding(".scenario_output","td","<a class=\"output_link\" href='' title='read the output log'>output</a>","a.output_link");
	toggleFolding(".scenario_error","td","<a class=\"error_link\" href='' title='read the error log'>errors</a>","a.error_link");
	
};
