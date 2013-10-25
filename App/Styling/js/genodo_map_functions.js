

//Constructor for map object.
function Map(mapOptions, mapDiv) {
	this.mapOptions = mapOptions;
	this.mapDiv = mapDiv;
};

//Prototype functions or class functions that get inherited by a child object.

Map.prototype.initializeMap = function()
{
	return new google.maps.Map(document.getElementById(this.mapDiv), this.mapOptions);
};

Map.prototype.parseLocation = function(location_obj)
{
	if (!location_obj) {
		return 0;
	}
	else {
		var markerObj = {};

	//Parses the location name for the marker title
	var locationName = location_obj.isolation_location[0].match(/<location>[\w\d\W\D]*<\/location>/)[0];
	locationName = locationName.replace(/<location>/, '');
	locationName = locationName.replace(/<\/location>/, '');
	locationName = locationName.replace(/<[\/]+[\w\d]*>/g, '');
	locationName = locationName.replace(/<[\w\d]*>/g, ', ');
	locationName = locationName.replace(/, /, '');

	var locationCoordinates = location_obj.isolation_location[0].match(/<coordinates>[\w\d\W\D]*<\/coordinates>/)[0];

	//Parses out the center LatLong point
	var locationCenter = locationCoordinates.match(/<center>[\w\d\W\D]*<\/center>/)[0];
	var locationCenterLat = locationCenter.match(/<lat>[\w\d\W\D]*<\/lat>/)[0];
	locationCenterLat = locationCenterLat.replace(/<lat>/, '');
	locationCenterLat = locationCenterLat.replace(/<\/lat>/, '');
	var locationCenterLng = locationCenter.match(/<lng>[\w\d\W\D]*<\/lng>/)[0];
	locationCenterLng = locationCenterLng.replace(/<lng>/, '');
	locationCenterLng = locationCenterLng.replace(/<\/lng>/, '');

	//Parses out boundary LatLongs
	var locationViewportSW = locationCoordinates.match(/<southwest>[\w\d\W\D]*<\/southwest>/)[0];
	var locationViewportSWLat = locationViewportSW.match(/<lat>[\w\d\W\D]*<\/lat>/)[0];
	var locationViewportSWLng = locationViewportSW.match(/<lng>[\w\d\W\D]*<\/lng>/)[0];
	locationViewportSWLat = locationViewportSWLat.replace(/<lat>/, '');
	locationViewportSWLat = locationViewportSWLat.replace(/<\/lat>/, '');
	locationViewportSWLng = locationViewportSWLng.replace(/<lng>/, '');
	locationViewportSWLng = locationViewportSWLng.replace(/<\/lng>/, '');

	var locationViewportNE = locationCoordinates.match(/<northeast>[\w\d\W\D]*<\/northeast>/)[0];
	var locationViewportNELat = locationViewportNE.match(/<lat>[\w\d\W\D]*<\/lat>/)[0];
	var locationViewportNELng = locationViewportNE.match(/<lng>[\w\d\W\D]*<\/lng>/)[0];
	locationViewportNELat = locationViewportNELat.replace(/<lat>/, '');
	locationViewportNELat = locationViewportNELat.replace(/<\/lat>/, '');
	locationViewportNELng = locationViewportNELng.replace(/<lng>/, '');
	locationViewportNELng = locationViewportNELng.replace(/<\/lng>/, '');

	var centerLatLng = new google.maps.LatLng(locationCenterLat, locationCenterLng);
	var swLatLng = new google.maps.LatLng(locationViewportSWLat, locationViewportSWLng);
	var neLatLng = new google.maps.LatLng(locationViewportNELat, locationViewportNELng);
	var markerBounds = new google.maps.LatLngBounds(swLatLng, neLatLng);

	markerObj['locationName'] = locationName;
	markerObj['centerLatLng'] = centerLatLng;
	markerObj['markerBounds'] = markerBounds;

	return markerObj;
}
};

Map.prototype.reLoadMap = function()
{
	alert('Reloading Map');
};

