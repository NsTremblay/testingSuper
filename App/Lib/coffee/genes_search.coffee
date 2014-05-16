###


 File: genes_search.coffee
 Desc: Javascript functions for the genes/search page
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: May 16th, 2013
 
 
###

root = exports ? this


# FUNC initGeneList
# initialises several variables for vf/amr object list
#
# USAGE initGeneList object_array
# 
# RETURNS
# boolean
#    
root.initGeneList = (gList) ->
  
  for k,o of gList
    o.visible = true
    o.selected = false
    

# FUNC appendGeneList
# Appends genes to form. Only attaches
# genes where object.visible = true
#
# USAGE appendGeneList object_array
# 
# RETURNS
# boolean
#    
root.appendGeneList = (gList, elem, listType) ->
  
  throw new Error("Invalid listType parameter: #{listType}.") unless listType is 'vf' or listType is 'amr'
  
  for k,o of gList
    if o.visible
        id = "#{listType}_gene_#{k}"
        item = jQuery("<li><label class='checkbox'><input id='#{id}' class='checkbox' type='checkbox' value='#{k}' name='selected-#{listType}' />#{o.name} - #{o.uniquename}</label></li>")
        item.prop('checked', true) if o.selected
        elem.append(item)
      
