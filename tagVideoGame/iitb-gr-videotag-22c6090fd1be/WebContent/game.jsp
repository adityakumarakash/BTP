<!DOCTYPE html>
<%@page import="in.ac.iitb.cse.videotag.user.User"%>
<%@page import="in.ac.iitb.cse.videotag.video.Video"%>
<%@page import="in.ac.iitb.cse.videotag.video.VideoLibrary"%>

<%
User user = (User) session.getAttribute("user");
if (user == null) {
	response.sendRedirect("login.jsp");
	return;
}
%>

<html>
<head>
<title>tagVideo | Game</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<!-- bootstarp-css -->
<link href="css/bootstrap.css" rel="stylesheet" type="text/css" media="all" />
<!--// bootstarp-css -->
<!-- css -->
<link rel="stylesheet" href="css/style.css" type="text/css" media="all" />
<link rel="stylesheet" href="mediaelement/mediaelementplayer.css" />
<!--// css -->
<!--fonts-->
<link href='http://fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
<!--/fonts-->
</head>

<%
String videoCode = request.getParameter("video");
Video video = null;
if (videoCode == null) {
	video = VideoLibrary.getInstance().getRandomVideo();
} else {
	video = VideoLibrary.getInstance().getVideo(videoCode);
	if (video == null) {
		response.sendRedirect("game.jsp"); // without parameters
		return;
	}
}
%>

<body>
	<div id="home" class="header">
		<div class="container">
			<!-- container -->
			<div class="head-logo">
				<a href="dashboard.jsp"><img src="images/icon.png" class="img-responsive" alt="" /></a>
			</div>
			<div class="head-greeting">
				<p>Hi! You're playing as <a href="profile.jsp" class="head-username"><%= user.getUsername() %></a>.</p>
			</div>
			<!-- //container -->
			<div class="clearfix"></div>
		</div>
	<!-- //header -->
<div class="container">
	<div class="bg-banner">
		<div class="banner-bottom-bg">
			<div class="banner-bg"> 
					<!-- banner -->
					<div class="banner">
						<div class="banner-grids">
							<div class="banner-top">
							</div>
							<div class="ban-top">
								<div class="col-md-6 bann-left">
									<div class="video-wrapper">
									    <video id="main-video" width="240" height="135" style="width: 100%; height: 100%; z-index: 4001;">
										    <source src="<%= video.getUrl() %>" data="<%= video.getCode() %>"
         										type='video/youtube'>
										    <p>Browser doesn't support the video.</p>
									    </video>
									</div>
									<div class="clearfix"></div>
									<div class="col-md-12">
										<div class="banner-bottom-left-grids">
											<div class="search">
												<input type="text" id="tag_input" value="play the video to start" disabled='disabled' onfocus="this.value = '';" onblur="if (this.value == '') {this.value = 'type a tag, and press enter';}" required="">
											</div>
										</div>
									</div>
								</div>
								<div class="col-md-6 bann-right">
								 	<h2 style="float: left;">Total Score: <span id = "totalscore"><b>0</b></span></h2>
								 	<form action="dashboard.jsp" method="GET" id="end-game-form">
								 	<button id="end-game-button" title="End the game and submit your score." type="button" style="float: right;" onclick="endGame()"><b>End Game</b></button>
								 	</form>
									<h2 id="right-title" style="clear: both;">Tags Entered:</h2>
									<div id="stats-container" class="leaderboard">
										<div id = "wrapper">
											<div id="scrollY">	
											</div>
										</div>
									</div>
								</div>
								<div class="clearfix"> </div>
							</div>
						</div>
					</div>
					<!-- //banner -->
				</div>
			</div>
		</div>
		<div class="clearfix"> </div>
		<!-- //bg-banner -->
		<div class="footer">
		<!-- container -->
			<div class="footer-grids">
				<div class="viewport">
					<h3>How to play tagVideo?</h3>
					<p>The game begins when you start playing your video. You can then play/pause the video at any time during gameplay.
						As you watch the video you'll have to keep assigning tags <i>relevant</i> to the video.
						Use the input box to enter your tags.
						On typing the first few characters of the tag a set of suggestions relevant to the tag you are
						entering will be presented through an autocomplete dropdown.
						To select a suggestion click on it.
						You can submit tags that appear in this dropdown only.
					<span>The tags you entered appear under <i>Tags Entered</i> along with the score for it.
					You will be scored based on how accurate your tag is for resembling the given video. 
					Keep in mind tags should describe what the video is about more than what you see. Synonyms of
					already added tags will not be accepted.</span>
					<span>To end the game and submit your score at any point, click on <i>End Game</i>. You will
					then see the highest scorers and your rank for this video!
					<span>You are quite ready now, go hunt down the best tags and top the leaderboard. Have fun!</span>
					</p>
				</div>
				<div class="clearfix"> </div>
				<div class="copyright">
					<p>Copyright &copy; 2015 IIT Bombay</p>
				</div>
			</div>
		</div>
	</div>
</div>
<script src="js/jquery-2.1.4.js"></script>
<script src="mediaelement/mediaelement-and-player.js"></script>
<script src="js/jquery.autocomplete.js"></script>
<script src="js/game.js"></script>
</body>
</html>