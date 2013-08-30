/**
 * Phylogenetic tree with single select setting
 *
 *
 */

var w, h;

if(smallTreeWindow == true) {
	w = 500,
	h = 800;
} else {
	w = 960,
	h = 1400;
}

var margin = {top: 20, right: 180, bottom: 20, left: 20},
    width = w - margin.right - margin.left,
    height = h - margin.top - margin.bottom;

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

var maskedNodes = {};  // A dictionary object for keeping track of masked nodes
var selectedNodes = {}; // A dictionary object for keeping track of selected nodes
var nodes;  // A pointer to the nodes created by the cluster call


