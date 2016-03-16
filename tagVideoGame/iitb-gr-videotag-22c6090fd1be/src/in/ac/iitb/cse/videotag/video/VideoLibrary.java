package in.ac.iitb.cse.videotag.video;

import in.ac.iitb.cse.videotag.auth.ConceptInsightsAuth;
import in.ac.iitb.cse.videotag.auth.SQLPersistence;

import java.net.URI;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.logging.Level;
import java.util.logging.Logger;

import org.apache.http.HttpResponse;
import org.apache.http.client.fluent.Request;
import org.apache.http.client.fluent.Response;
import org.apache.http.entity.ContentType;

import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;

public class VideoLibrary {
	private static Logger logger = Logger.getLogger(VideoLibrary.class.getName());
	private static VideoLibrary instance = new VideoLibrary();

	private Map<String, Video> videos;
	private Map<String, Integer> videoFrequency;

	private VideoLibrary() {
		this.videos = new HashMap<String, Video>();
		this.videoFrequency = new HashMap<String, Integer>();

		loadVideosFromDatabase();
		loadVideoFrequencyFromDatabase();
		loadTaggersFromDatabase();

		/*if (populateWatsonCorpus())
			logger.severe("All done!");
		else
			logger.severe("Failed!");*/
	}

	public static VideoLibrary getInstance() {
		return instance;
	}

