###

 File: superphy_map.coffee
 Desc: Objects & functions for managing geospatial views in Superphy
 Author: Akiff Manji akiff.manji@gmail.com
 Date: May 6, 2014

###

class MapView extends ViewTemplate
  constructor: (@parentElem, @style , @elNum, @mapArgs) ->
    #add map args to mapArgs list 

    # Call default constructor - creates unique element ID                  
    super(@parentElem, @style, @elNum, @mapArgs)
  
  type: 'map'

  elName: 'genome_map'

  cartographer: null

  mapView: true

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

    pubVis = []
    pvtVis = []

    if !@cartographer?
      pubVis = genomes.pubVisible
      pvtVis = genomes.pvtVisible
    else if @cartographer? && @cartographer.visibleStrains

      for i in @cartographer.visibileStrainLocations.pubVisible
        if i in genomes.pubVisible
          pubVis.push i
    
      for i in @cartographer.visibileStrainLocations.pvtVisible
        if i in genomes.pvtVisible
          pvtVis.push i
    
    #append genomes to list
    t1 = new Date()
    @_appendGenomes(mapElem, pubVis, genomes.public_genomes, @style, false)
    @_appendGenomes(mapElem, pvtVis, genomes.private_genomes, @style, true)
    t2 = new Date()
    ft = t2-t1

    console.log 'MapView update elapsed time: ' +ft
    true # return success

  # Helper function for update
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
        actionEl = jQuery("<a href='#' data-genome='#{g}'> <span class='fa fa-search'></span>info</a>")

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

  # FUNC conscriptCartographer
  # creates a new cartographer object
  # reappends download-view dive for better display
  #
  # PARAMS
  #
  # RETURNS
  # boolean
  #
  conscriptCartographger: () ->
    elem = @parentElem
    @mapArgs[0] = @mapArgs[0] ? 'base'
    cartographerTypes = {
      'base': new Cartographer(jQuery(elem))
      'dot': new DotCartographer(jQuery(elem))
      'satellite': new SatelliteCartographer(jQuery(@parentElem))
      'infoSatellite': new InfoSatelliteCartographer(jQuery(@parentElem), null, window.selectedGenome)
    }
    @cartographer = cartographerTypes[@mapArgs[0]];
    console.log @cartographer
    @cartographer.cartograPhy()
    true

###
  CLASS Cartographer

  Handles map drawing and location searching

###
class Cartographer
  constructor: (@cartographDiv, @cartograhOpt) ->
  
  visibleStrains: false
  map: null
  splitLayout: '
      <div class="col-md-6 map-search-div">
        <table class="table map-search-table">
          <tr>
            <td>
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
            </td>
          </tr>
          <tr>
            <td>
              <div class="map-canvas"></div>
            </td>
          </tr>
        </table>
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
    jQuery(@cartographDiv).prepend(@splitLayout)
    @map = null if @map?
    cartograhOpt = {
      center: new google.maps.LatLng(-0.000, 0.000),
      zoom: 1,
      streetViewControl: false,
      mapTypeId: google.maps.MapTypeId.ROADMAP
    }
    @map = new google.maps.Map(jQuery(@cartographDiv).find('.map-canvas')[0], cartograhOpt)
    jQuery('.map-search-button').bind('click', {context: @}, @pinPoint)
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
          self.map.setCenter(results[0].geometry.location)
          self.map.fitBounds(results[0].geometry.viewport)
        else
          alert("Location "+queryLocation+" could not be found. Please enter a proper location")
    )
    true

###
  CLASS DotCartographer

  Handles map drawing and location searching
  Allows for pinpointing locations

###
class DotCartographer extends Cartographer
  constructor: (@dotCartographDiv, @dotCartograhOpt) ->
    # Call default constructor
    super(@dotCartographDiv, @dotCartograhOpt)
  
  latLng: null
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
    google.maps.event.addListener(@map , 'click', (event) ->
      DotCartographer::plantFlag(event.latLng, @)
      )
    true

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
          DotCartographer::plantFlag(self.latLng, self.map)
        else
          alert("Location "+queryLocation+" could not be found. Please enter a proper location")
    )
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
    @marker.setMap(null) if @marker?
    @marker = new google.maps.Marker({
      position: location,
      map: map
      });
    @marker.setTitle(@marker.getPosition().toString())
    map.panTo(@marker.getPosition())
    true

