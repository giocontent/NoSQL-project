// ================================================
// RECOMMENDATION SYSTEM EVALUATION
// ================================================
// This file evaluates the recommendation system by comparing
// actual ratings with predicted ratings for a sample of user-movie pairs.
//
// It calculates:
// - Mean Absolute Error (MAE)
// - Root Mean Squared Error (RMSE)
// - Coverage (% of predictions successfully made)
//
// ================================================

// ------------------------------------------------
// 1. SAMPLE EVALUATION DATA
// ------------------------------------------------
// Get a random sample of actual ratings to test predictions on

// Get 100 random user-movie pairs with actual ratings
MATCH (u:User)-[r:RATED]->(m:Movie)
WITH u, m, r.rating as actualRating, rand() as random
ORDER BY random
LIMIT 100

RETURN 
    u.userId as userId,
    m.movieId as movieId,
    m.title as movieTitle,
    actualRating;

// ------------------------------------------------
// 2. PREDICT AND COMPARE (USER-BASED CORRECTED)
// ------------------------------------------------
// For each user-movie pair, predict rating and compare with actual

MATCH (u:User)-[actualR:RATED]->(targetMovie:Movie)
WITH u, targetMovie, actualR.rating as actualRating, rand() as random
ORDER BY random
LIMIT 100

// Get user's average rating
MATCH (u)-[ur:RATED]->()
WITH u, targetMovie, actualRating, avg(ur.rating) as userAvg

// Calculate user-based collaborative filtering prediction
OPTIONAL MATCH (other:User)
WHERE other <> u
OPTIONAL MATCH (u)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(other)
WITH u, userAvg, targetMovie, actualRating, other, 
     collect({targetRating: r1.rating, otherRating: r2.rating}) as commonRatings,
     count(*) as commonCount
WHERE commonCount >= 3

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount,
     reduce(sumTarget=0.0, r in commonRatings | sumTarget + r.targetRating) / commonCount as avgTarget,
     reduce(sumOther=0.0, r in commonRatings | sumOther + r.otherRating) / commonCount as avgOther

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount, avgTarget, avgOther,
     reduce(numerator=0.0, r in commonRatings | 
         numerator + (r.targetRating - avgTarget) * (r.otherRating - avgOther)) as numerator,
     sqrt(reduce(sumSqTarget=0.0, r in commonRatings | 
         sumSqTarget + (r.targetRating - avgTarget)^2)) as denomTarget,
     sqrt(reduce(sumSqOther=0.0, r in commonRatings | 
         sumSqOther + (r.otherRating - avgOther)^2)) as denomOther

WITH u, userAvg, targetMovie, actualRating, other, avgOther, commonCount,
     CASE 
         WHEN denomTarget = 0 OR denomOther = 0 THEN 0
         ELSE numerator / (denomTarget * denomOther)
     END as similarity
WHERE similarity > 0.3

OPTIONAL MATCH (other)-[r:RATED]->(targetMovie)
WITH u, userAvg, targetMovie, actualRating, similarity, avgOther, r.rating as otherRating
WITH u, userAvg, targetMovie, actualRating,
     CASE 
         WHEN sum(similarity) > 0 
         THEN userAvg + (sum(similarity * (otherRating - avgOther)) / sum(similarity))
         ELSE NULL 
     END as predictedRating,
     count(otherRating) as similarUsersCount

// Add fallback to movie average if no prediction
OPTIONAL MATCH (targetMovie)<-[allR:RATED]-()
WITH u, targetMovie, actualRating, predictedRating, similarUsersCount,
     avg(allR.rating) as movieAvg

// Add global average fallback
OPTIONAL MATCH ()-[globalR:RATED]->()
WITH u, targetMovie, actualRating, predictedRating, similarUsersCount, movieAvg,
     avg(globalR.rating) as globalAvg

WITH u, targetMovie, actualRating,
     CASE
         WHEN predictedRating IS NOT NULL THEN predictedRating
         WHEN movieAvg IS NOT NULL THEN movieAvg
         ELSE globalAvg
     END as finalPrediction,
     CASE
         WHEN predictedRating IS NOT NULL THEN 'user-based-corrected'
         WHEN movieAvg IS NOT NULL THEN 'movie-average'
         ELSE 'global-average'
     END as method,
     similarUsersCount

