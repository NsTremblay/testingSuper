###


 File: superphy.coffee
 Desc: Objects & functions for managing views in Superphy
 Author: Matt Whiteside matthew.whiteside@phac-aspc.gc.ca
 Date: March 7th, 2013
 
 
###

# Set export object and namespace
root = exports ? this
#root.Superphy or= {}

jQuery

###
 CLASS SuperphyError
 
 Error object for this library
 
###
class SuperphyError extends Error
  constructor: (@message='', @name='Superphy Error') ->


###
 CLASS ViewController
  
 Captures events. Updates data and views 
 
###
class ViewController
  constructor: ->
    throw new SuperphyError 'jQuery must be loaded before the SuperPhy libary' unless jQuery?
    throw new SuperphyError 'SuperPhy library requires the URL library' unless URL?
    throw new SuperphyError 'SuperPhy library requires the Blob library' unless Blob?
    
    
  # Properties
  
  # View objects in window
  views: []
  groups: []
  
  # Main action triggered by clicking on genome
  actionMode: false
  action: false
  
  genomeController: undefined
  
  # Methods
  init: (publicGenomes, privateGenomes, @actionMode, @action) ->
    unless @actionMode is 'single_select' or @actionMode is 'multi_select' or @actionMode is 'two_groups'
      throw new SuperphyError 'Unrecognized actionMode in ViewController init() method.'
       
    @genomeController = new GenomeController(publicGenomes, privateGenomes)
    
    # Reset view and group lists
    @views = []
    @groups = []
 
 
  createView: (viewType, elem, viewArgs...) ->
    
    # Define style of view (select|redirect)
    # to match actionMode
    clickStyle = 'select'
    
    # Current view number
    vNum = @views.length + 1
    
    # Create download link
    downloadElem = jQuery("<a href='#' data-genome-view='#{vNum}'>Download</a>")
    downloadElem.click (e) ->
      #e.preventDefault
      viewNum = parseInt(@.dataset.genomeView)
      data = viewController.downloadViews(viewNum)
      @.href = data.href
      @.download = data.file
      true
    
    elem.append(downloadElem)
    
    if @actionMode is 'single_select'
      # single_select behaviour: user clicks on single genome for more info
      clickStyle = 'redirect'
    
    if viewType is 'list'
      # New list view
      listView = new ListView(elem, clickStyle, vNum)
      listView.update(@genomeController)
      @views.push listView
      
    else if viewType is 'tree'
      # New tree view
      treeView = new TreeView(elem, clickStyle, vNum, viewArgs);
      treeView.update(@genomeController)
      @views.push treeView
      
    else
      throw new SuperphyError 'Unrecognized viewType in ViewController createView() method.'
      return false
      
    return true # return success
    
  createGroup: (boxEl, buttonEl) ->
    
    # Current view number
    gNum = @groups.length + 1
    
    # New list view
    grpView = new GroupView(boxEl, 'select', gNum)
    grpView.update(@genomeController)
    @groups.push grpView
    
    # Add response to button click
    buttonEl.click (e) ->
      e.preventDefault()
      viewController.addToGroup(gNum)
      
    return true # return success
  
  select: (g, checked) ->
    @genomeController.select(g, checked)
 
    true
    
  redirect: (g) ->
    alert('Genome '+g+' redirected!')
    true
    
  addToGroup: (grp) ->
    # Get all currently selected genomes
    selected = @genomeController.selected()
    console.log(selected)
    
    # Change genome properties
    @genomeController.assignGroup(selected, grp)
    
    # Unselect this set now that its added to a group
    @genomeController.unselectAll()
    
    # Add to group box
    i = grp - 1
    @groups[i].add(selected, @genomeController)
    
    # Update views (class, checked, etc)
    v.update(@genomeController) for v in @views
    
  removeFromGroup: (genomeID, grp) ->
    # Remove single genome from list
    
    console.log('deleting '+genomeID)
    
    # Change genome properties
    # Convert to Set format
    gset = @genomeController.genomeSet([genomeID])
    @genomeController.deleteGroup(gset)
    
    # Delete from list element
    i = grp - 1
    @groups[i].remove(genomeID)
    
    # Update style for genomes in views
    v.updateCSS(gset, @genomeController) for v in @views

    true
     
    
  #submit:
  
  viewAction: (vNum, viewArgs...) ->
    @views[vNum].viewAction(this.genomeController, viewArgs)
    true
    
  getView: (vNum) ->
    @views[vNum]
  
  
  updateViews: (option, checked) ->
    
    @genomeController.updateMeta(option, checked)
    
    v.update(@genomeController) for v in @views
    v.update(@genomeController) for v in @groups
    
    true
    
  downloadViews: (viewNum) ->
    
    # External libraries needed to download files
    url = window.URL || window.webkitURL
    blob = window.Blob
    
    dump = @views[viewNum-1].dump(@genomeController)
    
    file = new blob([dump.data], {type: dump.type})
    href = url.createObjectURL(file);
    file = "superphy_download.#{dump.ext}"
    
    return {
      href: href
      file: file
    }
  
  # FUNC metaForm
  # Build and attach form used to alter genome meta-data displayed
  #
  # PARAMS
  # jQuery element object to pin form to
  # 
  # RETURNS
  # boolean 
  #      
  metaForm: (elem) ->
    
    # Build & attach form
    form = '<div style="display:inline-block;">'+  
    '<button type="button" class="btn btn-mini btn-info" data-toggle="collapse" data-target="#meta-display">'+
    '<i class=" icon-eye-open icon-white"></i>'+
    '<span class="caret"></span>'+
    '</button>'+
    '<div id="meta-display" class="collapse out">'+
    '<div style="padding:10px;">Change meta-data displayed:</div>'+
    '<form class="form-horizontal">'+
    '<fieldset>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="accession"> Accession # </label>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="strain"> Strain </label>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="serotype"> Serotype </label>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="isolation_host"> Isolation Host </label>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="isolation_source"> Isolation Source </label>'+
    '<label><input class="meta-option" type="checkbox" name="meta-option" value="isolation_date"> Isolation Date </label>'+                                                    
    '</fieldset>'+
    '</form>'+
    '</div>'+
    '</div>'+
    '</div>'
    
    elem.append(form)
    
    # Set response
    jQuery('input[name="meta-option"]').change ->
      #alert(@.value, @.checked)
      viewController.updateViews(@.value, @.checked)
      
    true
    
  # FUNC filterViews
  # Identify genomes that match query and update
  # views with the new visible genome lists. Submitting empty form
  # or clicking clear button remove any filter
  #
  # PARAMS
  # string indicating if the 'fast' or 'advanced' form was submitted
  # 
  # RETURNS
  # boolean 
  #      
  filterViews: (filterForm) ->
    
    searchTerms = null
    
    if filterForm is 'fast'
      # Fast form - basic filtering of name
      
      # retrieve search term
      term = jQuery("#fast-filter > input").val().toLowerCase()
      
      if term? and term.length
        searchTerms = []
        searchTerms.push { searchTerm: term, dataField: 'displayname', negate: false }
        
    else
      # Advanced form - specified fields, terms
      searchTerms = @_parseFilterForm()
    
    @genomeController.filter(searchTerms)
    @_toggleFilterStatus()
    v.update(@genomeController) for v in @views
    
    true
    
  # FUNC resetFilter
  # Removes any filter applied, displaying all genomes
  #
  # RETURNS
  # boolean 
  #      
  resetFilter: ->
    @genomeController.filter()
    @_toggleFilterStatus()
    @_clearFilterForm()
    v.update(@genomeController) for v in @views
    
  # FUNC filterForm
  # Build and attach form used to filter genome by name/property
  #
  # PARAMS
  # jQuery element object to pin form to
  # 
  # RETURNS
  # boolean 
  #      
  filterForm: (elem) ->
    
    # Add form selector
    filtType = jQuery('<div id="select-filter-form"></div>')
    fastLab = jQuery('<label class="radio">Basic</label>')
    fastRadio = jQuery('<input type="radio" name="filter-form-type" value="fast" checked>')
    
    fastRadio.change (e) ->
      if this.checked?
        jQuery("#fast-filter").show()
        jQuery("#adv-filter").hide()
      true
    
    fastLab.append(fastRadio)
    filtType.append(fastLab)
    
    advLab = jQuery('<label class="radio">Advanced</label>')
    advRadio = jQuery('<input type="radio" name="filter-form-type" value="advanced">')
    
    advRadio.change (e) ->
      if this.checked?
        jQuery("#fast-filter").hide()
        jQuery("#adv-filter").show()
      true
    
    advLab.append(advRadio)
    filtType.append(advLab)
    elem.append(filtType)
    
    # Add filter status bar
    numVisible = @genomeController.filtered
    filterStatus = jQuery('<div id="filter-status"></div>')
    filterOn = jQuery("<div id='filter-on'>Filter active. #{numVisible} genomes visible.</div>")
    filterOff = jQuery('<div id="filter-off"></div>')
    delFilterButton = jQuery('<button id="remove-filter" type="button">Clear</button>')
    delFilterButton.click (e) ->
      e.preventDefault()
      viewController.resetFilter()  
    filterOn.append(delFilterButton)
    
    if numVisible > 0
      filterOn.show()
      filterOff.hide()
    else 
      filterOn.hide()
      filterOff.show()
      
    filterStatus.append(filterOn)
    filterStatus.append(filterOff)
    elem.append(filterStatus)
    
    
    # Build & attach simple fast form
    sf = jQuery("<div id='fast-filter'></div>")
    @addFastFilter(sf)
    elem.append(sf)
    
    # Build & attach advanced form
    advForm = jQuery("<div id='adv-filter'></div>")
    @addAdvancedFilter(advForm)
    advForm.hide()
    elem.append(advForm)
    
    true
      
  _toggleFilterStatus: ->
    
    numVisible = @genomeController.filtered
    filterOn = jQuery('#filter-on')
    filterOff = jQuery('#filter-off')
    
    if numVisible > 0
      filterOn.text("Filter active. #{numVisible} genomes visible.")
      filterOn.show()
      filterOff.hide()
    else 
      filterOn.hide()
      filterOff.show()
      
    true
    
   _clearFilterForm: ->
    
    # Remove, build & attach simple fast form
    sf = jQuery("#fast-filter")
    sf.empty()
    @addFastFilter(sf)
    
    # Remove, build & attach advanced form
    advForm = jQuery("#adv-filter")
    advForm.empty()
    @addAdvancedFilter(advForm)
      
    true
    
  addAdvancedFilter: (elem) ->
    
    advRows = jQuery("<div id='adv-filter-rows'></div>")
    elem.append(advRows)
    @addFilterRow(advRows, 1)
    
    # Create execution button
    advButton = jQuery('<button id="adv-filter-submit" type="button">Filter</button>')
    elem.append(advButton)
    advButton.click (e) ->
      e.preventDefault
      viewController.filterViews('advanced')
    
    # Add term button
    addRow = jQuery('<a href="#" class="adv-filter-addition">Add term</a>')
    
    addRow.click (e) -> 
      e.preventDefault()
      rows = jQuery('.adv-filter-row')
      rowI = rows.length + 1
      viewController.addFilterRow(jQuery('#adv-filter-rows'), rowI)
     
    elem.append(addRow)
      
    true
      
  # FUNC addFilterRow
  # Adds additional search term row to advanced filter form.
  # Multiple search terms are joined using boolean operators.
  #
  # PARAMS
  # elem - jQuery element object of rows
  # rowNum - sequential number for new row
  # 
  # RETURNS
  # boolean 
  #       
  addFilterRow: (elem, rowNum) ->
    
    # Row wrapper
    row = jQuery('<div class="adv-filter-row" data-filter-row="' + rowNum + '"></div>').appendTo(elem)
    
    # Term join operation
    if rowNum isnt 1
      jQuery('<select name="adv-filter-op" data-filter-row="' + rowNum + '">' +
        '<option value="and" selected="selected">AND</option>' +
        '<option value="or">OR</option>' +
        '<option value="not">NOT</option>' +
        '</select>').appendTo(row)
    
    # Field type
    dropDown = jQuery('<select name="adv-filter-field" data-filter-row="' + rowNum + '"></select>').appendTo(row)
    for k,v of @genomeController.metaMap
        dropDown.append('<option value="' + k + '">' + v + '</option>')
    
    dropDown.append('<option value="displayname" selected="selected">Genome name</option>')
    
    # Change type of search term box depending on field type
    dropDown.change ->
      thisRow = this.dataset.filterRow
      if @.value is 'isolation_date'
        jQuery('.adv-filter-keyword[data-filter-row="' + thisRow + '"]').hide()
        jQuery('.adv-filter-date[data-filter-row="' + thisRow + '"]').show()
      else
        jQuery('.adv-filter-keyword[data-filter-row="' + thisRow + '"]').show()
        jQuery('.adv-filter-date[data-filter-row="' + thisRow + '"]').hide()
      true
    
    # Keyword-based search wrapper
    keyw = jQuery('<div class="adv-filter-keyword" data-filter-row="' + rowNum + '"></div>)')
    
    # Search term box
    jQuery('<input type="text" name="adv-filter-term" data-filter-row="' + rowNum + '" placeholder="Keyword"></input>').appendTo(keyw)
    keyw.appendTo(row)

    # Date-based search wrapper
    dt = jQuery('<div class="adv-filter-date" data-filter-row="' + rowNum + '"></div>)')
    dt.append('<select name="adv-filter-before" data-filter-row="' + rowNum + '">' +
      '<option value="before" selected="selected">before</option>' +
      '<option value="after">after</option>' +
      '</select>')
    dt.append('<input type="text" name="adv-filter-year" data-filter-row="' + rowNum + '" placeholder="YYYY"></input>')
    dt.append('<input type="text" name="adv-filter-mon" data-filter-row="' + rowNum + '" placeholder="MM"></input>')
    dt.append('<input type="text" name="adv-filter-day" data-filter-row="' + rowNum + '" placeholder="DD"></input>')
    dt.hide()
    dt.appendTo(row)
    
    # Delete button
    if rowNum isnt 1
      delRow = jQuery('<a href="#" class="adv-filter-subtraction" data-filter-row="' + rowNum + '">Remove term</a>')
      delRow.appendTo(row)

      # Delete row wrapper
      delRow.click (e) ->
        e.preventDefault()
        thisRow = this.dataset.filterRow
        jQuery('.adv-filter-row[data-filter-row="' + thisRow + '"]').remove()
  
    true
    
  # FUNC addSimpleFilter
  # Perform 'as-you-type' filter based on displayed name.
  #
  # PARAMS
  # elem - jQuery element object for simple form wrapper
  #
  # 
  # RETURNS
  # boolean 
  #       
  addFastFilter: (elem) ->
    
    # Search term box
    tBox = jQuery('<input type="text" name="fast-filter-term" placeholder="Filter by..."></input>')
    
    # Filter after keyup
    #tBox.keyup (e) ->
    #  viewController.filterViews('fast')
      
    # Create execution button
    fastButton = jQuery('<button id="fast-filter-submit" type="button">Filter</button>')
    fastButton.click (e) ->
      e.preventDefault
      viewController.filterViews('fast')
      
    # Attach elements
    tBox.appendTo(elem)
    fastButton.appendTo(elem)
    
    true
    
  # FUNC _parseFilterForm
  # Retrieves the input from the advanced filter form and
  # generates a searchTerms array
  #
  # RETURNS
  # array of searchTerms objects (see _runFilter method)
  # or null if form is missing data
  #
  _parseFilterForm:  ->
    
    rows = jQuery('.adv-filter-row')
    searchTerms = []
    
    for row in rows
      t = {}
      rowNum = parseInt(row.dataset.filterRow)
      
      # Retrieve dataField
      df = jQuery("[name='adv-filter-field'][data-filter-row='#{rowNum}']").val()
      t.dataField = df
      
      isDate = false
      isDate = true if df is 'isolation_date'
      
      if !isDate
        # Retrieve keyword
        term = jQuery("[name='adv-filter-term'][data-filter-row='#{rowNum}']").val()
        
        term = trimInput term, 'keyword'
        return null unless term?
        
        t.searchTerm = term
        
      else
        # Retrieve date
        bef = jQuery("[name='adv-filter-before'][data-filter-row='#{rowNum}']").val()
        unless bef is 'before' or bef is 'after'
          throw new SuperphyError('Invalid input in advanced filter form. Element "adv-filter-before" must contain strings "before","after".')
        isBefore = true
        isBefore = false if bef is 'after'
        
        # Year
        yr = jQuery("[name='adv-filter-year'][data-filter-row='#{rowNum}']").val()
        
        yr = trimInput yr, 'Year'
        return null unless yr?
        
        unless /^[1-9][0-9]{3}$/.test(yr)
          alert('Error: invalid Year.')
          return null
       
        # Month
        # Ignore empty month field, use january as default
        mn = jQuery("[name='adv-filter-mon'][data-filter-row='#{rowNum}']").val()
        mn = jQuery.trim(mn) if mn?
        
        if mn? and mn.length
          unless /^[0-9]{1,2}$/.test(mn)
            alert('Error: invalid Month.')
            return null
          
        else
          mn = '01'
          
        # Day
        # Ignore empty day field, use 1st default
        dy = jQuery("[name='adv-filter-day'][data-filter-row='#{rowNum}']").val()
        dy = jQuery.trim(dy) if dy?
        
        if dy? and dy.length
          unless /^[0-9]{1,2}$/.test(dy)
            alert('Error: invalid Day.')
            return null
          
        else
          dy = '01'
        
        date = Date.parse("#{yr}-#{mn}-#{dy}")
        if isNaN date
          alert('Error: invalid date.')
          return null
        
        t.date = date
        t.before = isBefore
        
        
      unless rowNum == 1
        # Subsequent terms have join operators
        op = jQuery("[name='adv-filter-op'][data-filter-row='#{rowNum}']").val()
        negate = false
        
        unless op is 'or' or op is 'and' or op is 'not'
          throw new SuperphyError('Invalid input in advanced filter form. Element "adv-filter-op" must contain strings "and","or","not".')
        
        if op is 'not'
          op = 'and'
          negate = true
          
        t.op = op
        t.negate = negate
        
        searchTerms.push t
        
      else
        # Currently, the first term cannot be negated
        t.negate = false
        searchTerms.unshift t
        
    searchTerms

