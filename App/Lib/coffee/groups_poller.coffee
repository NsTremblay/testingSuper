###
    CLASS Poller
###
class Poller
  constructor: (@jobId, @alertStatusDiv) ->
    throw new SuperphyError 'Job id must be specified in Poller constructor' unless @jobId?
    throw new SuperphyError 'Need to specify status div for Poller constructor' unless @alertStatusDiv?

  # Handles polling the server for update on job status 
  pollJob: () ->
    jQuery.ajax({
      type: 'POST',
      url: '/groups/poll/',
      data: {'job_id' : @jobId}
      }).done( (data) ->
        console.log data
        )
    true