WHERE finalPrediction IS NOT NULL

RETURN
    u.userId as userId,
    targetMovie.movieId as movieId,
    targetMovie.title as movieTitle,
    actualRating,
    finalPrediction as predictedRating,
    abs(actualRating - finalPrediction) as absoluteError,
    (actualRating - finalPrediction)^2 as squaredError,
    method,
    similarUsersCount
ORDER BY absoluteError DESC;

// ------------------------------------------------
// 3. CALCULATE MAE AND RMSE (USER-BASED CORRECTED)
// ------------------------------------------------
// Calculate overall evaluation metrics

MATCH (u:User)-[actualR:RATED]->(targetMovie:Movie)
WITH u, targetMovie, actualR.rating as actualRating, rand() as random
ORDER BY random
LIMIT 100

// Get user's average rating
MATCH (u)-[ur:RATED]->()
WITH u, targetMovie, actualRating, avg(ur.rating) as userAvg

// Calculate user-based collaborative filtering prediction
OPTIONAL MATCH (other:User)
WHERE other <> u
OPTIONAL MATCH (u)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(other)
WITH u, userAvg, targetMovie, actualRating, other, 
     collect({targetRating: r1.rating, otherRating: r2.rating}) as commonRatings,
     count(*) as commonCount
WHERE commonCount >= 3

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount,
     reduce(sumTarget=0.0, r in commonRatings | sumTarget + r.targetRating) / commonCount as avgTarget,
     reduce(sumOther=0.0, r in commonRatings | sumOther + r.otherRating) / commonCount as avgOther

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount, avgTarget, avgOther,
     reduce(numerator=0.0, r in commonRatings | 
         numerator + (r.targetRating - avgTarget) * (r.otherRating - avgOther)) as numerator,
     sqrt(reduce(sumSqTarget=0.0, r in commonRatings | 
         sumSqTarget + (r.targetRating - avgTarget)^2)) as denomTarget,
     sqrt(reduce(sumSqOther=0.0, r in commonRatings | 
         sumSqOther + (r.otherRating - avgOther)^2)) as denomOther

WITH u, userAvg, targetMovie, actualRating, other, avgOther, commonCount,
     CASE 
         WHEN denomTarget = 0 OR denomOther = 0 THEN 0
         ELSE numerator / (denomTarget * denomOther)
     END as similarity
WHERE similarity > 0.3

OPTIONAL MATCH (other)-[r:RATED]->(targetMovie)
WITH u, userAvg, targetMovie, actualRating, similarity, avgOther, r.rating as otherRating
WITH u, targetMovie, actualRating,
     CASE 
         WHEN sum(similarity) > 0 
         THEN userAvg + (sum(similarity * (otherRating - avgOther)) / sum(similarity))
         ELSE NULL 
     END as predictedRating

// Add fallback to movie average if no prediction
OPTIONAL MATCH (targetMovie)<-[allR:RATED]-()
WITH u, targetMovie, actualRating, predictedRating,
     avg(allR.rating) as movieAvg

// Add global average fallback
OPTIONAL MATCH ()-[globalR:RATED]->()
WITH u, targetMovie, actualRating, predictedRating, movieAvg,
     avg(globalR.rating) as globalAvg

WITH actualRating,
     CASE
         WHEN predictedRating IS NOT NULL THEN predictedRating
         WHEN movieAvg IS NOT NULL THEN movieAvg
         ELSE globalAvg
     END as finalPrediction

WHERE finalPrediction IS NOT NULL

WITH 
    count(*) as totalPredictions,
    avg(abs(actualRating - finalPrediction)) as MAE,
    sqrt(avg((actualRating - finalPrediction)^2)) as RMSE,
    100.0 as sampleSize

RETURN 
    'User-Based Collaborative Filtering (Corrected)' as method,
    totalPredictions,
    sampleSize,
    (totalPredictions * 100.0 / sampleSize) as coveragePercent,
    MAE,
    RMSE;

