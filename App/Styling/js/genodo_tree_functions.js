/**
 * Phylogenetic tree builder in JavaScript.
 * 
 * Copyright (c) Matt Whiteside 2013.
 *
 * Copyright (c) Jason Davies 2010.
 *  
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *  
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *  
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 *
 * Input is a json-based tree:
 * 
 * {
 *   name: "F",
 *   children: [
 *     {name: "A", length: 0.1},
 *     {name: "B", length: 0.2},
 *     {
 *       name: "E",
 *       length: 0.5,
 *       children: [
 *         {name: "C", length: 0.3},
 *         {name: "D", length: 0.4}
 *       ]
 *     }
 *   ]
 * }
 *
 */

var i = 0;


// Build right-angle branch connectors
function step(d) {
  return (
    "M" + d.source.y + "," + d.source.x +
    "L" + d.source.y + "," + d.target.x +
    "L" + d.target.y + "," + d.target.x);
}

// Build right-angle connectors for zoom
function stepTranslate(d) {
	var sourceX = xzoom(d.source.y),
	sourceY = yzoom(d.source.x),
	targetX = xzoom(d.target.y),
	targetY = yzoom(d.target.x);
	
	  return (
	    "M" + sourceX + "," + sourceY +
	    "L" + sourceX + "," + targetY + 
	    "L" + targetX + "," + targetY);
}

// Event handler for a clicked node
// Can be a leaf or internal node
function selectNode(d, i, source) {
	
	// When source == null, we are in
	// the clicked node.
	// Child nodes will be set to the value
	// of the source node
	
	if(!source) {
		if(d.selected) {
			source = 'uncheck';
		} else {
			source = 'check';
		}
	}
	
	if(source === 'uncheck') {
		d.selected = false;
		vis.selectAll("g#node"+i+".node")
			.select("circle")
			.style("fill", "#fff");
	} else {
		d.selected = true;
		vis.selectAll("g#node"+i+".node")
			.select("circle")
			.style("fill", "lightsteelblue");
	}
		
	if(d.children && d.depth != 0) {
		// Internal non-root node, select all children
		d.children.forEach(function(c) {
			selectNode(c, c.id, source);
		});
	}
}

//Event handler for a clicked leaf node
function selectLeafNode(id, name, label, clickOn) {
	
	// If check not specified, toggle value
	if(!clickOn) {
		if(selectedNodes[id]) {
			clickOn = 'uncheck';
		} else {
			clickOn = 'check';
		}
	}
	
	if(clickOn == 'check') {
		selectedNodes[id] = true;
		vis.selectAll("g#node"+id+".node")
			.select("circle")
			.style("fill", "lightsteelblue");
	} else {
		if(selectedNodes[id]) {
			delete selectedNodes[id];
		}
		
		vis.selectAll("g#node"+id+".node")
			.select("circle")
			.style("fill", "#fff");
		
	}
			
	updateSelectedList(id, name, label, clickOn);
}

function updateSelectedList(node_id, genome_id, label, checked) {
	
	var selectedList = $('#tree-selected-genomes');
	
	if(checked == 'check') {
		// Add checked genome
		var newItem = selectedList.append(
		    	'<li>'+
				'<label class="checkbox" for="tree-genome'+node_id+'"><input id="tree-genome'+node_id+'" type="hidden" value="'+genome_id+'" name="genomes-in-tree"/>'+label+
				'  <a href="#" title="delete" class="treeGenomeDelete"><span style="font-size: small">[x]</span></a>'+
				'</label>'+			
				'</li>'
			);
		
		// Register click event
		newItem.find('a').click(function (event) {
			event.preventDefault();
			
		    deleteInList(node_id);
		    
		    return false;
		});
	} else {
		// Remove unchecked genome
		selectedList.find('#tree-genome'+node_id).closest('li').remove();
	}
}

// User is deleting a genome from the tree list and not by clicking in a tree node
function deleteInList(id) {
	
		selectLeafNode(id, null, null, 'uncheck');
}


// Change node name in selectedGenome div when clicked
function selectSingleNode(d) {
	
	if(d.leaf) {
		// Can only select leaf nodes
		$("#dialog-genome-select")
			.text('Would you like to retrieve genome information for the selected genome: '+d.label+'?')
			.data('genome', d.name)
	     	.dialog('open');
	}
}

