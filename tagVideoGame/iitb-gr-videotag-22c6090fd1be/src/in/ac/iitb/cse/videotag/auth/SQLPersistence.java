package in.ac.iitb.cse.videotag.auth;

import java.sql.Connection;
import java.sql.SQLException;
import java.util.Set;
import java.util.logging.Logger;

import com.ibm.db2.jcc.DB2SimpleDataSource;
import com.ibm.nosql.json.api.BasicDBList;
import com.ibm.nosql.json.api.BasicDBObject;
import com.ibm.nosql.json.util.JSON;

public class SQLPersistence {
	private static Logger logger = Logger.getLogger(SQLPersistence.class.getName());
	private static SQLPersistence instance = new SQLPersistence();

	// set defaults to be used when testing from local. On Bluemix, load from VCAP_SERVICES.
	private String databaseHost = "5.10.125.192";
	private int port = 50000;
	private String databaseName = "SQLDB";
	private String user = "LOCAL_USAGE_USERNAME";
	private String password = "LOCAL_USAGE_PASSWORD";
	private String url = "jdbc:db2://5.10.125.192:50000/SQLDB";

	private SQLPersistence() {
		processVCAP();
	}

	private boolean processVCAP() {
		// VCAP_SERVICES is a system environment variable
		// Parse it to obtain the for DB2 connection info
		String VCAP_SERVICES = System.getenv("VCAP_SERVICES");
		logger.info("VCAP_SERVICES content: " + VCAP_SERVICES);

		if (VCAP_SERVICES != null) {
			// parse the VCAP JSON structure
			BasicDBObject obj = (BasicDBObject) JSON.parse(VCAP_SERVICES);
			String thekey = null;
			Set<String> keys = obj.keySet();
			logger.info("Searching through VCAP keys");
			// Look for the VCAP key that holds the SQLDB information
			for (String eachkey : keys) {
				logger.info("Key is: " + eachkey);
				// Just in case the service name gets changed to lower case in the future, use toUpperCase
				if (eachkey.toUpperCase().contains("SQLDB")) {
					thekey = eachkey;
				}
			}
			if (thekey == null) {
				logger.info("Cannot find any SQLDB service in the VCAP; exiting");
				return false;
			}
			BasicDBList list = (BasicDBList) obj.get(thekey);
			obj = (BasicDBObject) list.get("0");
			logger.info("Service found: " + obj.get("name"));
			// parse all the credentials from the vcap env variable
			obj = (BasicDBObject) obj.get("credentials");
			databaseHost = (String) obj.get("host");
			databaseName = (String) obj.get("db");
			port = (int)obj.get("port");
			user = (String) obj.get("username");
			password = (String) obj.get("password");
			url = (String) obj.get("jdbcurl");
		} else {
			logger.info("VCAP_SERVICES is null");
			return false;
		}
		logger.info("database host: " + databaseHost);
		logger.info("database port: " + port);
		logger.info("database name: " + databaseName);
		logger.info("username: " + user);
		logger.info("password: " + password);
		logger.info("url: " + url);
		return true;
	}

	public static SQLPersistence getInstance() {
		return instance;
	}

	public Connection getConnection() {
		Connection con = null;
		try {
			logger.info("Connecting to the database");
			DB2SimpleDataSource dataSource = new DB2SimpleDataSource();
			dataSource.setServerName(databaseHost);
			dataSource.setPortNumber(port);
			dataSource.setDatabaseName(databaseName);
			dataSource.setUser(user);
			dataSource.setPassword(password);
			dataSource.setDriverType(4);
			con = dataSource.getConnection();
			con.setAutoCommit(false);
		} catch (SQLException e) {
			logger.severe("Error connecting to database");
			logger.severe("SQL Exception: " + e);
		}
		return con;
	}

	public String getTableName(String table) {
		return user + "." + table;
	}

}
