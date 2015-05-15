#File containing the methodes that are to be tested
require '../App/Lib/coffee/genes_info.coffee'
require '../App/Lib/intro/intro_example.coffee'

#first test, simply seing if the into part works
describe 'Testing introduction function', ->
	it 'Should return true for the firts element', ->
		expect(startIntro()).toEqual true