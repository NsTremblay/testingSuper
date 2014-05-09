###

 File: superphy_map.coffee
 Desc: Objects & functions for managing geospatial views in Superphy
 Author: Akiff Manji akiff.manji@gmail.com
 Date: May 6, 2014

###

class MapView extends ViewTemplate
  constructor: (@parentElem, @style , @elNum, mapArgs) ->
    #add map args to mapArgs list 

    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum)
  
  type: 'map'

  elName: 'genome_map'

  #Create layout for map and list
  #console.log @parentElem.selector

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
    mapElem = jQuery("##{@elID}")
    if mapElem.length
      mapElem.empty()
    
    else
      mapElem = jQuery("<ul id='#{@elID}' />")
      jQuery(@parentElem).find('.map-manifest').append(mapElem)

    #append genomes to list
    t1 = new Date()
    @_appendGenomes(mapElem, genomes.pubVisible, genomes.public_genomes, @style, false)
    @_appendGenomes(mapElem, genomes.pvtVisible, genomes.private_genomes, @style, true)
    t2 = new Date()
    ft = t2-t1

    console.log 'List view elapsed time: ' +ft
    true # return success

  _appendGenomes: (el, visibleG, genomes, style, priv) -> 

    # View class
    cls = @cssClass()

    if priv && visibleG.length
      el.append("<li class='genome_list_spacer'>---- USER-SUBMITTED GENOMES ----</li>")

    for g in visibleG
      thiscls = cls
      thiscls = cls+' '+genomes[g].cssClass if genomes[g].cssClass?

      name = genomes[g].htmlname
      if style = 'redirect'
        # Links

        # Create elements
        mapEl = jQuery("<li class='#{thiscls}'>#{name}</li>")
        actionEl = jQuery("<a href='#' data-genome='#{g}'><span class='fa fa-search'></span> info</a>")

        # Set behavior
        actionEl.click (e) -> 
          e.preventDefault()
          gid = @.dataset.genome
          viewController.select(gid, true)

        # Append to list
        mapEl.append(actionEl)
        el.append(mapEl)

      else if style == 'select'
        # Checkboxes

        # Create elements
        checked = ''
        checked = 'checked' if genomes[g].isSelected
        mapEl = jQuery("<li class='#{thiscls}'></li>")
        labEl = jQuery("<label class='checkbox'>#{name}</label>")
        actionEl = jQuery("<input class='checkbox' type='checkbox' value='#{g}' #{checked}/>")

        # Set behavior
        actionEl.change (e) ->
          e.preventDefault()
          viewController.select(@.value, @.checked)

        # Append to list
        labEl.append(actionEl)
        mapEl.append(labEl)
        el.append(mapEl)

      else
        return false 

      true

  # FUNC updateCSS
  # Change  CSS class for selected genomes to match underlying genome properties
  #
  # PARAMS
  # simple hash object with private and public list of genome Ids to update
  # genomeController object
  # 
  # RETURNS
  # boolean
  #
  updateCSS: (gset, genomes) -> 
    #TODO: modify the helper functions for updating CSS

    #Retrieve list DOM element
    mapEl = jQuery("##{@elID}")
    throw new SuperphyError " DOM element for map view #{@elID} not found. Cannot call MapView method updateCSS()." unless mapEl? and mapEl.length

    #@_updateGenomeCSS(mapEl, gset.public, genomes.public_genomes) if gset.public?
    #@_updateGenomeCSS(mapEl, gset.private, genomes.private_genomes) if gset.private?

    true # return succes

  # FUNC select
  # Change style to indicate its selection status
  #
  # PARAMS
  # genome object from GenomeController list
  # boolean indicating if selected/unselected
  #
  # RETURNS
  # boolean
  #
  select: (genome, isSelected) -> 

    itemEl = null

    if @style == 'select'
     # Checkbox style, other styles do not have a 'select' behavior

     # Find element
     descriptor = "li input[value='#{genome}']"
     itemEl = jQuery(descriptor)

    else
      return false

    unless itemEl? and itemEl.length
      throw new SuperphyError " Map element for genome #{genome} not found in MapView #{@elID}"
      return false

    itemEl.prop('checked', isSelected);

    true # success

  dump: (genomes) -> 
    #TODO: Download the set of genomes and their coordinates into a table
    return

  conscriptCartographger: () ->
    cartographer = new DotCartographer(jQuery(@parentElem))
    cartographer.cartograPhy()
