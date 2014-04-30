###


 File: superphy_matrix.coffee
 Desc: Genome x Gene table showing # of alleles
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: April 24th, 2013
 
 
###
 
###
 CLASS MatrixView
  
 Gene Allele Matrix view
 
 Always genome based
 Links to individual genes

###

class MatrixView extends ViewTemplate
  constructor: (@parentElem, @style, @elNum, genomes, matrixArgs) ->
    
    throw new SuperphyError 'Missing argument. MatrixView constructor requires GenomeController object.' unless genomes?
    throw new SuperphyError 'Missing argument. MatrixView constructor requires JSON object containing: nodes, links.' unless matrixArgs.length > 0
    
    tmp = matrixArgs[0]
    genes = tmp['nodes']
    alleles = tmp['links']
    gList = Object.keys(genomes.public_genomes).concat Object.keys(genomes.private_genomes)
    nList = Object.keys(genes)
    
    # Base maximum matrix size on input (no filtering)
    # Actual matrix may only fill part of the svg viewport
    @cellWidth = 10
    @margin = {top: 20, right: 0, bottom: 0, left: 20}
    #@height = gList.length * @cellWidth
    @height = 72
    #@width = nList.length * @cellWidth
    @width = 72
    @dim = {
      w: @width + @margin.right + @margin.left
      h: @height + @margin.top + @margin.bottom
    }
    
    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum)
    
    # Create matrix objects
    # Defines @matrix, @geneNodes, @genomeNodes
    @_computeMatrix(gList, genes, alleles)
    
    # Precompute ordering for genes which are stable
    # genomes can be removed through filtering
    @geneOrders = {
      name: d3.range(@nGenes).sort (a, b) =>
          d3.ascending(@geneNodes[a].name, @geneNodes[b].name)
        
      count: d3.range(@nGenes).sort (a, b) =>
          @geneNodes[b].count - @geneNodes[a].count
    }
    @orderType = 'name' # Start with alphabetical ordering
    
    # Set color opacity based on num of alleles
    # Above 4 alleles full saturation is reached
    @z = d3.scale.linear().domain([0, 4]).clamp(true)
    # Create gene mapping
    @x = d3.scale.ordinal().rangeBands([0, @width])
    
    # Setup and attach SVG viewport
    @parentElem.append("<div id='#{@elID}'></div>")
    @wrap = d3.select("##{@elID}").append("svg")
      .attr("width", @dim.w)
      .attr("height", @dim.h)
      .style("margin-left", -@margin.left + "px")
    
    # Parent element for attaching matrix elements
    @canvas = @wrap.append("g")
      .attr("transform", "translate(" + @margin.left + "," + @margin.top + ")")
      
    # Background
    @canvas.append("rect")
      .attr("class", "matrixBackground")
      .attr("width", @width)
      .attr("height", @height);
    

    true
  
  type: 'matrix'
  
  elName: 'genome_matrix'
   
  # FUNC _computeMatrix
  # build matrix data from input
  #
  # PARAMS
  # 1) List of genomeIDs
  # 2) Object of gene IDs => gene names
  # 3) Object of allele IDs for each genome and gene (e.g. genome => gene => array of allele IDs) 
  # 
  # RETURNS
  # boolean 
  #       
  _computeMatrix: (gList, genes, alleles) ->
     
    nList = Object.keys(genes)
    @nGenomes = gList.length
    @nGenes = nList.length
     
    # Genome nodes
    @genomeNodes = []
    @matrix = []
    i = 0
    for g in gList
      gObj = {
        index: i
        genome: g
        count: 0
      }
      @genomeNodes.push gObj
      @matrix[i] = d3.range(@nGenes).map (j) -> 
        {x: j, y: i, z: 0, i:null} 
      i++
      
    console.log @genomeNodes 
    # Gene nodes
    @geneNodes = []
    
    i = 0
    for g in nList
      gObj = {
        index: i
        gene: g
        name: genes[g]
        count: 0
      }
      @geneNodes.push gObj
      i++
      
    # Cell values
    i = 0
    for g in @genomeNodes
      for n in @geneNodes
         
        # Count alleles for genome/gene pair
        numAlleles = 0
        if alleles[g.genome]? and alleles[g.genome][n.gene]?
          numAlleles = alleles[g.genome][n.gene].length
           
        g.count += numAlleles
        n.count += numAlleles
           
        @matrix[g.index][n.index].z = numAlleles
        @matrix[g.index][n.index].i = i
        i++
         
    true
         
     
    
  # FUNC update
  # Update genome tree view
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  update: (genomes) ->
    
    t1 = new Date()
    
    # Sync internal objects to current genome settings
    @_sync(genomes)
    
    # Draw
    
    # Attach gene rows
    svgGenes = @canvas.selectAll("g.matrixrows")
      .data(@currNodes, (d) -> d.index)
      
    
    # Update existing positions
    
    # Insert new rows
    that = @
    svgGenes.enter().append("g")
      .attr("class", "matrixrow")
      .attr("transform", (d, i) =>
        "translate(0," + @y(i) + ")"
      )
      .each((d) -> that._row(@, that.matrix[d.index], that.x, that.y, that.z))
    
    t2 = new Date()
    dt = new Date(t2-t1)
    console.log('MatrixView update elapsed time (s): '+dt.getMillieconds)
    
    true # return success
    
 
  _sync: (genomes) ->
     
    # Compute current visible matrix columns
    @currNodes = []
    @currN = 0
    
    for n in @genomeNodes
      console.log n
      g = genomes.genome(n.genome)
      
      if g.visible
        # Record column object
        n.viewname = g.viewname
        n.selected = (g.isSelected? and g.isSelected)
        # Need default group assignment to compute order
        if g.assignedGroup?
          n.assignedGroup = g.assignedGroup
        else
          n.assignedGroup = -1
       
        @currNodes.push n
        
        # Record matrix column
        @currN++
        
    # Compute new ordering
    @genomeOrders = {
      name: d3.range(@currN).sort (a, b) =>
        d3.ascending(@currNodes[a].viewname, @currNodes[b].viewname)
        
      count: d3.range(@currN).sort (a, b) =>
        @currNodes[b].count - @currNodes[a].count
          
      group: d3.range(@currN).sort (a, b) =>
        gdiff = @currNodes[b].group - @currNodes[a].group
        if gdiff == 0
          return @currNodes[b].count - @currNodes[a].count
        else
          return gdiff
    }
    
    # Recompute width
    #@height = @cellWidth * @currN
    
    # Resize background
    
    # Recompute domain
    @y = d3.scale.ordinal().rangeBands([0, @height])
    @y.domain(@genomeOrders[@orderType])
    @x.domain(@geneOrders[@orderType])
           
    true
    
  _row: (svgRow, rowData, x, y, z) ->
    
    # Grab row cells
    svgCells = d3.select(svgRow).selectAll(".matrixcell")
      .data(rowData, (d) -> d.i)
      
    # Update cells
    
    # Insert new cells
    svgCells.enter().append("rect")
      .attr("class", "matrixcell")
      .attr("x", (d) -> x(d.x))
      #.attr("y", (d) -> y(d.y))
      .attr("width", x.rangeBand())
      .attr("height", y.rangeBand())
      .style("fill-opacity", (d) -> z(d.z))
      .style("fill", 'blue')
      #.on("mouseover", mouseover)
      #.on("mouseout", mouseout);
    
    true
    