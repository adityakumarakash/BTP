package in.ac.iitb.cse.videotag.auth;

import java.io.IOException;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.http.client.fluent.Executor;

import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;

public abstract class ServiceAuthentication {

	private static Logger logger = Logger.getLogger(ServiceAuthentication.class.getName());

	private String serviceName;
	private String baseURL;
	private String username;
	private String password;
	private Executor executor;

	public ServiceAuthentication(String serviceName, String baseURL, String username, String password, boolean processVcap) {
		this.serviceName = serviceName;
		this.baseURL = baseURL;
		this.username = username;
		this.password = password;

		if (processVcap)
			processVCAPServices();

		this.executor = Executor.newInstance().auth(username, password);
	}

	/**
	 * If exists, process the VCAP_SERVICES environment variable in order to get
	 * the username, password and baseURL
	 */
	private void processVCAPServices() {
		logger.info("Processing VCAP_SERVICES");
		JSONObject sysEnv = getVCAPServices();
		if (sysEnv == null)
			return;
		logger.info("Looking for: " + serviceName);

		for (Object key : sysEnv.keySet()) {
			String keyString = (String) key;
			logger.info("found key: " + key);
			if (keyString.startsWith(serviceName)) {
				JSONArray services = (JSONArray) sysEnv.get(key);
				JSONObject service = (JSONObject) services.get(0);
				JSONObject credentials = (JSONObject) service
						.get("credentials");
				baseURL = (String) credentials.get("url");
				username = (String) credentials.get("username");
				password = (String) credentials.get("password");
				logger.info("baseURL  = " + baseURL);
				logger.info("username = " + username);
				logger.info("password = " + password);
			} else {
				logger.info("Doesn't match /^" + serviceName + "/");
			}
		}
	}

	/**
	 * Gets the <b>VCAP_SERVICES</b> environment variable and return it as a
	 * JSONObject.
	 * 
	 * @return the VCAP_SERVICES as Json
	 */
	private JSONObject getVCAPServices() {
		String envServices = System.getenv("VCAP_SERVICES");
		if (envServices == null)
			return null;
		JSONObject sysEnv = null;
		try {
			sysEnv = JSONObject.parse(envServices);
		} catch (IOException e) {
			// Do nothing, fall through to defaults
			logger.log(Level.SEVERE,
					"Error parsing VCAP_SERVICES: " + e.getMessage(), e);
		}
		return sysEnv;
	}

	public String getServiceName() {
		return serviceName;
	}

	public String getBaseURL() {
		return baseURL;
	}

	public String getUsername() {
		return username;
	}

	public String getPassword() {
		return password;
	}

	public Executor getExecutor() {
		return executor;
	}

}
