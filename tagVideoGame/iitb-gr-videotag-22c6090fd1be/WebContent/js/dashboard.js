var searchSenses = {};
var tagSenses = {};
var videosClone = $('.post-container').clone();
var ourPicks = true;

$(document).bind("showInputTag",function(e, sense){
	if (sense in searchSenses)
		return;
	else
		searchSenses[sense] = true;

	var tag_entered = $('#video_search').val();
	tagSenses[tag_entered] = sense;

	$('#video_tags').append('<div class="video_tag">'+tag_entered+'</div>');
	$(document).trigger("displayVideos");
});

$('#video_tags').on('click', '.video_tag', function(e) {
	var tag_entered = $(this).text();
	delete searchSenses[tagSenses[tag_entered]];
	delete tagSenses[tag_entered];
	$(this).remove();
	$(document).trigger("displayVideos");
});

$('#video_search').autocomplete({
    serviceUrl: 'AutoComplete',
    minChars: 3,
    deferRequestBy: 100,
    showNoSuggestionNotice: true,
    onSelect: function (suggestion) {
    	$("#video_search").trigger("showInputTag", [suggestion.data.sense]);
  		$('#video_search').val('');
  		$('#video_search').focus();
    },
    formatResult: function (suggestion, currentValue) {
        var htmlSafeString = suggestion.value.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        var pattern = '(' + $.Autocomplete.utils.escapeRegExChars(currentValue) + ')';
        var thumbnail = suggestion.data.thumbnail;
        var abstr = suggestion.data.abstr;

        htmlSafeString = htmlSafeString.replace(new RegExp(pattern, 'gi'), '<strong>$1<\/strong>');

        if (abstr == null) abstr = "No information available.";
        if (thumbnail != null) {
        	thumbnail = thumbnail.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
        	htmlSafeString = '<div title="' + abstr + '" class="suggestion-thumbnail" style="background-image: url(' + thumbnail + ')">' + htmlSafeString + '<\/div>';
        } else {
        	htmlSafeString = '<div title="' + abstr + '" class="suggestion-thumbnail">' + htmlSafeString + '<\/div>';
        }
        return htmlSafeString;
    }
});

$(document).bind("displayVideos",function(e){
	if (!jQuery.isEmptyObject(searchSenses)) {
		ourPicks = false;
		$("#search-label").text('Searching ...');
		$.get("CorpusSearch?queries="+encodeURI(JSON.stringify(Object.keys(searchSenses))))
		.done(function(data) {
			if (ourPicks)
				return;
			$("#search-label").text('Search results');
			$('.post-container').empty();
			videos = data.videos;
			if (videos.length > 0){
				for (var i = 0; i < videos.length; i++) {
					video = videos[i];
					var descLength = 100;
					if (video.description.length > descLength) {
						var trimmedDescription = video.description.substr(0, descLength);
						trimmedDescription = trimmedDescription.substr(0, Math.min(trimmedDescription.length, trimmedDescription.lastIndexOf(" "))) + ' ...';
					} else if (video.description == "None"){
						trimmedDescription = "No description.";
					} else {
						trimmedDescription = video.description;
					}
					$('.post-container').append('<div class="post-grids"><div class="col-md-4 post-left"><a href="game.jsp?video=' + video.id + '" "target="_blank"><img src="'+video.thumbnail+'" alt="" /></a></div><div class="col-md-5 post-right"><h4><a href="game.jsp?video=' + video.id + '">'+video.title+'</a></h4><p class="comments"><a href="'+video.videourl+'" target="_blank">Watch on YouTube</a></p><p class="text">'+trimmedDescription+'</p></div><div class="clearfix"> </div></div>');
				}
			} else {
				$('.post-container').html('<div class="post-grids"><div class="col-md-12 post-left"><h4 style = "color: #cc0000;">Oops! No results found.</h4></div><div class="clearfix"> </div></div>');
			}
		})
		.fail(function() {
			$("#search-label").text('Our video picks');
			alert("Server disconnected!");
		});
	} else {
		ourPicks = true;
		$("#search-label").text('Our video picks');
		$('.post-container').empty();
		$('.post-container').replaceWith(videosClone);
		videosClone = $('.post-container').clone();
	}
});
