###


 File: superphy_tickers.coffee
 Desc: Multiple Superphy Ticker Classes. Tickers are single line summaries of current genome data
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: April 16th, 2013
 
 
###

###
 CLASS TickerTemplate
 
 Template object for tickers. Defines required and
 common properties/methods. All ticker objects
 are descendants of the TickerTemplate.

###
class TickerTemplate
  constructor: (@parentElem, @flavor='select', @elNum=1) ->
    @elID = @elName + @elNum
  
  elNum: 1
  elName: 'ticker'
  elID: undefined
  parentElem: undefined
  
  update: (genomes) ->
    throw new SuperphyError "TickerTemplate method update() must be defined in child class (#{this.flavor})."
    false # return fail
 
###
 CLASS StxTicker
  
 Counts number of each subtype

###

class StxView extends TickerTemplate
  constructor: (@parentElem, @flavor, @elNum, tickerArgs) ->
    
    throw new SuperphyError 'Missing argument. MsaView constructor requires JSON alignment object.' unless msaArgs.length > 0
    
    alignmentJSON = tickerArgs[0]
    
    # Additional data to append to node names
    # Keys are genome|locus IDs
    if msaArgs[1]?
      @locusData = msaArgs[1]
      
    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum)
    
    # Format alignment object into rows of even length
    @_formatAlignment(alignmentJSON)
  
  type: 'msa'
  
  elName: 'stx_ticker'
  
  
  # FUNC update
  # Update Ticker
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
        if @locusData? && @locusData[i]?
          name += @locusData[i]
        
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
    
  
    
    
  