/**
 * Manages complex groupwise form in SuperPhy application
 * 
 * Copyright (c) Matt Whiteside 2013.
 *
 **/

// Update and reload various forms with new meta data
function updateMeta(tab, visableData) {
	// Default is to display just the name
	if(typeof visableData === 'undefined' || visableData.length == 0) {
		visableData = ['name'];
	}
	var strainsAlreadyInGroups = groupsList();
	if(tab == 'list' || tab == 'init') {
		var dropDown = $('#pubStrainList')
		dropDown.empty();
		$('#select-all-genomes').is(':checked') ? $('#select-all-genomes').click() : 0;
		genomeLabels = {};
		$.each( public_genomes, function(feature_id, feature_obj) {
			var lab = metaTab.metaLabel(feature_obj, visableData);
			genomeLabels[feature_id] = lab;
			dropDown.append(
				'<li>'+
				'<label class="checkbox" for="'+feature_id+'"><input id="'+feature_id+'" class="checkbox" type="checkbox" value="'+feature_id+'" name="genomes-in-list"/>'+lab+'</label>'+								
				'</li>'
				);
			if (strainsAlreadyInGroups.indexOf(feature_id) > -1) {
				selectInList(feature_id, true);
			}
			else {
				selectInList(feature_id, false);
			}
		});
	} else if(tab == 'tree') {
		modifyLabels(visableData);

	} else if (tab == 'mapList') {
		//Do something here about that
		var dropDown = $('#multiMapStrainList');
		dropDown.empty();
		$('#select-all-map').is(':checked') ? $('#select-all-map').click() : 0;
		
		$.each( visableMarkers, function(feature_id, feature_obj) {
			var location = multiMarkers[feature_id].location;
			var lab = metaMapTab.metaLabel(public_location_genomes[feature_id], visableData);
			dropDown.append(
				'<li style="list-style-type:none">'+
				'<label class="checkbox" for="map_'+feature_id+'"><input id="map_'+feature_id+'" class="checkbox" type="checkbox" value="'+feature_id+'" name="genomes-in-map-search">'+location+' - '+lab+'</label>'+								
				'</li>'
				);
			if (strainsAlreadyInGroups.indexOf(feature_id) > -1) {
				selectInMapSearch(feature_id, true);
			}
			else {
				selectInMapSearch(feature_id, false);
			}
		});	

	}
	
}

// Add list of genomes to group form box
function addToGroup(groupNum, genomeList) {
	
	for(var genome in genomeList) {

		var label = genomeList[genome];
		
		if($('input[name="comparison-group1-genome"][value="'+genome+'"]').length) {
			// Check if already in box 1
			if(groupNum == 2) {
				alert('Genome '+label+' is currently in group 1. You must remove it from group 1 before adding it to group 2.');
			}
		} else if($('input[name="comparison-group2-genome"][value="'+genome+'"]').length) {
			// Check if already in box 1
			if(groupNum == 1) {
				alert('Genome '+label+' is currently in group 2. You must remove it from group 2 before adding it to group 1.');
			}
		} else {
			// Newly added genome

			// Add to group
			$('#comparison-group'+groupNum+' fieldset').append(
				'<li class="comparison-group-item" style="list-style:none">'+
				'<label class="checkbox">'+
				'<input class="checkbox" type="checkbox" value="'+genome+'" name="comparison-group'+groupNum+'-genome"/>'+label+
				'</label>'+
				'</li>'
				);

			// Change format of selected genomes
			updateSelected(genome, true);
			
			// Show remove button
			if(groupNum == 1) {
				$('#buttonRemoveGroup1').show();
			} else if(groupNum == 2) {
				$('#buttonRemoveGroup2').show();
			}
			
			
		}
	}
}

//Remove checked genomes from group box
function removeFromGroup(groupNum) {
	
	var checked = $('input[name="comparison-group'+groupNum+'-genome"]:checked');
	
	// change formatting back to normal and delete parent element 
	checked.each( function(i, e) { 
		updateSelected($( e ).val(), false); 
		$( e ).closest('li').remove(); 
	});

	// Hide remove button if list empty
	if($('input[name="comparison-group'+groupNum+'-genome"]').length == 0) {
		$('#buttonRemoveGroup'+groupNum).hide();
	}
	
}

function updateSelected(genome_id, selected) {
	// Change drop-down list
	selectInList(genome_id, selected);
	maskNode(genome_id, selected);
	selectInAttrSearch(genome_id, selected);
	selectInMapSearch(genome_id, selected);
}

// These functions alter genome format after its selected
// select in list
function selectInList(genome, selected) {
	$('#pubStrainList label[for="'+genome+'"]').toggleClass('listSelected', selected);
	$('#pubStrainList input[value="'+genome+'"]').toggleClass('listSelected', selected);
}

//select in attribute search form
function selectInAttrSearch(genome, selected) {
	if(genome in attr_search_result) {
		$('#attr-search-display label[for="'+genome+'"]').toggleClass('selected-attr-genome', selected);
		$('#attr-search-display input[value="'+genome+'"]').toggleClass('selected-attr-genome', selected);
	}
}

function selectInMapSearch(genome, selected) {
	$('#multiMapStrainList label[for="map_'+genome+'"]').toggleClass('listSelected', selected);
	$('#multiMapStrainList input[value="'+genome+'"]').toggleClass('listSelected', selected);
}

// returns list of genome_ids already added to group1 or 2.
function groupsList() {
	
	var glist = [];
	
	$.each( $('input[name="comparison-group1-genome"]'), function(i, e) {
		glist.push( $( e ).val() );
	});
	
	$.each( $('input[name="comparison-group2-genome"]'), function(i, e) {
		glist.push( $( e ).val() );
	});
	
	return glist;
}


// Add genomes to a group list for the checkbox-style forms
function submitGenomes(inputName, group) {
	var genomeList = {};
	var checked = $('input[name="'+inputName+'"]:checked');
	checked.each( function(i, e) { 
		var id = $( e ).val(); 
		var genome_data;
		if(/^public_/.test(id)) {
			genome_data = public_genomes[id]
		} else {
			genome_data = private_genomes[id]
		}
		if(typeof genome_data === 'undefined') {
			return "Unrecognized genome";
		}
		var lab = genome_data.uniquename;
		genomeList[id] = lab;
		$( e ).prop("checked", false);
	});
	
	addToGroup(group, genomeList);
}
