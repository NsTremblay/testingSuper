###


 File: superphy_genes.coffee
 Desc: Javascript functions for the genes/search page
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca & Akiff Manji akiff.manji@gmail.com
 Date: June 26th, 2014
 
 
###

root = exports ? this

class GenesSearch
  constructor: (@geneList, @geneType, @categories, @tableElem, @selectedElem, @countElem, @categoriesElem, @autocompleteElem, @selectAllEl, @unselectAllEl, @multi_select=false) ->
    throw new Error("Invalid gene type parameter: #{@geneType}.") unless @geneType is 'vf' or @geneType is 'amr'
    @num_selected = 0
    @sortField = 'name'
    @sortAsc = true

    for k,o of @geneList
      o.visible = true
      o.selected = false

    @_appendGeneTable()
    @_appendCategories()

    jQuery(@autocompleteElem).keyup( () => 
      @_filterGeneList() 
    )

    jQuery(@selectAllEl).click((e) => 
      e.preventDefault()
      @_selectAllGenes(true); 
    )

    jQuery(@unselectAllEl).click((e) => 
      e.preventDefault()
      @_selectAllGenes(false); 
    )
    

  typeIsArray = Array.isArray || ( value ) -> return {}.toString.call( value ) is '[object Array]'

  _appendHeader: () ->  
    table = '<thead><tr>'
    values = []
    i = -1

    if @sortField is 'name'
      sortIcon = 'fa-sort-asc'
      sortIcon = 'fa-sort-desc' unless @sortAsc
      values[++i] = {type:'name', name:'Gene Name', sortIcon:sortIcon}
    else
      values[++i] = {type:'name', name:'Gene Name', sortIcon:'fa-sort'}

    values[++i] = {type:'uniquename', name:'Unique Name', sortIcon:'fa-sort'}

    table += @_template('th', v) for v in values

    table += '</thead></tr>'

    table
  
  _appendGenes: (visibleG, genes, type, style) ->

    table = ''

    for gId, gObj of visibleG

      row = ''

      geneObj = genes[gId]

      name = geneObj.name
      uniquename = geneObj.uniquename

      continue unless geneObj.visible

      if style is 'redirect'
        #Links
        row += @_template('td1_redirect', {klass: 'gene_table_item', name: name, type: type})

      else if style = "select"
        checked = ''
        checked = 'checked' if geneObj.selected
        row += @_template('td1_select', {klass: 'gene_table_item', g: gId, name: name, type: type, checked:checked})

      else
        return false

      row += @_template('td', {data: uniquename})
      table += @_template('tr', {row: row})

    table
        
  # FUNC _appendGeneTable
  # Appends genes to form. Only attaches
  # genes where object.visible = true
  #
  # USAGE appendGeneTable data_object
  #
  # RETURNS
  # boolean
  #    
  _appendGeneTable: () ->
    table = @tableElem
    name = "#{@geneType}-gene"
    tableElem = jQuery("<table />").appendTo(table)

    style = 'select' if @multi_select
    style = 'redirect' unless @multi_select

    tableHtml = ''
    tableHtml += @_appendHeader()
    tableHtml += '<tbody>'
    tableHtml += @_appendGenes(@_sort(@geneList, @sortField, @sortAsc), @geneList, @geneType, style)
    tableHtml += '</tbody>'

    tableElem.append(tableHtml)

    cboxes = table.find("input[name='#{name}']")
    that = @
    cboxes.change( ->
      console.log @
      obj = $(@)
      geneId = obj.val()
      checked = obj.prop('checked')
      that._selectGene([geneId], checked)
    )
    
    @_updateCount()
    
    true

  # FUNC sort
  # Sort genes by meta-data 
  #
  # PARAMS
  # gids        - a list of genome labels ala: private_/public_123445
  # metaField   - a data field to sort on
  #
  # RETURNS
  # string
  #      
  _sort: (gids, metaField, asc) ->
    #TODO: Get this working
    ###  return gids unless gids.length
   
    that = @
    gids.sort (a,b) ->
      aObj = that.genome(a)
      bObj = that.genome(b)
      
      aField = aObj[metaField]
      aName = aObj.displayname.toLowerCase()
      bField = bObj[metaField]
      bName = bObj.displayname.toLowerCase()
      
      if aField? and bField?
        
        if typeIsArray aField
          aField = aField.join('').toLowerCase()
          bField = bField.join('').toLowerCase()
        else
          aField = aField.toLowerCase()
          bField = bField.toLowerCase()
          
        if aField < bField
          return -1
        else if aField > bField
          return 1
        else
          if aName < bName
            return -1
          else if aName > bName
            return 1
          else
            return 0
            
      else
        if aField? and not bField?
          return -1
        else if bField? and not aField?
          return 1
        else
          if aName < bName
            return -1
          else if aName > bName
            return 1
          else
            return 0

    if not asc
      gids.reverse()###
      
    gids


  _template: (tmpl, values) ->
      
    html = null
    if tmpl is 'tr'
      html = "<tr>#{values.row}</tr>"
      
    else if tmpl is 'th'
      html = "<th><a class='genome-table-sort' href='#' data-genomesort='#{values.type}'>#{values.name} <i class='fa #{values.sortIcon}'></i></a></th>"
    
    else if tmpl is 'td'
      html = "<td>#{values.data}</td>"
    
    else if tmpl is 'td1_redirect'
      html = "<td class='#{values.klass}'>#{values.name} <a class='gene-table-link' href='/genes/info?#{values.type}=#{values.g}' data-gene='#{values.g}' title='#{values.name} info'><i class='fa fa-external-link'></i></a></td>"
        
    else if tmpl is 'td1_select'
      html = "<td class='#{values.klass}'><div class='checkbox'><label><input class='checkbox gene-table-checkbox gene-search-select' type='checkbox' value='#{values.g}' #{values.checked} name='#{values.type}-gene'/> #{values.name}</label> <a class='gene-table-link' href='/genes/info?#{values.type}=#{values.g}' data-gene='#{values.g}' title='#{values.name} info'><i class='fa fa-search'></i></a></div></td>"
    
    else
      throw new SuperphyError "Unknown template type #{tmpl} in TableView method _template"
      
    html

  # FUNC filterGeneList
  # Find genes that match filter and
  # append to list
  #
  # USAGE appendGeneList data_object
  # 
  # RETURNS
  # boolean
  #    
  _filterGeneList: () ->
    #DONE
    searchTerm = @autocompleteElem.val()
    
    @_matching(@geneList, searchTerm)
    
    #Table
    @tableElem.empty()

    @_appendGeneTable()
    
    true


  # FUNC matching
  # Find genes that match filter search word
  #
  # USAGE matching object_array, string
  # 
  # RETURNS
  # boolean
  #    
  _matching: (gList, searchTerm) ->
    #DONE
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
  _appendCategories: () ->
    #DONE
    categoryE = @categoriesElem
    introDiv = jQuery('<div class="gene-category-intro"></div>').appendTo(categoryE)
    introDiv.append('<span>Select category to refine list of genes:</span>')
    
    resetButt = jQuery("<button id='#{@geneType}-reset-category' class='btn btn-link'>Reset</button>").appendTo(introDiv)
    resetButt.click( (e) =>
      e.preventDefault()
      @_filterByCategory(-1,-1)
      @_resetNullCategories()
    )
    
    for k,o of @categories
      
      row1 = jQuery('<div class="row"></div>').appendTo(categoryE)
      cTitle = @_capitaliseFirstLetter(o.parent_name)
      titleDiv = jQuery("<div class='category-header col-xs-12'>#{cTitle}: </div>").appendTo(row1)
      
      if o.parent_definition?
        moreInfoId = 'category-info-'+k
        moreInfo = jQuery("<a id='#{moreInfoId}' href='#' data-toggle='tooltip' data-original-title='#{o.parent_definition}'><i class='fa fa-info-circle'></i></a>")
        titleDiv.append(moreInfo)
        moreInfo.tooltip({ placement: 'right' })
      
      row2 = jQuery('<div class="row"></div>').appendTo(categoryE)
      col2 = jQuery('<div class="col-xs-12"></div>').appendTo(row2)
      sel = jQuery("<select name='#{@geneType}-category' data-category-id='#{k}' class='form-control'></select>").appendTo(col2)
      
      for s,t of o.subcategories
        def = ""
        def = t.category_definition if t.category_definition?
        name = @_capitaliseFirstLetter(t.category_name)
        id = "subcategory-id-#{s}"
        def.replace(/\.n/g, ". &#13;");
        sel.append("<option id='#{id}' value='#{s}' title='#{def}'>#{name}</option>")
        
      sel.append("<option value='null' selected><strong>--Select Category--</strong></option>")
      
      that = @
      sel.change( ->
        obj = jQuery(@)
        catId = obj.data('category-id')
        subId = obj.val()
        
        if subId isnt 'null'
          jQuery("select[name='#{@geneType}-category'][data-category-id!='#{catId}']").val('null')
          that._filterByCategory(catId, subId)
          
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
  _filterByCategory: (catId, subcatId) ->
    #DONE
    geneIds = []
    if catId is -1
      geneIds = Object.keys(@geneList)
      
    else
      geneIds = @categories[catId].subcategories[subcatId].gene_ids
      throw new Error("Invalid category or subcategory ID: #{catId} / #{subcatId}.") unless geneIds? and typeIsArray geneIds
      o.visible = false for k,o of @geneList
    
    for g in geneIds
      o = @geneList[g]
      throw new Error("Invalid gene ID: #{g}.") unless o?
      o.visible = true
      
    #Table
    @tableElem.empty()
    @_appendGeneTable()
    
    true
  
  # FUNC selectGene
  # Update data object and elements for checked / unchecked genes\
  #
  # USAGE selectGene array, boolean, data_object
  # 
  # RETURNS
  # boolean
  #    
  _selectGene: (geneIds, checked) ->
    #DONE
    console.log geneIds
    console.log checked
    
    for g in geneIds
      @geneList[g].selected = checked
    
      if checked
        @num_selected++
      else
        @num_selected--
    
    @_updateCount()
     
    if checked
      @_addSelectedGenes(geneIds)
      
    else
      @_removeSelectedGenes(geneIds)
      
    true

  # FUNC updateCount
  # Update displayed # of genes selected
  # 
  # USAGE updateCount data_object
  #
  # RETURNS
  # boolean
  #    
  _updateCount: () ->
    #DONE
    # Stick in inner span
    innerElem = @countElem.find('span.selected-gene-count-text')
    unless innerElem.length
      innerElem = jQuery("<span class='selected-gene-count-text'></span>").appendTo(@countElem)
      
    if @geneType is 'vf'
      innerElem.text("#{@num_selected} virulence genes selected")
          
    if @geneType is 'amr'
      innerElem.text("#{@num_selected} AMR genes selected")
        
    true

  # FUNC addSelectedGenes
  # Add genes to selected box element
  # 
  # USAGE addSelectedGenes array data_object
  #
  # RETURNS
  # boolean
  #    
  _addSelectedGenes: (geneIds) ->
    #DONE
    cls = 'selected-gene-item'
    for g in geneIds
      
      gObj = @geneList[g]
      
      listEl = jQuery("<li class='#{cls}'>"+gObj.name+' - '+gObj.uniquename+'</li>')
      actionEl = jQuery("<a href='#' data-gene='#{g}'> <i class='fa fa-times'></a>")
        
      # Set behaviour
      actionEl.click (e) ->
        e.preventDefault()
        gid = @.dataset.gene
        @_selectGene([gid], false)
        $("input.gene-search-select[value='#{gid}']").prop('checked',false)
        
      # Append to list
      listEl.append(actionEl)
      @selectedElem.append(listEl)
    
    true

  # FUNC removeSelectedGenes
  # Remove genes from selected box element
  # 
  # USAGE removeSelectedGenes array data_object
  #
  # RETURNS
  # boolean
  #    
  _removeSelectedGenes: (geneIds) ->
    
    for g in geneIds
      listEl = @selectedElem.find("li > a[data-gene='#{g}']")
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
  _selectAllGenes: (checked) ->
    
    if checked
      visible = (k for k,g of @geneList when g.visible && !g.selected)
      @_selectGene(visible, true)
      $("input.gene-search-select[value='#{g}']").prop('checked',true) for g in visible
    else
      all = (k for k,g of @geneList when g.selected)
      @_selectGene(all, false)
      $("input.gene-search-select[value='#{g}']").prop('checked',false) for g in all
    
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
  prepareGenesQuery: () ->

    form = jQuery('form .genes_search')
    
    # Append genes
    for k,g of @geneList when g.selected
      input = jQuery('<input></input>')
      input.attr('type','hidden')
      input.attr('name', 'gene')
      input.val(k)
      form.append(input)        
    
    true

  # FUNC resetNullCategories
  # Reset category drop downs back to null values. Triggered
  # when clicking reset button
  # 
  # USAGE resetNullCategories data_object
  #
  # RETURNS
  # boolean
  #    
  _resetNullCategories: () ->
    el = @categoriesElem
    name = "#{@geneType}-category"
    el.find("select[name='#{name}']").val('null')
    
    true
    
  
  # FUNC capitaliseFirstLetter
  # Its obvious <- haha
  #
  # USAGE capitaliseFirstLetter string
  # 
  # RETURNS
  # string
  # 
  _capitaliseFirstLetter: (str) -> 
    str[0].toUpperCase() + str[1..-1]
    
    
  # FUNC escapeRegExp
  # Hides RegExp characters in a search string
  #
  # USAGE escapeRegExp str
  # 
  # RETURNS
  # string 
  #    
  _escapeRegExp: (str) -> str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&")

  # FUNC typeIsArray
  # A safer way to check if variable is array
  #
  # USAGE typeIsArray variable
  # 
  # RETURNS
  # boolean 
  #    

# Return instance of GeneSearch
unless root.GenesSearch
  root.GenesSearch = GenesSearch