//Redraw tree after user selects to expand/collapse node
function expandCollapse(d, el, centerOnFocus, multiSelect) {
	
	if (d.children) {
		d._children = d.children;
		d.children = null;
	} else {
		d.children = d._children;
		d._children = null;
	}
	
	update(d, centerOnFocus, multiSelect);
	
	if(d.children) {
		// Hide label when the node is clicked
		d3.select(el).select("text")
			.transition()
			.duration(duration)
	    	.style("fill-opacity", 1e-6);
	}
}

//Redraw tree after user selects to expand/collapse node
function update(source, centerOnFocus, multiSelect) {
	
	if(typeof centerOnFocus === 'undefined') {
		centerOnFocus = false;
	}
	
	if(typeof multiSelect === 'undefined') {
		multiSelect = false;
	}
	
	//var branch_scale_factor_y = 7;
	//var branch_scale_factor_x = 1.5;
	
	// Re-compute tree
	//var nodes = cluster.nodes(root);
	nodes = cluster.nodes(root);
	
	// Scale branch lengths
	var farthest = d3.max(nodes, function(d) { return d.sum_length; });
	var lowest = d3.max(nodes, function(d) { return d.x; });
	
	var branch_scale_factor_y = (width - 20)/farthest;
	var branch_scale_factor_x = (height - 20)/lowest;
	nodes.forEach(function (d) { d.y = d.sum_length * branch_scale_factor_y; d.x = d.x * branch_scale_factor_x; });
	
	console.log('far: '+farthest);
	console.log('low: '+lowest);
	console.log('width: '+width);
	console.log('height: '+height);
	console.log('scaley: '+branch_scale_factor_y);
	console.log('scalex: '+branch_scale_factor_x);
	
	// Shift tree to make room for new level if expansion
	
	// If centerOnFocus == true, use focus node to position tree
	if(centerOnFocus == true) {
		source = nodes.filter(function(d) { return d.focus; } )[0];
		source.x0 = height / 2;
		source.y0 = 0;
	}
	var yshift = null;
	var xshift1 = null;
	var xshift2 = null;
	if(source.children) {
		var maxy = d3.max(source.children, function(d) { return d.y; });
		if(maxy > width)
			yshift = maxy - width;
		
		var maxx = d3.max(source.children, function(d) { return d.x; });
		if(maxx > height)
			xshift1 = maxx - height;
		
		var minx = d3.min(source.children, function(d) { return d.x; });
		if(minx < 0)
			xshift2 = minx+2;
	} else {
		var maxy = source.y;
		if(maxy > width)
			yshift = maxy - width;
		
		var maxx = source.x;
		if(maxx > height)
			xshift1 = maxx - height;
		
		var minx = source.y;
		if(minx < 0)
			xshift2 = minx+2;
	}
	
	if(yshift) {
		nodes.forEach(function(d) {
	    	d.y = d.y-yshift;
		});
	}
	
	if(xshift1) {
		nodes.forEach(function(d) {
	    	d.x = d.x-xshift1;
		});
	}
	
	if(xshift2) {
		nodes.forEach(function(d) {
	    	d.x = d.x+xshift2;
		});
	}
    
	// Get all nodes and assign ID #'s
	var node = vis.selectAll("g.node")
    	.data(nodes, function(d) { return d.id || (d.id = ++i); });
	
	// Add lines
	var link = vis.selectAll("path.link")
		.data(cluster.links(nodes), function(d) { return d.target.id; });

	var linkEnter = link.enter()
		.insert("path")
		.attr("class", "link")
		.attr("d", function(d) {
			var p = {x: source.x0, y: source.y0};
			return step({source: p, target: p});
		});
	
	// Transition links to their new position.
    link.transition()
        .duration(duration)
        .attr("d", step);

    // Transition exiting nodes to the parent's new position.
    link.exit().transition()
    	.duration(duration)
        .attr("d", function(d) {
        	var o = {x: source.x, y: source.y};
        	return step({source: o, target: o});
        })
        .remove();
		
	
    // Update the nodes...
	
    // Enter any new nodes at the parent's previous position.
    var nodeEnter = node.enter()
    	.append("g")
		.attr("class", "node")
		.attr("id", function(d) { return "node"+d.id })
		.attr("transform", function(d) { return "translate(" + source.y0 + "," + source.x0 + ")"; });
    
    var leaves = nodeEnter.filter(function(d) { return d.leaf; });
    
    leaves.append("circle")
		.attr("r", 1e-6)
		.style("fill", function(d) { return d.selected ? "lightsteelblue" : "#fff"; });
	
    if(multiSelect) {
    	leaves.on("click", function(d) { selectLeafNode(d.id, d.name, d.label); } );
    } else {
    	leaves.on("click", selectSingleNode);
    }
    
    // Remove click response and change formatting of masked nodes.
    var masked = leaves.filter(function(d) { return maskedNodes[d.name]; })
    	.classed('maskedNode', true);
  
    masked.on("click", null);
    
    masked.select("circle")
		.style("fill", "grey");
	
	nodeEnter
		.append("text")
		.attr("dx", ".6em")
		.attr("dy", ".4em")
		.attr("text-anchor", "start")
		.text(function(d) { 
			if(d.leaf)
				return dataLabel(d.name, public_genomes, private_genomes, visableData);
			else
				return d.label
		})
		.style("fill-opacity", 1e-6);
	
	var focusNode = nodeEnter.filter(function(d) { return d.focus; } );
	
	focusNode
    	.select("circle")
		.attr('id', 'focusNodeCircle');

	focusNode
		.select("text")
		.attr('id', 'focusNodeText');
	
	var cmdBox = nodeEnter.filter(function(n) { return !n.leaf })
		.append("rect")
		.attr("width", 1e-6)
		.attr("height",1e-6)
		.attr("y", -4)
		.attr("x", -14)
		.style("fill", "#fff");
	
	cmdBox.on("click", function(d) { expandCollapse(d, this.parentNode, centerOnFocus, multiSelect); } );
	
	var nodeUpdate = node.transition()
    	.duration(duration)
    	.attr("transform", function(d) { return "translate(" + d.y + "," + d.x + ")" });
	
    nodeUpdate.select("circle")
        .attr("r", 4);

    nodeUpdate.filter(function(d) { return !d.children })
    	.select("text")
        .style("fill-opacity", 1);
    
    nodeUpdate.select("rect")
	    .attr("width", 8)
		.attr("height",8)
	    .style("fill", function(d) { return d._children ? "lightsteelblue" : "#fff"; });
    
    // Transition exiting ndoes to the parent's new position.
    var nodeExit = node.exit().transition()
        .duration(duration)
        .attr("transform", function(d) { return "translate(" + source.y + "," + source.x + ")"; })
        .remove();

    nodeExit.select("circle")
        .attr("r", 1e-6);
    
    nodeExit.select("text")
        .style("fill-opacity", 1e-6);
    
    nodeExit.select("rect")
	    .attr("width", 1e-6)
		.attr("height",1e-6);
    
    // Stash old positions for transitions
    nodes.forEach(function(d) {
    	d.x0 = d.x;
    	d.y0 = d.y;
    });
    
}

