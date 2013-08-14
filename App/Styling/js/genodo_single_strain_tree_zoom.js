/**
 * Phylogenetic tree with single select setting
 * 
 * ZOOOM
 *
 */

var margin = {top: 20, right: 180, bottom: 20, left: 20},
    width = 960 - margin.right - margin.left,
    height = 2000 - margin.top - margin.bottom;

var xzoom = d3.scale.linear().domain([0, width]).range([0, width]),
yzoom = d3.scale.linear().domain([0, height]).range([0, height]);

var duration = 1000;

var cluster = d3.layout.cluster()
    .size([width, height])
    .sort(null)
    .value(function(d) { return Number(d.length); })
    .separation(function(a, b) { return 1; });

var wrap = d3.select("#vis").append("svg")
	.attr("width", width + margin.right + margin.left)
	.attr("height", height + margin.top + margin.bottom)
	.style("-webkit-backface-visibility", "hidden");

var vis = wrap.append("g")
	.attr("transform", "translate(" + margin.left + "," + margin.top + ")");

wrap.call(d3.behavior.zoom().x(xzoom).y(yzoom).scaleExtent([1,8]).on("zoom",zoomed));

var root = null,
visableData = ['name'];

// Set up event for view options button
$("#update_view").click(function(event) {
	event.preventDefault();
	
	visibleData = [];
	$("input[name='view_options']:checked").each( function(i, e) { visibleData.push( $( e ).val() ); });
	modifyLabels(visibleData);

	return false;
});


