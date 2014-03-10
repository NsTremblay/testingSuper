###


 File: superphy.coffee
 Desc: Objects & functions for managing views in Superphy
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: March 7th, 2013
 
 
###

# Set export object and namespace
root = exports ? this
root.Superphy or= {}


###
 CLASS ViewController
  
 Captures events. Updates data and views 
 
###
class ViewController
  constructor: ->
    alert 'SuperPhy Error: jQuery must be loaded before the SuperPhy libary' unless jQuery?
    
  # Properties
  
  # View objects in window
  views: []
  
  # Main action triggered by clicking on genome
  actionType: undefined
  
  
  
  # Methods
  init: (type) ->
    unless type is 'single_select' or type is 'multi_select' or type is 'two_groups'
      alert 'SuperPhy Error: unrecognized type in ViewController init() method.'
    
    
    
  createView: (viewType, elem, submitAction) ->
    
  
  #select:
    
  #addToGroup:
    
  #submit:
    
  
    
  
    
  

# Return instance of a ViewController
unless root.ViewController
  root.ViewController = new ViewController


###
 CLASS ViewTemplate
 
 Template object for views. Defines required and
 common properties/methods. All view objects
 are descendants of the ViewTemplate.

###
class ViewTemplate
  type: undefined
  
  update: (elem, genomes) ->
    alert "Error: update() must be defined in child class."
      

###
 CLASS ListView
 
 Genome list 

###
class ListView extends ViewTemplate
  type: 'list'
  
  update: (elem, gc) ->
    
    jQuery(elem).append ->
      '<p>HELLO</p>'
      
  
# Add to global namespace
unless root.ListView
  root.ListView = ListView
    

###
 CLASS GenomeController
 
 Manages private/public genome list 

###
class GenomeController
  constructor: (@public_genomes, @private_genomes) ->
    # Initialize the viewname field
    @update()
    
  pubVisable: []
  
  pvtVisable: []
  
  visibleMeta: 
    strain: false
    serotype: false
    isolation_host: false
    isolation_source: false
    isolation_date: false
    accession: false
    
   
  # FUNC update
  # Update genome names displayed to user
  #
  # PARAMS
  # none (object variable visibleMeta is used to determine which fields are displayed)
  # 
  # RETURNS
  # undefined 
  #      
  update: ->
    for id,g of @public_genomes
      g.viewname = @label(g,@visibleMeta) 
    undefined
    
  
  # FUNC filter
  # Updates the pubVisable and pvtVisable id lists with the genome
  # Ids that passed filter in sorted order
  #
  # PARAMS
  # searchTerm - search string (any portion is matched, no 'exact'/global matching) 
  # dataField - a meta-data key name to do the search on
  # negate - a boolean indicating is user wants to do a NOT search
  # 
  # RETURNS
  # undefined
  #
  filter: (searchTerm = false, dataField = 'displayname', negate = false) ->
    
    pubGenomeIds = []
    pvtGenomeIds = []
    
    if searchTerm
      
      regex = new RegExp escapeRegExp(searchTerm), "i"
      
      
      pubGenomeIds = (id for id in Object.keys(@public_genomes) when @match(@public_genomes[id], dataField, regex, negate))
      #pvtGenomeIds = Object.keys(@private_genomes).filter(x) -> match(x, dataType, regex, negate)
    else
      pubGenomeIds = Object.keys(@public_genomes)
      pvtGenomeIds = Object.keys(@private_genomes)
    
    @pubVisable = pubGenomeIds.sort (a, b) -> @public_genomes[b].viewname - @public_genomes[a].viewname
    @pvtVisable = pvtGenomeIds.sort (a, b) -> @private_genomes[b].viewname - @private_genomes[a].viewname
    
    undefined
    
  
  # FUNC match
  # Determines if genome passes filter conditions
  #
  # PARAMS
  # genome - a single genome object from the private_/public_genomes
  # key    - a data field name in the genome object
  # regex  - a js RegExp object representing search string
  # negate - a boolean indicating whether to do NOT search
  # 
  # RETURNS
  # boolean 
  #      
  match: (genome, key, regex, negate) ->
    
    unless genome[key]?
      return false
    
    # change array into suitable string
    val = genome[key]
    val = genome[key].toString if typeIsArray genome[key]
    
    # check if any part of string matches
    if regex.test val
      if !negate
        console.log('passed')
        return true
      else
        return false
    else
      if negate
        return true
      else
        console.log('failed')
        return false
  
  
  # FUNC label
  # Genome names displayed to user, may include meta-data appended to end
  #
  # PARAMS
  # genome      - a single genome object from the private_/public_genomes
  # visableMeta - a data field name in the genome object
  #
  # RETURNS
  # string
  #      
  label: (genome, visibleMeta) ->
    na = 'NA'
    lab = [genome.displayname]
    
    # Add visible meta-data to label is specific order
    # Array values
    mtypes = ['strain', 'serotype', 'isolation_host', 'isolation_source', 'isolation_date']
    for t in mtypes
      lab.push (genome[t] ? [na]).join(' ') if visibleMeta[t]
    
    # Scalar values
    lab.push genome.primary_dbxref ? na if visibleMeta.accession
    
    # Return string
    lab.join('|')

# Add to global namespace
unless root.GenomeController
  root.GenomeController = GenomeController





###

  HELPER FUNCTIONS
  
### 

# FUNC typeIsArray
# A safer way to check if variable is array
#
# USAGE typeIsArray variable
# 
# RETURNS
# boolean 
#    
typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

# FUNC escapeRegExp
# Hides RegExp characters in a search string
#
# USAGE escapeRegExp str
# 
# RETURNS
# string 
#    
escapeRegExp = (str) -> str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")
