-- Assignment 1: Jordan on the world stage, in SQL
-- Name:AYAT ALNJJAR
-- TA group:Rami Airout
-- Save this file as A01_<FirstName>_<LastName>.sql.
-- Under every query: the number of rows it returned, and one sentence that answers the question.
-- The file must run from top to bottom without errors: the view in Q2 has to exist before Q3 reads it.


-- =====================================================================
-- Part 1. Load and check the data
-- =====================================================================

-- Q1. Row counts of the three tables, and the first and last match_date, in one row.


SELECT
  (SELECT COUNT(*) FROM `football.matches`) AS matches_count,
  (SELECT COUNT(*) FROM `football.goals`) AS goals_count,
  (SELECT COUNT(*) FROM `football.shootouts`) AS shootouts_count,
  (SELECT MIN(match_date) FROM `football.matches`) AS first_match_date,
  (SELECT MAX(match_date) FROM `football.matches`) AS last_match_date;

-- Rows: 1 
-- Answer: The three tables contain 49807 matches_count,  47914 goals_count,
-- and 694 shootouts_count . Match dates  first_match_date 1872-11-30 , last_match_date 2026-09-30 .


-- Q2. The view football.team_matches: one row per team per match.
CREATE OR REPLACE VIEW `football.team_matches` AS
WITH both_sides AS (
  SELECT
    match_id,
    match_date,
    tournament,
    home_team AS team,
    away_team AS opponent,
    home_score AS goals_for,
    away_score AS goals_against
  FROM `football.matches`

  UNION ALL

  SELECT
    match_id,
    match_date,
    tournament,
    away_team AS team,
    home_team AS opponent,
    away_score AS goals_for,
    home_score AS goals_against
  FROM `football.matches`
)
SELECT
  match_id,
  match_date,
  tournament,
  team,
  opponent,
  goals_for,
  goals_against,
  CASE
    WHEN goals_for > goals_against THEN 'win'
    WHEN goals_for < goals_against THEN 'loss'
    ELSE 'draw'
  END AS result
FROM both_sides;

-- Q2 audit: rows, different matches, wins, losses, draws.
SELECT
  COUNT(*) AS team_rows,
  COUNT(DISTINCT match_id) AS different_matches,
  COUNTIF(result = 'win') AS wins,
  COUNTIF(result = 'loss') AS losses,
  COUNTIF(result = 'draw') AS draws
FROM `football.team_matches`;

-- Rows: 1
-- Answer: The view contains 99614 team rows across 49807 matches, with 38498 wins, 38498 losses and 22618 draws.




-- =====================================================================
-- Part 2. Jordan in numbers
-- =====================================================================

-- Q3. How has Jordan done overall?
SELECT
  COUNT(*) AS matches,
  COUNTIF(result = 'win') AS wins,
  COUNTIF(result = 'draw') AS draws,
  COUNTIF(result = 'loss') AS losses,
  SUM(goals_for) AS goals_for,
  SUM(goals_against) AS goals_against,
  ROUND(100.0 * COUNTIF(result = 'win') / COUNT(*), 1) AS win_pct
FROM `football.team_matches`
WHERE team = 'Jordan';
-- Rows: 1
-- Answer: Jordan played 494 matches, winning 181, drawing 136 and losing 177, with a win rate of 36.6%.


-- Q4. Has Jordan got better over time? (by decade)
SELECT
  DIV(EXTRACT(YEAR FROM match_date), 10) * 10 AS decade,
  COUNT(*) AS matches,
  ROUND(100.0 * COUNTIF(result = 'win') / COUNT(*), 1) AS win_pct
FROM `football.team_matches`
WHERE team = 'Jordan'
GROUP BY decade
ORDER BY decade;

-- Rows: 7
-- Answer: Jordan's win rate generally improved from 7.7% in the 1960s to 44.9% in the 2020s, although the 2020s are incomplete because the data ends on 30 September 2026.


