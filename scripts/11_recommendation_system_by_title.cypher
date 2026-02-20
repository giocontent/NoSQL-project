// ================================================
// MOVIE RECOMMENDATION SYSTEM (BY TITLE)
// ================================================
// This file implements user-based and item-based collaborative filtering
// with fallback mechanisms for movie rating prediction.
//
// USAGE: Set parameters using MOVIE TITLE instead of ID:
// :param userId => 1;
// :param movieTitle => "Star Wars: Episode IV - A New Hope (1977)";
//
// The system will automatically look up the movie ID from the title.
// Note: Title must match EXACTLY (case-sensitive, including year).
//
// ================================================

// ------------------------------------------------
// 1. USER-BASED COLLABORATIVE FILTERING (BY TITLE)
// ------------------------------------------------
// Find similar users based on Pearson correlation of ratings
// and predict rating for a target movie using CENTERED ratings

// Set parameters:
// :param userId => 1;
// :param movieTitle => "Star Wars: Episode IV - A New Hope (1977)";

// First, get target user's average rating
MATCH (target:User {userId: $userId})-[tr:RATED]->()
WITH target, avg(tr.rating) as targetUserAvg

// Match target movie by TITLE (case-sensitive exact match)
MATCH (targetMovie:Movie {title: $movieTitle})

// Find users who rated the target movie (limits search space)
MATCH (targetMovie)<-[otherTargetRating:RATED]-(other:User)
WHERE other <> target

// Find common movies between target and other users
MATCH (target)-[r1:RATED]->(commonMovie:Movie)<-[r2:RATED]-(other)
WITH target, targetUserAvg, targetMovie, other, otherTargetRating,
     collect({targetRating: r1.rating, otherRating: r2.rating}) as commonRatings
WITH target, targetUserAvg, targetMovie, other, otherTargetRating,
     commonRatings, size(commonRatings) as commonCount
WHERE commonCount >= 3  // Require at least 3 common movies

// Calculate Pearson correlation
WITH target, targetUserAvg, targetMovie, other, otherTargetRating, commonRatings, commonCount,
     reduce(sumTarget=0.0, r in commonRatings | sumTarget + r.targetRating) / commonCount as avgTarget,
     reduce(sumOther=0.0, r in commonRatings | sumOther + r.otherRating) / commonCount as avgOther

WITH target, targetUserAvg, targetMovie, other, otherTargetRating, commonRatings, commonCount, avgTarget, avgOther,
     reduce(numerator=0.0, r in commonRatings | 
         numerator + (r.targetRating - avgTarget) * (r.otherRating - avgOther)) as numerator,
     sqrt(reduce(sumSqTarget=0.0, r in commonRatings | 
         sumSqTarget + (r.targetRating - avgTarget)^2)) as denomTarget,
     sqrt(reduce(sumSqOther=0.0, r in commonRatings | 
         sumSqOther + (r.otherRating - avgOther)^2)) as denomOther

WITH target, targetUserAvg, targetMovie, other, otherTargetRating, avgOther, commonCount,
     CASE 
         WHEN denomTarget = 0 OR denomOther = 0 THEN 0
         ELSE numerator / (denomTarget * denomOther)
     END as similarity
WHERE similarity > 0.3  // Keep only positive correlations

// Use centered ratings: prediction = userAvg + Σ(similarity * (otherRating - otherAvg)) / Σ(similarity)
WITH target, targetMovie, targetUserAvg,
     sum(similarity * (otherTargetRating.rating - avgOther)) as numerator,
     sum(similarity) as denominator,
     count(other) as ratingCount
     
RETURN 
    target.userId as userId,
    targetMovie.movieId as movieId,
    targetMovie.title as movieTitle,
    CASE 
        WHEN denominator > 0 THEN targetUserAvg + (numerator / denominator)
        ELSE NULL
    END as predictedRating,
    ratingCount as similarUsersWhoRated,
    targetUserAvg as userAvgRating,
    'user-based-corrected' as method;

// ------------------------------------------------
// 2. ITEM-BASED COLLABORATIVE FILTERING (BY TITLE)
// ------------------------------------------------
// Find similar movies based on user rating patterns
// and predict rating based on target user's ratings of similar movies

// Set parameters:
// :param userId => 1;
// :param movieTitle => "Star Wars: Episode IV - A New Hope (1977)";

// Get target user's average rating
MATCH (targetUser:User {userId: $userId})-[tr:RATED]->()
WITH targetUser, avg(tr.rating) as targetUserAvg

MATCH (targetMovie:Movie {title: $movieTitle})

