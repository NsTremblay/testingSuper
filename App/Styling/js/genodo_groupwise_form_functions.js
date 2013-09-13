/**
 * Manages complex groupwise form in SuperPhy application
 * 
 * Copyright (c) Matt Whiteside 2013.
 *
 **/

 function buildMetaForm(el, tab) {

 	var validTabs = ['list', 'tree', 'map'];
 	var formLabels = ['drop-down list', 'tree', 'map'];

 	var i = validTabs.indexOf(tab);
 	if(i == -1) {
 		alert('unknown tab name');
 		return('false');
 	}

	// Build form
	var form_html = '<div style="display: inline-block;">'+	
	'<button type="button" class="btn btn-mini btn-info" data-toggle="collapse" data-target="#'+tab+'-meta-display">'+
	'<i class=" icon-eye-open icon-white"></i>'+
	'<span class="caret"></span>'+
	'</button>'+
	'<div id="'+tab+'-meta-display" class="collapse out" style="border-style:solid; border-width:1px; border-color:#d3d3d3; margin:10px;">'+
	'<div style="padding:10px;">Change meta-data displayed in '+formLabels[i]+':</div>'+
	'<form class="form-horizontal" style="padding:0px 5px 0 20px;">'+
	'<fieldset>'+		    	
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="name"> Name </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="accession"> Accession # </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="strain"> Strain </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="serotype"> Serotype </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="isolation_host"> Isolation Host </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="isolation_source"> Isolation Source </label>'+
	'<label><input class="meta-option" type="checkbox" name="'+tab+'-meta-option" value="isolation_date"> Isolation Date </label>'+														   			   						   
	'</fieldset>'+
	'<button id="update-'+tab+'-meta" class="btn btn-small" style="margin:10px 0 0 10px;">Update</button>'+
	'</form>'+
	'</div>'+
	'</div>'+
	'</div>'+
	'</div>';
	
	$(el).append(form_html);
	
	// Setup button behavior
	$('#update-'+tab+'-meta').click(function(event) {
		event.preventDefault();
		var visibleData = [];
		$('input[name="'+tab+'-meta-option"]:checked').each( function(i, e) { visibleData.push( $( e ).val() ); });
		updateMeta(tab, visibleData);

		return false;
	});
}

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
		var currentLabels = genomeLabels;
		genomeLabels = {};
		$.each( public_genomes, function(feature_id, feature_obj) {
			var lab = metaLabel(feature_obj, visableData);
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

	} else if (tab == 'map') {
		//Do something here about that
		var dropDown = $('#multiMapStrainList');
		dropDown.empty();
		$('#select-all-map').is(':checked') ? $('#select-all-map').click() : 0;
		
		$.each( visibleMarkers, function(feature_id, feature_obj) {
			var locationTitle = multiMarkers[feature_id].title;
			var lab = metaLabel(public_location_genomes[feature_id], visableData);
			dropDown.append(
				'<li style="list-style-type:none">'+
				'<label class="checkbox" for="map_'+feature_id+'"><input id="map_'+feature_id+'" class="checkbox" type="checkbox" value="'+feature_id+'" name="genomes-in-map-search">'+locationTitle+' - '+lab+'</label>'+								
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

// Create labels for a genome with required meta data
function metaLabel(feature, vdata) {
	var label = [];
	if(vdata.indexOf('name') != -1) {
		label.push(feature.uniquename);
	}
	
	if(vdata.indexOf('accession') != -1) {
		if(typeof feature.primary_dbxref !== 'undefined') {
			label.push(feature.primary_dbxref);
		} else {
			label.push('NA');
		}
	}
	
	var metaDataTypes = ['strain', 'serotype', 'isolation_host', 'isolation_source', 'isolation_date'];
	for(var i=0; i<metaDataTypes.length; i++) {
		var x = metaDataTypes[i];
		
		if(vdata.indexOf(x) != -1) {
			
			if(typeof feature[x] !== 'undefined') {
				var sublabel = [];
				
				for(var j=0; j<feature[x].length; j++) {
					sublabel.push(feature[x][j]);
				}
				
				var sublabel_string = sublabel.join();
				label.push(sublabel_string);
			} else {
				label.push('NA');
			}
		}
	}
	return label.join('|');
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
