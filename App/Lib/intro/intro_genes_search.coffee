###


 File: intro_genes_search.coffee
 Desc: CoffeeScript for genes/search page intros
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
  
  # Create introJS object
  intro = introJs()
  
  
  intro.setOptions(
    {
      steps : [
        {
          intro: "You can use this page to determine whether or not specified virulence factors and antimicrobial resistance genes are present in genomes of interest."
        }
        {
          element: document.querySelector('#genes-menu-affix')
          intro: "You can choose your search method by selecting virulence factors or by antimicrobial resistance genes"
          position: 'bottom'
        }
        {
          element: document.querySelector('#vf-selected-list')
          intro: "Your selected virulence factors will appear here.  Click the blue x next to a factor to remove it."
          position: 'bottom'
        }
        {
          element: document.querySelector('#vf-autocomplete')
          intro: "Use this to filter virulence factors by inputed gene name."
          position: 'bottom'
        }
        {
          element: document.querySelector('#vf-table')
          intro: "Select one or more virulence factors to search for their presence in your specified genomes.  Click the links above to select or unselect all of the virulence factors."
          position: 'right'
        }
        {
          element: document.querySelector("#vf-categories")
          intro: "You can select from these categories to refine the list of genes.  Click the reset button to reset your selections."
          position: 'left'
        }
        {
          element: document.querySelector('#amr-selected-list')
          intro: "Your selected antimicrobial resistance genes will appear here.  Click the blue x next to a factor to remove it."
          position: 'bottom'
        }
        {
          element: document.querySelector('#amr-autocomplete')
          intro: "Use this to filter antimicrobial resistance genes by inputed gene name."
          position: 'bottom'
        }
        {
          element: document.querySelector('#amr-table')
          intro: "Select one or more antimicrobial resistance genes to search for their presence in your specified genomes.  Click the links above to select or unselect all of the antimicrobial resistance genes."
          position: 'right'
        }
        {
          element: document.querySelector("#amr-categories")
          intro: "You can select from these categories to refine the list of genes."
          position: 'left'
        }
        {
          element: document.querySelector('#next-btn')
          intro: "Click here to proceed and select your genomes."
          position: 'right'
        }
      ]
    }
  )

  intro.onbeforechange (targetElement) ->
    switch ($(targetElement).attr("data-step"))
        when "10"
          $('#gene-search-tabs a[href="#gene-search-genomes"]').tab('show')


  intro.start()

  # Coffeescript will return the value of 
	# the last statement from function
  false

# END FUNC

# Make this function visible in global namespace
# If there isnt a function already called startIntro
unless root.startIntro
  root.startIntro = startIntro

