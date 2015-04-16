begins_with = (input_string, comparison_string) ->
	return input_string.toUpperCase().indexOf(comparison_string.toUpperCase()) == 0

geojson_embed = (pleiades_id) ->
	iframe = $('<iframe>')
	iframe.attr('height',210)
	iframe.attr('width','100%')
	iframe.attr('frameborder',0)
	iframe.attr('src',"https://render.githubusercontent.com/view/geojson?url=https://raw.githubusercontent.com/ryanfb/pleiades-geojson/master/geojson/#{pleiades_id}.geojson")
	return iframe

window.pleiades_link = (pleiades_id) ->
	link = $('<a>').attr('href',"http://pleiades.stoa.org/places/#{pleiades_id}")
	link.attr('target','_blank')
	link.text(pleiades_id)
	return link

append_modern_country = (div_id, lat, lng) ->
	$.ajax "http://api.geonames.org/countrySubdivisionJSON?lat=#{lat}&lng=#{lng}&username=ryanfb",
		type: 'GET'
		dataType: 'json'
		crossDomain: 'true'
		error: (jqXHR, textStatus, errorThrown) ->
			console.log "AJAX Error: #{textStatus}"
		success: (data) ->
			if data.countryName
				modern_country = data.countryName
				if data.adminName1
					modern_country += " > " + data.adminName1
				$("##{div_id}").before($('<span>',style:'color:gray;').text(modern_country))
				$("##{div_id}").before($('<br>'))

append_description = (div_id) ->
	(data) ->
		$("##{div_id}").append $('<em>',id:"#{div_id}_description").text(data.description)
		if (_.values(data.features[0])[2].location_precision == 'unlocated')
			$("##{div_id}").addClass('unlocated')
		append_modern_country("#{div_id}_description", data.reprPoint[1], data.reprPoint[0])

populate_results = (results) ->
	$('#results').empty()
	for i in [0..results.length] by 3
		row = $('<div>').attr('class','row')
		for result in results.slice(i,i+3)
			col = $('<div>').attr('class','col-md-4')
			uid = _.uniqueId('results-col-')
			col.attr('id',uid)
			col.append $('<p>').text("#{result[0].join(', ')} - ").append(window.pleiades_link(result[1]))
			col.append geojson_embed(result[1])
			$.ajax "/pleiades-geojson/geojson/#{result[1]}.geojson",
				type: 'GET'
				dataType: 'json'
				crossDomain: true
				error: (jqXHR, textStatus, errorThrown) ->
					console.log "AJAX Error: #{textStatus}"
				success: append_description(uid)
			row.append col
		$('#results').append row
		$('#results').append $('<br>')

search_for = (value, index) ->
	console.log "Searching for #{value}"
	id_url_regex = /(?:https?:\/\/)?(?:pleiades\.stoa\.org\/places\/)?(\d+)\/?/
	if id_url_regex.test(value)
		pleiades_id = value.match(id_url_regex)[1]
		console.log pleiades_id
		name_matches = index.filter (entry) -> pleiades_id in entry[1..-1]
	else
		name_matches = index.filter (entry) -> begins_with(entry[0], value)
	unique_ids = _.uniq(name_matches.map (match) -> match[1])
	matches = ([(name_match[0] for name_match in name_matches when name_match[1] == unique_id), unique_id] for unique_id in unique_ids)
	populate_results(matches.reverse())
	console.log "done searching"

$(document).ready ->
	$.ajax "/pleiades-geojson/name_index.json",
		type: 'GET'
		dataType: 'json'
		crossDomain: true
		error: (jqXHR, textStatus, errorThrown) ->
			console.log "AJAX Error: #{textStatus}"
		success: (data) ->
			names = (name[0] for name in data)
			$('#search').autocomplete
				delay: 600
				minLength: 3
				source: (request, response) ->
					matches = names.filter (name) -> begins_with(name, request.term)
					response(matches.reverse())
				search: (event, ui) ->
					search_for($('#search').val(), data)
				select: (event, ui) ->
					search_for(ui.item.value, data)
