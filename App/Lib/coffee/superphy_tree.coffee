###


 File: superphy_tree.coffee
 Desc: Phylogenetic Tree View Class
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: March 20th, 2013
 
 
###
 
# Add D3 method to move node to top
d3.selection.prototype.moveToFront = ->
  @.each( -> @.parentNode.appendChild(@) )

###
 CLASS TreeView
  
 Phylogenetic tree view
 
###

class TreeView extends ViewTemplate
  constructor: (@parentElem, @style, @elNum, treeArgs) ->
    
    throw new SuperphyError 'Missing argument. TreeView constructor requires JSON tree object.' unless treeArgs.length > 0
    
    @root = @trueRoot = treeArgs[0]
    
    @dim={w: 500, h: 800}
    @margin={top: 20, right: 180, bottom: 20, left: 20}
    @dim = treeArgs[1] if treeArgs[1]?
    @margin = treeArgs[2] if treeArgs[2]?
                  
    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum)
    
    # Setup and attach SVG viewport
    
    # Dimensions
    @width = @dim.w - @margin.right - @margin.left
    @height = @dim.h - @margin.top - @margin.bottom
    @xzoom = d3.scale.linear().domain([0, @width]).range([0, @width])
    @yzoom = d3.scale.linear().domain([0, @height]).range([0, @height])
    
    # Tree layout rendering object
    @cluster = d3.layout.cluster()
      .size([@width, @height])
      .sort(null)
      .value((d) -> Number(d.length) )
      .separation((a, b) -> 1)
    
    # SVG layer
    @parentElem.append("<div id='tree-viewport'></div>")
    @wrap = d3.select("#tree-viewport").append("svg")
      .attr("width", @dim.w)
      .attr("height", @dim.h)
      .style("-webkit-backface-visibility", "hidden")
    
    # Parent element for attaching tree elements
    @canvas = @wrap.append("g")
      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")

    # Build viewport
    num = @elNum - 1;
    @wrap.call(
      d3.behavior.zoom()
        .x(@xzoom)
        .y(@yzoom)
        .scaleExtent([1,8]).on("zoom", -> viewController.getView(num).zoomed())
    )
    
    # Attach a clade dialog
    if @style is 'select'
      dialog = jQuery('#dialog-clade-select')
      unless dialog.length
        dialog = jQuery('<div id="dialog-clade-select"></div>').appendTo('body')
        dialog
          .text("Select/unselect genomes in clade:")
          .dialog({
            title: 'Select clade',
            autoOpen: false,
            resizable: false,
            height:160,
            modal: true,
            buttons: {
              Select: ->
                node = jQuery( @ ).data("clade-node")
                viewController.getView(num).selectClade(node, true)
                jQuery( @ ).dialog( "close" )
              Unselect: ->
                node = jQuery( @ ).data("clade-node")
                viewController.getView(num).selectClade(node, false)
                jQuery( @ ).dialog( "close" )
              Cancel: ->
                jQuery( @ ).dialog( "close" )
            }
          })
        
    
    # Add properties to tree nodes
    @_prepTree()
    
    true
    
  type: 'tree'
  
  elName: 'genome_tree'
  
  nodeId: 0
  
  duration: 1000
  
  
  
  # FUNC update
  # Update genome tree view
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  update: (genomes, sourceNode=null) ->
    
    t1 = new Date()
    
    # save old root, might require updating
    oldRoot = @root
    
    # filter visible, set selected, set class, set viewname
    # changes @root object
    @_sync(genomes)
    
    # find starting point to launch new nodes/links
    sourceNode = @root unless sourceNode?
    @launchPt = {x: sourceNode.x, y: sourceNode.y, x0: sourceNode.x0, y0: sourceNode.y0}
    
    # Compute layout, return D3 node objects
    @nodes = @cluster.nodes(@root)
    
    # Scale branch lengths
    farthest = d3.max(@nodes, (d) -> d.sum_length * 1)
    lowest = d3.max(@nodes, (d) -> d.x )
  
    branch_scale_factor_y = (@width - 20)/farthest
    branch_scale_factor_x = (@height - 20)/lowest
    
    for n in @nodes
      n.y = n.sum_length * branch_scale_factor_y
      n.x = n.x * branch_scale_factor_x
    
    # Collect existing nodes and create needed new nodes
    svgNodes = @canvas.selectAll("g.treenode")
      .data(@nodes, (d) -> d.id )
      
    # Compute connector layout
    svgLinks = @canvas.selectAll("path.treelink")
      .data(@cluster.links(@nodes), (d) -> d.target.id )
      
    # Insert new connectors
    linksEnter = svgLinks.enter()
      .insert("path")
      .attr("class", "treelink")
      .attr("d", (d) =>
        p = {x: @launchPt.x0, y: @launchPt.y0}
        @_step({source: p, target: p})
      )
    
    # Final position of all branches
    svgLinks.transition()
      .duration(@duration)
      .attr("d", @_step);

    # Transition exiting connectors to the parent nodes new position.
    svgLinks.exit().transition()
      .duration(@duration)
        .attr("d", (d) => 
          o = {x: @launchPt.x, y: @launchPt.y}
          @_step({source: o, target: o})
        )
        .remove()
        
    # Update existing node's text, classes, style and events
    # Only leaf nodes will change
    currLeaves = svgNodes.filter((d) -> d.leaf)
      .attr("class", (d) => @_classList(d))
      .on("click", (d) ->
        unless d.assignedGroup?
          viewController.select(d.name, !d.selected)
        else
          null
      )
      
    currLeaves.select("text")
      .text((d) ->
        d.viewname
      )
       
    currLeaves.select("circle")
      .style("fill", (d) -> 
        if d.selected
          "lightsteelblue"
        else
          "#fff"
      )   

    # Insert nodes
    # Enter any new nodes at the parent's previous position.
    nodesEnter = svgNodes.enter()
      .append("g")
      .attr("class", (d) => @_classList(d))
      .attr("id", (d) -> "treenode"+d.id )
      .attr("transform", (d) => "translate(" + @launchPt.y0 + "," + @launchPt.x0 + ")" )
      
    leaves = nodesEnter.filter( (d) -> d.leaf )
    
    leaves.append("circle")
      .attr("r", 1e-6)
      .style("fill", (d) -> 
        if d.selected
          "lightsteelblue"
        else
          "#fff"
      )
    
    if @style is 'select'
      leaves.on("click", (d) ->
        unless d.assignedGroup?
          viewController.select(d.name, !d.selected)
        else
          null
      )
    else
      leaves.on("click", viewController.redirect(d.name))
      
    nodesEnter
      .append("text")
      .attr("class","treelabel")
      .attr("dx", ".6em")
      .attr("dy", ".4em")
      .attr("text-anchor", "start")
      .text((d) ->
        if d.leaf
          d.viewname
        else
          d.label
      )
      .style("fill-opacity", 1e-6)
  
    # Append command elements to new internal nodes
    iNodes = nodesEnter.filter((n) -> !n.leaf && !n.root )
    num = @elNum-1
    
    # expand/collapse box
    cmdBox = iNodes
      .append("rect")
      .attr("width", 1e-6)
      .attr("height",1e-6)
      .attr("y", -4)
      .attr("x", -12)
      .style("fill", "#fff")
  
    cmdBox.on("click", (d) -> 
      viewController.viewAction(num, 'expand_collapse', d, @.parentNode) 
    )
    
    # select/unselect clade
    if @style is 'select'
      # select
      cladeIcons = iNodes
        .append('text')
        .attr("class","treeicon")
        .attr("text-anchor", 'middle')
        .attr("y", 4)
        .attr("x", -20)
        .text((d) -> "\uf058")
        
      cladeIcons.on("click", (d) ->
        jQuery('#dialog-clade-select')
          .data('clade-node', d)
          .dialog('open')
      )
  
    # Transition out new nodes
    nodesUpdate = svgNodes.transition()
      .duration(@duration)
      .attr("transform", (d) -> "translate(" + d.y + "," + d.x + ")" )
  
    nodesUpdate.select("circle")
        .attr("r", 4)

    nodesUpdate.filter((d) -> !d.children )
      .select("text")
        .style("fill-opacity", 1)
    
    nodesUpdate.select("rect")
      .attr("width", 8)
      .attr("height",8)
      .style("fill", (d) ->
        if d._children? 
          "lightsteelblue"
        else
          "#fff"
      )
    
    # Transition exiting ndoes to the parent's new position.
    nodesExit = svgNodes.exit().transition()
      .duration(@duration)
      .attr("transform", (d) => "translate(" + @launchPt.y + "," + @launchPt.x + ")")
      .remove()

    nodesExit.select("circle")
      .attr("r", 1e-6)
    
    nodesExit.select("text")
      .style("fill-opacity", 1e-6)
    
    nodesExit.select("rect")
      .attr("width", 1e-6)
      .attr("height",1e-6)
      
    # Reinsert previous root on top 
    # (when filter is applied the viewable tree can
    # have a root that does not match global tree root. 
    # When restoring the tree, the previous root 
    # has to be re-inserted after the branches, so it 
    # appears on top of branches
    if !oldRoot.root and @root != oldRoot
      # Need to redraw the command features
      id = oldRoot.id
      elID = "treenode#{id}"
      svgNode = @canvas.select("##{elID}")
      svgNode.moveToFront()
      
    
    # Stash old positions for transitions
    for n in @nodes
      n.x0 = n.x
      n.y0 = n.y
    
    t2 = new Date()
    dt = new Date(t2-t1)
    console.log('TreeView update elapsed time (sec): '+dt.getSeconds())
    
    true # return success
    
  # FUNC updateCSS
  # Change CSS class for all genomes to match underlying genome properties
  #
  # PARAMS
  # simple hash object with private and public list of genome Ids to update
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  updateCSS: (gset, genomes) ->
  
    # Retrieve genome objects for each in gset
    genomeList = {}
    if gset.public?
      
      for g in gset.public
        genomeList[g] = genomes.public_genomes[g]
        
    if gset.private?
      
      for g in gset.private
        genomeList[g] = genomes.private_genomes[g]
        
        
    svgNodes = @canvas.selectAll("g.treenode")
    
    # Filter elements to those that are in set
    updateNodes = svgNodes.filter((d) -> genomeList[d.name]?)
      .attr("class", (d) =>
        g = genomeList[d.name]
        d.selected = (g.isSelected? and g.isSelected)
        d.assignedGroup = g.assignedGroup
        @_classList(d)
      )
      
    updateNodes.on("click", (d) ->
      unless d.assignedGroup?
        viewController.select(d.name, !d.selected)
      else
        null
    )
      
    # Disable select on nodes assigned to groups
    
    
    true
    
  
  # FUNC viewAction
  # For top-level, global commands in TreeView that require
  # the genomeController as input the viewAction in viewController.
  # This method will call the desired method in the TreeView class
  #
  # PARAMS
  # event[string]: the type of event
  # eArgs[array]: argument array passed to event method
  # 
  # RETURNS
  # boolean 
  #      
  viewAction: (genomes, argArray) ->
    
    event = argArray.shift()
    
    if event is 'expand_collapse'
      @_expandCollapse(genomes, argArray[0], argArray[1])
    else if event is 'select_clade'
      console.log('SC')
    else
      throw new SuperphyError "Unrecognized event type: #{event} in TreeView viewAction method."
    
    true
    
  selectClade: (node, checked) ->
    
    if node.leaf
      viewController.select(node.name, checked)
    
    else
      if node.children?
        @selectClade(c, checked) for c in node.children
      else if node._children?
        @selectClade(c, checked) for c in node._children
        
  select: (genome, isSelected) ->
    
    svgNodes = @canvas.selectAll("g.treenode")
    
    # Find element matching genome
    updateNode = svgNodes.filter((d) -> d.name is genome)
      .attr("class", (d) =>
        d.selected = isSelected
        @_classList(d)
      )
      
    updateNode.select("circle")
      .style("fill", (d) -> 
        if d.selected
          "lightsteelblue"
        else
          "#fff" 
      )
        
    true
    
  # FUNC dump
  # Generate a Newick formatted tree of all genomes (ignores any filters)
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # object containing:
  #   ext[string] - a suitable file extension (e.g. csv)
  #   type[string] - a MIME type
  #   data[string] - a string containing data in final format
  #      
  dump: (genomes) ->
    
    tokens = []
    
    @_printNode(genomes, @root, tokens)
    
    output = tokens.join('')
    
    return {
      ext: 'newick'
      type: 'text/plain'
      data: output 
    }
    
  _printNode: (genomes, node, tokens) ->
    
    if node.leaf
      # Genome node
      g = genomes.genome(node.name)
      lab = genomes.label(g, genomes.visibleMeta)
      
      tokens.push("\"#{lab}\"",':',node.length)
    
    else
      # Internal node
      
      # Add all children
      if node.daycare?
        tokens.push('(')
        
        for c in node.daycare
          @_printNode(genomes, c, tokens)
          tokens.push(',')
          
        tokens[tokens.length-1] = ')' # replace last comma with closing bracket
      
      tokens.push("\"#{node.name}\"",':',node.length)
    
    true
    
    
  # Build right-angle branch connectors
  _step: (d) -> 
    "M" + d.source.y + "," + d.source.x +
    "L" + d.source.y + "," + d.target.x +
    "L" + d.target.y + "," + d.target.x
    
  _prepTree: ->
    
    # Set starting position of root
    @trueRoot.root = true
    @trueRoot.x0 = @height / 2;
    @trueRoot.y0 = 0;
    
    @_assignKeys(@trueRoot, 0)
  

  _assignKeys: (n, i) ->
    
    n.id = i
    n.storage = n.length*1 # save original value
    i++
    
    if n.children?
      # Save original children array
      n.daycare = n.children.slice() # clone array
      
      for m in n.children
        i = @_assignKeys(m, i)
        
    else if n._children?
      # Save original children array
      n.daycare = n._children.slice() # clone array
      
      for m in n._children
        i = @_assignKeys(m, i)
    
    i
  
  # FUNC _sync
  # Creates up-to-date root object with matched the genome data properties 
  # (i.e. filtered nodes remvoed from children array and added to hiddenChildren array, 
  # group classes, genome names etc)
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  _sync: (genomes) ->
    
    # Need to keep handle on the true root
    @root = @_syncNode(@trueRoot, genomes, 0)

    true
    
  _syncNode: (node, genomes, sumLengths) ->
    
    # Restore to original branch length
    # Compute cumulative branch length
    node.length = node.storage*1
    node.sum_length = sumLengths + node.length;
    
    if node.leaf? and node.leaf is "true"
      # Genome leaf node
      g = genomes.genome(node.name)
     
      if g.visible
        # Update node with sync'd genome properties
        node.viewname = g.viewname
        node.selected = (g.isSelected? and g.isSelected)
        node.assignedGroup = g.assignedGroup
        node.hidden   = false
        
      else
        # Mask filtered node
        node.hidden = true
       
    else
      # Internal node
      
      isExpanded = true
      isExpanded = false if node._children?
      
      # Iterate through the original children array
      children = []
      for c in node.daycare
        u = @_syncNode(c, genomes, node.sum_length)
        
        unless u.hidden
          children.push(u)
          
      if children.length == 0
        node.hidden = true
      else if children.length == 1
        # Child replaces this node
        node.hidden = true
        child = children[0]
        child.length += node.length
        return child
        
      else
        node.hidden = false
        if isExpanded
          node.children = children
        else
          node._children = children
        
    node
    
    
  # FUNC _cloneNode
  # Creates copy of node object by copying properties
  # 
  # DOES NOT COPY children/_children array because 
  # that will copy the child objects by reference and
  # not actual cloning
  #
  # PARAMS
  # javascript object representing tree node
  # 
  # RETURNS
  # JS object
  #
  _cloneNode: (node) ->
    
    copy = {}
    
    for k,v of node
      unless k is 'children' or k is '_children'
        copy[k] = v
    
    copy
             
  _expandCollapse: (genomes, d, el) ->
    
    svgNode = d3.select(el)
   
    if d.children?
      # Collapse all child nodes into parent
      d._children = d.children
      d.children = null
      
    else
      # Expand 2-levels
      d.children = d._children
      d._children = null
      
      # Hide internal label when the node is expanded
      svgNode.select("text")
        .transition()
        .duration(@duration)
        .style("fill-opacity", 1e-6)
      
      # Expand child nodes
      for c in d.children
        if c._children?
          c.children = c._children
          c._children = null
          d3.select("#treenode#{c.id}").select("text")
            .transition()
            .duration(@duration)
            .style("fill-opacity", 1e-6)
            
    @update(genomes, d)
    
    true
    
  zoomed: ->
    
    @canvas.selectAll("g.treenode")
      .attr("transform", (d) => @_zTransform(d, @xzoom, @yzoom))
    
    @canvas.selectAll("path.treelink")
      .attr("d", (d) => @_zTranslate(d, @xzoom, @yzoom))
      
    true
      
  # Build right-angle connectors stretched for zoom
  _zTranslate: (d, xzoom, yzoom) ->  
    sourceX = xzoom(d.source.y)
    sourceY = yzoom(d.source.x)
    targetX = xzoom(d.target.y)
    targetY = yzoom(d.target.x)
  
    "M" + sourceX + "," + sourceY +
    "L" + sourceX + "," + targetY + 
    "L" + targetX + "," + targetY
  
  # Position nodes stretched for zoom
  _zTransform: (d, xzoom, yzoom) ->
    "translate(" + xzoom(d.y) + "," + yzoom(d.x) + ")"

  _classList: (d) ->
    
    clsList  = ['treenode'];
    clsList.push("selectedNode") if d.selected
    clsList.push("focusNode") if d.focus
    clsList.push("groupedNode#{d.assignedGroup}") if d.assignedGroup?
    
    clsList.join(' ')
    
    
  