true

#Base class for map functions
class Cartographer
  constructor: (@cartographDiv, @cartograhOpt) ->
  map: null
  latLng: null
  splitLayout: '
      <div>
        <form class="form">
          <fieldset>
            <div>
              <div class="input-group">
                <input type="text" class="form-control map-search-location" placeholder="Enter a search location">
                  <span class="input-group-btn">
                    <button class="btn btn-default map-search-button" type="button"><span class="fa fa-search"></span></button>
                  </span>
                </div>
              </div>
            </div>
          </fieldset>
        </form>
        <div class="map-canvas" style="height:200px;width:200px"></div>
      </div>'


  # FUNC cartograPhy
  # initializes map in specified map div
  #
  # PARAMS
  #
  # RETURNS
  # google map object drawn into specified div
  #
  cartograPhy: () ->
    jQuery(@cartographDiv).prepend(@.splitLayout)
    @.map = null if @.map?
    cartograhOpt = {
      center: new google.maps.LatLng(-0.000, 0.000),
      zoom: 1,
      streetViewControl: false,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    @.map = new google.maps.Map(jQuery(@cartographDiv).find('.map-canvas')[0], cartograhOpt);
    jQuery('.map-search-button').bind('click', {context: @}, @.pinPoint)
    true

  reCartograPhy: () ->
    true

  # FUNC pinPoint
  # geocodes an address from the map search query
  # centers the map at specified area, and stores the latLng info in the database if it doesnt already exist
  #
  # PARAMS
  # address string
  # 
  # RETURNS
  #
  pinPoint: (e) ->
    # TODO: ability to check and store latlngs in the database
    e.preventDefault()
    self = e.data.context
    geocoder = new google.maps.Geocoder();
    queryLocation = jQuery('.map-search-location').val()
    geocoder.geocode({'address': queryLocation}, (results, status) ->
        if status is google.maps.GeocoderStatus.OK
          self.latLng = results[0].geometry.location
          self.map.setCenter(results[0].geometry.location)
          self.map.fitBounds(results[0].geometry.viewport)
        else
          alert("Location #{address} could not be found. Please enter a proper location")
    )
    true

class DotCartographer extends Cartographer
  constructor: (@dotCartographDiv, @dotCartograhOpt) ->
    # Call default constructor
    super(@dotCartographDiv, @dotCartograhOpt)
  
  marker: null

  # FUNC cartograPhy overrides Cartographer
  # initializes map in specified map div
  # binds click listener to map for dropping a map marker
  #
  # PARAMS
  #
  # RETURNS
  # google map object drawn into specified div
  #
  cartograPhy: () ->
    super
    google.maps.event.addListener(@.map , 'click', (event) ->
      DotCartographer::plantFlag(event.latLng, @)
      )
    true

  reCartograPhy: () ->
    super

  # FUNC pinPoint overrides Cartographer
  # geocodes an address from the map search query
  # centers the map at specified area, and stores the latLng info in the database if it doesnt already exist
  # adds marker to center of map (i.e. queried location)
  #
  # PARAMS
  # address string
  # 
  # RETURNS
  #
  pinPoint: (e) ->
    super(e)
    self = e.data.context
    DotCartographer::plantFlag(self.latLng, self.map)
    true

  # FUNC plantFlag
  # sets new marker on map on click event
  # removes old marker off of map if defined
  #
  # PARAMS
  # location latLng, map map
  #
  # RETURNS
  #
  plantFlag: (location, map) ->
    @.marker.setMap(null) if @.marker?
    @.marker = new google.maps.Marker({
      position: location,
      map: map
      });
    @.marker.setTitle(@.marker.getPosition().toString())
    map.panTo(@.marker.getPosition())
    true
