# MovieLens Recommendation System

**Authors:** Giovanni Contento, Giulio Delicato  
**Date:** 12/11/2025

A collaborative filtering-based recommendation system implemented in Neo4j using graph database technology to generate personalized movie suggestions.

## 📋 Project Overview

This project explores how graph databases can efficiently model and analyze relationships between users and movies to generate personalized recommendations. The system uses a movie ratings dataset where:

- **User nodes**: Represent individual users (`:User {userId}`)
- **Movie nodes**: Represent movies (`:Movie {movieId, title, genres}`)
- **RATED relationships**: Connect users to movies with ratings (`:RATED {rating}`)

## ✨ Features

### 1. User-Based Collaborative Filtering
- Finds users with similar rating patterns using Pearson correlation
- Predicts ratings based on what similar users rated
- Requires at least 3 common movies and similarity > 0.3

### 2. Item-Based Collaborative Filtering
- Finds movies with similar rating patterns
- Predicts ratings based on the user's ratings of similar movies
- Requires at least 3 common raters and similarity > 0.3

### 3. Fallback Mechanisms
When collaborative filtering cannot make a prediction:
- **Movie average**: Uses the average rating for that movie
- **Global average**: Uses the overall average rating across all movies

### 4. Title-Based Interface
- Intuitive movie search by title instead of ID
- Helper script to find movies by partial title, year, or genre
- Maintains same prediction accuracy as ID-based system

## 📁 File Structure

### Setup and Import Scripts
- `01_setup.cypher` - Database initialization
- `02_import_movies.cypher` - Import movie data
- `03_import_links.cypher` - Import external links
- `04_import_genome_tags.cypher` - Import genome tags
- `05_import_genome_scores.cypher` - Import genome scores
- `06_import_users.cypher` - Import user data
- `07_import_ratings.cypher` - Import rating data
- `08_import_tags.cypher` - Import user tags

### Analysis Scripts
- `09_verification.cypher` - Data integrity verification
- `10_analysis.cypher` - Exploratory data analysis and statistics

### Recommendation System
- `11_recommendation_system.cypher` - Core recommendation engine (ID-based)
- `11_recommendation_system_by_title.cypher` - User-friendly title-based interface
- `00_find_movie_titles.cypher` - Helper for searching movies by title

### Evaluation
- `12_evaluation.cypher` - System performance evaluation (MAE, RMSE, Coverage)

## 🚀 Getting Started

### Dataset Setup

This repository includes some dataset files in the `data/` folder:
- ✅ `genome_tags.csv` (20KB)
- ✅ `link.csv` (527KB)
- ✅ `movie.csv` (1.5MB)

**Large files not included** (due to GitHub size limits):
- ❌ `rating.csv` (659MB)
- ❌ `genome_scores.csv` (205MB)
- ❌ `tag.csv` (21MB)

**To download missing files:**
1. Visit [MovieLens Latest Datasets](https://grouplens.org/datasets/movielens/latest/)
2. Download the **MovieLens Latest Dataset (Small or Full)**
3. Extract and copy `rating.csv`, `genome_scores.csv`, and `tag.csv` to the `data/` folder

### Prerequisites
- Neo4j Community Edition (2025.10.1 or later)
- Neo4j for VS Code extension (for interactive use)

### Connection Details
- **URL**: `bolt://localhost:7687`
- **Username**: `neo4j`
- **Password**: `radar-salami-happy-appear-grand-6593`

### Running Queries in VS Code

1. Install the Neo4j for VS Code extension
2. Connect to your Neo4j instance
3. Open any `.cypher` file
4. Set parameters:
```cypher
:param userId => 100;
:param movieId => 260;
```
5. Select and run the desired query

### Running from Terminal

```bash
export NEO4J_PASSWORD="radar-salami-happy-appear-grand-6593"

# Run a complete file
/path/to/neo4j/bin/cypher-shell -u neo4j -p "$NEO4J_PASSWORD" \
  -f /path/to/script.cypher
```

## 💡 Usage Examples

### Example 1: Get Rating Prediction (by Movie ID)

```cypher
:param userId => 100;
:param movieId => 260;
```

**Result:** User-based prediction: 4.33/5.0 (based on 51 similar users)

### Example 2: Get Rating Prediction (by Title)

```cypher
:param userId => 100;
:param movieTitle => "Star Wars: Episode IV";
```

**Result:** User-based prediction: 4.33/5.0 (based on 51 similar users)

### Example 3: Search for Movies

```cypher
:param searchTerm => "inception";
```

Returns all movies matching "inception" with their release years.

## 📊 Technical Implementation

### Pearson Correlation Formula

For users u and v with common movie ratings:

```
similarity = Σ(ru,i - r̄u)(rv,i - r̄v) / √[Σ(ru,i - r̄u)²] × √[Σ(rv,i - r̄v)²]
```

### Prediction Formula

```
r̂u,i = r̄u + Σ[similarity(u,v) × (rv,i - r̄v)] / Σ|similarity(u,v)|
```

This formula accounts for user rating biases (some users consistently rate higher or lower than others).

### Key Parameters
- **Minimum common items**: 3 (ensures statistical significance)
- **Similarity threshold**: 0.3 (filters weak correlations)
- **Dataset size**: 50k ratings (optimized for performance)

## 📈 Evaluation Metrics

The system is evaluated using:

- **MAE (Mean Absolute Error)**: Average absolute difference between predicted and actual ratings
- **RMSE (Root Mean Squared Error)**: Emphasizes larger prediction errors
- **Coverage**: Percentage of user-movie pairs for which predictions can be generated

Evaluation process:
1. Random sample of 100 user-movie pairs
2. Hide actual ratings and predict using collaborative filtering
3. Compare predictions with actual ratings
4. Calculate aggregate error metrics

## Rennes
0:05
🔍 Test Queries

The project includes diagnostic queries for:
- Database structure verification
- Relationship inspection
- Most active users and popular movies
- Single prediction tests
- User genre preferences analysis

## 📚 References

- [MovieLens Dataset](https://grouplens.org/datasets/movielens/)
- [Neo4j Documentation](https://neo4j.com/docs/)
- [Collaborative Filtering](https://en.wikipedia.org/wiki/Collaborative_filtering)
- [Pearson Correlation](https://en.wikipedia.org/wiki/Pearson_correlation_coefficient)

## 🎯 Conclusion

This project demonstrates how a complete recommendation system can be implemented directly within a graph database using Neo4j. The graph structure proved particularly effective for modeling user-item relationships, enabling intuitive querying and efficient similarity computations. The combination of user-based and item-based collaborative filtering generates meaningful predictions with evaluation metrics consistent with standard collaborative filtering benchmarks.

---

**License:** MIT  
**Contact:** For questions or contributions, please open an issue.
