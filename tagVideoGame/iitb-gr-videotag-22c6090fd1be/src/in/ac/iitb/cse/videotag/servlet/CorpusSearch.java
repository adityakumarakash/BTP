package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.auth.ConceptInsightsAuth;
import in.ac.iitb.cse.videotag.video.Video;
import in.ac.iitb.cse.videotag.video.VideoLibrary;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.URLEncoder;
import java.util.Iterator;
import java.util.logging.Logger;

import javax.servlet.ServletException;
import javax.servlet.annotation.WebServlet;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.apache.http.HttpStatus;
import org.apache.http.client.fluent.Request;
import org.apache.http.client.fluent.Response;

import com.ibm.json.java.JSONArray;
import com.ibm.json.java.JSONObject;

/**
 * Servlet implementation class CorpusSearch
 */
@WebServlet("/CorpusSearch")
public class CorpusSearch extends HttpServlet {
	private static final long serialVersionUID = 1L;
	private static Logger logger = Logger.getLogger(CorpusSearch.class.getName());

	/**
	 * @see HttpServlet#HttpServlet()
	 */
	public CorpusSearch() {
		super();
	}

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	@SuppressWarnings("rawtypes")
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		if (request.getSession().getAttribute("user") == null) {
			logger.severe("Someone tried to access CorpusSearch without logging in!");
			return;
		}

		ConceptInsightsAuth conceptInsights = ConceptInsightsAuth.getInstance();
		try {
			JSONArray conceptIds = new JSONArray();
			String queries = request.getParameter("queries");
			JSONArray tags = JSONArray.parse(queries);

			Iterator iterator = tags.iterator();
			while (iterator.hasNext()) {
				String tag = (String) iterator.next();
				tag = tag.replaceAll("\\s+", "_");
				conceptIds.add("/graph/wikipedia/en-20120601/" + tag);
			}

			URI graphURI = new URI(
					conceptInsights.getBaseURL() + "/v1/searchable/" + conceptInsights.getUsername() + "/" + conceptInsights.getCorpusName() + "?func=semanticSearch&limit=15&ids=" + URLEncoder.encode(conceptIds.serialize(), "UTF-8")).normalize();

			Request graphRequest = Request.Get(graphURI).addHeader("Accept", "application/json");
			Response resp = conceptInsights.getExecutor().execute(graphRequest);

			String content = new String(resp.returnContent().asBytes(), "UTF-8");
			JSONObject jsonObject = new JSONObject();
			JSONArray videos = new JSONArray();

			if (!content.equals("null")) {
				JSONObject contentJsonObj = JSONObject.parse(content);
				JSONArray contentJson = (JSONArray) contentJsonObj.get("results");
				if (contentJson != null) {
					for (Object obj : contentJson) {
						JSONObject inputSuggestion = (JSONObject) obj;
						JSONObject outputVideo = new JSONObject();
						String id = (String) inputSuggestion.get("id");
						Video videoObj = VideoLibrary.getInstance().getVideo(id);
						String title = videoObj.getTitle();
						String description = videoObj.getDescription();
						String thumbnail = videoObj.getThumbnailUrl();
						String videourl = videoObj.getUrl();
						outputVideo.put("id", id);
						outputVideo.put("title", title);
						outputVideo.put("description", description);
						outputVideo.put("thumbnail", thumbnail);
						outputVideo.put("videourl", videourl);
						videos.add(outputVideo);
					}
				}
			}
			jsonObject.put("videos", videos);

			response.setContentType("application/json");
			PrintWriter out = response.getWriter();
			out.print(jsonObject);
			out.flush();
		}catch (Exception e) {
			e.printStackTrace();
			response.setStatus(HttpStatus.SC_BAD_GATEWAY);
		}
	}

}