// Only consider movies the target user has rated
MATCH (targetUser)-[r1:RATED]->(ratedMovie:Movie)
WHERE ratedMovie <> targetMovie

// Find users who rated BOTH movies (limits search space)
MATCH (ratedMovie)<-[r2:RATED]-(other:User)-[r3:RATED]->(targetMovie)

WITH targetUser, targetUserAvg, targetMovie, ratedMovie, r1.rating as userRating,
     collect({otherRatingRated: r2.rating, otherRatingTarget: r3.rating}) as coRatings
WITH targetUser, targetUserAvg, targetMovie, ratedMovie, userRating, coRatings,
     size(coRatings) as coRatingCount
WHERE coRatingCount >= 3  // Require at least 3 common users

// Calculate Pearson correlation between movies
WITH targetUser, targetUserAvg, targetMovie, ratedMovie, userRating, coRatings, coRatingCount,
     reduce(sumRated=0.0, r in coRatings | sumRated + r.otherRatingRated) / coRatingCount as avgRated,
     reduce(sumTarget=0.0, r in coRatings | sumTarget + r.otherRatingTarget) / coRatingCount as avgTarget

WITH targetUser, targetUserAvg, targetMovie, ratedMovie, userRating, coRatings, coRatingCount, avgRated, avgTarget,
     reduce(numerator=0.0, r in coRatings | 
         numerator + (r.otherRatingRated - avgRated) * (r.otherRatingTarget - avgTarget)) as numerator,
     sqrt(reduce(sumSqRated=0.0, r in coRatings | 
         sumSqRated + (r.otherRatingRated - avgRated)^2)) as denomRated,
     sqrt(reduce(sumSqTarget=0.0, r in coRatings | 
         sumSqTarget + (r.otherRatingTarget - avgTarget)^2)) as denomTarget

WITH targetUser, targetUserAvg, targetMovie, ratedMovie, userRating,
     CASE 
         WHEN denomRated = 0 OR denomTarget = 0 THEN 0
         ELSE numerator / (denomRated * denomTarget)
     END as similarity
WHERE similarity > 0.3  // Keep only positive correlations

// Use centered approach: prediction = userAvg + Σ(similarity * (userRating - userAvg)) / Σ(similarity)
WITH targetUser, targetMovie, targetUserAvg,
     sum(similarity * (userRating - targetUserAvg)) as numerator,
     sum(similarity) as denominator,
     count(ratedMovie) as similarMoviesCount

RETURN 
    targetUser.userId as userId,
    targetMovie.movieId as movieId,
    targetMovie.title as movieTitle,
    CASE 
        WHEN denominator > 0 THEN targetUserAvg + (numerator / denominator)
        ELSE NULL
    END as predictedRating,
    similarMoviesCount as similarMoviesUsed,
    targetUserAvg as userAvgRating,
    'item-based-corrected' as method;

// ------------------------------------------------
// 3. COMBINED PREDICTION WITH FALLBACKS (BY TITLE)
// ------------------------------------------------
// Try user-based, then item-based, then movie average, then global average

// Set parameters:
// :param userId => 1;
// :param movieTitle => "Star Wars: Episode IV - A New Hope (1977)";

// Get target user's average rating first
MATCH (target:User {userId: $userId})-[tr:RATED]->()
WITH target, avg(tr.rating) as targetUserAvg

MATCH (targetMovie:Movie {title: $movieTitle})

// Try user-based collaborative filtering
OPTIONAL MATCH (targetMovie)<-[otherTargetRating:RATED]-(other:User)
WHERE other <> target

OPTIONAL MATCH (target)-[r1:RATED]->(commonMovie:Movie)<-[r2:RATED]-(other)
WITH target, targetUserAvg, targetMovie, other, otherTargetRating,
     collect({targetRating: r1.rating, otherRating: r2.rating}) as commonRatings
WITH target, targetUserAvg, targetMovie, other, otherTargetRating,
     commonRatings, size(commonRatings) as commonCount
WHERE commonCount >= 3

WITH target, targetUserAvg, targetMovie, other, otherTargetRating, commonRatings, commonCount,
     reduce(sumTarget=0.0, r in commonRatings | sumTarget + r.targetRating) / commonCount as avgTarget,
     reduce(sumOther=0.0, r in commonRatings | sumOther + r.otherRating) / commonCount as avgOther

WITH target, targetUserAvg, targetMovie, other, otherTargetRating, commonRatings, commonCount, avgTarget, avgOther,
     reduce(numerator=0.0, r in commonRatings | 
         numerator + (r.targetRating - avgTarget) * (r.otherRating - avgOther)) as numerator,
     sqrt(reduce(sumSqTarget=0.0, r in commonRatings | 
         sumSqTarget + (r.targetRating - avgTarget)^2)) as denomTarget,
     sqrt(reduce(sumSqOther=0.0, r in commonRatings | 
         sumSqOther + (r.otherRating - avgOther)^2)) as denomOther