// Identify selected nodes
function submitSelection() {
	var node = vis.selectAll("g.node").filter(function(d) { return d.selected && !d.children && !d._children });
	
	var list = [];
	node.each(function (n) { list.push(n.name); } );
	alert("SUBMITTING: "+list);
}


// Update labels
//Expects global variables public_genomes and private_genomes
//to be defined.
function modifyLabels(vdata) {
	
	vdata = (typeof vdata !== 'undefined' || vData.length == 0) ? vdata : ['name'];
	
	visableData = vdata;
	
	// Add text
	var label = vis.selectAll("text")
		.text(function(d) { 
			if(d.leaf)
				return dataLabel(d.name, public_genomes, private_genomes, vdata);
			else
				return d.label
		});
}

// Builds label for a given node given a visible data-type array
function dataLabel(node, public_genomes, private_genomes, vdata) {
	
	var node_data;
	if(/^public_/.test(node)) {
		node_data = public_genomes[node]
	} else {
		node_data = private_genomes[node]
	}
	
	if(typeof node_data === 'undefined') {
		return "Unrecognized node";
	}
	
	var label = [];
	
	if(vdata.indexOf('name') != -1) {
		label.push(node_data.uniquename);
	}
	
	if(vdata.indexOf('accession') != -1) {
		if(typeof node_data.primary_dbxref !== 'undefined') {
			label.push(node_data.primary_dbxref);
		} else {
			label.push('NA');
		}
		
	}
	
	var metaDataTypes = ['strain', 'serotype', 'isolation_host', 'isolation_source', 'isolation_date'];
	
	for(var i=0; i<metaDataTypes.length; i++) {
		
		var x = metaDataTypes[i];
		
		if(vdata.indexOf(x) != -1) {
			
			if(typeof node_data[x] !== 'undefined') {
				
				var sublabel = [];
				
				for(var j=0; j<node_data[x].length; j++) {
					sublabel.push(node_data[x][j]);
				}
				var sublabel_string = sublabel.join();
				label.push(sublabel_string);
					
			} else {
				label.push('NA');
			}
		}
	}
	
	return label.join('|');
}