# Return instance of a ViewController
unless root.ViewController
  root.viewController = new ViewController


###
 CLASS ViewTemplate
 
 Template object for views. Defines required and
 common properties/methods. All view objects
 are descendants of the ViewTemplate.

###
class ViewTemplate
  constructor: (@parentElem, @style='select', @elNum=1) ->
    @elID = @elName + @elNum
  
  type: undefined
  
  elNum: 1
  elName: 'view'
  elID: undefined
  parentElem: undefined
  
  # Default is 'select' where elements styled for on/off checkbox behaviour.
  # Other option is 'redirect', elements styled for clicking on genome to go to page
  style: 'select'
  
  update: (genomes) ->
    throw new SuperphyError "ViewTemplate method update() must be defined in child class (#{this.type})."
    false # return fail
    
  updateCSS: (gset, genomes) ->
    throw new SuperphyError "ViewTemplate method updateCSS() must be defined in child class (#{this.type})."
    false # return fail
    
  select: (genome, isSelected) ->
    throw new SuperphyError "ViewTemplate method select() must be defined in child class (#{this.type})."
    false # return fail
  
  dump: (genomes) ->
    throw new SuperphyError "ViewTemplate method dump() must be defined in child class (#{this.type})."
    false # return fail
    
  cssClass: ->
    # For each list element
    @elName + '_item'
    
    
      

