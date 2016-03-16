# tagVideo: Watch. Tag. Gain.

**tagVideo** is a place where people can play a game by watching educational videos of varying subjects such as science, math, economics, latest affairs, and so on. Users can search educational videos by topics to watch videos of their interest, or just let the game pick videos for them. tagVideo encourage students to enjoy learning, and not take education as a burden. That, in return, contributes to a lower school dropout rate. Everyone enjoys playing games, and fun provides an incentive to learn. Learning, in return, stimulates curiosity and fuels the desire to learn more. In fact, our users can not only be students and instructors, but anyone with a thirst for knowledge.

tagVideo is also a *Game With A Purpose (GWAP)*, such that we can use the collected tags to better understand videos and how people go about tagging. This data can help provide more effective searches, intuitive navigation, and data for training video classification models. Concepts and expectations evolve with time, and a system can keep track of these changes through the game's tag data as well.

## Demo

For a demo, the system is deployed on Bluemix [here](http://vgame.eu-gb.mybluemix.net/).

## Installation

1. You will need to add the following Bluemix services to your application:
  1. IBM Watson Concept Insights
  2. SQL Database
2. If you wish to get this application running for you, you'll need to do a few things first:
3. Create the appropriate database tables. You can use the provided *tables.sql* file to generate them.
  * Make sure you replace *SCHEMANAME* with your schema name.
4. Populate the *VIDEO* database table with metadata from YouTube videos.
  * Some sample data is provided in *sample_data.csv*
5. Populate a IBM Watson Concept Insights corpus. The default name of your corpus is *vids*.
  * If you want, you can change the name of your corpus in *src/in/ac/iitb/cse/videotag/auth/ConceptInsightsAuth.java* in the *corpusName* field.
  * You can use the *populateWatsonCorpus()* method of *VideoLibrary* to populate the Concept Insights corpus using the video data from your *VIDEO* table.
6. Deploy the application on Bluemix, and enjoy!

## Usage Instructions

* You will be presented with the **login** page
  * If you are a first time user, fill up the signup form. Your username will be public and will be used to maintain your rank and game stats.
  * If you have already registered, just login.
* On login, you can see the **dashboard**. 
  * The ranks of the top 10 players of tagVideo will be displayed on the leaderboard. You can also see your rank. 
  * To be able to play the game you will have to select a video. There are two ways of doing so:
    1. Click on *“Play now!”*. By doing so you will be able to tag a random video.
    2. You can also pick a video from our video picks or of your choice by using the search. Enter keywords of your search query. Wait for an autocomplete drop down to appear. Select a suggestion from the dropdown that matches your search concept. To get more information about a suggestion, hover over it. The suggestion you selected will then appear below the search box and you’ll be presented with a set of videos results for that concept. You can also eliminate an entered concept by clicking on it. The search results with refresh accordingly.
      * Clicking on the title of the video or its thumbnail will allow you to tag that video (the game begins)
      * By clicking on "Watch on YouTube", you can watch the video on YouTube.
  * You can click on your username (upper right) to access your profile, where you can change your password.
* The **gameplay**
  * You’ll have to start playing the video in order to start entering your tags.
  * Watch the video.
    1. As and how you realize what the video is about, and what it covers, tag that topic.
    2. The search box works similar to the one on dashboard. Your entered tags appear below *“Tags entered”* along with the score for that tag. You cannot repeat a tag or enter a synonym for an already-added tag.
    3. You can end the game and submit your scores at any time. You will be presented with the high scorers for that video, and your rank among them, along with your updated overall leaderboard rank.
