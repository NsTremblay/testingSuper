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
	constructor: (@userGroupsObj, @parentElem) ->
		throw new SuperphyError 'User groups object cannot be empty/null.' unless @userGroupsObj
		throw new SuperphyError 'Parent div not specified.' unless @parentElem

		@user_group_collections = {
			group_collections : {}
		}

		@processUserGroups(@userGroupsObj)


	processUserGroups: (uGpObj) ->
		if uGpObj.status
			return @parentElem.append('<div class="alert alert-info" role="alert">'+uGpObj.status+'</div>')
		else
			group_collections_select = jQuery('<select id="select-group-collections" class="form-control" placeholder="--Select from group collections--"></select>').appendTo(@parentElem)
			group_collections_group_select = jQuery('<select id="select-group-collections-groups" class="form-control" placeholder="--Select from groups--"></select>').appendTo(@parentElem)
			editSpan = jQuery('<span>You can edit your existing groups <a href="/groups/shiny"> here</a>.</span>').appendTo(@parentElem)


			group_collections_select_options = []
			for collection_name, collection_array of uGpObj when collection_name isnt 'genome_id'
				group_collections_select_options.push({value: "#{collection_name}", name: "#{collection_name}"})
				@user_group_collections.group_collections[collection_name] = {}
				@user_group_collections.group_collections[collection_name]['Ungrouped'] = []
				for group_name, index in collection_array
					@user_group_collections.group_collections[collection_name][group_name] = [] unless @user_group_collections.group_collections[collection_name][group_name] or group_name is null
					@user_group_collections.group_collections[collection_name][group_name].push(uGpObj.genome_id[index]) unless group_name is null
					@user_group_collections.group_collections[collection_name]['Ungrouped'].push(uGpObj.genome_id[index]) if group_name is null
				delete @user_group_collections.group_collections[collection_name]['Ungrouped'] unless @user_group_collections.group_collections[collection_name]['Ungrouped'].length
			
			$select_group_collection = group_collections_select.selectize({
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


			$select_group = group_collections_group_select.selectize({
				onChange: (value) =>
					return @_updateSelections(value)
				valueField: 'value'
				labelField: 'name'
				searchField: ['name']
				})

			@select_group_collection = $select_group_collection[0].selectize
			@select_group = $select_group[0].selectize

			@select_group.disable();

			true

	_updateSelections: (group_name) =>
		collection_name = @select_group_collection.getValue()
		console.log collection_name
		console.log group_name
		true

# Return instance of UserGroups
unless root.UserGroups
  root.UserGroups = UserGroups