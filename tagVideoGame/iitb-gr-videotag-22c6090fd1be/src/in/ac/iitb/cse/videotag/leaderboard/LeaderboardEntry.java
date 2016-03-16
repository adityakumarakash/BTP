package in.ac.iitb.cse.videotag.leaderboard;

public class LeaderboardEntry implements Comparable<LeaderboardEntry> {
	private String name;
	private int score;

	public LeaderboardEntry(String name, int score) {
		this.name = name;
		this.score = score;
	}

	@Override
	public int compareTo(LeaderboardEntry o) {  
		return o.score - this.score; // always sort leaderboard entries from highest score to lowest 
	}

	public String getName() {
		return name;
	}

	public void setName(String name) {
		this.name = name;
	}

	public int getScore() {
		return score;
	}

	public void setScore(int score) {
		this.score = score;
	}

}
