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
        var button = $(this);
        
        // find the URL in the link right next to us 
        //var dataurl = button.siblings('a').attr('href');

        // then fetch the data with jQuery
        function onDataReceived(series) {
            // extract the first coordinate pair so you can see that
            // data is now an ordinary Javascript object
            
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
            url: '/statistics/data/fraap016_fs.rutema',
            method: 'GET',
            dataType: 'json',
            success: onDataReceived
        });
    });
})

