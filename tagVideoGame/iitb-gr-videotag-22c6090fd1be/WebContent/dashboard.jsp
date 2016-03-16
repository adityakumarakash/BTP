<!DOCTYPE html>
<%@page import="in.ac.iitb.cse.videotag.leaderboard.Leaderboard"%>
<%@page import="in.ac.iitb.cse.videotag.user.User"%>
<%@page import="in.ac.iitb.cse.videotag.video.Video"%>
<%@page import="java.util.List"%>
<%@page import="in.ac.iitb.cse.videotag.video.VideoLibrary"%>
<%@page import="in.ac.iitb.cse.videotag.leaderboard.LeaderboardEntry"%>

<%
User user = (User) session.getAttribute("user");
if (user == null) {
	response.sendRedirect("login.jsp");
	return;
}

List<Video> videos = VideoLibrary.getInstance().getRandomVideos(10);
%>

<html>
<head>
<title>tagVideo | Dashboard</title>
<meta name="viewport" content="width=device-width, initial-scale=1">
<meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
<link rel="shortcut icon" href="favicon.ico" type="image/x-icon" />
<!-- bootstarp-css -->
<link href="css/bootstrap.css" rel="stylesheet" type="text/css" media="all" />
<!--// bootstarp-css -->
<!-- css -->
<link rel="stylesheet" href="css/style.css" type="text/css" media="all" />
<!--// css -->
<!--fonts-->
<link href='http://fonts.googleapis.com/css?family=Open+Sans:300italic,400italic,600italic,700italic,800italic,400,300,600,700,800' rel='stylesheet' type='text/css'>
<!--/fonts-->
</head>

<body>
	<div id="home" class="header">
		<div class="container">
			<!-- container -->
			<div class="head-logo">
				<a href="#"><img src="images/icon.png" class="img-responsive" alt="" /></a>
			</div>
			<div class="head-greeting">
				<p>Hi!
<% if (request.getParameter("signedup") != null) { %>
					<span style="color: rgb(155, 107, 199);">Sign up successful!</span>
<% } %>
					You're logged in as <a href="profile.jsp" class="head-username"><%= user.getUsername() %></a>. <a href="Logout">Logout?</a>
				</p>
			</div>
			<!-- //container -->
			<div class="clearfix"></div>
		</div>
	</div>
	<!-- //header -->	
<div class="container">
	<div class="bg-banner">
		<div class="banner-bottom-bg">
			<div class="col-md-9" style="padding-left: 0;"> 
				<div class="banner-bg ban-top" style="padding-bottom: 1px;">
					<div class="col-md-5" style="float: left;">
						<div class="login-left-container">
							<h3>The game rules are simple.<br>
							<span style = "color: #36C2A2;">Watch</span>. 
							<span style = "color: #F98A5F;">Tag</span>.
							<span style = "color: #2E9EC7;"> Gain</span>.</h3> 
						</div>
						<form action="game.jsp" method="get"  style="margin-top: 30px;">
							<button type="submit" value="Play now!"><h3 style="color: #888899; display: inline;"><b>Play now!</b></h3></button>
						</form>
					</div>
					<div class="col-md-7" style="float: right;">
						<div class="login-left-container">
							<p style="margin-top: 16px;">You can click on <i>Play Now</i> and start tagging a random video. 
								If you wish to browse a video of your choice then use the search box
								to enter concepts to search videos for.
							</p>
							<p>
								Go grab your headphones and pump up the volume!
							</p>
						</div>
					</div>
					<div class="clearfix"></div>
				</div>
				<div class="banner-bottom-grids">
					<!-- banner-bottom-left -->
					<div class="banner-bottom-left">
						
						<!-- post -->
						<div class="post">
							<div class="search">
								<form>
									<input type="text" id="video_search" value="start typing a concept, and select to search" onfocus="this.value = '';" onblur="if (this.value == '') {this.value = 'start typing a concept, and select to search';}" required="">
			 					</form>
							</div>
							<div id="video_tags"></div>
							<div class="clearfix"> </div>
							<hr style="height:1px;border:none;color:#E7E9ff;background-color:#E7E9EA; margin-bottom: 12px; margin-top: 15px;" />
							<h3 id="search-label" style="padding-bottom: 1px;">Our video picks</h3>
							<div class = "post-container">
<%
for (Video videoRandom: videos){
	String trimmedDescription;
	int descLength = 100;
	if (videoRandom.getDescription().length() > descLength) {
		trimmedDescription = videoRandom.getDescription().substring(0, descLength);
		trimmedDescription = (trimmedDescription.substring(0, Math.min(trimmedDescription.length(), trimmedDescription.lastIndexOf(" ")))).concat(" ...");
	} else if (!videoRandom.getDescription().equals("None")) {
		trimmedDescription = videoRandom.getDescription();
	} else {
		trimmedDescription = "No description.";
	}
%>
								<div class="post-grids">
									<div class="col-md-4 post-left">
										<a href="game.jsp?video=<%= videoRandom.getCode() %>"><img src="<%= videoRandom.getThumbnailUrl() %>" alt="" /></a>
									</div>
									<div class="col-md-5 post-right">
										<h4><a href="game.jsp?video=<%= videoRandom.getCode() %>"><%= videoRandom.getTitle() %></a></h4>
										<p class="comments"><a href="<%= videoRandom.getUrl() %>" target="_blank">Watch on YouTube</a></p><p class="text"><%= trimmedDescription %></p>
									</div>
									<div class="clearfix"> </div>
								</div>
<%
}
%>
							</div>
						</div>
						<!-- //post -->
					</div>
				</div>
			</div>
			<div class="banner-bg ban-top col-md-3 leaderboard" style="background-color: #FBFBFB;">
				<h2 style="font-size: 22px; margin-top: 12px; margin-bottom: 12px; color: #A0A500;">Leaderboard</h2>
				<ol>
<%
int total = 0;
for (LeaderboardEntry e : Leaderboard.getInstance().getEntries(null, 20)) {
	if (e.getName().equals(user.getUsername())) {
%>
					<li class="main-leaderboard my-score"><%= e.getName() %> <b><%= e.getScore() %></b></li>
<%
	} else {
%>
					<li class="main-leaderboard"><%= e.getName() %> <b><%= e.getScore() %></b></li>
<%
	}
	if (++total == 10)
		break;
}
%>
				</ol>
<%
if (total == 0) {
%>
				<p>No one has tagged any videos yet!</p>
<%
} else {
	int rank = Leaderboard.getInstance().getUserRank(user, null);
	if (rank > 0) {
%>
				<h2 style="margin-top: 24px; color: #07626E;">Your rank: <span style="color: #FF0F0F;"><%= rank %></span></h2>
<%
	}
}
%>
			</div>
		</div>

		<div class="clearfix"> </div>
		<!-- //bg-banner -->
		<div class="footer-login">
		<!-- container -->
			<div class="footer-grids">
				<div class="clearfix"> </div>
				<div class="copyright">
					<p>Copyright &copy; 2015 IIT Bombay</a></p>
				</div>
			</div>
		</div>
	</div>
</div>
<script src="js/jquery-2.1.4.js"></script>
<script src="js/jquery.autocomplete.js"></script>
<script src="js/dashboard.js"></script>
</body>
</html>