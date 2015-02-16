###


 File: superphy_user_groups.coffee
 Desc: Objects & functions for managing user created groups in Superphy
 Author: Akiff Manji akiff.manji@gmail.com
 Date: Sept 8th, 2014
 
 
###

root = exports ? this

###
 CLASS SuperphyError
 
 Error object for this library
 
###
class SuperphyError extends Error
  constructor: (@message='', @name='Superphy Error') ->

class UserGroups
	constructor: (@userGroupsObj, @parentElem, @viewController) ->
		throw new SuperphyError 'User groups object cannot be empty/null.' unless @userGroupsObj
		throw new SuperphyError 'Parent div not specified.' unless @parentElem
		throw new SuperphyError 'ViewController object is required' unless @viewController

		@user_group_collections = {
			group_collections : {}
		}

		@appendGroupForm(@userGroupsObj)
		@processUserGroups(@userGroupsObj)

	#Separate out appending the user groups div and processing the actual groups

	appendGroupForm: (uGpObj) ->
		if uGpObj.status
			return @parentElem.append('<div class="alert alert-info" role="alert">'+uGpObj.status+'</div>')
		else
			#@group_collections_select = jQuery('<select id="select-group-collections" class="form-control" placeholder="--Select from group collections--"></select>').appendTo(@parentElem)
			#@group_collections_group_select = jQuery('<select id="select-group-collections-groups" class="form-control" placeholder="--Select from groups--"></select>').appendTo(@parentElem)
			#editSpan = jQuery('<span>You can edit your existing groups <a href="/groups/shiny"> here</a>.</span>').appendTo(@parentElem)
			
			# Header
		    header = jQuery(
		      '<div class="panel-heading">'+
		      '<div class="panel-title">'+
		      '<a data-toggle="collapse" href="#user-groups-form"><i class="fa fa-filter"></i> User Groups '+
		      '<span class="caret"></span></a>'+
		      '</div></div>').appendTo(@parentElem)

			container = jQuery('<div id="user-groups-form" class="panel-collapse collapse in"></div>')
			user_groups_form = jQuery('<form class="form"></form>').appendTo(container)

			create_group = jQuery('<div class="form-group"></div>').appendTo(user_groups_form)
			create_group_row = jQuery('<div class="row"></div>').appendTo(create_group)
			create_group_button = jQuery('<div class="col-xs-5"><button class="btn btn-default btn-sm">Create Group</button></div>').appendTo(create_group_row)
			create_group_input = jQuery('<div class="col-xs-7"><input class="form-control input-sm" type="text" placeholder="Group Name"></div>').appendTo(create_group_row)

			group_select = jQuery('<div class="control-group"></div>').appendTo(user_groups_form)
			select = jQuery("<select multiple id='user_group_collections' class='form-control' placeholder='Select group(s)...'></select>").appendTo(group_select)
			
			load_save_groups = jQuery('<div class="form-group"></div>').appendTo(user_groups_form)
			load_save_groups_row = jQuery('<div class="row"></div>').appendTo(load_save_groups)
			load_groups_button = jQuery('<div class="col-xs-3"><button class="btn btn-default btn-sm">Load</button></div>').appendTo(load_save_groups_row)
			save_groups_button = jQuery('<div class="col-xs-3"><button class="btn btn-default btn-sm">Save</button></div>').appendTo(load_save_groups_row)

			container.appendTo(@parentElem)

		true

	processUserGroups: (uGpObj) ->
		#return if uGpObj.status

		user_groups_select_optgroups = []
		user_groups_select_options = []
		for group_collection, group_collection_index of uGpObj.standard
			user_groups_select_optgroups.push({value: group_collection_index.name, label: group_collection_index.name, count: group_collection_index.children.length})
			user_groups_select_options.push({class: group_collection_index.name, value: group.name, name: group.name, id: group.id}) for group in group_collection_index.children
			
		#console.log(user_groups_select_optgroups)
		console.log(user_groups_select_options)

		$selectized_group_select = $('#user_group_collections').selectize({
			delimiter: ',',
			persist: false,
			options: user_groups_select_options,
			optgroups: user_groups_select_optgroups,
			optgroupField: 'class',
			labelField: 'name',
			searchField: ['name'],
			render: {
				optgroup_header: (data, escape) =>
					return "<div class='optgroup-header'>#{data.label} - <span>#{data.count}</span></div> "
				option: (data, escape) =>
					#console.log data
					return "<div>#{data.value}</div>"
				item: (data, escape) =>
					#console.log data
					return "<div>#{data.value}</div>"
			},
			create:	true
			})

		true

		#console.log($selectized_group_select)

		###		group_collections_select_options = []
		for collection_name, collection_array of uGpObj when collection_name isnt 'genome_id'
			group_collections_select_options.push({value: "#{collection_name}", name: "#{collection_name}"})
			@user_group_collections.group_collections[collection_name] = {}
			@user_group_collections.group_collections[collection_name]['Ungrouped'] = []
			for group_name, index in collection_array
				@user_group_collections.group_collections[collection_name][group_name] = [] unless @user_group_collections.group_collections[collection_name][group_name] or group_name is null
				@user_group_collections.group_collections[collection_name][group_name].push(uGpObj.genome_id[index]) unless group_name is null
				@user_group_collections.group_collections[collection_name]['Ungrouped'].push(uGpObj.genome_id[index]) if group_name is null
			delete @user_group_collections.group_collections[collection_name]['Ungrouped'] unless @user_group_collections.group_collections[collection_name]['Ungrouped'].length
		
		$select_group_collection = @group_collections_select.selectize({
				onChange: (value) =>
					@select_group.disable()
					@select_group.clearOptions()
					return if not value.length
					true
					@select_group.load( (callback) =>
						@select_group.enable()
						groups_results = []
						groups_results.push({name: k, value: k}) for k, v of @user_group_collections.group_collections[value]
						callback(groups_results);
						)
				searchField: ['name']
				options: group_collections_select_options
				render: {
        			option: (data, escape) =>
          				return "<div class='option'>#{data.name}</div>"
        			item: (data, escape) =>
          				return "<div class='item'>#{data.name}</div>"
      			}
			})


		$select_group = @group_collections_group_select.selectize({
			onChange: (value) =>
				return @_updateSelections(value)
			valueField: 'value'
			labelField: 'name'
			searchField: ['name']
			})

		@select_group_collection = $select_group_collection[0].selectize
		@select_group = $select_group[0].selectize

		@select_group.disable();

		true###

	_updateSelections: (group_name) =>
		collection_name = @select_group_collection.getValue()
		@viewController.select(genome_id, false) for genome_id in Object.keys(viewController.genomeController.public_genomes)
		@viewController.select(genome_id, false) for genome_id in Object.keys(viewController.genomeController.private_genomes)
		if group_name is ""
			#Do nothing but return
		else
			group_genomes = @user_group_collections.group_collections[collection_name][group_name]
			@viewController.select(genome_id, true) for genome_id in group_genomes when genome_id in viewController.genomeController.pubVisible
			@viewController.select(genome_id, true) for genome_id in group_genomes when genome_id in viewController.genomeController.pvtVisible
		true

# Return instance of UserGroups
unless root.UserGroups
  root.UserGroups = UserGroups