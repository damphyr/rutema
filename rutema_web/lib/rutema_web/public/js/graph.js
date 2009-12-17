$(function () {
    var options = {
		stack: true,
		bars: { show: true },
        xaxis: { tickDecimals: 0, tickSize: 1 }
    };
    var data = [];
    var placeholder = $("#placeholder");
    
    $.plot(placeholder, data, options);
 
    $("input.fetchSeries").click(function () {
        //var button = $(this);
        
        // find the URL in the link right next to us 
        var dataurl = '/statistics/data/' + this.value;

        // then fetch the data with jQuery
        function onDataReceived(series) {
            // and plot all we got
            $.plot(placeholder, series, {
			            series: {
			                stack: true,
			                bars: { show: true, barWidth: 0.6 },
			            },
						legend: {position:'sw'}
			});
         }
        
        $.ajax({
            url: dataurl,
            method: 'GET',
            dataType: 'json',
            success: onDataReceived
        });
    });
})

