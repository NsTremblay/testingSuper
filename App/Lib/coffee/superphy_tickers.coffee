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
  constructor: (@parentElem, @elNum=1) ->
    @elID = @elName + @elNum
  
  elNum: 1
  elName: 'ticker'
  elID: undefined
  parentElem: undefined
  cssClass: undefined
  flavor: undefined
  
  update: (genomes) ->
    throw new SuperphyError "TickerTemplate method update() must be defined in child class (#{this.flavor})."
    false # return fail
 
###
 CLASS MetaTicker
  
 Counts number of a specified meta-data item

###

class MetaTicker extends TickerTemplate
  constructor: (@parentElem, @elNum, tickerArgs) ->
    
    super(@parentElem, @elNum)
    
    throw new SuperphyError 'Missing argument. MetaTicker constructor requires a string indicating meta-data type.' unless tickerArgs.length == 1
    
    @metaType = tickerArgs[0]
    
  
  elName: 'meta_ticker'
  cssClass: 'superphy_ticker_table'
  flavor: 'meta'
  noDataLabel: 'Not available'
  
  
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
    tickerElem = jQuery("##{@elID}")
    if tickerElem.length
      tickerElem.empty()
    else      
      tickerElem = jQuery("<table id='#{@elID}' class='#{@cssClass}'></table>")
      jQuery(@parentElem).append(tickerElem)
   
    t1 = new Date()
    
    # Update totals
    countObj = {}
    @_updateCounts(countObj, genomes.pubVisible, genomes.public_genomes)
    @_updateCounts(countObj, genomes.pvtVisible, genomes.private_genomes)
    
    # Add to table
    headElem = jQuery('<thead><tr></tr></thead>').appendTo(tickerElem)
    bodyElem = jQuery('<tbody><tr></tr></tbody>').appendTo(tickerElem)
    headRow = jQuery('<tr></tr>').appendTo(headElem)
    bodyRow = jQuery('<tr></tr>').appendTo(bodyElem)
    
    ks = (k for k of countObj).sort(a, b) ->
      if a is @noDataLabel
        return 1
      if b is @noDataLabel
        return -1
      
      if a < b
        return -1
      else if a > b
        return 1
      else
        return 0
      
        
    for k in ks
      v = countObj[k]
      headRow.append("<th>#{k}</th>")
      bodyRow.append("<td>#{v}</td>") 
    
    t2 = new Date()
    
    ft = t2-t1
    console.log('MetaTicker update elapsed time: '+ft)
   
    true # return success
    

  _updateCounts: (counts, visibleG, genomes) ->
    
    meta = @metaType
    
    console.log('META'+meta)

    for g in visibleG
      
      if genomes[g][meta]?
        if counts[genomes[g][meta]]?
          counts[genomes[g][meta]]++
        else
          counts[genomes[g][meta]] = 1
      else
        if counts[@noDataLabel]?
          counts[@noDataLabel]++
        else
          counts[@noDataLabel] = 1
      
    true
    

###
 CLASS LocusTicker
  
 Counts number of a specified meta-data item

###

class LocusTicker extends TickerTemplate
  constructor: (@parentElem, @elNum, tickerArgs) ->
    
    super(@parentElem, @elNum, @elNum)
    
    throw new SuperphyError 'Missing argument. LocusTicker constructor requires a LocusController object.' unless tickerArgs.length == 1
    
    @locusData = tickerArgs[0]
    
  
  elName: 'locus_ticker'
  cssClass: 'superphy_ticker_table'
  flavor: 'locus'
  noDataLabel: 'NA'
  
  
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
    tickerElem = jQuery("##{@elID}")
    if tickerElem.length
      tickerElem.empty()
    else      
      tickerElem = jQuery("<table id='#{@elID}' class='#{@cssClass}'></table>")
      jQuery(@parentElem).append(tickerElem)
   
    t1 = new Date()
    
    # Update totals
    countObj = @locusData.count(genomes)
    
    # Add to table
    headElem = jQuery('<thead></thead>').appendTo(tickerElem)
    bodyElem = jQuery('<tbody></tbody>').appendTo(tickerElem)
    headRow = jQuery('<tr></tr>').appendTo(headElem)
    bodyRow = jQuery('<tr></tr>').appendTo(bodyElem)
    
    ks = (k for k of countObj)
    ks.sort (a, b) ->
      if a is @noDataLabel
        return 1
      if b is @noDataLabel
        return -1
      
      if a < b
        return -1
      else if a > b
        return 1
      else
        return 0
      
        
    for k in ks
      v = countObj[k]
      headRow.append("<th>#{k}</th>")
      bodyRow.append("<td>#{v}</td>") 
    
    t2 = new Date()
    
    ft = t2-t1
    console.log('LocusTicker update elapsed time: '+ft)
   
    true # return success
    
    
  