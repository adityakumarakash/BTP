package in.ac.iitb.cse.videotag.user;

import in.ac.iitb.cse.videotag.auth.SQLPersistence;

import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.logging.Logger;

public class UserManager {
	private static Logger logger = Logger.getLogger(UserManager.class.getName());
	private static UserManager instance = new UserManager();

	private UserManager() {
	}

	public static UserManager getInstance() {
		return instance;
	}

	public boolean registerUser(String username, String password) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String update = "INSERT INTO " + persistence.getTableName("USER") + " (\"username\", \"password\") values('" + username + "', '" + password + "')";
		logger.info("Statement: " + update);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			int rows = statement.executeUpdate(update);
			statement.close();
			con.commit();
			con.close();
			if (rows == 1)
				return true;
		} catch (SQLException e) {
			e.printStackTrace();
		}
		return false;
	}

	public User getUser(String username) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = "SELECT \"username\", \"password\", \"admin\" FROM " + persistence.getTableName("USER") + " WHERE \"username\"='" + username + "'";
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			if (!rs.next())
				return null;

			User user = new User(rs.getString("username"), rs.getString("password"), rs.getInt("admin") == 1);

			rs.close();
			statement.close();
			con.commit();
			con.close();
			return user;
		} catch (SQLException e) {
			e.printStackTrace();
			return null;
		}
	}

}
