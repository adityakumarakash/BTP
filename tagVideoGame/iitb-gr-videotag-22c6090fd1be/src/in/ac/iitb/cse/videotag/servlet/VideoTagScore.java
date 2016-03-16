package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.user.User;
import in.ac.iitb.cse.videotag.video.Video;
import in.ac.iitb.cse.videotag.video.VideoLibrary;

import java.io.IOException;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

@WebServlet("/VideoTagScore")
public class VideoTagScore extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(VideoTagScore.class.getName());

    public VideoTagScore() {
        super();
    }

	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		User user = (User) request.getSession().getAttribute("user");
		if (user == null) {
			logger.severe("Someone tried to access VideoTagScore without logging in!");
			return;
		}

		Video video = VideoLibrary.getInstance().getVideo(request.getParameter("video"));
		String tag = request.getParameter("tag");
		double time = Double.parseDouble(request.getParameter("time"));
		response.getOutputStream().print(video.getTagScore(tag, time, user));
	}

}
