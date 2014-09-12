###


 File: intros_groups_geophy.coffee
 Desc: CoffeeScript for groups/geophy page intros
 Author: Jason Masih jason.masih@phac-aspc.gc.ca
 Date: Sept 9, 2014
 

 Name all files like this intro_[page_name].coffee

 Compiled coffeescript files will be sent to App/Lib/js/. This directory
 contains all Superphy's js files. So this naming scheme will help ensure 
 there are no filename collisions.

 Cakefile has a routine to compile and output the coffeescript files
 in intro/ to js/. To run:

   cake intro

###

# Default in coffescript is to not put any functions into global namespace
# Global namespace, depending on environment, can be referenced by 'exports' or
# 'this' variables
#
# Here we find which one is being used, and assign it to the root variable
root = exports ? this


# FUNC startIntro
# Starts the introJS intro
#
# USAGE startIntro()
# 
# RETURNS
# Boolean
#    
startIntro = ->
  

  opts = viewController.introOptions()
  opts.splice(0,0,{intro: "The GeoPhy page provides users with the opportunity to view genome data simultaneously on a map and on a tree to answer any potential epidimiological questions."})
  opts.splice(1,0,{
    element: document.querySelector('#geophy-control-panel-body')
    intro: "Click 'Highlight Genomes' to isolate your selected genomes on the map and on the tree.  Click 'Reset Views' to reset genome selections, the map, and the tree."
    position: 'bottom'
    })
  opts.splice(4,1,{
    element: document.querySelector('#genome_map1')
    intro: "The genomes corresponding to locations on the map are shown here.  Check the boxes of any genomes you would like to select."
    position: 'right'
    })
  opts.splice(7,1,{
    element: document.querySelector('#genome_tree2')
    intro: "The phylogenetic relationships between the genomes are indicated by this tree.  Click the blue circles to select genomes.  Click the red boxes to select clades.  Pan by clicking and dragging.  Clicking on the '+' and '-' symbols will expand or collapse each clade.  Use the clickwheel on your mouse to zoom."
    position: 'left'
    })
    # Create introJS object
  intro = introJs()


  # Set intros for each element
  # in order they appear
  intro.setOptions(
    {
      steps : opts
    }
  )

  intro.start()

  # Coffeescript will return the value of 
	# the last statement from function
  false

# END FUNC

# Make this function visible in global namespace
# If there isnt a function already called startIntro
unless root.startIntro
  root.startIntro = startIntro

