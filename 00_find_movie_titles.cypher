// ================================================
// HELPER: FIND MOVIE TITLES
// ================================================
// Use this to search for movie titles when you don't know the exact spelling
// Useful before using 11_recommendation_system_by_title.cypher
//
// ================================================

// ------------------------------------------------
// 1. SEARCH BY PARTIAL TITLE (CASE-INSENSITIVE)
// ------------------------------------------------
// Finds movies whose title contains a search term

// Set parameter:
// :param searchTerm => "star wars";

MATCH (m:Movie)
WHERE toLower(m.title) CONTAINS toLower($searchTerm)
RETURN m.movieId as movieId, m.title as title, m.genres as genres
ORDER BY m.title
LIMIT 20;


// ------------------------------------------------
// 2. SEARCH BY YEAR
// ------------------------------------------------
// Finds all movies from a specific year
// Note: Year is part of the title string like "Movie Name (1995)"

// Set parameter:
// :param year => "1977";

MATCH (m:Movie)
WHERE m.title CONTAINS ("(" + $year + ")")
RETURN m.movieId as movieId, m.title as title, m.genres as genres
ORDER BY m.title
LIMIT 50;


// ------------------------------------------------
// 3. BROWSE POPULAR MOVIES
// ------------------------------------------------
// Shows most-rated movies (usually the most well-known)

MATCH (m:Movie)<-[r:RATED]-()
WITH m, count(r) as ratingCount
WHERE ratingCount >= 1000
RETURN m.movieId as movieId, m.title as title, m.genres as genres, ratingCount
ORDER BY ratingCount DESC
LIMIT 50;


// ------------------------------------------------
// 4. GET EXACT TITLE BY MOVIE ID
// ------------------------------------------------
// If you know the movie ID but need the exact title for the by_title version

// Set parameter:
// :param movieId => 260;

MATCH (m:Movie {movieId: $movieId})
RETURN m.movieId as movieId, m.title as exactTitle, m.genres as genres;


// ------------------------------------------------
// 5. SEARCH BY GENRE
// ------------------------------------------------
// Finds movies in a specific genre

// Set parameter:
// :param genre => "Sci-Fi";

MATCH (m:Movie)
WHERE $genre IN m.genres
MATCH (m)<-[r:RATED]-()
WITH m, count(r) as ratingCount
WHERE ratingCount >= 100
RETURN m.movieId as movieId, m.title as title, m.genres as genres, ratingCount
ORDER BY ratingCount DESC
LIMIT 30;

