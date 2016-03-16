package in.ac.iitb.cse.videotag.auth;

public class ConceptInsightsAuth extends ServiceAuthentication {

	private static ConceptInsightsAuth instance = new ConceptInsightsAuth();
	private String corpusName = "vids";

	private ConceptInsightsAuth() {
		// default settings here for local usage, on Bluemix, details will be loaded from VCAP_SERVICES
		super("concept_insights",
				"https://gateway.watsonplatform.net/concept-insights-beta/api",
				"LOCAL_USAGE_USERNAME", "LOCAL_USAGE_PASSWORD", true);
	}

	public static ConceptInsightsAuth getInstance() {
		return instance;
	}

	public String getCorpusName() {
		return corpusName;
	}

}