###
 CLASS ListView
 
 Genome list 

###
class ListView extends ViewTemplate
  type: 'list'
  
  elName: 'genome_list'
  
  # FUNC update
  # Update genome list view
  #
  # PARAMS
  # parent jQuery element object
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  update: (genomes) ->
    
    # create or find list element
    listElem = jQuery("##{@elID}")
    if listElem.length
      listElem.empty()
    else      
      listElem = jQuery("<ul id='#{@elID}'/>")
      jQuery(@parentElem).append(listElem)
   
    # append genomes to list
    t1 = new Date()
    @_appendGenomes(listElem, genomes.pubVisible, genomes.public_genomes, @style)
    listElem.append ->
      "<li class='genome_list_spacer'>---- USER-SUBMITTED GENOMES ----</li>"
    @_appendGenomes(listElem, genomes.pvtVisible, genomes.private_genomes, @style)
    t2 = new Date()
    
    ft = t2-t1
    console.log('ListView update elapsed time: '+ft)
    
    true # return success
  
  _appendGenomes: (el, visibleG, genomes, style) ->
    
    # View class
    cls = @cssClass()
    
    for g in visibleG
      
      thiscls = cls
      thiscls = cls+' '+genomes[g].cssClass if genomes[g].cssClass?
      
      if style == 'redirect'
        # Links
        
        # Create elements
        listEl = jQuery("<li class='#{thiscls}'>"+genomes[g].viewname+'</li>')
        actionEl = jQuery("<a href='#' data-genome='#{g}'><i class='icon-search'></i> info</a>")
        
        # Set behaviour
        actionEl.click (e) ->
          e.preventDefault()
          gid = @.dataset.genome
          viewController.redirect(gid)
        
        # Append to list
        listEl.append(actionEl)
        el.append(listEl)
        
      else if style == 'select'
        # Checkboxes
        
        # Create elements
        checked = ''
        checked = 'checked' if genomes[g].isSelected
        listEl = jQuery("<li class='#{thiscls}'></li>")
        labEl = jQuery("<label class='checkbox'>"+genomes[g].viewname+"</label>")
        actionEl = jQuery("<input class='checkbox' type='checkbox' value='#{g}' #{checked}/>")
        
        # Set behaviour
        actionEl.change (e) ->
          e.preventDefault()
          viewController.select(@.value, @.checked)
        
        # Append to list
        labEl.append(actionEl)
        listEl.append(labEl)
        el.append(listEl)
        
      else
        return false
      
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
    listEl = jQuery("##{@elID}")
    throw new SuperphyError "DOM element for list view #{@elID} not found. Cannot call ListView method updateCSS()." unless listEl? and listEl.length
    
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
      itemEl = null
      
      if @style == 'redirect'
        # Link style
        
        # Find element
        descriptor = "li > a[data-genome='#{g}']"
        itemEl = el.find(descriptor)
       
      else if @style == 'select'
        # Checkbox style
        
        # Find element
        descriptor = "li input[value='#{g}']"
        itemEl = el.find(descriptor)
   
      else
        return false
      
      unless itemEl? and itemEl.length
        throw new SuperphyError "List element for genome #{g} not found in ListView #{@elID}"
        return false
      
      console.log("Updating class to #{thiscls}")
      liEl = itemEl.parents().eq(1)
      #console.log("Current class for list li: "+liEl.class)  
      liEl.attr('class', thiscls)
      #console.log("Updated class for list li: "+liEl.class())  
        
        
    true # success
  
  # FUNC dump
  # Generate CSV tab-delimited representation of all genomes and meta-data
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
    
    # Create complete list of meta-types
    # make all visible
    fullMeta = {}
    fullMeta[k] = true for k of genomes.visibleMeta
    
    output = ''
    # Output header
    header = (genomes.metaMap[k] for k of fullMeta)
    header.unshift "Genome name"
    output += "#" + header.join("\t") + "\n"
    
    # Output public set
    for id,g of genomes.public_genomes
      output += genomes.label(g,fullMeta,"\t") + "\n"
      
    # Output private set
    for id,g of genomes.private_genomes
      output += genomes.label(g,fullMeta,"\t") + "\n"
      
    return {
      ext: 'csv'
      type: 'text/plain'
      data: output 
    }
    
 