	private void loadVideosFromDatabase() {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = "SELECT \"code\", \"url\", \"thumbnailUrl\", \"title\", \"desc\", \"keywords\", \"maxscoretag\" FROM " + persistence.getTableName("VIDEO");
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			while (rs.next()) {
				String code = rs.getString(1);
				String url = rs.getString(2);
				String thumbnailUrl = rs.getString(3);
				String title = rs.getString(4);
				String desc = rs.getString(5);
				String keywords = rs.getString(6);
				String maxscoretag = rs.getString(7);
				Video video = new Video(code, url, thumbnailUrl, title, desc, keywords, maxscoretag);
				videos.put(video.getCode(), video);
			}
			rs.close();
			statement.close();
			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	private void loadVideoFrequencyFromDatabase() {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = "SELECT \"tag\", COUNT(\"tag\") AS \"freq\" FROM (SELECT \"tag\" FROM " + persistence.getTableName("TAGGER") + " GROUP BY \"tag\", \"code\") GROUP BY \"tag\"";
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			while (rs.next()) {
				String tag = rs.getString(1);
				int freq = rs.getInt(2);
				videoFrequency.put(tag, freq);
			}
			rs.close();
			statement.close();
			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	private void loadTaggersFromDatabase() {
		SQLPersistence persistence = SQLPersistence.getInstance();
		String query = "SELECT \"code\", \"tag\", \"username\" FROM " + persistence.getTableName("TAGGER");
		logger.info("Statement: " + query);
		Connection con = persistence.getConnection();
		try {
			Statement statement = con.createStatement();
			ResultSet rs = statement.executeQuery(query);
			while (rs.next()) {
				String code = rs.getString(1);
				String tag = rs.getString(2);
				String username = rs.getString(3);
				Video video = getVideo(code);
				video.readTag(tag, username);
			}
			rs.close();
			statement.close();
			con.commit();
			con.close();
		} catch (SQLException e) {
			e.printStackTrace();
		}
	}

	public Video getVideo(String code) {
		return videos.get(code);
	}

	public Video getRandomVideo() {
		List<Video> videoCollection = new ArrayList<Video>(videos.values());
		if (videoCollection.isEmpty()) {
			logger.severe("There are no videos in the collection!");
			return null;
		} else {
			return videoCollection.get((new Random()).nextInt(videoCollection.size()));
		}
	}

	public List<Video> getRandomVideos(int n) {
		List<Video> videoCollection = new ArrayList<Video>(videos.values());
		if (videoCollection.isEmpty()) {
			logger.severe("There are no videos in the collection!");
			return null;
		} else {
			Collections.shuffle(videoCollection);
			return videoCollection.subList(0, n);
		}
	}

	public void addTag(String tag) {
		Integer count = videoFrequency.get(tag);
		if (count == null) {
			count = 0;
		}
		videoFrequency.put(tag, count + 1);
	}

	public double getTf(Video video, String tag) {
		int tagFrequency = video.getTagFrequency(tag);
		int totalTags = video.getTotalTags();
		double tf = 0.0;
		if (totalTags > 0 && tagFrequency > 0)
			tf = ((double) tagFrequency) / ((double) totalTags);
		logger.info("TF for " + tag + " for " + video.getCode() + ": " + tf);
		return tf;
	}

	public double getIdf(String tag) {
		double idf = 1.0;
		Integer videoFreq = videoFrequency.get(tag);
		if (videoFreq == null)
			videoFreq = 0;
		if (videos.size() > 0 && videoFreq > 0)
			idf += Math.log(((double) videos.size()) / ((double) videoFreq));
		logger.info("IDF for " + tag + ": " + idf);
		return idf;
	}

	public double getTfIdf(Video video, String tag) {
		return getTf(video, tag) * getIdf(tag);
	}

	private boolean createWatsonCorpusIfNotExisting() {
		ConceptInsightsAuth conceptInsights = ConceptInsightsAuth.getInstance();

		try {
			URI corpusURI = new URI(conceptInsights.getBaseURL() + "/v1/corpus/" + conceptInsights.getUsername() + "/" + conceptInsights.getCorpusName()).normalize();

			Request corpusRequest = Request.Put(corpusURI).bodyString("{\"access\":\"private\"}", ContentType.APPLICATION_JSON);
			Response response = conceptInsights.getExecutor().execute(corpusRequest);
			logger.info("Request " + corpusURI.toString() + " is made.");

			HttpResponse httpResponse = response.returnResponse();
			int statusCode = httpResponse.getStatusLine().getStatusCode();
			if (statusCode == 201 || statusCode == 409) // created or already exists
				return true;
			else
				logger.severe("Status code: " + statusCode);

		} catch (Exception e) {
			e.printStackTrace();
			logger.log(Level.SEVERE, "Service error: " + e.getMessage(), e);
		}

		return false;
	}

	@SuppressWarnings("unchecked")
	public boolean populateWatsonCorpus() {
		if (!createWatsonCorpusIfNotExisting())
			return false;

		int added = 0;
		int startFrom = 0; // how many already added
		ConceptInsightsAuth conceptInsights = ConceptInsightsAuth.getInstance();
		try {
			for (Map.Entry<String, Video> videoEntry : videos.entrySet()) {
				if (added < startFrom) {
					added++;
					continue;
				}
				Video video = videoEntry.getValue();
				URI corpusURI = new URI(
						conceptInsights.getBaseURL() + "/v1/corpus/" + conceptInsights.getUsername() + "/" + conceptInsights.getCorpusName() + "/" + video.getCode()).normalize();

				JSONObject titleJson = new JSONObject();
				JSONObject descriptionJson = new JSONObject();
				JSONObject keywordsJson = new JSONObject();

				Map<String, String> titleMap = new HashMap<String, String>();
				Map<String, String> descriptionMap = new HashMap<String, String>();
				Map<String, String> keywordsMap = new HashMap<String, String>();

				titleMap.put("name", "title"); titleMap.put("data", video.getTitle());
				descriptionMap.put("name", "description"); descriptionMap.put("data", video.getDescription());
				keywordsMap.put("name", "keywords"); keywordsMap.put("data", video.getKeywords());

				titleJson.putAll(titleMap);
				descriptionJson.putAll(descriptionMap);
				keywordsJson.putAll(keywordsMap);

				JSONArray parts = new JSONArray();
				parts.add(titleJson);
				parts.add(descriptionJson);
				parts.add(keywordsJson);

				JSONObject body = new JSONObject();
				body.put("label", video.getTitle());
				body.put("parts", parts);

				Request corpusRequest = Request.Put(corpusURI).bodyString(body.serialize(), ContentType.APPLICATION_JSON);
				Response response = conceptInsights.getExecutor().execute(corpusRequest);
				//logger.info("Request " + corpusURI.toString() + " is made.");

				HttpResponse httpResponse = response.returnResponse();
				int statusCode = httpResponse.getStatusLine().getStatusCode();
				if (statusCode != 201) {
					logger.severe("Status code: " + statusCode);
					logger.severe("Added " + added + " videos.");
					return false;
				} else {
					added++;
				}
				if (added % 100 == 0) {
					logger.warning("Added " + added + " videos");
				}
			}

			return true;

		} catch (Exception e) {
			e.printStackTrace();
			logger.log(Level.SEVERE, "Service error: " + e.getMessage(), e);
		}

		logger.severe("Added " + added + " videos.");
		return false;
	}

}
