import pandas as pd
movies = pd.read_csv('movies_metadata.csv',low_memory=False)
movies.shape
movies.columns

trimmed_movies = movies[["id", "title", "overview", "release_date", "genres"]]
trimmed_movies.head(5)

unclean_movies_dict = trimmed_movies.to_dict('records')
print(f"{len(unclean_movies_dict)} movies")
movies_dict = []
for movie in unclean_movies_dict:
    if  movie["overview"] == movie["overview"] and movie["release_date"] == movie["release_date"] and movie["genres"] == movie["genres"] and movie["title"] == movie["title"]:
        movies_dict.append(movie)
print('{} movies'.format(len(movies_dict)))

from pymilvus import *

connections.connect("default", host="localhost", port="19530")
print("Connected!")

COLLECTION_NAME = 'film_vectors'
PARTITION_NAME = 'Movie'

id = FieldSchema(name='title', dtype=DataType.VARCHAR, max_length=500, is_primary=True)
field = FieldSchema(name='embedding', dtype=DataType.FLOAT_VECTOR, dim=384)
schema = CollectionSchema(fields=[id, field], description="movie recommender: film vectors", enable_dynamic_field=True)

if utility.has_collection(COLLECTION_NAME):
    collection = Collection(COLLECTION_NAME)
    collection.drop()
collection = Collection(name=COLLECTION_NAME, schema=schema)
print("Collection created")
index_params = {"index_type": "IVF_FLAT", "metric_type":"L2", "params":{"nlist": 128}}
collection.create_index(field_name="embedding", index_params=index_params)
collection.load()
print("Collection indexed!")

from sentence_transformers import SentenceTransformer
import ast

def build_genres(data):
    genres = data['genres']
    genre_list = ""
    entries= ast.literal_eval(genres)
    genres = ""
    for entry in entries:
        genre_list = genre_list + entry["name"] + ", "
    genres += genre_list
    genres = "".join(genres.rsplit(",", 1))
    return genres

transformers = SentenceTransformer('all-MiniLM-L6-v2')

def embed_movie(data):
    embed = "{} Released on {}. Genres are {}".format(data["overview"], data["release_date"], build_genres(data))
    embeddings = transformers.encode(embed)
    return embeddings

j = 0
batch = []
for movie_dict in movies_dict:
    try:
        movie_dict["embedding"] = embed_movie(movie_dict)
        batch.append(movie_dict)
        j += 1
        if j % 5 == 0:
            print("Embedded {} records".format(j))
            collection.insert(batch)
            print("Batch insert completed")
            batch = []
    except Exception as e:
        print("Error inserting record {}".format(e))
        print(batch)
        break
collection.insert(movie_dict)
print("Final batch completed")
print("Finished with {} embeddings".format(j))

collection.load()
topK = 5
SEARCH_PARAM = {
    "metric_type":"L2",
    "params":{"nprobe": 20}
}
def embed_search(search_string):
    search_embeddings = transformers.encode(search_string)
    return search_embeddings
def search_for_movies(search_string):
    user_vector = embed_search(search_string)
    return collection.search([user_vector], "embedding", param=SEARCH_PARAM, limit=topK, expr=None, output_fields=['title', 'overview'])

from pprint import pprint
search_string = "A comedy from the 1990s set in a hospital. The main characters are in their 20s and are trying to stop a vampire."
results = search_for_movies(search_string)
for hits in results:
    for hit in hits:
        print(hit.entity.get('title'))
        print(hit.entity.get('overview'))
        print("-------------------------------")
        