###
 CLASS GroupView
 
 A special type of genome list that is used to temporarily store the user's
 selected genomes.
 
 Only one 'style' which provides a remove button to remove group from group.
 Will be updated by changes to the meta-display options but not by filtering.

###
class GroupView extends ViewTemplate
  type: 'group'
  
  elName: 'group'
  
  # FUNC update
  # Update genome list view
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  update: (genomes) ->
    
    # create or find list element
    listElem = jQuery("##{@elID}")
    if listElem.length
      listElem.empty()
    else      
      listElem = jQuery("<ul id='#{@elID}'/>")
      jQuery(@parentElem).append(listElem)
   
    # append group genomes to list
    ingrp = genomes.grouped(@elNum)
    @_appendGenomes(listElem, ingrp.public, genomes.public_genomes)
    @_appendGenomes(listElem, ingrp.private, genomes.private_genomes)
    
    true # return success
  
  # FUNC add
  # Add single genome to list view
  # Should be faster than calling update (which will reinsert all genomes)
  #
  # PARAMS
  # genomeController object
  # 
  # RETURNS
  # boolean 
  #      
  add: (genomeSet, genomes) ->
    
    # create or find list element
    listElem = jQuery("##{@elID}")
    if not listElem.length    
      listElem = jQuery("<ul id='#{@elID}'/>")
      jQuery(@parentElem).append(listElem)
    
    if genomeSet.public?
      @_appendGenomes(listElem, genomeSet.public, genomes.public_genomes)
        
    if genomeSet.private?
      @_appendGenomes(listElem, genomeSet.private, genomes.private_genomes)
      
  _appendGenomes: (el, visibleG, genomes) ->
    
    # View class
    cls = @cssClass()
    
    for g in visibleG
      # Includes remove links
      
      # Create elements
      listEl = jQuery("<li class='#{cls}'>"+genomes[g].viewname+'</li>')
      actionEl = jQuery("<a href='#' data-genome='#{g}' data-genome-group='#{@elNum}'> remove</a>")
      
      # Set behaviour
      actionEl.click (e) ->
        e.preventDefault()
        gid = @.dataset.genome
        grp = @.dataset.genomeGroup
        console.log('clicked remove on '+gid)
        viewController.removeFromGroup(gid, grp)
      
      # Append to list
      listEl.append(actionEl)
      el.append(listEl)
      
    true
    
  remove: (gid) ->

    # Retrieve list DOM element    
    listEl = jQuery("##{@elID}")
    throw new SuperphyError "DOM element for group view #{@elID} not found. Cannot call GroupView method remove()." unless listEl? and listEl.length
    
    # Find genome DOM element
    descriptor = "li > a[data-genome='#{gid}']"
    linkEl = listEl.find(descriptor)
    
    unless linkEl? and linkEl.length
      throw new SuperphyError "List item element for genome #{gid} not found in GroupView #{@elID}"
      return false
      
    # Remove list item element from selected list
    linkEl.parent('li').remove()
      
    true
    

