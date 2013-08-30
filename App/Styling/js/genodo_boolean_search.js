/**
 * Boolean search on meta data
 *
 * Expects global js objects public_genomes and private_genomes to contain the meta data for the client
 * 
 */

/**
 * Func: booleanSearch
 * 
 * Given a "search operator" object array, performs a boolean search. Returns matching results in the same
 * format as the public_genomes and private_genomes meta-data objects.
 * 
 * Input format:
 * 
 * NOTE: the first search object does not have an operator property
 * NOTE(2): valid operator property values are ("or"|"not"|"and"). 
 * NOTE(3): I do only limited validation of input, so don't screw this up.
 * 
 * var so = [
 * 	{
 * 		search_term: "hello"
 * 		search_field: "isolation_host",
 * 		exact: false
 * 	},
 *  {
 * 		search_term: "bye"
 * 		search_field: "isolation_source",
 * 		exact: true,
 * 		operator: "not"
 * 	}
 * ];
 */
function booleanSearch(searchObj) {
	
	var searchOperations = searchObj['search'];
	var dateSearch = searchObj['date'];
	
	var numOps = searchOperations.length;
	var dateOps = dateSearch.length;
	
	if(numOps > 0) {
		// Run initial search as an OR on an empty starting set
		var s = searchOperations[0];
		var result = doSearch(s.search_term, s.search_field, "or", {}, s.exact);
		
		// Combine with remaining search operations
		for(var i = 1; i < numOps; i++) {
			s = searchOperations[i];
			result = doSearch(s.search_term, s.search_field, s.operator, result, s.exact);
		}
		
		// Limit by date
		if(dateOps > 0) {
			for(var j = 0; j < dateOps; j++) {
				var d = dateSearch[j];
				result = dateRange(d.date, d.before, result);
			}
		}
		
		return result;
		
	} else if(dateOps > 0) {
		// Only a date search
		
		// Run first date search
		var d = dateSearch[0];
		var result = dateRange(d.date, d.before);
		
		// Combine with remaining date restrictions
		for(var j = 1; j < dateOps; j++) {
			d = dateSearch[j];
			result = dateRange(d.date, d.before, result);
		}
		
		return result;
		
	} else {
		alert('No search operations passed in');
		return null;
	}
	
	
}

function doSearch(term, field, op, result, exact) {
	
	if(op == 'or') {
		// logical OR
		// Augments result
		var newresult1 = getMatching(public_genomes, field, term, exact, false);
		var newresult2 = getMatching(private_genomes, field, term, exact, false);
		
		return(combineResults(result, newresult1, newresult2));
		
	} else if(op == 'and') {
		// logical AND
		// Refines result
		return getMatching(result, field, term, exact, false);
		
	} else if(op == 'not') {
		// equivalent to logical AND NOT
		// Refines result
		return getMatching(result, field, term, exact, true);
		
	} else {
		alert('Unrecognized boolean operator: '+op);
		return null;
	}
}

function getMatching(genomeObjs, key, val, exact, negate) {
	
	var re = new RegExp(escapeRegExp(val), "i");
	
    var matches = {};
    for (var g in genomeObjs) {
    	
    	gObj = genomeObjs[g];
    	
    	
        if (!gObj.hasOwnProperty(key)) {
        	continue;
        } else {
            if(exact && !negate && gObj[key] == val) {
            	matches[g] = gObj;
            } else if(exact && negate && gObj[key] != val) {
            	matches[g] = gObj;
            } else if(!exact && !negate && re.test(gObj[key])) {
            	matches[g] = gObj;
            } else if(!exact && negate && !re.test(gObj[key])) {
            	matches[g] = gObj;
            }
        }
    }
    
    return matches;
}

function combineResults() {
	var ret = {};
	var len = arguments.length;
	for (var i=0; i<len; i++) {
		for (p in arguments[i]) {
			if (arguments[i].hasOwnProperty(p)) {
				ret[p] = arguments[i][p];
			}
		}
	}
	return ret;
}

function escapeRegExp(str) {
	return str.replace(/[\-\[\]\/\{\}\(\)\*\+\?\.\\\^\$\|]/g, "\\$&");
}

function dateRange(date, before, startSet) {
	
	if(!startSet) {
		var newresult1 = passDate(public_genomes, date, before);
		var newresult2 = passDate(private_genomes, date, before);
		
		return(combineResults(newresult1, newresult2));
		
	} else {
		return passDate(startSet, date, before);
	}
}

