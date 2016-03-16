<!DOCTYPE html>
<%@page import="in.ac.iitb.cse.videotag.user.User"%>
<%
if (session.getAttribute("user") != null) {
	response.sendRedirect("dashboard.jsp");
	return;
}
%>
<html>
<head>
<title>tagVideo | Login</title>
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
				<img src="images/icon.png" class="img-responsive" alt="" />
			</div>
			<!-- //container -->
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
							<div class="ban-top" style="padding-bottom: 38px;">
								<div class="col-md-6 bann-left">
									<div class="clearfix"></div>
									<div class="col-md-12">
										<div class="banner-bottom-left-grids">
											<div class="login-left-container">
												<h1> Welcome to tagVideo</h1> 
												<p>tagVideo is a game that lets you tag interesting educational videos. You can also view these
													videos on YouTube to gain knowledge.</p><p>
													To be able to play the game you will have to register yourself with us. 
													To do so please fill out a small sign up form. If you have already signed up then login.<br/>
													Your sign up helps us maintain your rank on the leaderboard and stats for different videos,
													as per the public username you'll pick.</p><p>
													Put your thinking cap on and lets go for a tagging ride!</p>
											</div>
										</div>
									</div>
								</div>
								<div class="col-md-4 bann-right">
<% if (request.getParameter("fail") != null) { %>
									<h4 style="color: red; background-color: #FFFFFF;">Incorrect username or password.</h4>
<% } %>
									<h2>Registered user login:</h2>
									<form action="Login" method="POST">
									<div class = "login-form-registereduser">
										<label for="username">Public username</label>
										<input type="text" name="username" placeholder="sarah" required><br/>
										<label for="password">Password</label> 
										<input type="password" name="password" placeholder="password" required>
										<div class="clearfix"></div>
										<br/>
										<button type="submit" value="Login" style="text-align:center">Login</button>
									</div>
									</form>
									<br/>
									<h3>------OR------</h3>
<% if (request.getParameter("su_fail") != null) { %>
									<h4 style="color: red; background-color: #FFFFFF;">The username is already taken.</h4>
<% } %>
									<h2>Sign Up:</h2>
									<form action="Signup" method="POST" id="signup-form">
									<div class = "login-form-registereduser">
										<label for="su_username">Public username</label>  
										<input type="text" name="su_username" placeholder="sarah" required><br/>
										<label for="password">Password</label>  
										<input id="su_password" type="password" name="su_password" placeholder="password" required><br/>
										<label for="repassword">Confirm Password</label>  
										<input id="su_repassword" type="password" placeholder="password" required>
										<div class="clearfix"></div>
										<br/>
										<button id="signup-button" type="submit" value="Sign Up" style="text-align:center">Sign Up</button>
										</div>
									</form>
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
<script>
$('#signup-button').click(function(event) {
	if ($('#su_password').val() != $('#su_repassword').val()) {
		alert("Password and Confirm Password don't match");
		event.preventDefault();
	}
});
</script>
</body>
</html>
