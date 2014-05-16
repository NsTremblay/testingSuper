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
 
 Can be genome- or locus-based
 Returns genome ID to redirect/select if leaf node is clicked
 
###

class TreeView extends ViewTemplate
  constructor: (@parentElem, @style, @elNum, treeArgs) ->
    
    throw new SuperphyError 'Missing argument. TreeView constructor requires JSON tree object.' unless treeArgs.length > 0
    @root = @trueRoot = treeArgs[0]
    
    # Tracks changes in underlying visible genome set
    @currentGenomeSet = -1;
    
    @dim={w: 700, h: 800}
    @margin={top: 20, right: 180, bottom: 20, left: 20}
    @locusData = treeArgs[1] if treeArgs[1]?
    @dim = treeArgs[2] if treeArgs[2]?
    @margin = treeArgs[3] if treeArgs[3]?
                  
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
    
    # Link to legend
    legendID = "tree_legend#{@elNum}"
    @parentElem.append("<div class='tree_legend_link'><a href='##{legendID}'>Functions List</a></div>")
    
    # SVG layer
    @parentElem.append("<div id='#{@elID}' class='#{@cssClass()}'></div>")
    @wrap = d3.select("##{@elID}").append("svg")
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
    
    # Legend SVG
    
    jQuery("<div id='#{legendID}' class='genome_tree_legend'></div>").appendTo(@parentElem)
    @wrap2 = d3.select("##{legendID}").append("svg")
      .attr("width", @dim.w)
      .attr("height", 100)
      .style("-webkit-backface-visibility", "hidden")
    
    @legend = @wrap2.append("g")
      .attr("transform", "translate(" + 5 + "," + 5 + ")")
    
    @_legend(@legend)  
    
    
    # Attach a clade dialog
    if @style is 'select'
      dialog = jQuery('#dialog-clade-select')
      unless dialog.length
        dialog = jQuery('<div id="dialog-clade-select"></div>').appendTo('body')
        dialog
          .text("Select/unselect genomes in clade:")
          .dialog({
            #title: 'Select clade',
            dialogClass: 'noTitleStuff',
            autoOpen: false,
            resizable: false,
            height: 120,
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
  
  expandDepth: 5
  
  x_factor: 1.5
  y_factor: 5000
  
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
    
    # Compute layout, return D3 node objects
    @nodes = @cluster.nodes(@root)
    
     # find starting point to launch new nodes/links
    sourceNode = @root unless sourceNode?
    @launchPt = {x: sourceNode.x, y: sourceNode.y, x0: sourceNode.x0, y0: sourceNode.y0}
    
    # Scale branch lengths
    farthest = d3.max(@nodes, (d) -> d.sum_length * 1)
    lowest = d3.max(@nodes, (d) -> d.x )
    yedge = @width - 20
    xedge = @height - 20
    
    # Start with default scale values,
    # If tree is larger than window, shrink scale
    branch_scale_factor_y = @y_factor
    if (branch_scale_factor_y * farthest) > yedge
      branch_scale_factor_y = yedge/farthest
      
    branch_scale_factor_x = @x_factor
    if (branch_scale_factor_x * lowest) > xedge
      branch_scale_factor_x = xedge/lowest
      
      
    console.log 'y'+branch_scale_factor_y
    console.log 'x'+branch_scale_factor_x
    
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
          viewController.select(d.genome, !d.selected)
        else
          null
      )
          
    currLeaves.select("circle")
      .style("fill", (d) -> 
        if d.selected
          "lightsteelblue"
        else
          "#fff"
      )
    
    # Update text if meta-labels
    # or filter changed them
    svgNodes.select("text")
      .text((d) ->
        if d.leaf
          d.viewname
        else
          d.label
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
          viewController.select(d.genome, !d.selected)
        else
          null
      )
    else
      leaves.on("click", (d) ->
        viewController.redirect(d.genome)
      )
      
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
      
    cmdBox = iNodes
      .append('text')
      .attr("class","treeicon expandcollapse")
      .attr("text-anchor", 'middle')
      .attr("y", 4)
      .attr("x", -8)
      .text((d) -> "\uf0fe")
  
    cmdBox.on("click", (d) -> 
      viewController.viewAction(num, 'expand_collapse', d, @.parentNode) 
    )
    
    # # select/unselect clade
    # if @style is 'select'
      # # select
      # cladeIcons = iNodes
        # .append('text')
        # .attr("class","treeicon selectclade")
        # .attr("text-anchor", 'middle')
        # .attr("y", 4)
        # .attr("x", -20)
        # .text((d) -> "\uf058")
#         
      # cladeIcons.on("click", (d) ->
        # jQuery('#dialog-clade-select')
          # .data('clade-node', d)
          # .dialog('open')
      # )
      
     # select/unselect clade
    if @style is 'select'
      # select
      cladeSelect = iNodes
        .append('rect')
        .attr("class","selectClade")
        .attr("width", 8)
        .attr("height", 8)
        .attr("y", -4)
        .attr("x", -25)
        
      cladeSelect.on("click", (d) ->
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
    
    nodesUpdate.select(".expandcollapse")
      .text((d) ->
        if d._children? 
          "\uf0fe"
        else
          "\uf146"
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
    updateNodes = svgNodes.filter((d) -> genomeList[d.genome]?)
      .attr("class", (d) =>
        g = genomeList[d.genome]
        d.selected = (g.isSelected? and g.isSelected)
        d.assignedGroup = g.assignedGroup
        @_classList(d)
      )
      
    updateNodes.on("click", (d) ->
      unless d.assignedGroup?
        viewController.select(d.genome, !d.selected)
      else
        null
    )
      
  
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
    else
      throw new SuperphyError "Unrecognized event type: #{event} in TreeView viewAction method."
    
    true
    
  # FUNC selectCladed
  # Call select on every leaf node in clade
  #
  # PARAMS
  # Data object representing node
  # boolean indicating select/unselect
  # 
  # RETURNS
  # boolean 
  #        
  selectClade: (node, checked) ->
    
    if node.leaf
      viewController.select(node.genome, checked)
    
    else
      if node.children?
        @selectClade(c, checked) for c in node.children
      else if node._children?
        @selectClade(c, checked) for c in node._children
  
  # FUNC select
  # Changes css classes for selected genome in tree
  # Also updates coloring of selectClade command icons
  # to indicate presence of selected genome
  #
  # PARAMS
  # Data object representing node
  # boolean indicating select/unselect
  # 
  # RETURNS
  # boolean 
  #              
  select: (genome, isSelected) ->
    
    svgNodes = @canvas.selectAll("g.treenode")
    
    # Find element matching genome
    updateNode = svgNodes.filter((d) -> d.genome is genome)
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
    
    # Push selection up tree
    d = updateNode.datum()
    console.log updateNode
    console.log d.parent
    @_percolateSelected(d.parent, isSelected)
    
    # update classes
    svgNodes.filter((d) -> !d.leaf)
      .attr("class", (d) =>
        @_classList(d)
      )
      
    true
    
    
  # FUNC _percolateSelected
  # Updates internal nodes up the tree
  # changing classes based on if 
  #
  # PARAMS
  # Data object representing node
  # boolean indicating select/unselect
  # 
  # RETURNS
  # boolean 
  #
  _percolateSelected: (node, checked) ->
    
    return true unless node?
  
    if checked
      node.num_selected++
    else
      node.num_selected--
    
    if node.num_selected == node.num_leaves
      node.internal_node_selected = 2
    else if node.num_selected > 0
      node.internal_node_selected = 1
    else
      node.internal_node_selected = 0
       
    @_percolateSelected(node.parent, checked)
    
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
      g = genomes.genome(node.genome)
      lab = genomes.label(g, genomes.visibleMeta)
      
      tokens.push("\"#{lab}\"",':',node.length)
    
    else
      # Internal node
      
      # Add all children
      children = node.children
      children = node._children if node._children?
      
      tokens.push('(')
        
      for c in children
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
    @trueRoot.x0 = @height / 2
    @trueRoot.y0 = 0
    
    gPattern = /^((?:public_|private_)\d+)\|/
    
    @_assignKeys(@trueRoot, 0, gPattern)
  

  _assignKeys: (n, i, gPattern) ->
    
    n.id = i
    n.storage = n.length*1 # save original value
    i++
    
    if n.children?
      n.num_selected = 0
      
      # Save original children array
      n.daycare = n.children.slice() # clone array
      
      for m in n.children
        i = @_assignKeys(m, i, gPattern)
        
    else if n._children?
      n.num_selected = 0
    
      # Save original children array
      n.daycare = n._children.slice() # clone array
      
      for m in n._children
        i = @_assignKeys(m, i, gPattern)
    
    
    if n.leaf? and n.leaf is "true"
      if @locusData?
        # Nodes are keyed: genome|locus
        res = gPattern.exec(n.name)
        throw new SuperphyError "Invalid tree node key. Expecting: genome|locus. Recieved: #{n.name}" unless res?
        n.genome = res[1]
      else
        # Nodes are keyed: genome
        n.genome = n.name
    
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
    
    console.log 'sync'
    
    # Need to keep handle on the true root
    @root = @_syncNode(@trueRoot, genomes, 0)
    
    # Check if genome set has changed
    if genomes.genomeSetId != @currentGenomeSet
      # Need to set starting expansion layout
      @_expansionLayout()
      @currentGenomeSet = genomes.genomeSetId
    

    true
    
  _syncNode: (node, genomes, sumLengths) ->
    
    # Restore to original branch length
    # Compute cumulative branch length
    node.length = node.storage*1
    node.sum_length = sumLengths + node.length
    
    if node.leaf? and node.leaf is "true"
      # Genome leaf node
      g = genomes.genome(node.genome)

      # Genome can be missing if a subset of genomes was used
      # Or if it was filtered     
      if g? and g.visible
        # Update node with sync'd genome properties
        
        node.viewname = g.viewname
        
        node.selected = (g.isSelected? and g.isSelected)
        node.assignedGroup = g.assignedGroup
        node.hidden   = false
        
        # Append locus data
        # This will overwrite assignedGroup
        if @locusData?
          ld = @locusData.locusNode(node.name)
          node.viewname += ld[0]
          node.assignedGroup = ld[1]
        
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
    
  
  # FUNC _expansionLayout
  # Set internal node names, set initial expanded
  # nodes 
  # 
  # PARAMS
  # javascript object representing tree node
  # 
  # RETURNS
  # boolean
  #  
  _expansionLayout: (focusNode=null) ->
    
    @_formatNode(@root, 0, focusNode)
    
    @root.x0 = @height / 2
    @root.y0 = 0
    @root.root = true
    
    true
  
  # FUNC _formatNode
  # Recursive function that sets expand / collapse setting 
  # based on level and if on path to focus node.
  # Also sets interactive internal node names.
  # 
  # PARAMS
  # javascript object representing tree node
  # Int for tree level
  # Reference to parent node
  # String indicating 
  # 
  # RETURNS
  # JS object
  #  
  _formatNode: (node, depth, parentNode=null, focusNode=null) ->
    
    # There shouldn't be any hidden nodes in the
    # traversal
    return null if node.hidden
    
    current_depth = depth+1
    record = {}
    node.parent = parentNode
    node.root = false
    
    if node.leaf? and node.leaf is "true"
      # Genome leaf node
      
      record['num_leaves'] = 1
      record['outgroup'] = node.label
      record['depth'] = current_depth
      record['length'] = node.length
      record['num_selected'] = (node.selected ? 1 : 0)
      
      return record
       
    else
      # Internal node
      
      # Set expand / collapse setting
      isExpanded = true
      children = node.children
      if node._children?
        isExpanded = false
        children = node._children
        
      if current_depth < @expandDepth
        # Expand upper level
        node.children = children
        node._children = null
      else if isExpanded
        # Maintain existing setting
        node.children = children
        node._children = null
      else
        # Maintain existing setting
        node._children = children
        node.children = null
      
      # Iterate through the children array
      record = {
        num_leaves: 0
        num_selected: 0
        outgroup: ''
        depth: 1e6
        length: 0 
      }
      for c in children
        r = @_formatNode(c, current_depth, node, focusNode)
        
        record['num_leaves'] += r['num_leaves']
        record['num_leaves'] += r['num_selected']
      
        # Compare to existing outgroup
        if (record['depth'] > r['depth']) || (record['depth'] == r['depth'] && record['length'] < r['length']) 
          # new outgroup found
          record['depth'] = r['depth']
          record['length'] = r['length']
          record['outgroup'] = r['outgroup']
          
      # Assign node node
      node.label = "#{record['num_leaves']} genomes (outgroup: #{record['outgroup']})";
      node.num_leaves = record['num_leaves']
      node.num_selected = record['num_selected']
      
      if node.num_selected == node.num_leaves
        node.internal_node_selected = 2
      else if node.num_selected > 0
        node.internal_node_selected = 1
      else
        node.internal_node_selected = 0
           
    record
             
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
    
    if d.internal_node_selected?
      if d.internal_node_selected == 2
        clsList.push("internalSNodeFull")
      else if d.internal_node_selected == 1
        clsList.push("internalSNodePart")
      
    clsList.join(' ')
 
  # FUNC _legend
  # Attach legend for tree manipulations
  # 
  # PARAMS
  # D3 svg element to attach legend elements to
  # 
  # RETURNS
  # boolean
  #   
  _legend: (el) ->
    
    lineh = 25
    lineh2 = 40
    lineh3 = 55
    lineh4 = 80
    textdx = ".6em"
    textdx2= "2.5em"
    textdy = ".4em"
    pzdx   = "3.2em"
    pzdx2  = "3.7em"
    pzdy   = ".5em"
    indent = 8
    colw = 245
    colw2 = 480
    
    if @style is 'select'
      
      # Genome select column
      gsColumn = el.append("g")
        .attr("transform", "translate(5,"+lineh+")" )
        
      genomeSelect = gsColumn.append("g")
        .attr("class", 'treenode')
        
      genomeSelect.append("circle")
        .attr("r", 4)
        .attr("cx", 0)
        .attr("cy", 0)
        .style("fill", "#fff")
        
      genomeSelect.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Click to select / unselect genome')
        
      genomeSelect = gsColumn.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+indent+","+lineh+")" )
        
      genomeSelect.append("circle")
        .attr("r", 4)
        .attr("cx", 0)
        .attr("cy", 0)
        .style("fill", "lightsteelblue")
        
      genomeSelect.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Selected genome')
        
      genomeSelect = gsColumn.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+indent+","+lineh2+")" )
        
      genomeSelect.append("circle")
        .attr("r", 4)
        .attr("cx", 0)
        .attr("cy", 0)
        .style("fill", "#fff")
        
      genomeSelect.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Unselected genome')
        
      # Clade select column
      csColumn = el.append("g")
        .attr("transform", "translate("+colw+","+lineh+")" )
        
      cladeSelect = csColumn.append("g")
        .attr("class", 'treenode')
        
      cladeSelect.append('rect')
        .attr("class","selectClade")
        .attr("width", 8)
        .attr("height", 8)
        .attr("y", -4)
        .attr("x", -4)
        
      cladeSelect.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Click to select / unselect clade')
        
      cladeSelect = csColumn.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+indent+","+lineh+")" )
        
      cladeSelect.append('rect')
        .attr("class","selectClade")
        .attr("width", 8)
        .attr("height", 8)
        .attr("y", -4)
        .attr("x", -4)
        
      cladeSelect.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('No genomes selected in clade')
        
      cladeSelect = csColumn.append("g")
        .attr("class", 'treenode internalSNodePart')
        .attr("transform", "translate("+indent+","+lineh2+")" )
        
      cladeSelect.append('rect')
        .attr("class","selectClade")
        .attr("width", 8)
        .attr("height", 8)
        .attr("y", -4)
        .attr("x", -4)
        
      cladeSelect.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Some genomes selected in clade')
        
      cladeSelect = csColumn.append("g")
        .attr("class", 'treenode internalSNodeFull')
        .attr("transform", "translate("+indent+","+lineh3+")" )
        
      cladeSelect.append('rect')
        .attr("class","selectClade")
        .attr("width", 8)
        .attr("height", 8)
        .attr("y", -4)
        .attr("x", -4)
        
      cladeSelect.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('All genomes selected in clade')
      
      # clade expand/collapse  
      ecColumn = el.append("g")
        .attr("transform", "translate("+colw2+","+lineh+")" )
        
      expandCollapse = ecColumn.append("g")
        .attr("class", 'treenode')
          
      expandCollapse.append('text')
        .attr("class","treeicon expandcollapse")
        .attr("text-anchor", 'middle')
        .attr("dy", 4)
        .attr("dx", -1)
        .text((d) -> "\uf0fe")
        
      expandCollapse.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Click to collapse / expand clade')
        
      expandCollapse = ecColumn.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+indent+","+lineh+")" )
        
      expandCollapse.append('text')
        .attr("class","treeicon expandcollapse")
        .attr("text-anchor", 'middle')
        .attr("dy", 4)
        .attr("dx", -1)
        .text((d) -> "\uf146")
        
      expandCollapse.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Expanded clade')
        
      expandCollapse = ecColumn.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+indent+","+lineh2+")" )
        
      expandCollapse.append('text')
        .attr("class","treeicon expandcollapse")
        .attr("text-anchor", 'middle')
        .attr("dy", 4)
        .attr("dx", -1)
        .text((d) -> "\uf0fe")
        
      expandCollapse.append("text")
        .attr("class","legendlabel2")
        .attr("dx", textdx)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Collapsed clade')
        
      # Pan / zoom
      pzRow = el.append("g")
        .attr("transform", "translate(0,0)" )
      
      panZoom = pzRow.append("g") 
        .attr("class", 'treenode')
        
      panZoom.append("text")
        .attr("class","slash")
        .attr("dx", 0)
        .attr("dy", ".5em")
        .attr("text-anchor", "start")
        .text('Pan')
        
      panZoom.append("text")
        .attr("class","legendlabel1")
        .attr("dx", pzdx)
        .attr("dy", pzdy)
        .attr("text-anchor", "start")
        .text('Click & Drag')
        
      panZoom = pzRow.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+colw+",0)" )
        
      panZoom.append("text")
        .attr("class","slash")
        .attr("dx", "-.4em")
        .attr("dy", ".5em")
        .attr("text-anchor", "start")
        .text('Zoom')
        
      panZoom.append("text")
        .attr("class","legendlabel1")
        .attr("dx", pzdx)
        .attr("dy", pzdy)
        .attr("text-anchor", "start")
        .text('Scroll')
        
    else
      # Genome select
      genomeSelect = el.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate(5,0)" )
        
      genomeSelect.append("circle")
        .attr("r", 4)
        .attr("cx", 8)
        .attr("cy", 0)
        .style("fill", "#fff")
        
      genomeSelect.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx2)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Select genome')
        
      # Clade expand
      cladeExpand = el.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate(5, "+lineh+")" )
      
      cladeExpand.append('text')
        .attr("class","treeicon expandcollapse")
        .attr("text-anchor", 'middle')
        .attr("y", 4)
        .attr("x", -1)
        .text((d) -> "\uf0fe")
        
      cladeExpand.append("text")
        .attr("class","slash")
        .attr("dx", ".5em")
        .attr("dy", ".5em")
        .attr("text-anchor", "start")
        .text('/')
        
      cladeExpand.append('text')
        .attr("class","treeicon expandcollapse")
        .attr("text-anchor", 'middle')
        .attr("y", 8)
        .attr("x", 17)
        .text((d) -> "\uf146")
        
      cladeExpand.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx2)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Expand / Collapse clade')
        
      # Pan / zoom
      panZoom = el.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+colw+",0)" )
        
      panZoom.append("text")
        .attr("class","slash")
        .attr("dx", 0)
        .attr("dy", ".5em")
        .attr("text-anchor", "start")
        .text('Pan ')
        
      panZoom.append("text")
        .attr("class","legendlabel1")
        .attr("dx", pzdx2)
        .attr("dy", pzdy)
        .attr("text-anchor", "start")
        .text('Click & Drag')
        
      panZoom = el.append("g")
        .attr("class", 'treenode')
        .attr("transform", "translate("+colw+","+lineh+")" )
        
      panZoom.append("text")
        .attr("class","slash")
        .attr("dx", 0)
        .attr("dy", ".5em")
        .attr("text-anchor", "start")
        .text('Zoom')
        
      panZoom.append("text")
        .attr("class","legendlabel1")
        .attr("dx", pzdx2)
        .attr("dy", pzdy)
        .attr("text-anchor", "start")
        .text('Scroll')
        
        
      # Focus node
      focusNode = el.append("g")
        .attr("class", 'treenode focusNode')
        .attr("transform", "translate("+colw2+",0)" )
        
      focusNode.append("circle")
        .attr("r", 4)
        .attr("cx", 8)
        .attr("cy", 2)
        #.style("fill", "#fff")
        
      focusNode.append("text")
        .attr("class","legendlabel1")
        .attr("dx", textdx2)
        .attr("dy", textdy)
        .attr("text-anchor", "start")
        .text('Target genome')