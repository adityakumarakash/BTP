package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.user.User;
import in.ac.iitb.cse.videotag.user.UserManager;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class Login
 */
@WebServlet("/Login")
public class Login extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(Login.class.getName());

    /**
     * @see HttpServlet#HttpServlet()
     */
    public Login() {
        super();
    }

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String username = request.getParameter("username");
		String password = request.getParameter("password");
		User user = UserManager.getInstance().getUser(username);
		if (user == null || !user.getPassword().equals(password)) {
			logger.info("Failed login attempt for " + username);
			response.sendRedirect("login.jsp?fail=1");
		} else {
			logger.info("Logging in as " + username);
			request.getSession().setAttribute("user", user);
			response.sendRedirect("dashboard.jsp");
		}
	}

}
