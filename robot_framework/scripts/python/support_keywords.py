import json
from playsound import playsound
from sklearn.feature_extraction.text import TfidfVectorizer
from sklearn.metrics.pairwise import cosine_similarity
import nltk
from nltk.corpus import stopwords
from nltk.tokenize import word_tokenize
from nltk.data import find
import os
import string
from robot.api import logger
import news_data
from sklearn.feature_extraction.text import CountVectorizer
from sklearn.naive_bayes import MultinomialNB
from sklearn.pipeline import Pipeline
import joblib
from datetime import datetime

#This downloads NLTK data files
#nltk.download("punkt")
#nltk.download("stopwords")


#This replaces forced downloading. If files exist, they're used. Otherwise they're downloaded.
#This should improve performance and prevent unnecessary connections.
def download_nltk_data():
   resources = ['tokenizers/punkt', 'corpora/stopwords']
   for resource in resources:
      try:
         find(resource)
      except LookupError:
         nltk.download(resource.split("/")[-1])
download_nltk_data()

def preprocess_text(text):
   tokens = word_tokenize(text)

   #This removes punctuation and makes it all lower case
   tokens = [word.lower()
             for word in tokens
             if word.isalnum()]

   #Removes stopwords from the tokens
   stop_words = set(stopwords.words("english"))
   tokens = [
      word for word in tokens
      if word not in stop_words
   ]
   return ' '.join(tokens)

def is_text_related_to_keywords_json(text, keywords_json, threshold=0.1):
   keywords_list = json.loads(keywords_json)
   print(keywords_list)
   return is_text_related_to_keywords(text, keywords_list, threshold)

def truncate_string(text, maxlength):
   maxlength = int(maxlength)
   return text[:maxlength]

def is_text_related_to_keywords(text, keywords, threshold=0.1):
   #text = "Python is a great programming language for data science."
   #keywords = ["problem solving", "Trucks", "programming", "driving", "Taxis", "automobiles"]

   logger.console("Beginning to look for relations")

   processed_text = preprocess_text(text)

   for keyword in keywords:
      processed_keyword = preprocess_text(keyword)
      documents = [processed_text, processed_keyword]

      vectorizer = TfidfVectorizer()
      tfidf_matrix = vectorizer.fit_transform(documents)

      #This calculates similarity in cosine, between the text and the keyword
      similarity = cosine_similarity(tfidf_matrix[0:1], tfidf_matrix[1:2])

      #Check if similarities excees threshold.
      if similarity[0][0] > threshold:
         logger.console("Found similarities.")
         return True

   logger.console("Could not find similarities.")
   return False

def test_relatio_detection():
   text1 = "Python is the best programming language you can use. Yada yada"
   keyword = ["cooking","programming"]
   return is_text_related_to_keywords(text1, keyword)

def train_text_sentiment_model(model_path):
   #News data is imported from news_data.py under the name news_data
   data = news_data.news_data
   news_titles, labels = zip(*data)
   vectorizer = CountVectorizer()
   model = Pipeline([
      ("vectorizer", vectorizer),
      ("classifier",MultinomialNB())
   ])

   model.fit(news_titles, labels)

   #saving the model
   joblib.dump((model, vectorizer, labels), model_path)

   logger.console("Model has been trained and saved at ", model_path)


def load_model(model_path):
   #Loads given model path
   model, vectorizer, labels = joblib.load(model_path)
   print("Model loaded from ", model_path)
   return model, vectorizer, labels

def analyse_text_sentiment(model_path, text):
   model, vectorizer, labels = load_model(model_path)
   preprocessed_text = preprocess_text(text)
   prediction = model.predict([preprocessed_text])[0]
   return prediction


def convert_database_output_to_json(dbstring):
   return json.dumps(dbstring, indent=4)

def string_to_json(string):
   return json.loads(string)

def Json_Length(json):
   return len(json)

def Is_Json_Empty(json):
   return len(json) == 0

def Play_Sound_File(mp3, shouldPlay):
   if (shouldPlay == "True"):
       playsound(mp3)

def convert_timestamp_to_mysql_timestring(timestamp):
   timestamp = float(timestamp)
   timestamp = timestamp//1000
   return datetime.fromtimestamp(timestamp).strftime('%Y-%m-%d %H:%M:%S')
