<!DOCTYPE html>
<%@page import="in.ac.iitb.cse.videotag.user.User"%>
<%
User user = (User) session.getAttribute("user");
if (user == null) {
	response.sendRedirect("login.jsp");
	return;
}
%>
<html>
<head>
<title>tagVideo | Profile</title>
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
				<a href="dashboard.jsp"><img src="images/icon.png" class="img-responsive" alt="" /></a>
			</div>
			<div class="head-greeting">
				<p>Hi! You're logged in as <a href="#" class="head-username"><%= user.getUsername() %></a>. <a href="Logout">Logout?</a>
				</p>
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
							<div class="ban-top" style="padding-bottom: 38px;">
								<div class="col-md-6 bann-left">
									<div class="clearfix"></div>
									<div class="col-md-12">
										<div class="banner-bottom-left-grids">
											<div class="login-left-container">
												<h1>Change password</h1> 
												<p>You can change your password here. <br>
												To go back to the dashboard, click on the <i>tagVideo</i> logo
												on the top.</p>
											</div>
										</div>
									</div>
								</div>
								<div class="col-md-4 bann-right">
<% if (request.getParameter("fail") != null) { %>
									<h4 style="color: red; background-color: #FFFFFF;">Old password was entered incorrectly.</h4>
<% } else if (request.getParameter("success") != null) { %>
									<h4 style="color: green; background-color: #FFFFFF;">Password successfully changed!<br/>
									<a href="dashboard.jsp">Click to return to dashboard.</a></h4>
<% } %>
									<form action="ChangePassword" method="POST">
									<div class = "login-form-registereduser">
										<label for="oldpassword"> Old Password</label> 
										<input id="oldpassword" type="password" name="oldpassword" placeholder="password" required>
										<div class="clearfix"></div>
										<label for="newpassword"> New Password</label> 
										<input id="newpassword" type="password" name="newpassword" placeholder="password" required>
										<div class="clearfix"></div>
										<label for="confirmnewpassword"> Confirm Password</label> 
										<input id="repassword" type="password" name="repassword" placeholder="password" required>
										<div class="clearfix"></div>
										<br/>
										<button id="changepass-button" type="submit" value="Change password" style="text-align:center">Change password</button>
									</div>
									</form>
									<br/>
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
$('#changepass-button').click(function(event) {
	if ($('#newpassword').val() != $('#repassword').val()) {
		alert("New password and Confirm password don't match");
		event.preventDefault();
	}
});
</script>
</body>
</html>