// ------------------------------------------------
// 4. DETAILED EVALUATION BY METHOD (CORRECTED)
// ------------------------------------------------
// Show how often each prediction method is used and its accuracy

MATCH (u:User)-[actualR:RATED]->(targetMovie:Movie)
WITH u, targetMovie, actualR.rating as actualRating, rand() as random
ORDER BY random
LIMIT 200

// Get user's average rating
MATCH (u)-[ur:RATED]->()
WITH u, targetMovie, actualRating, avg(ur.rating) as userAvg

// User-based prediction
OPTIONAL MATCH (other:User)
WHERE other <> u
OPTIONAL MATCH (u)-[r1:RATED]->(m:Movie)<-[r2:RATED]-(other)
WITH u, userAvg, targetMovie, actualRating, other, 
     collect({targetRating: r1.rating, otherRating: r2.rating}) as commonRatings,
     count(*) as commonCount
WHERE commonCount >= 3

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount,
     reduce(sumTarget=0.0, r in commonRatings | sumTarget + r.targetRating) / commonCount as avgTarget,
     reduce(sumOther=0.0, r in commonRatings | sumOther + r.otherRating) / commonCount as avgOther

WITH u, userAvg, targetMovie, actualRating, other, commonRatings, commonCount, avgTarget, avgOther,
     reduce(numerator=0.0, r in commonRatings | 
         numerator + (r.targetRating - avgTarget) * (r.otherRating - avgOther)) as numerator,
     sqrt(reduce(sumSqTarget=0.0, r in commonRatings | 
         sumSqTarget + (r.targetRating - avgTarget)^2)) as denomTarget,
     sqrt(reduce(sumSqOther=0.0, r in commonRatings | 
         sumSqOther + (r.otherRating - avgOther)^2)) as denomOther

WITH u, userAvg, targetMovie, actualRating, other, avgOther, commonCount,
     CASE 
         WHEN denomTarget = 0 OR denomOther = 0 THEN 0
         ELSE numerator / (denomTarget * denomOther)
     END as similarity
WHERE similarity > 0.3

OPTIONAL MATCH (other)-[r:RATED]->(targetMovie)
WITH u, userAvg, targetMovie, actualRating, similarity, avgOther, r.rating as otherRating
WITH u, targetMovie, actualRating,
     CASE 
         WHEN sum(similarity) > 0 
         THEN userAvg + (sum(similarity * (otherRating - avgOther)) / sum(similarity))
         ELSE NULL 
     END as userBasedPred

// Movie average
OPTIONAL MATCH (targetMovie)<-[allR:RATED]-()
WITH u, targetMovie, actualRating, userBasedPred,
     avg(allR.rating) as movieAvg

// Global average
OPTIONAL MATCH ()-[globalR:RATED]->()
WITH actualRating, userBasedPred, movieAvg,
     avg(globalR.rating) as globalAvg

WITH actualRating,
     CASE
         WHEN userBasedPred IS NOT NULL THEN userBasedPred
         WHEN movieAvg IS NOT NULL THEN movieAvg
         ELSE globalAvg
     END as finalPrediction,
     CASE
         WHEN userBasedPred IS NOT NULL THEN 'user-based-corrected'
         WHEN movieAvg IS NOT NULL THEN 'movie-average'
         ELSE 'global-average'
     END as method

WHERE finalPrediction IS NOT NULL

WITH method,
     count(*) as count,
     avg(abs(actualRating - finalPrediction)) as MAE,
     sqrt(avg((actualRating - finalPrediction)^2)) as RMSE

RETURN 
    method,
    count,
    MAE,
    RMSE
ORDER BY count DESC;

// ------------------------------------------------
// 5. EXAMPLE PREDICTIONS FOR SPECIFIC USERS
// ------------------------------------------------
// Show sample predictions for a few test users

// Set parameter for user ID
// :param testUserId => 100;

MATCH (u:User {userId: $testUserId})-[r:RATED]->(m:Movie)
WITH u, collect({movie: m.title, rating: r.rating}) as actualRatings
LIMIT 1

UNWIND actualRatings[0..5] as sample

RETURN 
    u.userId as userId,
    'User has rated: ' + sample.movie + ' with rating ' + toString(sample.rating) as info;
