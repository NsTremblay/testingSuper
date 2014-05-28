###


 File: genes_search.coffee
 Desc: Javascript functions for the genes/search page
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: May 16th, 2013
 
 
###

root = exports ? this

# Globals
root.numVfSelected = 0
root.numAmrSelected = 0


# FUNC initGeneList
# initialises several variables for vf/amr object list
#
# USAGE initGeneList object_array
# 
# RETURNS
# Object containing jQuery DOM elements and data object array
#    
root.initGeneList = (gList, geneType, categories, listElem, selElem, countElem, catElem, autocElem, multi_select=true) ->
  
  throw new Error("Invalid geneType parameter: #{geneType}.") unless geneType is 'vf' or geneType is 'amr'
  
  for k,o of gList
    o.visible = true
    o.selected = false
    
  dObj = {
    type: geneType
    genes: gList
    categories: categories
    num_selected: 0
    element: {
      list: listElem
      select: selElem
      count: countElem
      category: catElem
      autocomplete: autocElem
    }
    multi_select: multi_select
  }
    

# FUNC appendGeneList
# Appends genes to form. Only attaches
# genes where object.visible = true
#
# USAGE appendGeneList data_object
#
# RETURNS
# boolean
#    
root.appendGeneList = (d) ->
  
  list = d.element.list
  name = "#{d.type}-gene"
  
  for k,o of d.genes
    if o.visible
      id = "#{d.type}-gene-#{k}"
      item
      link = "<a href='/genes/info?#{d.type}=#{k}'><i class='fa fa-search'></i></a>"
      if d.multi_select
        item = jQuery("<li><label class='checkbox'><input id='#{id}' class='checkbox' type='checkbox' name='#{name}' value='#{k}'/>#{o.name} - #{o.uniquename} #{link}</label></li>")
        item.prop('checked', true) if o.selected
        
      else
         item = jQuery("<li>#{o.name} - #{o.uniquename} #{link}</li>")
      
      list.append(item)
      
  cboxes = list.find("input[name='#{name}']")
  cboxes.change( ->
    obj = $(@)
    geneId = obj.val()
    checked = obj.prop('checked')
    selectGene([geneId], checked, d)
  )
  
  updateCount(d)
  
  true
      
        
# FUNC filterGeneList
# Find genes that match filter and
# append to list
#
# USAGE appendGeneList data_object
# 
# RETURNS
# boolean
#    
root.filterGeneList = (d) ->
  
  searchTerm = d.element.autocomplete.val()
  
  matching(d.genes, searchTerm)
  
  d.element.list.empty()
  appendGeneList(d)
  
  true
        

# FUNC matching
# Find genes that match filter search word
#
# USAGE matching object_array, string
# 
# RETURNS
# boolean
#    
root.matching = (gList, searchTerm) ->
  
  regex = new RegExp escapeRegExp(searchTerm), "i"
  
  for k,g of gList
    
    val = g.name
    
    if regex.test val
      g.visible = true
      #console.log val+' passed'
      
    else
      g.visible = false
      #console.log val+' failed'
  
  true

# FUNC appendCategories
# Appends categores to form.
#
# USAGE appendGeneList data_object
# 
# RETURNS
# boolean
#
root.appendCategories = (d) ->
  
  categoryE = d.element.category
  introDiv = jQuery('<div class="gene-category-intro"></div>').appendTo(categoryE)
  introDiv.append('<span>Select category to refine list of genes:</span>')
 
  
  resetButt = jQuery("<button id='#{d.type}-reset-category' class='btn btn-link'>Reset</button>").appendTo(introDiv)
  resetButt.click( (e) ->
    e.preventDefault()
    filterByCategory(-1,-1,d)
  )
  
  for k,o of d.categories
    
    row1 = jQuery('<div class="row"></div>').appendTo(categoryE)
    cTitle = capitaliseFirstLetter(o.parent_name)
    titleDiv = jQuery("<div class='category-header col-xs-12'>#{cTitle}: </div>").appendTo(row1)
    
    if o.parent_definition?
      moreInfoId = 'category-info-'+k
      moreInfo = jQuery("<a id='#{moreInfoId}' href='#' data-toggle='tooltip' data-original-title=''#{o.parent_definition}><i class='fa fa-info-circle'></i></a>")
      titleDiv.append(moreInfo)
      moreInfo.tooltip({ placement: 'right' })
    
    row2 = jQuery('<div class="row"></div>').appendTo(categoryE)
    col2 = jQuery('<div class="col-xs-12"></div>').appendTo(row2)
    sel = jQuery("<select name='vf-category' data-category-id='#{k}' class='form-control'></select>").appendTo(col2)
    
    for s,t of o.subcategories
      def = ""
      def = t.category_definition if t.category_definition?
      name = capitaliseFirstLetter(t.category_name)
      id = "subcategory-id-#{s}"
      def.replace(/\.n/g, ". &#13;");
      sel.append("<option id='#{id}' value='#{s}' title='#{def}'>#{name}</option>")
      
    sel.append("<option value='null' selected><strong>--Select Category--</strong></option>")
    
    sel.change( ->
      obj = jQuery(@)
      catId = obj.data('category-id')
      subId = obj.val()
      
      if subId isnt 'null'
        jQuery("select[name='vf-category'][data-category-id!='#{catId}']").val('null')
        filterByCategory(catId, subId, d)
        
    )
    
  true
  