WITH target, targetUserAvg, targetMovie, other, otherTargetRating, avgOther, commonCount,
     CASE 
         WHEN denomTarget = 0 OR denomOther = 0 THEN 0
         ELSE numerator / (denomTarget * denomOther)
     END as similarity
WHERE similarity > 0.3

WITH target, targetUserAvg, targetMovie,
     sum(similarity * (otherTargetRating.rating - avgOther)) as userBasedNumerator,
     sum(similarity) as userBasedDenominator,
     count(other) as userBasedCount

WITH target, targetUserAvg, targetMovie,
     CASE 
         WHEN userBasedDenominator > 0 
         THEN targetUserAvg + (userBasedNumerator / userBasedDenominator)
         ELSE NULL 
     END as userBasedPred,
     userBasedCount

// Try item-based collaborative filtering
OPTIONAL MATCH (target)-[r1:RATED]->(ratedMovie:Movie)
WHERE ratedMovie <> targetMovie

OPTIONAL MATCH (ratedMovie)<-[r2:RATED]-(other:User)-[r3:RATED]->(targetMovie)
WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, 
     ratedMovie, r1.rating as userRating,
     collect({otherRatingRated: r2.rating, otherRatingTarget: r3.rating}) as coRatings
WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount,
     ratedMovie, userRating, coRatings, size(coRatings) as coRatingCount
WHERE coRatingCount >= 3

WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, 
     ratedMovie, userRating, coRatings, coRatingCount,
     reduce(sumRated=0.0, r in coRatings | sumRated + r.otherRatingRated) / coRatingCount as avgRated,
     reduce(sumTarget=0.0, r in coRatings | sumTarget + r.otherRatingTarget) / coRatingCount as avgTarget

WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, 
     ratedMovie, userRating, coRatings, coRatingCount, avgRated, avgTarget,
     reduce(numerator=0.0, r in coRatings | 
         numerator + (r.otherRatingRated - avgRated) * (r.otherRatingTarget - avgTarget)) as numerator,
     sqrt(reduce(sumSqRated=0.0, r in coRatings | 
         sumSqRated + (r.otherRatingRated - avgRated)^2)) as denomRated,
     sqrt(reduce(sumSqTarget=0.0, r in coRatings | 
         sumSqTarget + (r.otherRatingTarget - avgTarget)^2)) as denomTarget

WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, 
     ratedMovie, userRating,
     CASE 
         WHEN denomRated = 0 OR denomTarget = 0 THEN 0
         ELSE numerator / (denomRated * denomTarget)
     END as similarity
WHERE similarity > 0.3

WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount,
     sum(similarity * (userRating - targetUserAvg)) as itemBasedNumerator,
     sum(similarity) as itemBasedDenominator,
     count(ratedMovie) as itemBasedCount

WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount,
     CASE 
         WHEN itemBasedDenominator > 0 
         THEN targetUserAvg + (itemBasedNumerator / itemBasedDenominator)
         ELSE NULL 
     END as itemBasedPred,
     itemBasedCount

// Calculate fallback predictions
OPTIONAL MATCH (targetMovie)<-[r:RATED]-()
WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, itemBasedPred, itemBasedCount,
     avg(r.rating) as movieAvg,
     count(r) as movieRatingCount

OPTIONAL MATCH ()-[r2:RATED]->()
WITH target, targetMovie, targetUserAvg, userBasedPred, userBasedCount, itemBasedPred, itemBasedCount, 
     movieAvg, movieRatingCount,
     avg(r2.rating) as globalAvg

RETURN
    target.userId as userId,
    targetMovie.movieId as movieId,
    targetMovie.title as movieTitle,
    CASE
        WHEN userBasedPred IS NOT NULL THEN userBasedPred
        WHEN itemBasedPred IS NOT NULL THEN itemBasedPred
        WHEN movieAvg IS NOT NULL THEN movieAvg
        ELSE globalAvg
    END as predictedRating,
    CASE
        WHEN userBasedPred IS NOT NULL THEN 'user-based-corrected'
        WHEN itemBasedPred IS NOT NULL THEN 'item-based-corrected'
        WHEN movieAvg IS NOT NULL THEN 'movie-average'
        ELSE 'global-average'
    END as method,
    userBasedPred,
    userBasedCount,
    itemBasedPred,
    itemBasedCount,
    movieAvg,
    movieRatingCount,
    globalAvg,
    targetUserAvg;
