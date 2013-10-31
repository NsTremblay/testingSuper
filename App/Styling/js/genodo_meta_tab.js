//Right now we have meta tabs in:

// Strain Info
// Advanced Search - Genome Attributes
// Advanced Search - Tree
// Advanced Search - Map
// Group Comparisons - Genome Attributes
// Group Comparisons - Tree
// Group Comparisons - Map
// VF/AMR - Strain Selection

function MetaTab(tab) {
	this.labels = {strainList: "the list of genomes", attrList: "the search results", treeList: "the tree", mapList: "the list of genomes with locations"}

	this.tab = tab;
	// Build form
	this.form_html = '<div style="display: inline-block;">'+	
	'<button type="button" class="btn btn-mini btn-info" data-toggle="collapse" data-target="#'+tab+'-meta-display">'+
	'<i class=" icon-eye-open icon-white"></i>'+
	'<span class="caret"></span>'+
	'</button>'+
	'<div id="'+tab+'-meta-display" class="collapse out" style="border-style:solid; border-width:1px; border-color:#d3d3d3; margin:10px;">'+
	'<div style="padding:10px;">Change meta-data displayed in '+this.labels[tab]+':</div>'+
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
	//'<!--button id="update-'+tab+'-meta" class="btn btn-small" style="margin:10px 0 0 10px;">Update</button-->'+
	'</form>'+
	'</div>'+
	'</div>'+
	'</div>'+
	'</div>';
	return this;
}

MetaTab.prototype.updateSelections = function(selected, checked, selections) {
	var index = selections.indexOf(selected);
	//Checked and not found, add
	if (index == -1 && checked == 1) {
		selections.push(selected);
	}
	//Not checked and found, remove 
	else if (index > -1 && checked == 0) {
		selections.splice(index, 1);
	}
	//Either checked and found, or not checked and not found
	else {
		//Do nothing
	}
	return selections;
};

MetaTab.prototype.metaLabel = function(feature, vdata) {
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
};