function passDate(genomeObjs, date, before) {
	
    var matches = {};
    for (var g in genomeObjs) {
    	
    	gObj = genomeObjs[g];
    	
        if (!gObj.hasOwnProperty('isolation_date')) {
        	continue;
        } else {
            if(before && gObj.isolation_date < date) {
            	matches[g] = gObj;
            } else if(!before && gObj.isolation_date > date) {
            	matches[g] = gObj;
            } 
        }
    }
    
    return matches;
}

// Methods for building the boolean search form

// Search fields
var bsSearchFields = {
	uniquename: "Genome Name",
	primary_dbxref: "Accession #",
	strain: "Strain",
	serotype: "Serotype",
	isolation_host: "Isolation Host",
	isolation_source: "Isolation Source",
	isolation_date: "Isolation Date",
};

// Results get set to global variable 
function buildBSForm() {
	
	// Create first search field (no operators)
	var form1 = $('<fieldset></fieldset>').appendTo('#attr-search-form');
	form1.append('<div style="padding: 0px 0 0 10px"><p>Specify genome attribute search fields and keywords:</p></div>');
	
	var field1 = $('<div class="controls controls-row" style="padding-left: 20px;"></div>').appendTo(form1);
	addBSFieldDropDown(field1, 1);
	field1.append('<input class="span3" type="text" name="attr-search-term1" placeholder="Search Term"></input>');
	field1.append('<label class="checkbox span2"><input type="checkbox" name="attr-search-exact1" value="exact"><span style="font-size:small">exact</span></label>')
	
	for(var j=2; j<5; j++) {
		var field = $('<div class="controls controls-row"></div>').appendTo(form1);
		field.append('<select class="span1" name="attr-search-op'+j+'">'+
				     '<option value="and" selected="selected">AND</option>'+
				     '<option value="or">OR</option>'+
				     '<option value="not">NOT</option>'+
				     '</select>');
		addBSFieldDropDown(field, j);
		field.append('<input class="span3" type="text" name="attr-search-term'+j+'" placeholder="Search Term"></input>');
		field.append('<label class="checkbox span2"><input type="checkbox" name="attr-search-exact'+j+'" value="exact"><span style="font-size:small">exact</span></label>')
	}
	
	var form2 = $('<fieldset></fieldset>').appendTo('#attr-search-form');
	form2.append('<div style="padding: 30px 0 0 10px"><p>Limit results by isolation date:</p></div>');
	
	for(var k=1; k<3; k++) {
		var field2 = $('<div class="controls controls-row"></div>').appendTo(form2);
		field2.append('<select class="span1" name="attr-search-before'+k+'">'+
		     '<option value="before" selected="selected">before</option>'+
		     '<option value="after">after</option>'+
		     '</select>');
		field2.append('<input class="span1" type="text" name="attr-search-year'+k+'" placeholder="YYYY"></input>');
		field2.append('<input class="span1" type="text" name="attr-search-mon'+k+'" placeholder="MM"></input>');
		field2.append('<input class="span1" type="text" name="attr-search-day'+k+'" placeholder="DD"></input>');
	}
	
	$('#attr-search-form').append('<div style="margin:20px 0px 0px 20px">'+
		'<button id="attr-search-submit" type="submit" class="btn btn-small btn-primary" value="Submit"><i class="icon-search icon-white"></i> Search</button>'+
		'<button type="reset" class="btn btn-small btn-danger" name="cancel" value="Cancel" style="margin-left: 10px"><i class="icon-remove icon-white"></i> Cancel</button>'+
		'</div>');
	
	$('#attr-search-form').submit(function(event) {
		event.preventDefault;
		
		submitSearch();
		
		return false;
	});
}

// fields argument contains an key/value object 
function addBSFieldDropDown(el, i) {
	
	var dropDown = $( '<select class="span2" name="attr-search-field'+i+'"></select>' ).appendTo(el);
	
	for(var f in bsSearchFields) {
		dropDown.append('<option value="'+f+'">'+bsSearchFields[f]+'</option>');
	}
	dropDown.append('<option value="" selected="selected">-- Select Field --</option>');
}

