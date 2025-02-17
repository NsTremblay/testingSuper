// Generated by CoffeeScript 1.8.0

/*


 File: intro_home.coffee
 Desc: CoffeeScript for home page intro
 Author: Jason Masih jason.masih@phac-aspc.gc.ca
 Date: Sept 9, 2014
 

 Name all files like this intro_[page_name].coffee

 Compiled coffeescript files will be sent to App/Lib/js/. This directory
 contains all Superphy's js files. So this naming scheme will help ensure 
 there are no filename collisions.

 Cakefile has a routine to compile and output the coffeescript files
 in intro/ to js/. To run:

   cake intro
 */

(function() {
  var root, startIntro;

  root = typeof exports !== "undefined" && exports !== null ? exports : this;

  startIntro = function() {
    var intro;
    intro = introJs();
    intro.setOptions({
      steps: [
        {
          intro: "Welcome to SuperPhy, a user-friendly, integrated platform for the predictive genomic analyses of <i>Escherichia coli</i>.  The features of SuperPhy are as follows: "
        }, {
          element: document.querySelector("#strains"),
          intro: "Search for information about each genome."
        }, {
          element: document.querySelector("#groups"),
          intro: "Compare and analyze groups of genomes."
        }, {
          element: document.querySelector("#genes"),
          intro: "Check for the presence of specific virulence factors and antimicrobial resistance genes in genomes of interest."
        }, {
          element: document.querySelector("#geophy"),
          intro: "View genome data simultaneously on a map and on a tree."
        }, {
          element: document.querySelector("#genome-uploader"),
          intro: "Upload your own genome data for analysis."
        }
      ]
    });
    intro.start();
    return false;
  };

  if (!root.startIntro) {
    root.startIntro = startIntro;
  }

}).call(this);