###
  CLASS SatelliteCartographer

  Handles map drawing and location searching
  Displays multiple markers on map
  Handles marker clustering
  Displays list of genomes 
  Alters genome list when map viewport changes

###
class SatelliteCartographer extends Cartographer
  constructor: (@satelliteCartographDiv, @satelliteCartograhOpt) ->
    # Call default constructor
    super(@satelliteCartographDiv, @satelliteCartograhOpt)

  visibleStrains: true
  clusterList: []
  visibileStrainLocations: {}

  markerClusterer: null

  mapViewIndex: null

  # FUNC cartograPhy overrides Cartographer
  # initializes map in specified map div
  # initializs manifest list of genomes
  # displays genomes on map with known locations
  # clusters markers to reduces drawing overhead
  # binds listen-handlers to map to alter list with map view-port changes
  #
  # PARAMS
  # 
  # RETURNS
  # google map object drawn into specified div
  #
  cartograPhy: () ->
    
    # Init strain lis
    jQuery(@satelliteCartographDiv).prepend('<div class="col-md-5 map-manifest"></div>')
      
    # Init the map
    super
    
    # Init the visible list of strains and convert these to markers
    SatelliteCartographer::updateMarkerLists(viewController.genomeController, @map)
    
    # Init the marker clusterer
    SatelliteCartographer::markerCluster(@map)
    
    # Set mapViewIndex for easy lookup
    index = SatelliteCartographer::findMapViewIndex(viewController.views)
    SatelliteCartographer::mapViewIndex = index
    jQuery(@satelliteCartographDiv).data("viewsIndex", index);

    # Map viewport change event
    google.maps.event.addListener(@map, 'zoom_changed', () ->
      SatelliteCartographer::markerClusterer.clearMarkers()
      )
    google.maps.event.addListener(@map, 'bounds_changed', () ->
      SatelliteCartographer::markerClusterer.clearMarkers()
      )
    google.maps.event.addListener(@map, 'resize', () ->
      SatelliteCartographer::markerClusterer.clearMarkers()
      )
    google.maps.event.addListener(@map, 'idle', () ->
      SatelliteCartographer::updateMarkerLists(viewController.genomeController, @)
      viewController.getView(SatelliteCartographer::mapViewIndex).update(viewController.genomeController)
      SatelliteCartographer::markerClusterer.addMarkers(SatelliteCartographer::clusterList)
      )
    true

  # FUNC updateMarkerLists
  # Initializes and sets lists of genomes with known locations
  # Initializes and sets lists of markers for google maps and marker clusterer
  # Resets lists to contain only those markers visible in the viewport of the map
  #
  # PARAMS
  # list of genomeContorller genomes, map 
  #
  # RETURNS
  #
  updateMarkerLists: (genomes, map) ->
    # Init public strains
    @clusterList = []
    @visibileStrainLocations.pubVisible = []
    @visibileStrainLocations.pvtVisible = []

    for pubGenomeId, public_genome of genomes.public_genomes
      if public_genome.isolation_location? && public_genome.isolation_location != ""
        pubMarkerObj = SatelliteCartographer::parseLocation(public_genome)

        circleIcon = {
          path: google.maps.SymbolPath.CIRCLE
          fillColor: '#FF0000'
          fillOpacity: 0.8
          scale: 5
          strokeColor: '#FF0000'
          strokeWeight: 1
        }

        pubMarker = new google.maps.Marker({
          map: map
          icon: circleIcon
          position: pubMarkerObj['centerLatLng']
          title: public_genome.uniquename
          feature_id: pubGenomeId
          uniquename: public_genome.uniquename
          location: pubMarkerObj['locationName']
          })

        @clusterList.push(pubMarker)

        if map.getBounds() != undefined && map.getBounds().contains(pubMarker.getPosition())
          @visibileStrainLocations.pubVisible.push(pubGenomeId)


    for pvtGenomeId, private_genome of genomes.private_genomes
      if private_genome.isolation_location? && private_genome.isolation_location != ""
        pvtMarkerObj = SatelliteCartographer::parseLocation(private_genome)

        circleIcon = {
          path: google.maps.SymbolPath.CIRCLE
          fillColor: '#000000'
          fillOpacity: 0.8
          scale: 5
          strokeColor: '#FF0000'
          strokeWeight: 1
        }

        pvtMarker = new google.maps.Marker({
          map: map
          position: pvtMarkerObj['centerLatLng']
          title: private_genome.uniquename
          feature_id: pvtGenomeId
          uniquename: private_genome.uniquename
          location: pvtMarkerObj['locationName']
          })

        @clusterList.push(pvtMarker)

        if map.getBounds() != undefined && map.getBounds().contains(pubMarker.getPosition())
          @visibileStrainLocations.pvtVisible.push(pvtGenomeId)
    true

  # FUNC markerClusterer
  # creates a new marker clusterer object
  #
  # PARAMS
  # google maps map
  # 
  # RETURNS
  #
  markerCluster: (map) ->
    mcOptions = {gridSize: 50, maxZoom: 15}
    @markerClusterer = new MarkerClusterer(map, @clusterList, mcOptions)
    true

  # FUNC findMapViewIndex
  # gets the index of MapView object from the list of views
  #
  # PARAMS
  # list of views
  #
  # RETURNS
  # index of MapView
  #
  findMapViewIndex: (views) ->
    for v, index in views
      if v.mapView?
        return index
    return null

  # FUNC resetMap
  # recenters the map in the map-canvas div when bootstrap map-tab and map-panel divs clicked
  # circumvents issues with rendering maps in bootstraps hidden tab and panel divs
  # resets and reinitlializes a new list of markers on the map
  #
  # PARAMS
  #
  # RETURNS
  #
  resetMap: ()  ->
    SatelliteCartographer::updateMarkerLists(viewController.genomeController, @map)
    x = @map.getZoom();
    c = @map.getCenter();
    google.maps.event.trigger(@map, 'resize');
    @map.setZoom(x);
    @map.setCenter(c);
    SatelliteCartographer::markerClusterer.addMarkers(SatelliteCartographer::clusterList)

  # FUNC parseLocation
  # parses the location out from a genome object
  # parses location name, center latLng point, SW and NE boundary latLng points
  #
  # PARAMS
  # genomeController genome
  #
  # RETURNS
  # marker object
  #
  parseLocation: (genome) ->
    # Get location from genome
    locationName = genome.isolation_location[0].match(/<location>[\w\d\W\D]*<\/location>/)[0]
    
    # Remove markup tags
    locationName = locationName.replace(/<location>/, '').replace(/<\/location>/, '').replace(/<[\/]+[\w\d]*>/g, '').replace(/<[\w\d]*>/g, ', ').replace(/, /, '')
    
    # Get location coordinates
    locationCoordinates = genome.isolation_location[0].match(/<coordinates>[\w\d\W\D]*<\/coordinates>/)[0]

    # Get location center
    locationCenter = locationCoordinates.match(/<center>[\w\d\W\D]*<\/center>/)[0]

    # Get center lat
    locationCenterLat = locationCenter.match(/<lat>[\w\d\W\D]*<\/lat>/)[0]
    
    # Remove markup tags
    locationCenterLat = locationCenterLat.replace(/<lat>/, '').replace(/<\/lat>/, '')

    # Get center Lng
    locationCenterLng = locationCenter.match(/<lng>[\w\d\W\D]*<\/lng>/)[0]

    # Remove markup tags
    locationCenterLng = locationCenterLng.replace(/<lng>/, '').replace(/<\/lng>/, '')

    # Get location SW boundary
    locationViewPortSW = locationCoordinates.match(/<southwest>[\w\d\W\D]*<\/southwest>/)[0]

    # Get SW boundary lat
    locationViewPortSWLat = locationViewPortSW.match(/<lat>[\w\d\W\D]*<\/lat>/)[0]

    # Remove markup tags
    locationViewPortSWLat = locationViewPortSWLat.replace(/<lat>/, '').replace(/<\/lat>/, '')

    # Get SW boundary Lng
    locationViewPortSWLng = locationViewPortSW.match(/<lng>[\w\d\W\D]*<\/lng>/)[0]

    # Remove markup tags
    locationViewPortSWLng = locationViewPortSWLng.replace(/<lng>/, '').replace(/<\/lng>/, '')

    # Get location NE boundary
    locationViewPortNE = locationCoordinates.match(/<northeast>[\w\d\W\D]*<\/northeast>/)[0]

    # Get NE boundary lat
    locationViewPortNELat = locationViewPortNE.match(/<lat>[\w\d\W\D]*<\/lat>/)[0]

    # Remove markup tags
    locationViewPortNELat = locationViewPortNELat.replace(/<lat>/, '').replace(/<\/lat>/, '')

    # Get NE boundary lng
    locationViewPortNELng = locationViewPortNE.match(/<lng>[\w\d\W\D]*<\/lng>/)[0]

    # Remove tags
    locationViewPortNELng = locationViewPortNELng.replace(/<lng>/, '').replace(/<\/lng>/, '')

    centerLatLng = new google.maps.LatLng(locationCenterLat, locationCenterLng)
    swLatLng = new google.maps.LatLng(locationViewPortSWLat, locationViewPortSWLng)
    neLatLng = new google.maps.LatLng(locationViewPortNELat, locationViewPortNELng)
    markerBounds = new google.maps.LatLngBounds(swLatLng, neLatLng)

    markerObj = {}
    markerObj['locationName'] = locationName
    markerObj['centerLatLng'] = centerLatLng
    markerObj['markerBounds'] = markerBounds

    return markerObj

