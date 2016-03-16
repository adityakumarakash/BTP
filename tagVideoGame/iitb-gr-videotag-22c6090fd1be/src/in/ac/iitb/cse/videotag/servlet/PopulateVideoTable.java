package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.user.User;
import in.ac.iitb.cse.videotag.video.TempVideoLibraryLoader;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

/**
 * Servlet implementation class PopulateVideoTable
 */
@WebServlet("/PopulateVideoTable")
public class PopulateVideoTable extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(PopulateVideoTable.class.getName());

    /**
     * @see HttpServlet#HttpServlet()
     */
    public PopulateVideoTable() {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		User user = (User) request.getSession().getAttribute("user");
		if (user == null || user.isAdmin() == false) {
			logger.severe("Someone tried to access PopulateVideoTable without logging in or without admin!");
			return;
		}

		TempVideoLibraryLoader.loadVideosTable();
		response.setContentType("text/plain");
		PrintWriter out = response.getWriter();
		out.print("done");
		out.flush();
	}

}
