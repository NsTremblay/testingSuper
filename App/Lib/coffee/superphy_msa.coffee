###


 File: superphy_msa.coffee
 Desc: Multiple Sequence Alignment View Class
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: April 9th, 2013
 
 
###
 
###
 CLASS MsaView
  
 Multiple Sequence Alignment view
 
 Always locus-based
 Returns nothing to redirect/select (no click behavior defined)

###

class MsaView extends ViewTemplate
  constructor: (@parentElem, @style, @elNum, msaArgs) ->
    
    throw new SuperphyError 'Missing argument. MsaView constructor requires JSON alignment object.' unless msaArgs.length > 0
    
    alignmentJSON = msaArgs[0]
    
    # Additional data to append to node names
    # Keys are genome|locus IDs
    @locusData = null
    if msaArgs[1]?
      @locusData = msaArgs[1]
      
    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum)
    
    # Format alignment object into rows of even length
    @_formatAlignment(alignmentJSON)
  
  type: 'msa'
  
  elName: 'genome_msa'
  
  blockLen: 70
  
  nameLen: 25
  
  consLine: 'conservation_line'
  
  posLine: 'position_line'
  
  nuclClasses: { 'A': 'nuclA', 'G': 'nuclG', 'C': 'nuclC', 'T':'nuclT', '*': 'consM', ' ':'consMM', '-':'nuclGAP'}
  
  cssClass: 'msa_row_name'
  

  # FUNC _formatAlignment
  # Splits alignment strings into even-length
  # rows. Called once in constructor since
  # alignments do not change during lifetime of
  # of view. Stores final alignment in @alignment
  #
  # PARAMS
  # none
  # 
  # RETURNS
  # boolean 
  #      
  _formatAlignment: (alignmentJSON) ->
 
    # Loci in alignment
    @rowIDs = (g for g of alignmentJSON)
    
    # Splice out the match line
    i =  @rowIDs.indexOf(@consLine)
    throw new SuperphyError 'Alignment Object missing "conservation_line".' unless i >= 0
    @rowIDs.splice(i,1)
    
    # Initialise the alignment data
    seqLen = alignmentJSON[@rowIDs[0]]['seq'].length
    @alignment = {};
    for n in @rowIDs
      @alignment[n] = {
        'alignment': [],
        'seq': alignmentJSON[n]['seq']
        'genome': alignmentJSON[n]['genome']
        'locus': alignmentJSON[n]['locus']    
      }
      
    @alignment[@consLine] = { 'alignment': [] }
    @alignment[@posLine] = { 'alignment': [] }
    
    @numBlock = 0
    for j in [0..seqLen] by @blockLen
      @numBlock++
      for n in @rowIDs
        seq = alignmentJSON[n]['seq']
        @alignment[n]['alignment'].push(@_formatBlock(seq.substr(j,@blockLen)))
     
       # Conservation line 
       seq = alignmentJSON[@consLine]['seq']
       @alignment[@consLine]['alignment'].push(@_formatBlock(seq.substr(j,@blockLen)))
       # Position Line
       pos = j+1
       posElem = "<td class='msaPosition'>#{pos}</td>"
       @alignment[@posLine]['alignment'].push(posElem)
       
    true
    
  _formatBlock: (seq) ->
    html = '';
    seq.toUpperCase()
    
    for c in [0..seq.length]
      chr = seq.charAt(c)
      cls = @nuclClasses[chr]
      html += "<td class='#{cls}'>#{chr}</td>"
    
    html
  
  # FUNC update
  # Update MSA view
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  # 
  
  update: (genomes) ->
    
    # create or find MSA table
    msaElem = jQuery("##{@elID}")
    if msaElem.length
      msaElem.empty()
      msaElem.append('<tbody></tbody>')
    else      
      msaElem = jQuery("<table id='#{@elID}'><tbody></tbody></table>")
      jQuery(@parentElem).append(msaElem)
   
    # append alignment rows to table
    t1 = new Date()
    
    # obtain current names and sort
    @_appendRows(msaElem, genomes)
    
    t2 = new Date()
    
    ft = t2-t1
    console.log('MsaView update elapsed time: '+ft)
   
    true # return success
    

  _appendRows: (el, genomes) ->
    
    genomeElem = {}
    visibleRows = []
    tmp = {}
    
    for i in @rowIDs
      a = @alignment[i]
      genomeID = a['genome']
      g = genomes.genome(genomeID)
      
      if g.visible
        
        visibleRows.push i
        
        # MSA row name
        name = g.viewname
        tmp[i] = name
        
        # Append locus data
        if @locusData?
          name += @locusData.locusString(i)
        
        # Class data for row name
        thiscls = @cssClass
        thiscls = @cssClass+' '+g.cssClass if g.cssClass?
        
        nameCell = "<td class='#{thiscls}' data-genome='#{genomeID}'>#{name}</td>";
        
        genomeElem[i] = nameCell
        
    # Sort alphabetically
    visibleRows.sort (a,b) ->
      aname = tmp[a]
      bname = tmp[b]
      if aname > bname then 1 else if aname < bname then -1 else 0
    
    # Spit out each block row
    for j in [0...@numBlock]
      for i in visibleRows
        rowEl = jQuery('<tr></tr>')
        rowEl.append(genomeElem[i] + @alignment[i]['alignment'][j])
        el.append(rowEl)
      # Add conservation row and position row
      rowEl = jQuery('<tr></tr>')
      rowEl.append('<td></td>' + @alignment[@consLine]['alignment'][j])
      el.append(rowEl)
      rowEl = jQuery('<tr></tr>')
      rowEl.append(@alignment[@posLine]['alignment'][j])
      el.append(rowEl)
      
    true
    
  # FUNC updateCSS
  # Change CSS class for selected genomes to match underlying genome properties
  #
  # PARAMS
  # simple hash object with private and public list of genome Ids to update
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  updateCSS: (gset, genomes) ->
    
    # Retrieve list DOM element    
    msaEl = jQuery("##{@elID}")
    throw new SuperphyError "DOM element for Msa view #{@elID} not found. Cannot call MsaView method updateCSS()." unless msaEl? and msaEl.length
    
    # append genomes to list
    @_updateGenomeCSS(listEl, gset.public, genomes.public_genomes) if gset.public?
    
    @_updateGenomeCSS(listEl, gset.private, genomes.private_genomes) if gset.private?
    
    true # return success
    
  
  _updateGenomeCSS: (el, changedG, genomes) ->
    
    # View class
    cls = @cssClass()
    
    for g in changedG
      
      thiscls = cls
      thiscls = cls+' '+ genomes[g].cssClass if genomes[g].cssClass?
     
      # Find element
      descriptor = "td[data-genome='#{g}']"
      itemEl = el.find(descriptor)
      
      unless itemEl? and itemEl.length
        throw new SuperphyError "Msa element for genome #{g} not found in MsaView #{@elID}"
        return false
      
      console.log("Updating class to #{thiscls}")
      liEl = itemEl.parents().eq(1)
      liEl.attr('class', thiscls)
     
    true # success
  
  # FUNC select
  # No function in a MSA, always returns true
  #
  # RETURNS
  # boolean 
  #        
  select: (genome, isSelected) ->
    
    true # success
  
  # FUNC dump
  # Generate fasta file of visible sequences in MSA
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
    
    # Get the sequences and headers
    output = ''
    
    for i in @rowIDs
      a = @alignment[i]
      genomeID = a['genome']
      g = genomes.genome(genomeID)
      
      if g.visible
        
        # Fasta header
        name = g.viewname
        
        if @locusData? && @locusData[i]?
          name += @locusData[i]
          
        # Fasta sequence
        seq = a['seq']
        output += ">#{name}\n#{seq}\n"
        
        
    return {
      ext: 'fasta'
      type: 'text/plain'
      data: output 
    }
    
  
    
    
  