function zoomed(d) {

    vis.selectAll("g.node")
    	.attr("transform", transform);
    
    vis.selectAll("path.link")
    	.attr("d", stepTranslate);
}

function transform(d) {
    return "translate(" + xzoom(d.y) + "," + yzoom(d.x) + ")";
}

function legend() {
	var m = {top: 10, right: 10, bottom: 10, left: 10},
	w = 310 - m.right - m.left,
	h = 100 - m.top - m.bottom;
    
	var legend = d3.select("#legend").append("svg")
		.attr("width", w)
		.attr("height", h)
		.style("-webkit-backface-visibility", "hidden");

	var canvas = legend.append("g")
		.attr("transform", "translate(" + m.left + "," + m.top + ")");
	
	var circ = canvas.append("g")
		.attr("class", "legend")
		.attr("transform", function(d) { return "translate(10,10)"; });
	
	circ.append("circle")	
		.attr("r", 5);
	
	circ.append("text")
		.attr("dx", "1em")
		.attr("dy", ".4em")
		.attr("text-anchor", "start")
		.text("Click to select")
	
	var rec = canvas.append("g")
		.attr("class", "legend")
		.attr("transform", function(d) { return "translate(150,15)"; });
	
	rec.append("rect")
		.attr("width", 10)
		.attr("height",10)
		.attr("y", -10)
		.attr("x", -5)
		.attr("fill", "#fff")
	
	rec.append("text")
		.attr("dx", "1em")
		.attr("dy", "-.1em")
		.attr("text-anchor", "start")
		.text("Click to collapse")
		
	var rec = canvas.append("g")
		.attr("class", "legend")
		.attr("transform", function(d) { return "translate(10,40)"; });
	
	rec.append("rect")
		.attr("width", 10)
		.attr("height",10)
		.attr("y", -10)
		.attr("x", -5)
		.attr("fill", "lightsteelblue")
	
	rec.append("text")
		.attr("dx", "1em")
		.attr("dy", "-.1em")
		.attr("text-anchor", "start")
		.text("Click to expand")
		
	var rec = canvas.append("g")
		.attr("class", "legend")
		.attr("transform", function(d) { return "translate(10,63)"; });
	
	rec.append("text")
		.attr("y", 0)
		.attr("x", 0)
		.attr("dx", -7)
		.attr("dy", "0")
		.attr("text-anchor", "start")
		.text("Click and drag to pan / Mouse wheel to zoom");

}

// masking Node changes its format and stops any click events
function maskNode(nodeName, turnOn) {
	
	var foundNode = nodes.filter(function(d) { return d.name == nodeName; });
	
	if(foundNode.length == 1) {
		// Node is in current view, update its format
		var node = foundNode[0];
		
		if(turnOn) {
			// Add mask
			var el = vis.selectAll("g#node"+node.id+".node")
				.classed("maskedNode", true);
			
			el.on("click", null );
			
			el.select("circle")
				.style("fill", "grey");
			
		} else {
			// Restore to normal node
			var el = vis.selectAll("g#node"+node.id+".node")
				.classed("maskedNode", false);
			
			el.on("click", function() { selectLeafNode(node.id, node.name, node.label); } );
			
			el.select("circle")
				.style("fill", function() { return node.selected ? "lightsteelblue" : "#fff"; });
			
		}
	}
		
	// Update masked node list
	if(turnOn) {
		maskedNodes[nodeName] = true;
	} else {
		if(maskedNodes[nodeName]) {
			delete maskedNodes[nodeName];
		}
	}
	
}
