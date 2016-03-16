package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.leaderboard.Leaderboard;
import in.ac.iitb.cse.videotag.leaderboard.LeaderboardEntry;
import in.ac.iitb.cse.videotag.user.User;
import in.ac.iitb.cse.videotag.video.Video;
import in.ac.iitb.cse.videotag.video.VideoLibrary;

import java.io.IOException;
import java.io.PrintWriter;
import java.util.List;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;

/**
 * Servlet implementation class EndGame
 */
@WebServlet("/EndGame")
public class EndGame extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(EndGame.class.getName());

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public EndGame() {
		super();
	}

	/**
	 * @see HttpServlet#doPost(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		int score = Integer.parseInt(request.getParameter("score"));
		Video video = VideoLibrary.getInstance().getVideo(request.getParameter("video"));
		User user = (User) request.getSession().getAttribute("user");

		logger.info("Submitted score: " + score);
		Leaderboard.getInstance().updateScore(user, video, score);

		JSONObject returnObject = new JSONObject();
		JSONArray highScores = new JSONArray();
		List<LeaderboardEntry> entries = Leaderboard.getInstance().getEntries(video, 10);
		for (LeaderboardEntry e : entries) {
			JSONObject entry = new JSONObject();
			entry.put("name", e.getName());
			entry.put("score", e.getScore());
			entry.put("current", e.getName().equals(user.getUsername()));
			highScores.add(entry);
			if (highScores.size() == 10)
				break;
		}
		returnObject.put("highScores", highScores);
		returnObject.put("numPlayers", video.getVideoTaggers().size());

		int videoRank = Leaderboard.getInstance().getUserRank(user, video);
		if (videoRank > 0)
			returnObject.put("videoRank", videoRank);
		int overallRank = Leaderboard.getInstance().getUserRank(user, null);
		if (overallRank > 0)
			returnObject.put("overallRank", overallRank);

		response.setContentType("application/json");
		PrintWriter out = response.getWriter();
		out.print(returnObject);
		out.flush();
	}

}
