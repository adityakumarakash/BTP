package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.auth.SQLPersistence;
import in.ac.iitb.cse.videotag.user.User;

import java.io.IOException;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class ChangePassword
 */
@WebServlet("/ChangePassword")
public class ChangePassword extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(ChangePassword.class.getName());

    /**
     * @see HttpServlet#HttpServlet()
     */
    public ChangePassword() {
        super();
    }

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		User user = (User) request.getSession().getAttribute("user");
		if (user == null) {
			logger.severe("Someone tried to access ChangePassword without logging in!");
			return;
		}

		String oldPassword = request.getParameter("oldpassword");
		String newPassword = request.getParameter("newpassword");
		if (!user.getPassword().equals(oldPassword)) {
			logger.info("Failed change password attempt for " + user.getUsername());
			response.sendRedirect("profile.jsp?fail=1");
		} else {
			logger.info("Changing password for " + user.getUsername());

			SQLPersistence persistence = SQLPersistence.getInstance();
			Connection con = persistence.getConnection();
			String update = "UPDATE " + persistence.getTableName("USER") + " SET \"password\"='" + newPassword + "' WHERE \"username\"='" + user.getUsername() + "'";
			logger.info("Statement: " + update);
			try {
				Statement statement = con.createStatement();
				int rows = statement.executeUpdate(update);
				statement.close();
				con.commit();
				con.close();

				if (rows == 1) {
					logger.info("Password changed for " + user.getUsername());
					response.sendRedirect("profile.jsp?success=1");
				}
			} catch (SQLException e) {
				logger.severe("Failed to change password for " + user.getUsername());
				e.printStackTrace();
				response.sendRedirect("profile.jsp?fail=1");
			}
		}
	}

}
