###


 File: superphy_menu.coffee
 Desc: Objects & functions for managing navigation/icon menus in Superphy
 Author: Akiff Manji akiff.manji@gmail.com
 Date: July 24th, 2014
 
 
###

root = exports ? this

###
 CLASS SuperphyError
 
 Error object for this library
 
###
class SuperphyError extends Error
  constructor: (@message='', @name='Superphy Error') ->

class SuperphyMenu
  constructor: (@menuElem, @affix2Elem, @pageName, @searchList, @viewList, @searchUrl, @redirectSearch=false) ->
    throw new SuperphyError 'SuperphyMenu requires menuElem parameter' unless @menuElem
    throw new SuperphyError 'SuperphyMenu requires affix2Elem parameter' unless @affix2Elem

    @createNavMenu();
    @appendSearchList();
    @appendViewList();
    @setAffixActions();

  @iconLocation = '/App/Styling/superphy_icons/'

  @iconType = 'svg'

  @iconClasses = {
    'overview' : 'overview_icon_large'
    'stx': 'stx_icon_large'
    'phylogeny': 'phylogeny_icon_large'
    'geospatial': 'geospatial_icon_large'
    'vf': 'vf_icon_large'
    'amr': 'amr_icon_large'
    'download': 'download_icon_large'
    'genomelist': 'genomelist_icon_large'
    'alleles' : 'alleles_icon_large'
    'msa' : 'msa_icon_large'
  }

  createNavMenu: () ->
    #Creates the shell menu element
    @menuRowEl = jQuery('<div class="row"></div>')
    @menuAppendToEl = jQuery('<div class="col-md-12 hidden-xs" id="superphy-icon-menu"></div>').appendTo(@menuRowEl)
    @menuAffixEl = jQuery('<nav id="menu-affix" class="panel panel-default"></nav>').appendTo(@menuAppendToEl)
    @mainMenu = jQuery('<ul class="nav"></ul>').appendTo(@menuAffixEl)

    @menuRowEl.appendTo(@menuElem)

    true

  appendSearchList: () ->
    #TODO
    rowEl = jQuery('<div class="row"></div>')
    navEl = jQuery('<ul class="nav"></ul>').appendTo(rowEl)

    newLineEl = jQuery('<div class="col-sm-12"></div>').appendTo(navEl)

    jQuery('<div class="panel-heading"><div class="panel-title">Search By:</div></div>').appendTo(newLineEl)

    for sIcon in @searchList

      divEl = jQuery('<div class="col-xs-2"></div>')
      liEl = jQuery('<li></li>').appendTo(divEl)
      linkEl = jQuery("<a href='#'></a>").appendTo(liEl)
      iconDivEl = jQuery('<div class="superphy-icon"></div>').appendTo(linkEl)
      iconEl = jQuery("<div class='superphy-icon-img #{sIcon}' data-toggle='tooltip' title='#{sIcon}'></div>").appendTo(iconDivEl)
      captionEl = jQuery("<div class='caption'><small>#{sIcon}</small></div>").appendTo(iconDivEl)

      divEl.appendTo(newLineEl)

    rowEl.appendTo(@mainMenu)

    true

  appendViewList: () ->
    #TODO
    true

  setAffixActions: () ->
    menu_affix_height = jQuery(@menuAffixEl).height()

    navbar_height = jQuery('.navbar').height()

    that = @

    @menuAffixEl.on('affix.bs.affix', () ->
      jQuery('#accordian').css("margin-top", menu_affix_height + navbar_height)
      jQuery(@).prependTo(jQuery(that.affix2Elem)).hide().fadeIn('slow')
      jQuery('.superphy_icon').addClass('affix')
      )

    @menuAffixEl.on('affix-top.bs.affix', () ->
      jQuery('#accordian').css("margin-top", "0px")
      jQuery(@).appendTo(jQuery(that.menuAppendToEl)).hide().fadeIn('slow')
      jQuery('.superphy_icon').removeClass('affix')
      )

    jQuery('[data-toggle="tooltip"]').tooltip({'placement': 'top'})

    jQuery(@menuAffixEl).affix({
      offset: {top: menu_affix_height}
      })

    # Set size classes on window load and resize
    jQuery(window).load( () ->
      if jQuery(@).width() < 1000
        jQuery(that.menuAffixEl).addClass('sm')
      else
        jQuery(that.menuAffixEl).removeClass('sm')
      )

    jQuery(window).resize( () ->
      if jQuery(@).width() < 1000
        jQuery(that.menuAffixEl).addClass('sm')
      else
        jQuery(that.menuAffixEl).removeClass('sm')
      )

    true

# Return instance of SuperphyMenu
unless root.SuperphyMenu
  root.SuperphyMenu = SuperphyMenu