-- Q5. Opponents played at least 10 times.
SELECT
  opponent,
  COUNT(*) AS matches,
  COUNTIF(result = 'win') AS wins,
  COUNTIF(result = 'draw') AS draws,
  COUNTIF(result = 'loss') AS losses
FROM `football.team_matches`
WHERE team = 'Jordan'
GROUP BY opponent
HAVING COUNT(*) >= 10
ORDER BY matches DESC, opponent ASC;

-- Rows: 14
-- Answer: Iraq is Jordan's most-played opponent, with 48 matches, 10 wins, 13 draws and 25 losses.



-- Q6. Jordan's five biggest wins.
SELECT
  match_date,
  opponent,
  tournament,
  goals_for,
  goals_against,
  goals_for - goals_against AS margin
FROM `football.team_matches`
WHERE team = 'Jordan'
  AND result = 'win'
ORDER BY margin DESC, match_date ASC
LIMIT 5;

-- Rows: 5
-- Answer: Jordan's biggest win was a 9-0 victory over Nepal on 23 July 2011, a margin of 9 goals.



-- =====================================================================
-- Part 3. Goals, scorers and what the data covers
-- =====================================================================

-- Q7. The 2023 Asian Cup, match by match, with a running total of Jordan's goals.
SELECT
  match_date,
  opponent,
  goals_for,
  goals_against,
  result,
  SUM(goals_for) OVER (
    ORDER BY match_date, match_id
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS goals_so_far
FROM `football.team_matches`
WHERE team = 'Jordan'
  AND match_date BETWEEN '2024-01-12' AND '2024-02-10'
  AND tournament = 'AFC Asian Cup'
ORDER BY match_date, match_id;
-- Rows: 7
-- Answer: Jordan scored 10 goals across its first five matches of the 2023 AFC Asian Cup, reaching a running total of 10 by the quarter-final.



-- Q8. Every goal of Jordan's first World Cup.
SELECT
  m.match_date,
  m.home_team,
  m.away_team,
  g.minute,
  g.team,
  g.scorer,
  g.own_goal,
  g.penalty
FROM `football.matches` AS m
JOIN `football.goals` AS g
  ON m.match_id = g.match_id
WHERE m.tournament = 'FIFA World Cup'
  AND m.match_date BETWEEN '2026-06-01' AND '2026-07-31'
  AND (m.home_team = 'Jordan' OR m.away_team = 'Jordan')
ORDER BY m.match_date, g.minute;

-- Rows: 11
-- Answer: The goal records list 11 goals across Jordan's three matches at the 2026 FIFA World Cup, including goals scored by either team.



-- Q9. Can we trust an all-time top scorers list from this data?
WITH jordan_goal_matches AS (
  SELECT DISTINCT
    match_id
  FROM `football.goals`
  WHERE team = 'Jordan'
    AND scorer IS NOT NULL
    AND TRIM(scorer) != ''
),
jordan_scoring_matches AS (
  SELECT
    match_id
  FROM `football.team_matches`
  WHERE team = 'Jordan'
    AND goals_for > 0
)
SELECT
  COUNT(*) AS scoring_matches,
  COUNTIF(jgm.match_id IS NULL) AS no_scorer_recorded
FROM jordan_scoring_matches AS jsm
LEFT JOIN jordan_goal_matches AS jgm
  ON jsm.match_id = jgm.match_id;

-- Rows: 1
-- Answer: Jordan scored in 321 matches, but 240 of those matches have no recorded Jordan goalscorer, so the scorer data is incomplete and an all-time ranking may be unreliable.


-- =====================================================================
-- Part 4. The 2026 World Cup, step by step
-- =====================================================================

-- Q10. Teams with more goals per match than the average team.
WITH team_goals AS (
  SELECT
    match_id,
    home_team AS team,
    home_score AS goals
  FROM `football.matches`
  WHERE tournament = 'FIFA World Cup'
    AND match_date BETWEEN '2026-06-01' AND '2026-07-31'

  UNION ALL

  SELECT
    match_id,
    away_team AS team,
    away_score AS goals
  FROM `football.matches`
  WHERE tournament = 'FIFA World Cup'
    AND match_date BETWEEN '2026-06-01' AND '2026-07-31'
),
team_averages AS (
  SELECT
    team,
    COUNT(*) AS matches,
    SUM(goals) AS goals,
    AVG(goals) AS goals_per_match
  FROM team_goals
  GROUP BY team
)
SELECT
  team,
  matches,
  goals,
  ROUND(goals_per_match, 2) AS goals_per_match
FROM team_averages
WHERE goals_per_match > (
  SELECT AVG(goals_per_match)
  FROM team_averages
)
ORDER BY goals_per_match DESC, team ASC;

-- Rows:22
-- Answer: Twenty-two teams scored above the average goals per match, led by Germany and the Netherlands with 2.75 goals per match each.


-- =====================================================================
-- Bonus (not graded)
-- =====================================================================

-- B1. The Golden Boot race: the top three places.
WITH scorer_totals AS (
  SELECT
    g.scorer,
    g.team,
    COUNT(*) AS goals
  FROM `football.goals` AS g
  JOIN `football.matches` AS m
    ON g.match_id = m.match_id
  WHERE m.tournament = 'FIFA World Cup'
    AND m.match_date BETWEEN '2026-06-01' AND '2026-07-31'
    AND g.scorer IS NOT NULL
    AND TRIM(g.scorer) != ''
    AND COALESCE(g.own_goal, FALSE) = FALSE
  GROUP BY g.scorer, g.team
),
ranked_scorers AS (
  SELECT
    scorer,
    team,
    goals,
    DENSE_RANK() OVER (ORDER BY goals DESC) AS goal_rank
  FROM scorer_totals
)
SELECT
  scorer,
  team,
  goals,
  goal_rank
FROM ranked_scorers
WHERE goal_rank <= 3
ORDER BY goal_rank, scorer;

-- Rows: 4
-- Answer: Kylian Mbappé leads with 10 goals, while Erling Haaland and Jude Bellingham share third place with 7 goals each.



-- B2. Jordan's goals per year since 2015: change on the year before, and running total.


WITH years AS (
  SELECT year
  FROM UNNEST(GENERATE_ARRAY(2015, 2026)) AS year
),
annual_stats AS (
  SELECT
    EXTRACT(YEAR FROM match_date) AS year,
    COUNT(*) AS matches,
    SUM(
      CASE
        WHEN home_team = 'Jordan' THEN home_score
        ELSE away_score
      END
    ) AS goals
  FROM `football.matches`
  WHERE (home_team = 'Jordan' OR away_team = 'Jordan')
    AND match_date >= '2015-01-01'
    AND match_date <= '2026-09-30'
  GROUP BY year
),
yearly AS (
  SELECT
    y.year,
    COALESCE(a.matches, 0) AS matches,
    COALESCE(a.goals, 0) AS goals
  FROM years AS y
  LEFT JOIN annual_stats AS a
    ON y.year = a.year
)
SELECT
  year,
  matches,
  goals,
  goals - LAG(goals) OVER (ORDER BY year) AS change_on_last_year,
  SUM(goals) OVER (
    ORDER BY year
    ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW
  ) AS running_goals
FROM yearly
ORDER BY year;
-- Rows: 12
-- Answer: Jordan scored 42 goals in 2024, 29 more than in 2023; the 2026 figures cover only the period through 30 September.

-- B3. Penalty shootouts.has Jordan won?

SELECT
  COUNT(*) AS jordan_shootout_wins
FROM `football.shootouts`
WHERE winner = 'Jordan';

-- Rows: 1
-- Answer: Jordan has won result penalty shootouts

-- B3b. Which team has won the most shootouts of all time?
SELECT
  winner AS team,
  COUNT(*) AS shootout_wins
FROM `football.shootouts`
WHERE winner IS NOT NULL
  AND TRIM(winner) != ''
GROUP BY winner
ORDER BY shootout_wins DESC, team ASC
LIMIT 10;

-- Rows: 10
-- Answer: Egypt and South Korea lead with 16 shootout wins each, followed by Argentina with 15.


