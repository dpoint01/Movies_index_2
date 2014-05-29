require 'sinatra'
require 'haml'
require 'pg'
#------------------------HEROKU----------------#
def production_database_config
  db_url_parts = ENV['DATABASE_URL'].split(/\/|:|@/)

  {
    user: db_url_parts[3],
    password: db_url_parts[4],
    host: db_url_parts[5],
    dbname: db_url_parts[7]
  }
end

configure :development do
  set :database_config, { dbname: 'movies' }
end

configure :production do
  set :database_config, production_database_config
end

def connect_db
  begin
    connection = PG.connect(settings.database_config)
    yield(connection)
  ensure
    connection.close
  end
end
#--------------------------------------------------------#
# def connect_db
#   begin
#     connection = PG.connect(dbname: 'movies')
#     yield(connection)
#   ensure
#     connection.close
#   end
# end

get '/actors' do
  @page = params[:page] || 1
  @page = @page.to_i
  @search_actor = params[:query]
  offset = ((@page - 1) * 20)

  if !@search_actor
    query = "SELECT actors.name, actors.id FROM actors ORDER BY actors.name
            LIMIT 20 OFFSET #{offset};"
    @all_actors = connect_db {|conn| conn.exec(query)}.to_a
  end

  if @search_actor
    query = "SELECT actors.name, actors.id FROM actors WHERE actors.name ILIKE $1;"
    @all_actors = connect_db {|conn| conn.exec_params(query, ["%#{@search_actor}%"])}
  end

  haml :'actors/index'
end

get '/actors/:id' do
  actor_id = params[:id]
  query = "SELECT movies.title, actors.id, actors.name, cast_members.character FROM movies
          JOIN cast_members ON movies.id = cast_members.movie_id
          JOIN actors ON cast_members.actor_id = actors.id WHERE actors.id = $1
          ORDER BY movies.title;"
  @actor_roles = connect_db {|conn| conn.exec_params(query, [actor_id])}.to_a

  haml :'actors/show'
end

get '/movies' do

  @search_movie = params[:query]
  @page = params[:page] || 1
  @page = @page.to_i
  offset = ((@page - 1) * 20)

  if !@search_movie
    query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
              JOIN genres ON movies.genre_id = genres.id
              JOIN studios ON movies.studio_id = studios.id
              ORDER BY movies.title
              LIMIT 20 OFFSET #{offset};"

    @all_movies = connect_db {|conn| conn.exec(query)}.to_a
  end

  if @search_movie
    query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
            JOIN genres ON movies.genre_id = genres.id
            JOIN studios ON movies.studio_id = studios.id
            WHERE movies.title ILIKE $1;"

    @all_movies = connect_db {|conn| conn.exec_params(query, ["%#{@search_movie}%"])}.to_a
  end

  haml :'movies/index'
end

get '/movies/best_movies' do

  @page = params[:page] || 1
  @page = @page.to_i
  offset = ((@page - 1) * 20)

  query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
            JOIN genres ON movies.genre_id = genres.id
            JOIN studios ON movies.studio_id = studios.id
            ORDER BY movies.rating DESC
            LIMIT 20 OFFSET #{offset};"
  @all_movies = connect_db {|conn| conn.exec(query)}.to_a

  haml :'movies/best_movies'

end

get '/movies/worst_movies' do

  @page = params[:page] || 1
  @page = @page.to_i
  offset = ((@page - 1) * 20)

  query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
            JOIN genres ON movies.genre_id = genres.id
            JOIN studios ON movies.studio_id = studios.id
            ORDER BY movies.rating
            LIMIT 20 OFFSET #{offset};"
  @all_movies = connect_db {|conn| conn.exec(query)}.to_a

  haml :'movies/worst_movies'
end

get '/movies/newbies' do
  @page = params[:page] || 1
  @page = @page.to_i
  offset = ((@page - 1) * 20)

  query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
            JOIN genres ON movies.genre_id = genres.id
            JOIN studios ON movies.studio_id = studios.id
            ORDER BY movies.year DESC
            LIMIT 20 OFFSET #{offset};"
  @all_movies = connect_db {|conn| conn.exec(query)}.to_a

  haml :'movies/newbies'
end

get '/movies/oldies' do
  @page = params[:page] || 1
  @page = @page.to_i
  offset = ((@page - 1) * 20)

  query = "SELECT movies.title, movies.year, movies.id, movies.rating, genres.name AS genre, studios.name AS studio FROM movies
            JOIN genres ON movies.genre_id = genres.id
            JOIN studios ON movies.studio_id = studios.id
            ORDER BY movies.year
            LIMIT 20 OFFSET #{offset};"
  @all_movies = connect_db {|conn| conn.exec(query)}.to_a


  haml :'movies/newbies'
end

get '/movies/:id' do
  movie_id = params[:id]

  query = "SELECT movies.title, movies.year, movies.id, genres.name AS genre, studios.name AS studio,
          actors.name AS actor, actors.id AS actor_id, cast_members.character FROM movies
            JOIN studios ON movies.studio_id = studios.id
            JOIN genres ON movies.genre_id = genres.id
            JOIN cast_members ON cast_members.movie_id = movies.id
            JOIN actors ON cast_members.actor_id = actors.id WHERE movies.id = $1
            ORDER BY movies.title;"

  @movie_info = connect_db {|conn| conn.exec_params(query, [movie_id])}.to_a

  haml :'movies/show'
end




