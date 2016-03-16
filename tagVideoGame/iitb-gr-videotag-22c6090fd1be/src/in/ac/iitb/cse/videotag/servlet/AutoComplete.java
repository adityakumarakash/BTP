package in.ac.iitb.cse.videotag.servlet;

import in.ac.iitb.cse.videotag.auth.ConceptInsightsAuth;

import java.io.IOException;
import java.io.PrintWriter;
import java.net.URI;
import java.net.URLEncoder;
import java.util.logging.Level;
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
 * Servlet implementation class AutoComplete
 */
@WebServlet("/AutoComplete")
public class AutoComplete extends HttpServlet {
	private static final long serialVersionUID = 1L;

	private static Logger logger = Logger.getLogger(AutoComplete.class.getName());

	private int limit = 6;

    public AutoComplete() {
        super();
    }

	/**
	 * @see HttpServlet#doGet(HttpServletRequest request, HttpServletResponse response)
	 */
	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
		if (request.getSession().getAttribute("user") == null) {
			logger.severe("Someone tried to access AutoComplete without logging in!");
			return;
		}

		ConceptInsightsAuth conceptInsights = ConceptInsightsAuth.getInstance();

		try {
			String query = request.getParameter("query");
			URI graphURI = new URI(
					conceptInsights.getBaseURL() + "/v1/graph/wikipedia/en-20120601?func=labelSearch&label=" + URLEncoder.encode(query, "UTF-8") +
					"&prefix=true&limit=" + limit).normalize();

			Request graphRequest = Request.Get(graphURI).addHeader("Accept", "application/json");
			Response resp = conceptInsights.getExecutor().execute(graphRequest);
			logger.info("Request " + graphURI.toString() + " is made.");

			byte[] content = resp.returnContent().asBytes();
			JSONArray contentJson = JSONArray.parse(new String(content, "UTF-8"));

			JSONObject jsonObject = new JSONObject();
			JSONArray suggestions = new JSONArray();

			for (Object obj : contentJson) {
				JSONObject inputSuggestion = (JSONObject) obj;
				JSONObject outputSuggestion = new JSONObject();
				JSONObject data = new JSONObject();
				data.put("thumbnail", inputSuggestion.get("thumbnail"));
				data.put("abstr", inputSuggestion.get("abstract"));
				data.put("sense", inputSuggestion.get("id"));
				outputSuggestion.put("value", inputSuggestion.get("label"));
				outputSuggestion.put("data", data);
				suggestions.add(outputSuggestion);
			}
			jsonObject.put("suggestions", suggestions);

			response.setContentType("application/json");
			PrintWriter out = response.getWriter();
			out.print(jsonObject);
			out.flush();

		} catch (Exception e) {
			e.printStackTrace();
			logger.log(Level.SEVERE, "Service error: " + e.getMessage(), e);
			response.setStatus(HttpStatus.SC_BAD_GATEWAY);
		}
	}

}
