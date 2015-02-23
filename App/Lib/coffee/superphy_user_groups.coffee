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
  constructor: (@userGroupsObj, @username, @parentElem, @viewController, @public_genomes, @private_genomes) ->
    throw new SuperphyError 'User groups object cannot be empty/null.' unless @userGroupsObj
    throw new SuperphyError 'Parent div not specified.' unless @parentElem
    throw new SuperphyError 'ViewController object is required' unless @viewController

    @user_group_collections = {
      group_collections : {}
    }

    @appendGroupForm(@userGroupsObj)

    #Separate out appending the user groups div and processing the actual groups
  appendGroupForm: (uGpObj) =>
      # Header
      header = jQuery(
        '<div class="panel-heading">'+
        '<div class="panel-title">'+
        '<a data-toggle="collapse" href="#user-groups-form"> User Groups '+
        '<span class="caret"></span></a>'+
        '</div></div>').appendTo(@parentElem)

      container = jQuery('<div id="user-groups-form" class="panel-collapse collapse in"></div>').appendTo(@parentElem)
      user_groups_form = jQuery('<form class="form"></form>').appendTo(container)

      create_group = jQuery('<div class="form-group"></div>').appendTo(user_groups_form)
      create_group_row = jQuery('<div class="row"></div>').appendTo(create_group)
      create_group_button = jQuery('<div class="col-xs-5"><button class="btn btn-default btn-sm">Create Group</button></div>').appendTo(create_group_row)
      create_group_input = jQuery('<div class="col-xs-7"><input class="form-control input-sm" type="text" placeholder="Group Name"></div>').appendTo(create_group_row)

      group_select = jQuery('<div class="control-group"></div>').appendTo(user_groups_form)
      standard_select = jQuery('<select id="standard_group_collections" class="form-control" placeholder="Select group(s)..."></select>').appendTo(group_select)

      
      unless @username isnt ""
        custom_select = jQuery('<div class="alert alert-info" role="alert">Please <a href="/user/login">sign in</a> to view your custom groups</div>')
      else
        custom_select = jQuery('<select id="custom_group_collections" class="form-control" placeholder="Select custom group(s)..."></select>')
      custom_select.appendTo(group_select)
      
      @_processGroups(uGpObj)

      load_save_groups = jQuery('<div class="form-group"></div>').appendTo(user_groups_form)
      load_save_groups_row = jQuery('<div class="row"></div>').appendTo(load_save_groups)

      load_groups_button = jQuery('<div class="col-xs-3"><button class="btn btn-default btn-sm" type="button">Load</button></div>')

      load_groups_button.click( (e) => 
        #TODO:Update to deal with private groups
        e.preventDefault()
        select_ids = @_getGroupGenomes(standard_select.find('option').val(), @public_genomes, @private_genomes)
        @_updateSelections(select_ids)
        ).appendTo(load_save_groups_row)

      save_groups_button = jQuery('<div class="col-xs-3"><button class="btn btn-default btn-sm">Save</button></div>').appendTo(load_save_groups_row)

      true

  _processGroups: (uGpObj) =>
    # Process standard groups
    standard_groups_select_optgroups = []
    standard_groups_select_options = []
    for group_collection, group_collection_index of uGpObj.standard
      standard_groups_select_optgroups.push({value: group_collection_index.name, label: group_collection_index.name, count: group_collection_index.children.length})
      standard_groups_select_options.push({class: group_collection_index.name, value: group.id, name: group.name}) for group in group_collection_index.children

    $selectized_standard_group_select = $('#standard_group_collections').selectize({
      delimiter: ',',
      persist: false,
      options: standard_groups_select_options,
      optgroups: standard_groups_select_optgroups,
      optgroupField: 'class',
      labelField: 'name',
      searchField: ['name'],
      render: {
        optgroup_header: (data, escape) =>
          return "<div class='optgroup-header'>#{data.label} - <span>#{data.count}</span></div> "
        option: (data, escape) =>
          return "<div data-collection_name='#{data.class}' data-group_name='#{data.name}'>#{data.name}</div>"
        item: (data, escape) =>
          return "<div>#{data.name}</div>"
        },
      create:	true
      })

    @standardSelectizeControl = $selectized_standard_group_select[0].selectize

    return unless @username isnt ""

    # Process custom groups
    custom_groups_select_optgroups = []
    custom_groups_select_options = []
    for group_collection, group_collection_index of uGpObj.custom
      custom_groups_select_optgroups.push({value: group_collection_index.name, label: group_collection_index.name, count: group_collection_index.children.length})
      custom_groups_select_options.push({class: group_collection_index.name, value: group.id, name: group.name}) for group in group_collection_index.children

    $selectized_custom_group_select = $('#custom_group_collections').selectize({
      delimiter: ',',
      persist: false,
      options: custom_groups_select_options,
      optgroups: custom_groups_select_optgroups,
      optgroupField: 'class',
      labelField: 'name',
      searchField: ['name'],
      render: {
        optgroup_header: (data, escape) =>
          return "<div class='optgroup-header'>#{data.label} - <span>#{data.count}</span></div> "
        option: (data, escape) =>
          return "<div data-collection_name='#{data.class}' data-group_name='#{data.name}'>#{data.name}</div>"
        item: (data, escape) =>
          return "<div>#{data.name}</div>"
        },
      create: true
      })

    @customSelectizeControl = $selectized_custom_group_select[0].selectize


  _getGroupGenomes: (group_id, public_genomes, private_genomes) =>
    option = @standardSelectizeControl.getOption(group_id)[0]
    collection_name = $(option).data("collection_name")
    group_name = $(option).data("group_name")

    select_public_ids =  (genome_id for genome_id, genome_obj of public_genomes when parseInt(group_id) in genome_obj.groups)
    select_private_ids =  (genome_id for genome_id, genome_obj of private_genomes when parseInt(group_id) in genome_obj.groups)

    return {'select_public_ids' : select_public_ids, 'select_private_ids' : select_private_ids}

  # Create a method that will iterate through all the public genomes and if the loaded group id matches one in the group meta data select that genome

  _updateSelections: (select_ids) =>
    #TODO:
    # Uncheck all selected genomes
    @viewController.select(genome_id, false) for genome_id in Object.keys(viewController.genomeController.public_genomes)
    @viewController.select(genome_id, false) for genome_id in Object.keys(viewController.genomeController.private_genomes)
    if not select_ids.select_public_ids.length and not select_ids.select_private_ids.length
      #Do nothing but return
    # First check if custom user groups
    else
      @viewController.select(genome_id, true) for genome_id in select_ids.select_public_ids when genome_id in viewController.genomeController.pubVisible
      @viewController.select(genome_id, true) for genome_id in select_ids.select_private_ids when genome_id in viewController.genomeController.pvtVisible
    true

  # Return instance of UserGroups
unless root.UserGroups
  root.UserGroups = UserGroups