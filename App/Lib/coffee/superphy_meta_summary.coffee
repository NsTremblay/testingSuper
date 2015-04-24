###

 File: superphy_summary.coffee
 Desc: Meta-data Summary class
 Author: Jason Masih jason.masih@phac-aspc.gc.ca
 Date: March 4th, 2015

###

###

 CLASS SummaryView

 Group/selection meta-data summary view 

 Creates stacked bar representation of meta-data for genome group/selection

###

class SummaryView extends ViewTemplate
	constructor: (@parentElem, @style, @elNum, @genomes, summaryArgs) ->
    @width = 660
    @height = 280
    @svgActiveGroup = d3.select('#active-group-tab').append('text').text('No group selected')
    @svgSelection = d3.select('#selection-tab').append('text').text('No genomes selected')
    @mtypesDisplayed = ['serotype','isolation_host','isolation_source','syndrome','stx1_subtype','stx2_subtype']
    @colours = {
      'serotype' : [
        '#236932',
        '#468554',
        '#6AA276',
        '#8DBE98',
        '#B0DABA',
        '#D4F7DC',
        '#e9fbed'
      ]
      'isolation_host' : [
        '#a70209',
        '#b3262c',
        '#c04a4f',
        '#cc6e72',
        '#d99295',
        '#e5b6b8',
        '#f2dadb'
      ]
      'isolation_source' : [
        '#3741ae',
        '#535cb9',
        '#7077c5',
        '#8c92d0',
        '#a9addc',
        '#c5c8e7',
        '#e2e3f3'
      ]
      'syndrome' : [
        '#962ba6',
        '#a549b2',
        '#b467bf',
        '#c385cc',
        '#d2a4d8',
        '#e1c2e5',
        '#f0e0f2'
      ]
      'stx1_subtype' : [
        '#F05C00',
        '#EF7123',
        '#EE8746',
        '#ED9D69',
        '#ECB28C',
        '#EBC8AF',
        '#EADED2'
      ]
      'stx2_subtype' : [
        '#35a6a7',
        '#51b2b3',
        '#6ebfc0',
        '#8bcccc',
        '#a8d8d9',
        '#c5e5e5',
        '#e2f2f2'
      ]
    }

    totalCount = {}
    for m in @mtypesDisplayed
      totalCount[m] = {}

    all_genomes = (Object.keys(@genomes.public_genomes)).concat(Object.keys(@genomes.private_genomes))
    
    # Saves total meta-data frequency to totalCount object
    for g in all_genomes
      @countMeta(totalCount, @genomes.genome(g), true)

    # @metaOntology object ensures the sub-bars of the meta-data summaries are in the order of the most frequent meta-data types (descending), according to the entire set of genomes
    # tt_mtitle sets meta-data category titles to have correct capitalization and spacing 
    @metaOntology = {}
    @tt_mtitle = {}
    for m in @mtypesDisplayed
      @selectionCount[m] = {}
      @metaOntology[m] = []
      @tt_mtitle[m] = new String()
      @metaOntology[m] = Object.keys(totalCount[m]).sort((a,b) -> totalCount[m][b] - totalCount[m][a])
      if m is "isolation_host" or m is "isolation_source"
        @tt_mtitle[m] = m.charAt(0).toUpperCase() + m.slice(1)
        @tt_mtitle[m] = @tt_mtitle[m].replace("_", " ")
        @tt_mtitle[m] = @tt_mtitle[m].slice(0,10) + @tt_mtitle[m].charAt(10).toUpperCase() + @tt_mtitle[m].slice(11)
      if m is "syndrome"
        @tt_mtitle[m] = "Symptoms/Diseases"
      if m is "stx1_subtype" or m is "stx2_subtype"
        @tt_mtitle[m] = m.charAt(0).toUpperCase() + m.slice(1)
        @tt_mtitle[m] = @tt_mtitle[m].replace("_", " ")
        @tt_mtitle[m] = @tt_mtitle[m].slice(0,5) + @tt_mtitle[m].charAt(5).toUpperCase() + @tt_mtitle[m].slice(6)
      if m is "serotype"
        @tt_mtitle[m] = m.charAt(0).toUpperCase() + m.slice(1)

    super(@parentElem, @style, @elNum)

  selection: []
  selectionCount: {}
  activeGroup: []
  activeGroupCount: {}

  type: 'summary'
  
  elName: 'meta_summary'

  sumView: true

  # Currently empty to satisfy class requirement; needs to be resolved
  # FUNC update
  #
  # PARAMS
  # GenomeController object
  #
  # RETURNS
  # boolean
  #
  update: (genomes) ->

    true

  # FUNC updateActiveGroup
  # Update active group meta-data summary view
  #
  # PARAMS
  # GenomeController object, UserGroup object
  # 
  # RETURNS
  # boolean 
  # 
  updateActiveGroup: (genomes, usrGrp) ->

    # Reset counts upon selecting a new group
    for m in @mtypesDisplayed
      @activeGroupCount[m] = {}
      @selectionCount[m] = {}

    @svgActiveGroup.remove()
    @svgSelection.remove()

    # Get active group genome list
    @activeGroup = []
    @activeGroup = (usrGrp.active_group.public_list).concat(usrGrp.active_group.private_list)

    # Copy @activeGroup into @selection for initial selection view
    @selection = []
    @selection = @selection.concat(@activeGroup)

    @svgSelection = d3.select('#selection-tab').text(()=>
      if @selection.length is 0
        countText = ''
      if @selection.length is 1
        countText = '1 genome selected'
      if @selection.length > 1
        countText = @selection.length + ' genomes selected'
      countText).append('svg').attr('class', 'summaryPanel').attr('width', @width).attr('height', @height)
    
    if @activeGroup.length > 0
      @svgActiveGroup = d3.select('#active-group-tab').text('Active group: ' + usrGrp.active_group.group_name).append('svg').attr('class', 'summaryPanel').attr('width', @width).attr('height', @height)
      for g in @activeGroup
        @countMeta(@activeGroupCount, @genomes.genome(g), true)
      for g in @selection
        @countMeta(@selectionCount, @genomes.genome(g), true)
      @createMeters(@activeGroupCount, @svgActiveGroup, @activeGroup)
      @createMeters(@selectionCount, @svgSelection, @selection)
    else
      @svgActiveGroup = d3.select('#active-group-tab').append('text').text('No group selected')
      @svgSelection = d3.select('#selection-tab').append('text').text('No genomes selected')

    true

  # FUNC countMeta
  # Counts meta-data, for both selecting and unselecting
  #
  # PARAMS
  # Count object, genome object, isSelected boolean
  #
  # RETURNS
  # Count object
  #
  countMeta: (count, genome, isSelected) ->
    
    if isSelected
      # Increments count for selected genomes
      if count['serotype'][genome.serotype]?
        count['serotype'][genome.serotype] += 1
      else count['serotype'][genome.serotype] = 1
      if count['isolation_host'][genome.isolation_host]?  
        count['isolation_host'][genome.isolation_host] += 1
      else count['isolation_host'][genome.isolation_host] = 1
      if count['isolation_source'][genome.isolation_source]?
        count['isolation_source'][genome.isolation_source] += 1
      else count['isolation_source'][genome.isolation_source] = 1
      if count['syndrome'][genome.syndrome]?
        count['syndrome'][genome.syndrome] += 1
      else count['syndrome'][genome.syndrome] = 1
      if count['stx1_subtype'][genome.stx1_subtype]?
        count['stx1_subtype'][genome.stx1_subtype] += 1
      else count['stx1_subtype'][genome.stx1_subtype] = 1
      if count['stx2_subtype'][genome.stx2_subtype]?
        count['stx2_subtype'][genome.stx2_subtype] += 1
      else count['stx2_subtype'][genome.stx2_subtype] = 1
    else
      # Decrements count for unselected genomes
      if count['serotype'][genome.serotype] > 0
        count['serotype'][genome.serotype] -= 1
      else count['serotype'][genome.serotype] = 0
      if count['isolation_host'][genome.isolation_host] > 0
        count['isolation_host'][genome.isolation_host] -= 1
      else count['isolation_host'][genome.isolation_host] = 0
      if count['isolation_source'][genome.isolation_source] > 0
        count['isolation_source'][genome.isolation_source] -= 1
      else count['isolation_source'][genome.isolation_source] = 0
      if count['syndrome'][genome.syndrome] > 0
        count['syndrome'][genome.syndrome] -= 1
      else count['syndrome'][genome.syndrome] = 0
      if count['stx1_subtype'][genome.stx1_subtype] > 0
        count['stx1_subtype'][genome.stx1_subtype] -= 1
      else count['stx1_subtype'][genome.stx1_subtype] = 0
      if count['stx2_subtype'][genome.stx2_subtype] > 0
        count['stx2_subtype'][genome.stx2_subtype] -= 1
      else count['stx2_subtype'][genome.stx2_subtype] = 0

    count

  # FUNC select
  # Calls update function to add newly selected genomes to count object upon selection of a new genome
  #
  # PARAMS
  # Genome object from GenomeController list
  # Boolean indicating if selected/unselected 
  # 
  # RETURNS
  # boolean 
  #       
  select: (genome, isSelected) ->

    # Runs if a group has not been selected or a selection is being made after a group is selected; suppresses double run
    if user_groups_menu.runSelect or !user_groups_menu.groupSelected
      if isSelected
        @selection.push(genome) unless @selection.indexOf(genome) > -1
      else 
        @selection.splice(@selection.indexOf(genome), 1)

      @svgSelection.remove()
      @svgSelection = d3.select('#selection-tab').text(()=>
        if @selection.length is 0
          countText = ''
        if @selection.length is 1
          countText = '1 genome selected'
        if @selection.length > 1
          countText = @selection.length + ' genomes selected'
        countText).append('svg').attr('class', 'summaryPanel').attr('width', @width).attr('height', @height)
      if @selection.length > 0
        @countMeta(@selectionCount, @genomes.genome(genome), isSelected)
        @createMeters(@selectionCount, @svgSelection, @selection)
      else
        d3.select('#selection-tab').select('svg').remove()
        @svgSelection = d3.select('#selection-tab').append('text').text('No genomes selected')

    true

  # FUNC createMeters
  # Creates stacked bar representation of meta-data for summary count object
  #
  # PARAMS
  # summary count object, SVG view, count type array
  # 
  # RETURNS
  # boolean 
  # 
  createMeters: (sumCount, svgView, countType) ->

    if countType?
      totalSelected = countType.length
    else totalSelected = 0

    # Removes old summary meters
    svgView.selectAll('rect.summaryMeter').remove()
    
    # Creates HTML for popover tables
    tt_sub_table = {}
    tt_table_partial = {}
    tt_table = {}
    other_count = {}
    for m in @mtypesDisplayed
      tt_sub_table[m] = new String()
      tt_table_partial[m] = new String()
      tt_table[m] = new String()
      other_count[m] = 0
      i = 0
      while i < @metaOntology[m].length
        if i > 5 && sumCount[m][@metaOntology[m][i]]?
          other_count[m] += sumCount[m][@metaOntology[m][i]]
        tt_mtype = @metaOntology[m][i].charAt(0).toUpperCase() + @metaOntology[m][i].slice(1)
        if sumCount[m][@metaOntology[m][i]] > 0
          # If there is an "Other" case
          if i >= 6
            # Creates sub-table of all meta-data frequencies that are not within the top 6 overall 
            tt_sub_table[m] += ("<tr><td>" + tt_mtype + "</td><td style='text-align:right'>" + sumCount[m][@metaOntology[m][i]] + "</td></tr>")
            # Adds "Other" case to the whole table, including the expand/collapse functionality and the contents of tt_sub_table[m]
            tt_table[m] = tt_table_partial[m] + ("<tbody class='other-row' onclick=\"$('.after-other').slideToggle(100);\"><tr><td>[+] Other</td><td style='text-align:right'\">" + other_count[m] + "</td></tr></tbody><tbody class='after-other'>" + tt_sub_table[m] + "</tbody>")
          else
            # Assembles the rows of the table without the "Other" case
            tt_table_partial[m] += ("<tr><td>" + tt_mtype + "</td><td style='text-align:right'>" + sumCount[m][@metaOntology[m][i]] + "</td></tr>")
            # Copies last row for when there is no "Other" case
            tt_mtype_last = tt_mtype
            # In no "Other" case, copies over table contents into tt_table[m] for use in popovers
            tt_table[m] = tt_table_partial[m]
        i++
    
    # Adds rectangles to the tabbed window section for each type of meta-data summary
    y = 0
    for m in @mtypesDisplayed
      width = []
      i = 0
      j = 0
      x = 0
      y += 40
      if @metaOntology[m].length < 7
        bar_count = @metaOntology[m].length
      else bar_count = 7
      while i < bar_count
        if i < 6 && sumCount[m][@metaOntology[m][i]]?
          width[i] = @width * (sumCount[m][@metaOntology[m][i]] / totalSelected)
        else if i is 6 && totalSelected > 0 && @metaOntology[m][i]?
          width[i] = (@width - (width[0] + width[1] + width[2] + width[3] + width[4] + width[5]))
        else
          width[i] = 0
        length = 0
        pos = 0
        if @metaOntology[m][i]?
          pos = tt_table[m].indexOf(@metaOntology[m][i].charAt(0).toUpperCase() + @metaOntology[m][i].slice(1))
        if sumCount[m][@metaOntology[m][i]] > 0
          length = (@metaOntology[m][i] + "</td><td style='text-align:right'>" + sumCount[m][@metaOntology[m][i]]).length
          tt_data = tt_table[m].slice(0, pos - 8) + "<tr class='table-row-bold' style='color:" + @colours[m][3] + "'><td>" + tt_table[m].slice(pos, length + pos) + "</td></tr>" + tt_table[m].slice(length + pos)
        if i is 6
          if !sumCount[m][@metaOntology[m][5]]?
            if tt_table[m].indexOf("[+] Other")?
              pos = tt_table[m].indexOf("[+] Other")
            else pos = tt_table[m].indexOf(tt_mtype_last)
            tt_data = tt_table[m].slice(0, pos - 8) + "<tr class='table-row-bold' style='color:" + @colours[m][3] + "'><td>" + tt_table[m].slice(pos)
          else
            tt_data = tt_table[m].slice(0, tt_table[m].indexOf("[+] Other") - 8) + "<tr class='table-row-bold' style='color:" + @colours[m][3] + "'><td>" + tt_table[m].slice(tt_table[m].indexOf("[+] Other"))
        svgView.append('rect')
          .attr('class', 'summaryMeter')
          .attr('id',
            if i is 6
              "Other"
            else @metaOntology[m][i])
          .attr('x', x)
          .attr('y', y)
          .attr('height', 25)
          .attr('width', Math.abs(width[i]))
          .attr('stroke', 'black')
          .attr('stroke-width', 1)
          .attr('fill', @colours[m][j++])
          .attr("data-toggle", "popover")
          .attr('data-content',
            "<table class='popover-table'><tr><th style='min-width:160px;max-width:160px;text-align:left'>" + @tt_mtitle[m] + "</th><th style='min-width:110px;max-width:110px;text-align:right'># of Genomes</th></tr>" + tt_data + "</table>")
        x += width[i]
        i++

    # Allows popovers to work in SVG
    svgView.selectAll('.summaryMeter')
      .each(()->
        $(this).popover({
          placement: 'bottom',
          html: 'true',
          trigger: 'hover',
          delay: {show:500, hide:500},
          animate: 'false',
          container: 'body',
          }))

    true