Map.prototype.clickAddMarker = function(location, map) 
{
	if (marker) {
		marker.setMap(null);
	}
	marker = new google.maps.Marker({
		position: location,
		map: map,
	});
	marker.setTitle(marker.getPosition().toString());
	map.panTo(marker.getPosition());
	return marker;
};

Map.prototype.geoCodeMapAddress = function(address, geocoder) 
{
	geocoder.geocode( { 'address': address}, function(results, status) {
		if (status == google.maps.GeocoderStatus.OK) {
			return results;
		}
		else {
			alert('Location ' + address + ' could not be found. Please enter a proper location');
			return 0;
		}
	});
};

Map.prototype.addMultiMarkers = function(genomesList, genomesLocationList, map, selectedGenome) {
	var sortedPublicLocations = [];
	var multiMarkers = {};
	var clusterList = [];

	if (!genomesList) {
		console.log("No genome locations");
	}

	$.each(genomesList, function(feature_id, feature_obj) {
		if (feature_obj.isolation_location && feature_obj.isolation_location != "" && feature_id != selectedGenome) {
			genomesLocationList[feature_id] = feature_obj;
			var newMarkerObj = Map.prototype.parseLocation(feature_obj); 
			var multiMarker = new google.maps.Marker({
				map: map,
				position: newMarkerObj['centerLatLng'],
				title: feature_obj.uniquename,
				feature_id: feature_id,
				uniquename: feature_obj.uniquename
			});
			sortedPublicLocations.push(multiMarker);
		}
		else {
		}
	});

	sortedPublicLocations.sort(function(a,b){
		if(a.title < b.title) return -1;
		if(a.title > b.title) return 1;
		return 0;
	});

	//Create final marker objects and lists sorted alphanumerically
	for (var i = 0; i < sortedPublicLocations.length; i++) {
		var multiMarker = sortedPublicLocations[i];
		multiMarkers[multiMarker.feature_id] = multiMarker;
		clusterList.push(multiMarker);
	};

	return [multiMarkers, clusterList];
};

Map.prototype.showSelectedGenome = function(location, map) {
	if (!location) {
		return 0;
	}
	else {
		var maxZindex = google.maps.Marker.MAX_ZINDEX;
		var zInd = maxZindex + 1;
		var marker = new google.maps.Marker({
			icon: "http://maps.google.com/mapfiles/arrow.png",
			map: map,
			position: location.centerLatLng,
			animation: google.maps.Animation.DROP,
			title: location.locationName,
			zIndex: zInd,
		});
		return marker;
	}
};

Map.prototype.updateVisibleMarkers = function(visibleMarkers, multiMarkers, map) {
	visibleMarkers = {};
	$.each( multiMarkers, function(feature_id , marker) {
		if(map.getBounds().contains(marker.getPosition())){
			visibleMarkers[feature_id] = marker;
		}
		else{
		}
	});
	return visibleMarkers;
};

function MapOverlay(map, latLng, icon, title) {
	this.latLng_ = latLng;
	this.icon_ = icon;
	this.title_ = title;
	this.markerLayer = jQuery('<div />').addClass('overlay');
	this.setMap(map);
};

MapOverlay.prototype = new google.maps.OverlayView();

MapOverlay.prototype.onAdd = function() {
	var $pane = jQuery(this.getPanes().floatPane);
	$pane.append(this.markerLayer);
};

MapOverlay.prototype.onRemove = function() {
	this.markerLayer.remove();
};

MapOverlay.prototype.draw = function() {

	var overlayProjection = this.getProjection();
	var fragment = document.createDocumentFragment();
	this.markerLayer.empty();
	var location = overlayProjection.fromLatLngToDivPixel(this.latLng_);
	var $point = jQuery('<div class="map-point" title="'+this.title_+'" style="'
		+'width:32px; height:32px; '
		+'left:'+location.x+'px; top:'+location.y+'px; '
		+'position:absolute; cursor:pointer; '
		+'">'
		+'<img src="'+this.icon_+'" style="position: absolute; top: -16px; left: -16px" />'
		+'</div>');

	fragment.appendChild($point.get(0));
	this.markerLayer.append(fragment);
};