###
  CLASS InfoSatelliteCartographer

  Handles map drawing and location searching
  Displays multiple markers on map
  Handles marker clustering
  Displays list of genomes 
  Alters genome list when map viewport changes
  Highlights selected genome on map from search query

###
class InfoSatelliteCartographer extends SatelliteCartographer
  constructor: (@infoSatelliteCartographDiv, @infoSatelliteCartograhOpt, @infoSelectedGenome) ->
    # Call default constructor
    super(@infoSatelliteCartographDiv, @infoSatelliteCartograhOpt, @infoSelectedGenome)

  selectedGenomeLocation: null

  cartograPhy: () ->
    super
    @selectedGenomeLocation = @parseLocation(@infoSelectedGenome)
    @showSelectedGenome(@selectedGenomeLocation ,@map)

  showSelectedGenome: (location, map) ->
    unless location?
      throw new SuperphyError('Location cannot be determined or location is undefined (not specified)!')
      return 0

    maxZndex = google.maps.Marker.MAX_ZINDEX
    zInd = maxZndex + 1
    markerLatLng = new google.maps.LatLng(location.centerLatLng)
    overlay = new CartographerOverlay(map, location.centerLatLng, location.locationName)

class CartographerOverlay
  constructor: (@map, @latLng, @title) ->
    @setMap(@map)
    @div = null;
    
  CartographerOverlay:: = new google.maps.OverlayView()

  onAdd: () ->
    div = document.createElement('div')
    div.id = "selectedGenome"
    div.style.borderStyle = 'none'
    div.style.borderWidth = '0px'
    div.style.position = 'absolute'
    div.style.width = '22px'
    div.style.height = '40px' 
    div.style.cursor = 'pointer'

    # We initially created an svg circle marker but it didnt look very good on the map so were using the default image
    # svg = d3.select(div).append('svg')
    #   .attr('height', '15px')
    #   .attr('width', '15px')
    #
    # selectedMarker = svg.append("g")
    #   .attr('transform', 'translate(0,0)')
    #
    # selectedMarker.append("circle")
    #   .attr('cx', 7.5)
    #   .attr('cy', 7.5)
    #   .attr('r', '5px')
    #   .style({'fill': '#00FF00', 'stroke': '#00FF00', 'stroke-width': '1px', 'fill-opacity': '0.0'})

    img = document.createElement('img')
    img.src = '/App/Pictures/marker_icon_green.png'
    img.style.width = '100%'
    img.style.height = '100%'
    img.style.position = 'absolute'
    img.id = "selectedGenomeMarker"
    img.title = @title
    div.appendChild(img)

    @div = div

    panes = @getPanes()
    panes.floatPane.appendChild(div)

  onRemove: () ->
    @div.parentNode.removeChild(@div)
    @div = null

  draw: () ->
    overlayProjection = @getProjection()
    location = overlayProjection.fromLatLngToDivPixel(@latLng)
    
    div = @div

    div.style.left = (location.x - 11) + 'px'
    div.style.top = (location.y - 40) + 'px'