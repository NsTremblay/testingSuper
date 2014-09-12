###


 File: intro_strains_search.coffee
 Desc: CoffeeScript for strains/search page intros
 Author: Jason Masih jason.masih@phac-aspc.gc.ca
 Date: Sept 5, 2014
 

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
  opts.splice(0,0,{intro: "You can use this page to search for information about the genomes in the database."})
  opts.splice(1,0,{
      element: document.querySelector('#genomes-menu-affix')
      intro: "You can perform a search in three different ways: using the genome list, phylogenetic tree, or map."
      position: 'bottom'
      })
  opts.splice(3,0,{
      element: document.querySelector('.fa-search')
      intro: "Click the magnifying glass to get a detailed overview of each genome."
      position: 'right'
      })
  opts.splice(13,0,{
      element: document.querySelector('.fa-search')
      intro: "Click the magnifying glass to get a detailed overview of each genome."
      position: 'right'
      })

  # Create introJS object
  intro = introJs()


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