# FUNC filterByCategory
# Find genes belong to category and
# append to list
#
# USAGE filterByCategory int int data_object
# if catId == -1, reset of visible is performed
# 
# RETURNS
# boolean
#    
root.filterByCategory = (catId, subcatId, d) ->
  
  geneIds = []
  if catId is -1
    geneIds = Object.keys(d.genes)
    
  else
    geneIds = d.categories[catId].subcategories[subcatId].gene_ids
    throw new Error("Invalid category or subcategory ID: #{catId} / #{subcatId}.") unless geneIds? and typeIsArray geneIds
    o.visible = false for k,o of d.genes
  
  for g in geneIds
    o = d.genes[g]
    throw new Error("Invalid gene ID: #{g}.") unless o?
    o.visible = true
    
  d.element.list.empty()
  appendGeneList(d)
  
  true
  
# FUNC selectGene
# Update data object and elements for checked / unchecked genes\
#
# USAGE selectGene array, boolean, data_object
# 
# RETURNS
# boolean
#    
root.selectGene = (geneIds, checked, d) ->
  
  console.log geneIds
  console.log checked
  
  for g in geneIds
    d.genes[g].selected = checked
  
    if checked
      d.num_selected++
    else
      d.num_selected--
  
  updateCount(d)
   
  if checked
    addSelectedGenes(geneIds, d)
    
  else
    removeSelectedGenes(geneIds, d)
    
  true

# FUNC updateCount
# Update displayed # of genes selected
# 
# USAGE updateCount data_object
#
# RETURNS
# boolean
#    
root.updateCount = (d) ->
  
  # Stick in inner span
  innerElem = d.element.count.find('span.selected-gene-count-text')
  unless innerElem.length
    innerElem = jQuery("<span class='selected-gene-count-text'></span>").appendTo(d.element.count)
    
  if d.type is 'vf'
    innerElem.text("#{d.num_selected} virulence genes selected")
        
  if d.type is 'amr'
    innerElem.text("#{d.num_selected} AMR genes selected")
      
  true

# FUNC addSelectedGenes
# Add genes to selected box elment
# 
# USAGE addSelectedGenes array data_object
#
# RETURNS
# boolean
#    
root.addSelectedGenes = (geneIds, d) ->
  
  cls = 'selected-gene-item'
  for g in geneIds
    
    gObj = d.genes[g]
    
    listEl = jQuery("<li class='#{cls}'>"+gObj.name+'</li>')
    actionEl = jQuery("<a href='#' data-gene='#{g}'> <i class='fa fa-times'></a>")
      
    # Set behaviour
    actionEl.click (e) ->
      e.preventDefault()
      gid = @.dataset.gene
      selectGene([gid], false, d)
      $("input[value='#{gid}']").prop('checked',false)
      
    # Append to list
    listEl.append(actionEl)
    d.element.select.append(listEl)
  
      
  true 

# FUNC removeSelectedGenes
# Remove genes from selected box element
# 
# USAGE removeSelectedGenes array data_object
#
# RETURNS
# boolean
#    
root.removeSelectedGenes = (geneIds, d) ->
  
  for g in geneIds
    listEl = d.element.select.find("li > a[data-gene='#{g}']")
    listEl.parent().remove()
    
  true
  
# FUNC selectAllGenes
# Select all visible genes
#
# USAGE selectAllGenes boolean, d
#
# if checked==true, 
#   select all visible genes
# if checked==false,
#   unselect all genes 
#
# RETURNS
# boolean
#    
root.selectAllGenes = (checked, d) ->
  
  if checked
    visible = (k for k,g of d.genes when g.visible && !g.selected)
    selectGene(visible, true, d)
  else
    all = (k for k,g of d.genes when g.selected)
    selectGene(all, false, d)
  
  true
  
# FUNC submitGeneQuery
# Submit by dynamically building form with hidden
# input params
# 
# USAGE submitGeneQuery data_object data_object viewController
#
# RETURNS
# boolean
#    
root.submitGeneQuery = (vfData, amrData, viewController) ->
  
  form = jQuery('<form></form')
  form.attr('method', 'POST')
  form.attr('action', viewController.action)
  
  # Append genome params
  viewController.submitGenomes(form, 'selected')
  
  # Append VF genes
  for k,g of vfData.genes when g.selected
    input = jQuery('<input></input>')
    input.attr('type','hidden')
    input.attr('name', 'gene')
    input.val(k)
    form.append(input)
      
  for k,g of amrData.genes when g.selected
    input = jQuery('<input></input>')
    input.attr('type','hidden')
    input.attr('name', 'gene')
    input.val(k)
    form.append(input)
      
  jQuery('body').append(form)
  form.submit()
      
  true
  
  
# FUNC capitaliseFirstLetter
# Its obvious
#
# USAGE capitaliseFirstLetter string
# 
# RETURNS
# string
# 
root.capitaliseFirstLetter = (str) -> 
  str[0].toUpperCase() + str[1..-1]
  
  
# FUNC escapeRegExp
# Hides RegExp characters in a search string
#
# USAGE escapeRegExp str
# 
# RETURNS
# string 
#    
root.escapeRegExp = (str) -> str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

# FUNC typeIsArray
# A safer way to check if variable is array
#
# USAGE typeIsArray variable
# 
# RETURNS
# boolean 
#    
root.typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'



      
