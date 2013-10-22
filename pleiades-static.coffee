begins_with = (input_string, comparison_string) ->
	return input_string.toUpperCase().indexOf(comparison_string.toUpperCase()) == 0

$(document).ready ->
	$.ajax "name_index.json",
		type: 'GET'
		dataType: 'json'
		crossDomain: true
		error: (jqXHR, textStatus, errorThrown) ->
          console.log "AJAX Error: #{textStatus}"
		success: (data) ->
			names = (name[0] for name in data)
			$('#search').autocomplete
				source: (request, response) ->
					matches = names.filter (name) -> begins_with(name, request.term)
					response(matches)
				search: (event, ui) ->
					console.log $('#search').val()
				select: (event, ui) ->
					console.log ui.item.value