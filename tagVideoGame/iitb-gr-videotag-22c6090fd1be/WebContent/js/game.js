var statsDisplayed = false;
var gameStarted = false;
var gameEnded = false;
var gameSenses = {};

var player = new MediaElementPlayer('#main-video', {
	features: ['progress','current','duration','volume'],
    success: function (mediaElement, domObject) { 
        mediaElement.addEventListener('playing', function(e) {
        	if (!gameStarted) {
        		gameStarted = true;
        		if (!gameEnded) {
        			$("#tag_input").removeAttr('disabled');
        			$("#tag_input").val('type a tag, and press enter');
        		}
        	}
        }, false);
    },
});

$(document).bind("showInputTag",function(e, sense){
	if (sense in gameSenses)
		return;
	else
		gameSenses[sense] = true;

	var tag_entered = $('#tag_input').val();

	var videoCode;
	$("#main-video").find('source').each(function() {
		videoCode = $(this).attr('data');
	});
	$.post("VideoTagScore", { video: videoCode, time: (player.media.currentTime/player.media.duration), tag: tag_entered })
	.done(function(data) {
		var tag_score = parseInt(data);
		if (tag_score > 0) {
			var total_score = parseInt($('#totalscore').text());
			$('#scrollY').prepend('<div class="entered_tag"><span class="tag">'+tag_entered+'</span>'+'<span class="score"><b>'+'+'+tag_score+'</b></span></div>');
			total_score = total_score + tag_score;
			$('#totalscore').html(total_score);
		} else {
			$('#scrollY').prepend('<div class="entered_tag"><span class="tag">'+tag_entered+'</span>'+'<span class="score zero"><b>&nbsp;'+tag_score+'</b></span></div>');
		}
	})
	.fail(function() {
		alert("Server disconnected!");
	});
});

$('#tag_input').autocomplete({
    serviceUrl: 'AutoComplete',
    minChars: 3,
    deferRequestBy: 100,
    showNoSuggestionNotice: true,
    onSelect: function (suggestion) {
    	$("#tag_input").trigger("showInputTag", [suggestion.data.sense]);
  		$('#tag_input').val('');
  		$('#tag_input').focus();
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

function endGame() {
	$("#submit-score").attr("value", $('#totalscore').text().trim());
	if (statsDisplayed == true) {
		$("#end-game-form").submit();
	} else {
		gameEnded = true;
		var videoCode;
		var total_score = parseInt($('#totalscore').text());
		$("#main-video").find('source').each(function() {
			videoCode = $(this).attr('data');
		});
		$("#tag_input").attr('disabled','disabled');
		$("#tag_input").val('your game has ended');
		$("#end-game-button").attr('disabled','disabled');
		$("#end-game-button").html('<b>Loading stats...</b>');
		$("#end-game-button").removeAttr('title');
		$.post("EndGame", { score: total_score, video: videoCode })
		.done(function(stats) {
			$("#right-title").text('Game Stats:');
			var htmlNoPlayers = '<h4>Number of taggers for this video: <b>' + stats.numPlayers + '</b></h4>';
			var htmlRanks = '';
			if (stats.videoRank != null)
				htmlRanks += '<h4>Your rank for this video: <b>' + stats.videoRank + '</b></h4>';
			if (stats.overallRank != null)
				htmlRanks += '<h4>Your overall rank: <b>' + stats.overallRank + '</b></h4>';
			var htmlScoresLi = '';
			for (var i = 0; i < stats.highScores.length; i++) {
				var highScore = stats.highScores[i];
				if (highScore.current)
					htmlScoresLi += '<li class="my-score">' + highScore.name + ' <b>' + highScore.score + '</b></li>';
				else
					htmlScoresLi += '<li>' + highScore.name + ' <b>' + highScore.score + '</b></li>';
			}
			var htmlHighScores = '<h1>High scores for this video:</h1>\
			    <ol>' + htmlScoresLi + '</ol>';
			if (stats.highScores.length == 0)
				htmlHighScores += '<p style="font-size: 11px;">No one has tagged this video yet!</p>';
			$("#stats-container").html(htmlNoPlayers + htmlRanks + htmlHighScores);
			$("#end-game-button").removeAttr('disabled');
			$("#end-game-button").html('<b>Return to Dashboard</b>');
			statsDisplayed = true;
		})
		.fail(function() {
			alert("Server disconnected!");
		});
	}
}