###
 CLASS GenomeController
 
 Manages private/public genome list 

###
class GenomeController
  constructor: (@public_genomes, @private_genomes) ->
 
    @update() # Initialize the viewname field
    @filter() # Initialize the visible genomes
    
    
  pubVisible: []
  
  pvtVisible: []
  
  visibleMeta: 
    strain: false
    serotype: false
    isolation_host: false
    isolation_source: false
    isolation_date: false
    accession: false
    
  metaMap:
    'strain': 'Strain',
    'serotype': 'Serotype',
    'isolation_host': 'Host',
    'isolation_source': 'Source',
    'isolation_date': 'Date of isolation',
    'accession': 'Accession ID'
    
  publicRegexp: new RegExp('^public_')
  privateRegexp: new RegExp('^private_')
  
  filtered: 0
   
  # FUNC update
  # Update genome names displayed to user
  #
  # PARAMS
  # none (object variable visibleMeta is used to determine which fields are displayed)
  # 
  # RETURNS
  # boolean 
  #      
  update: ->
    # Update public set
    for id,g of @public_genomes
      g.viewname = @label(g,@visibleMeta)
      
    # Update private set
    for id,g of @private_genomes
      g.viewname = @label(g,@visibleMeta)
      
    true
    
  
  # FUNC filter
  # Updates the pubVisable and pvtVisable id lists with the genome
  # Ids that passed filter in sorted order
  #
  # PARAMS
  # searchTerms - an array of objects containing the following properties:
  #   searchTerm[string]: match string or date 
  #   dataField[string]: genome attribute to use in search (e.g. isolation_date)
  #   negate[boolean]: return genomes that do not pass filter
  #   op[string,optional] - and,or logical operators used to join multiple queries. First term should not have an operator
  # -OR-
  #   dataField[string]: 'isolation_date'
  #   date[string]: a date string YYYY-MM-DD
  #   before[boolean]: indicates before/after date
  #   op[string,optional] - see above
  # 
  # RETURNS
  # boolean
  #
  filter: (searchTerms = null) ->
    
    pubGenomeIds = []
    pvtGenomeIds = []

    if searchTerms?     
      results = @_runFilter(searchTerms);
      
      pubGenomeIds = results.public;
      pvtGenomeIds = results.private;
      
      @filtered = pubGenomeIds.length + pvtGenomeIds.length
      
      # Reset visible variable for all genomes
      g.visible = false for i,g of @public_genomes
      g.visible = false for i,g of @private_genomes
      
      # Set visible variable for genomes that passed filter
      @public_genomes[g].visible = true for g in pubGenomeIds
      @private_genomes[g].visible = true for g in pvtGenomeIds
      
    else
      pubGenomeIds = Object.keys(@public_genomes)
      pvtGenomeIds = Object.keys(@private_genomes)
      
      @filtered = 0
      
      # Reset visible variable for all genomes
      g.visible = true for i,g of @public_genomes
      g.visible = true for i,g of @private_genomes
    
    @pubVisible = pubGenomeIds.sort (a, b) => cmp(@public_genomes[a].viewname, @public_genomes[b].viewname)
    @pvtVisible = pvtGenomeIds.sort (a, b) => cmp(@private_genomes[a].viewname, @private_genomes[b].viewname)
    
    true
    
  
  # FUNC _runFilter
  # Calls match function for each search term and combines results for multi-term queries
  #
  # PARAMS
  # An array of searchTerm objects defined as:
  # searchTerm - search string (any portion is matched, no 'exact'/global matching) 
  # dataField  - a meta-data key name to do the search on
  # negate     - a boolean indicating is user wants to do a NOT search
  # op         - a string containing 'and/or'. The first term must not contain an op property.
  #              Subsequent terms must contain the op property.
  #
  #   -OR-, when dataField = 'isolation_date'
  #
  # dataField  - must be 'isolation_date'
  # date       - a date string in the format YYYY-MM-DD
  # before     - a boolean indicated 'before/after'
  # op         - see above
  #
  # RETURNS
  # two arrays
  #
  _runFilter: (searchTerms) ->
    
    unless typeIsArray searchTerms
      throw new SuperphyError('Invalid argument. GenomeController method _runFilter() requires array of search term objects as input.');
    
    # Start with entire set
    pubGenomeIds = Object.keys(@public_genomes)
    pvtGenomeIds = Object.keys(@private_genomes)
    firstTerm = true
    
    for t in searchTerms
      console.log(t)
     
      if firstTerm
        # Validate the first term just to do a quick check that input type is correct
        throw new SuperphyError("Invalid filter input. First search term object cannot contain an operator property 'op'.") if t.op?
        
        unless t.dataField is 'isolation_date'
          # Non-date form
          throw new SuperphyError("Invalid filter input. Search term objects must contain a 'searchTerm' property.") unless t.searchTerm?
          throw new SuperphyError("Invalid filter input. Search term objects must contain a 'dataField' property.") unless t.dataField?
          throw new SuperphyError("Invalid filter input. Search term objects must contain a 'negate' property.") unless t.negate?
        else
          # Date form
          throw new SuperphyError("Invalid filter input. Date objects must contain a 'searchTerm' property.") unless t.dataField?
          throw new SuperphyError("Invalid filter input. Date objects must contain a 'date' property.") unless t.date?
          throw new SuperphyError("Invalid filter input. Date objects must contain a 'before' property.") unless t.before?
          
        firstTerm = false

      else
         throw new SuperphyError("Invalid filter input. Subsequent search term objects must contain an operator property 'op'.") unless t.op?
 
      if t.op? and t.op is 'or'
        # Union operation runs on whole set
        
        pubSet = []
        pubSet = []
      
        if t.dataField is 'isolation_date'
          # Date comparison
          pubSet = (id for id in Object.keys(@public_genomes) when @passDate(@public_genomes[id], t.before, t.date))
          pvtSet = (id for id in Object.keys(@private_genomes) when @passDate(@private_genomes[id], t.before, t.date))
        else
          # String matching
          regex = new RegExp escapeRegExp(t.searchTerm), "i"
          pubSet = (id for id in Object.keys(@public_genomes) when @match(@public_genomes[id], t.dataField, regex, t.negate))
          pvtSet = (id for id in Object.keys(@private_genomes) when @match(@private_genomes[id], t.dataField, regex, t.negate))
          
        # Union with previous results
        pubGenomeIds = @union(pubGenomeIds, pubSet)
        pvtGenomeIds = @union(pvtGenomeIds, pvtSet)
          
      else
        # Intersection operation runs on current matched subset
        
        if t.dataField is 'isolation_date'
          # Date comparison
          pubSet = (id for id in pubGenomeIds when @passDate(@public_genomes[id], t.before, t.date))
          pvtSet = (id for id in pvtGenomeIds when @passDate(@private_genomes[id], t.before, t.date))
          pubGenomeIds = pubSet
          pvtGenomeIds = pvtSet
        else
          # String matching
          regex = new RegExp escapeRegExp(t.searchTerm), "i"
          pubSet = (id for id in pubGenomeIds when @match(@public_genomes[id], t.dataField, regex, t.negate))
          pvtSet = (id for id in pvtGenomeIds when @match(@private_genomes[id], t.dataField, regex, t.negate))
          pubGenomeIds = pubSet
          pvtGenomeIds = pvtSet
        
    return { public: pubGenomeIds, private: pvtGenomeIds }
  
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
    val = genome[key].toString() if typeIsArray genome[key]
    
    # check if any part of string matches
    if regex.test val
      if !negate
        #console.log('passed'+val)
        return true
      else
        return false
    else
      if negate
        return true
      else
        #console.log('failed'+val)
        return false
  
  # FUNC passDate
  # Determines if genome passes date conditions
  #
  # PARAMS
  # genome - a single genome object from the private_/public_genomes
  # before - a boolean indicating criteria 'before/after'
  # date   - a Date object
  # 
  # RETURNS
  # boolean 
  #      
  passDate: (genome, before, date) ->
    
    unless genome['isolation_date']?
      return false
    
    # Parse date
    # There should only be one date assigned
    val = genome['isolation_date'][0]
    d2 = Date.parse(val);
    
    # Compae dates
    if before
      if d2 < date
        return true
      else
        return false
    else
      if d2 > date
        return true
      else
        return false  
  
  # FUNC union
  # Returns the union of two arrays
  #
  # PARAMS
  # arr1
  # arr2
  # 
  # RETURNS
  # array 
  #      
  union: (arr1, arr2) ->
    
    arr = []
    
    for i in arr1.concat(arr2)
      unless i in arr
        arr.push i
        
    arr
      
  # FUNC label
  # Genome names displayed to user, may include meta-data appended to end
  #
  # PARAMS
  # genome      - a single genome object from the private_/public_genomes
  # visibleMeta - a data field name in the genome object
  #
  # RETURNS
  # string
  #      
  label: (genome, visibleMeta, joinStr = '|') ->
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
    lab.join(joinStr)
    
  updateMeta: (option, checked) ->
    
    unless @visibleMeta[option]?
      throw new SuperphyError 'unrecognized option in GenomeController method updateVisibleMeta()'
      return false
      
    unless checked is true or checked is false
      throw new SuperphyError 'invalid checked argument in GenomeController method updateVisibleMeta()'
      return false
    
    # toggle value
    @visibleMeta[option] = checked
      
    @update()
    
    true
    
  select: (g, checked) ->
    
    if @publicRegexp.test(g)
      @public_genomes[g].isSelected = checked 
      alert('selected public: '+g+' value:'+checked)
    else 
      @private_genomes[g].isSelected = checked
      alert('selected private: '+g+' value:'+checked)
    
    true
    
  selected: ->
    pub = []
    pvt = []
    pub = (k for k,v of @public_genomes when v.isSelected? and v.isSelected is true)
    pvt = (k for k,v of @private_genomes when v.isSelected? and v.isSelected is true)
    
    return { public: pub, private: pvt }
    
  unselectAll: ->
    for k,v of @public_genomes
      v.isSelected = false if v.isSelected?
      
    for k,v of @private_genomes
      v.isSelected = false if v.isSelected?
      
  
  assignGroup: (gset, grpNum) ->
    if gset.public? and typeof gset.public isnt 'undefined'
      for g in gset.public
        @public_genomes[g].assignedGroup = grpNum
        cls = 'genome_group'+grpNum
        @public_genomes[g].cssClass = cls
        
    if gset.private? and typeof gset.private isnt 'undefined'
      for g in gset.private
        @private_genomes[g].assignedGroup = grpNum
        cls = 'genome_group'+grpNum
        @private_genomes[g].cssClass = cls
    
    true
    
  deleteGroup: (gset) ->
    if gset.public? and typeof gset.public isnt 'undefined'
      for g in gset.public
        @public_genomes[g].assignedGroup = null
        @public_genomes[g].cssClass = null
        
    if gset.private? and typeof gset.public isnt 'undefined'
      for g in gset.private
        @private_genomes[g].assignedGroup = null
        @private_genomes[g].cssClass = null
    
    true
      
  grouped: (grpNum) ->
    pub = []
    pvt = []
    pub = (k for k,v of @public_genomes when v.assignedGroup? and v.assignedGroup is grpNum)
    pvt = (k for k,v of @private_genomes when v.assignedGroup? and v.assignedGroup is grpNum)

    return { public: pub, private: pvt }
    
  genomeSet: (gids) ->
    pub = []
    pvt = []
    pub = (g for g in gids when @publicRegexp.test(g))
    pvt = (g for g in gids when @privateRegexp.test(g))
    
    return { public: pub, private: pvt }
    
  genome: (gid) ->
    
    if @publicRegexp.test(gid)
      return @public_genomes[gid]
    else
      return @private_genomes[gid]
    
    
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

# FUNC cmp
# performs alphabetical comparison, case sensitive
#
# USAGE cmp is called in array.sort
# 
# RETURNS
# -1,0,1 if lower, equal or greater in alpha order 
#    
cmp = (a, b) -> if a > b then 1 else if a < b then -1 else 0

# FUNC trimInput
# Trims leading/trailing ws.
# Sends alert if input is empty (using field in warning message)
#
# USAGE trimInput string, string
# 
# RETURNS
# string or null
#    
trimInput = (str, field) ->
  if str?
    term = jQuery.trim(str)
    if term.length
      return term
    else 
      alert("Error: #{field} is empty.")
      return null
  else
    alert("Error: #{field} is empty.")
    return null
        
