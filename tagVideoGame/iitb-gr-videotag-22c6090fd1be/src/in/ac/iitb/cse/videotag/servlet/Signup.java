package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.user.UserManager;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class Signup
 */
@WebServlet("/Signup")
public class Signup extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(Signup.class.getName());
 
    /**
     * @see HttpServlet#HttpServlet()
     */
    public Signup() {
        super();
    }

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		String username = request.getParameter("su_username");
		String password = request.getParameter("su_password");
		boolean success = UserManager.getInstance().registerUser(username, password);
		if (!success) {
			logger.info("Failed signup attempt for " + username);
			response.sendRedirect("login.jsp?su_fail=1");
		} else {
			logger.info("Signing up " + username);
			request.getSession().setAttribute("user", UserManager.getInstance().getUser(username));
			response.sendRedirect("dashboard.jsp?signedup=1");
		}
	}

}
