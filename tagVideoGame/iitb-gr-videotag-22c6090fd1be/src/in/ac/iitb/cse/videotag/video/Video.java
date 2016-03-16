package in.ac.iitb.cse.videotag.video;

import in.ac.iitb.cse.videotag.auth.ConceptInsightsAuth;
import in.ac.iitb.cse.videotag.auth.SQLPersistence;
import in.ac.iitb.cse.videotag.user.User;

import java.net.URI;
import java.net.URLEncoder;
import java.sql.Connection;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Set;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.http.client.fluent.Request;
import org.apache.http.client.fluent.Response;

import com.ibm.json.java.JSONObject;

public class Video {
	private static Logger logger = Logger.getLogger(Video.class.getName());
	private static int gamesHalfWeight = 4;

	private String code;
	private String url;
	private String thumbnailUrl;
	private String title;
	private String description;
	private String keywords;

	private String maxScoreTag;

	private Map<String, Integer> tagFrequency;
	private Map<String, Set<String>> tagTaggers;
	private Set<String> videoTaggers;

	public Video(String code, String url, String thumbnailUrl, String title, String description, String keywords, String maxScoreTag) {
		this.code = code;
		this.url = url;
		this.thumbnailUrl = thumbnailUrl;
		this.title = title;
		this.description = description;
		this.keywords = keywords;

		this.maxScoreTag = maxScoreTag;

		this.tagFrequency = new HashMap<String, Integer>();
		this.tagTaggers = new HashMap<String, Set<String>>();
		this.videoTaggers = new HashSet<String>();
	}

	/**
	 * Only to be called from VideoLibrary to initialize the video state.
	 */
	public void readTag(String tag, String username) {
		Integer freq = tagFrequency.get(tag);
		if (freq == null)
			freq = 0;
		tagFrequency.put(tag, freq + 1);

		Set<String> taggerSet = tagTaggers.get(tag);
		if (taggerSet == null)
			taggerSet = new HashSet<String>();
		taggerSet.add(username);
		tagTaggers.put(tag, taggerSet);

		videoTaggers.add(username);		
	}

	public Set<String> getVideoTaggers() {
		return videoTaggers;
	}

	public String getCode() {
		return code;
	}

	public String getUrl() {
		return url;
	}

	public String getThumbnailUrl() {
		return thumbnailUrl;
	}

	public String getTitle() {
		return title;
	}

	public String getDescription() {
		return description;
	}

	public String getKeywords() {
		return keywords;
	}

	public int getTotalTags() {
		return tagFrequency.size();
	}

	public int getTagFrequency(String tag) {
		Integer count = tagFrequency.get(tag);
		if (count == null)
			count = 0;
		return count;
	}

	public void setMaxScoreTag(String tag) {
		maxScoreTag = tag;

		SQLPersistence persistence = SQLPersistence.getInstance();
		String update = "UPDATE " + persistence.getTableName("VIDEO") + " SET \"maxscoretag\"='" + maxScoreTag + "' WHERE \"code\"='" + getCode() + "'";
		logger.info("Statement: " + update);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			statement.executeUpdate(update);
			statement.close();
			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public String getMaxScoreTag() {
		return maxScoreTag;
	}

	private void addTag(String tag, User user, double time) {
		Integer count = tagFrequency.get(tag);
		Set<String> taggedBy = tagTaggers.get(tag);
		if (count == null) {
			count = 0;
			VideoLibrary.getInstance().addTag(tag);
			taggedBy = new HashSet<String>();
		}
		if (!taggedBy.contains(user.getUsername())) {
			taggedBy.add(user.getUsername());
			tagTaggers.put(tag, taggedBy);
			tagFrequency.put(tag, count + 1);
			videoTaggers.add(user.getUsername());
			addTaggerToDatabase(tag, user.getUsername(), time);
		}
	}

	private void addTaggerToDatabase(String tag, String username, double time) {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String update = "INSERT INTO " + persistence.getTableName("TAGGER") + " (\"code\", \"tag\", \"username\", \"video_time\") values('" + getCode() + "', '" + tag + "', '" + username + "', " + time + ")";
		logger.info("Statement: " + update);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			statement.executeUpdate(update);
			statement.close();
			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public Set<String> getTagTaggers(String tag) {
		return tagTaggers.get(tag);
	}

	private double getWatsonTagScore(String tag) {
		ConceptInsightsAuth conceptInsights = ConceptInsightsAuth.getInstance();
		double score = 0;

		try {
			URI searchableURI = new URI(
					conceptInsights.getBaseURL() + "/v1/searchable/" + conceptInsights.getUsername() + "/" + conceptInsights.getCorpusName() + "/" + this.code +
					"?func=relScore&dest=" + URLEncoder.encode("[\"/graph/wikipedia/en-20120601/" + tag.replaceAll("\\s+", "_") + "\"]", "UTF-8"))
			.normalize();

			Request searchableRequest = Request.Get(searchableURI).addHeader("Accept", "application/json");
			Response resp = conceptInsights.getExecutor().execute(searchableRequest);
			logger.info("Request " + searchableURI.toString() + " is made.");

			byte[] content = resp.returnContent().asBytes();
			JSONObject contentJson = JSONObject.parse(new String(content, "UTF-8"));
			if (!contentJson.containsKey("error")) {
				score = (((double) contentJson.get("score")) * 2.0) - 1.0;
				logger.info("Watson score: " + score);
			} else {
				logger.severe("Could not get score for tag " + tag);
			}

		} catch (Exception e) {
			e.printStackTrace();
			logger.log(Level.SEVERE, "Service error: " + e.getMessage(), e);
		}

		return score * VideoLibrary.getInstance().getIdf(tag);
	}

	private double getTfIdfTagScore(String tag) {
		double tfIdf = VideoLibrary.getInstance().getTfIdf(this, tag);
		if (tfIdf < 0.001)
			return 0;

		if (maxScoreTag == null) {
			setMaxScoreTag(tag);
			tfIdf = 1.0;
		} else {
			double maxTfIdf = VideoLibrary.getInstance().getTfIdf(this, maxScoreTag);
			logger.info("Tag TF-IDF: " + tfIdf + ", Max TF-IDF: " + maxTfIdf);
			if (tfIdf > maxTfIdf) {
				setMaxScoreTag(tag);
				tfIdf = 1.0;
			} else {
				tfIdf /= maxTfIdf;
			}
		}
		return tfIdf;
	}

	public int getTagScore(String tag, double time, User user) {
		// take scores and make them saner. try to get them to be 100 if sufficiently well tagged.
		double tfIdf = getTfIdfTagScore(tag) * 1.28 * 1.25;
		double watsonScore = getWatsonTagScore(tag) * 0.77 * 1.25;
		addTag(tag, user, time);

		logger.info("Tag entered: " + tag + ". TF-IDF: " + tfIdf + ", Watson: " + watsonScore);

		double wWatson = 1.0 / Math.pow(Math.E, ((Math.log(2.0) / ((double) gamesHalfWeight)) * ((double)(videoTaggers.size() - 1))));
		double wTfIdf = 1.0 - wWatson;
		logger.info("NumGames: " + videoTaggers.size() + ", wWatson: " + wWatson + ", wTfIdf: " + wTfIdf);

		double score = (((wTfIdf * tfIdf) + (wWatson * watsonScore)) * 25.0) - 5.0;
		int retScore = ((int) score) * 5;

		if (retScore < 0)
			retScore = 0;
		else if (retScore > 100)
			retScore = 100;
		return retScore;
	}

}
