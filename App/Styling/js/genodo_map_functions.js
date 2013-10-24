

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

Map.prototype.parseLocation = function(location)
{
	var markerObj = {}

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
};

Map.prototype.reLoadMap = function()
{
	alert('Reloading Map');
};

Map.prototype.addMarker = function(location) 
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