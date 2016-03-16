package in.ac.iitb.cse.videotag.leaderboard;

import in.ac.iitb.cse.videotag.auth.SQLPersistence;
import in.ac.iitb.cse.videotag.user.User;
import in.ac.iitb.cse.videotag.video.Video;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;
import java.util.logging.Logger;

public class Leaderboard {
	private static Logger logger = Logger.getLogger(Leaderboard.class.getName());
	private static Leaderboard instance = new Leaderboard();

	private Leaderboard() {
	}

	public static Leaderboard getInstance() {
		return instance;
	}

	private boolean updateVideoScore(Connection con, User user, Video video, int score, boolean insert) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String update = null;
		if (insert)
			update = "INSERT INTO " + persistence.getTableName("HIGHSCORE") + " (\"code\", \"username\", \"score\") values('" + video.getCode() + "', '" + user.getUsername() + "', " + score + ")";
		else
			update = "UPDATE " + persistence.getTableName("HIGHSCORE") + " SET \"score\"=" + score + " WHERE \"username\"='" + user.getUsername() + "' AND \"code\"='" + video.getCode() + "'";
		logger.info("Statement: " + update);
		try {
			Statement statement = con.createStatement();
			int rows = statement.executeUpdate(update);
			statement.close();
			if (rows == 1)
				return true;
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return false;
	}

	private boolean updateOverallScore(Connection con, User user, int score, boolean insert) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String update = null;
		if (insert)
			update = "INSERT INTO " + persistence.getTableName("LEADERBOARD") + " (\"username\", \"score\") values('" + user.getUsername() + "', " + score + ")";
		else
			update = "UPDATE " + persistence.getTableName("LEADERBOARD") + " SET \"score\"=" + score + " WHERE \"username\"='" + user.getUsername() + "'";
		logger.info("Statement: " + update);
		try {
			Statement statement = con.createStatement();
			int rows = statement.executeUpdate(update);
			statement.close();
			if (rows == 1)
				return true;
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return false;
	}

	public void updateScore(User user, Video video, int score) {
		if (score <= 0)
			return;
		int currentVideoScore = getUserScore(user, video);
		int currentTotalScore = getUserScore(user, null);

		try {
			Connection con = SQLPersistence.getInstance().getConnection();

			if (score > currentVideoScore)
				updateVideoScore(con, user, video, score, currentVideoScore == 0);
			updateOverallScore(con, user, currentTotalScore + score, currentTotalScore == 0);

			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public int getUserScore(User user, Video video) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = null;
		if (video == null)
			query = "SELECT \"score\" FROM " + persistence.getTableName("LEADERBOARD") + " WHERE \"username\"='" + user.getUsername() + "'";
		else
			query = "SELECT \"score\" FROM " + persistence.getTableName("HIGHSCORE") + " WHERE \"username\"='" + user.getUsername() + "' AND \"code\"='" + video.getCode() + "'";
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			int score = 0;
			if (rs.next())
				score = rs.getInt("score");

			rs.close();
			statement.close();
			con.commit();
			con.close();
			return score;
		} catch (SQLException e) {
			e.printStackTrace();
			return 0;
		}
	}

	public int getUserRank(User user, Video video) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = null;
		if (video == null)
			query = "SELECT \"rank\" FROM (SELECT row_number() OVER (ORDER BY \"score\" DESC) AS \"rank\", \"username\" FROM " + persistence.getTableName("LEADERBOARD") + ") WHERE \"username\"='" + user.getUsername() + "'";
		else
			query = "SELECT \"rank\" FROM (SELECT row_number() OVER (ORDER BY \"score\" DESC) AS \"rank\", \"username\" FROM " + persistence.getTableName("HIGHSCORE") + " WHERE \"code\"='" + video.getCode() + "') WHERE \"username\"='" + user.getUsername() + "'";
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			int rank = 0;
			if (rs.next())
				rank = rs.getInt("rank");

			rs.close();
			statement.close();
			con.commit();
			con.close();
			return rank;
		} catch (SQLException e) {
			e.printStackTrace();
			return 0;
		}
	}

	public List<LeaderboardEntry> getEntries(Video video, int maxCount) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = null;
		if (video == null)
			query = "SELECT \"username\", \"score\" FROM " + persistence.getTableName("LEADERBOARD") + " ORDER BY \"score\" DESC FETCH FIRST " + maxCount + " ROWS ONLY";
		else
			query = "SELECT \"username\", \"score\" FROM " + persistence.getTableName("HIGHSCORE") + " WHERE \"code\"='" + video.getCode() + "' ORDER BY \"score\" DESC FETCH FIRST " + maxCount + " ROWS ONLY";
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			List<LeaderboardEntry> entries = new ArrayList<LeaderboardEntry>();
			while (rs.next()) {
				entries.add(new LeaderboardEntry(rs.getString("username"), rs.getInt("score")));
			}

			rs.close();
			statement.close();
			con.commit();
			con.close();
			return entries;
		} catch (SQLException e) {
			e.printStackTrace();
			return null;
		}
	}

}