// Methods for parsing inputs
function getBSInput() {
	var search = [];
	var date = [];
	
	// Parse field/keyword search
	var valid_boolean_search = false;
	for(var i = 1; i < 5; i++) {
		// Parse individual search lines
		// Parse the first search line, no operator
		var op = $('select[name="attr-search-op'+i+'"]').find(':selected').val();
		var field = $('select[name="attr-search-field'+i+'"]').find(':selected').val();
		var term = $('input[name="attr-search-term'+i+'"]').val();
		var exact = false;
		if($('input[name="attr-search-exact'+i+'"]').prop("checked")) {
			exact = true;
		}
		
		// validation
		term = $.trim(term);
		var no_field = !field || field == '';
		var no_term = !term || term == '';
		
		// first line must be filled in
		if(i == 1) {	
			
			if(no_term) {
				continue;
			} else if(!no_term && no_field) {
				alert('Please select a search field in line '+i);
				return null;
			} else if(!no_term && !no_field) {
				valid_boolean_search = true;
			}

		} else {
			// other lines must be complete or empty (note: i allow users to skip lines)
			if(no_term) {
				continue;
			} else if(!no_term && no_field) {
				alert('Please select a search field in line '+i);
				return null;
			} else if(!valid_boolean_search && !no_term && !no_field) {
				alert('Error! The field and search term are required in line 1');
				return null;
			}
		}
		

		if(term.length < 3) {
			alert('Error! Minimum length for a search term is 3 characters (offending line: '+i+')');
			return null;
		}
		
		if(i > 1) {
			search.push({
				search_term: term,
				search_field: field,
				exact: exact,
				operator: op
			});
		} else {
			search.push({
				search_term: term,
				search_field: field,
				exact: exact
			});
		}
	}
	
	// Parse date
	var valid_date_search = false;
	for(var j = 1; j < 3; j++) {
		var before = $('select[name="attr-search-before'+j+'"]').find(':selected').val();
		var year = $('input[name="attr-search-year'+j+'"]').val();
		var mon = $('input[name="attr-search-mon'+j+'"]').val();
		var day = $('input[name="attr-search-day'+j+'"]').val();
		
		// Validate date
		if(year && year != '') {
			year = $.trim(year)
			if(!/^\d\d\d\d$/.test(year)) {
				alert('Error! Invalid year in line '+(j+4)+' (proper format: YYYY)');
				return null
			}
		}
		if(mon && mon != '') {
			if(!year) {
				alert('Error! year missing in line '+(j+4));
			}
			mon = $.trim(mon)
			if(!/^\d\d?$/.test(mon)) {
				alert('Error! Invalid month in line '+(j+4)+' (proper format: MM)');
				return null
			}
			if(/^\d$/.test(mon)) {
				mon = '0'+mon;
			}
			
		}
		if(day && day != '') {
			if(!mon) {
				alert('Error! month missing'+(j+4));
			}
			day = $.trim(day)
			if(!/^\d\d?$/.test(day)) {
				alert('Error! Invalid day in line '+(j+4)+' (proper format: DD)');
				return null
			}
			if(/^\d$/.test(day)) {
				day = '0'+day;
			}
		}
		
		// Only year is required
		if(year) {
			mon = mon ? mon : '01';
			day = day ? day : '01';
			
			// Make sure its a valid date:
			var d = new Date(year, mon, day);
			if(isNaN(d.getTime())) {
				alert('Error! invalid date in line '+(j+4));
			}
			var b = (before == 'before') ? true : false;
			
			date.push({
				date: year+'-'+mon+'-'+day,
				before: b
			});
			
			valid_date_search = true;
		}
	}
	
	if(!valid_date_search && !valid_boolean_search) {
		alert('Error! empty search form');
		return null;
	}
	
	return { search: search, date: date };
}

// Methods for changing meta data displayed in results window
function updateAttrMeta(visableData, set) {
	// Default is to display just the name
	if(typeof visableData === 'undefined' || visableData.length == 0) {
		visableData = ['name'];
	}
	
	if(!set || $.isEmptyObject(set)) {
		return false;
	}
	
	var display = $('#attr-search-display')
	display.empty();
	
	$.each( set, function(feature_id, feature_obj) {
		var lab = metaLabel(feature_obj, visableData);
		
		display.append(function() { 
			return attrListItem(feature_id, lab); 
		});
	});
	 
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

function attrListItem(id, label) {
	
	return '<li>'+
		label+
		' <a href="/strain_info?genome='+id+'" class=""><i class="icon-search"></i> info</a>'+
		'</li>';
}

function updateBSResultStatus(set, status) {
	
	if(status) {
		$('#attr-search-result-total').text(status);
	} else {
		var tot = Object.keys(set).length;
		$('#attr-search-result-total').text(tot+' results found.');
	}
}


// User clicked submit, run a search and update results display
function submitSearch() {
	
	// Clear old results
	attr_search_result = {};
	$('#attr-search-display').empty();
	updateBSResultStatus({}, 'performing search...');
	
	var searchObj = getBSInput();
	
	if(searchObj) {
		
		var res = booleanSearch(searchObj);
		
		// Post new results
		var visibleData = [];
		$('input[name="attr-meta-option"]:checked').each( function(i, e) { visibleData.push( $( e ).val() ); });
		updateAttrMeta(visableData, res);

		updateBSResultStatus(res, false);
		attr_search_result = res; // Save result as global
		
	} else {
		updateBSResultStatus({}, 'error in input');
	}
}


