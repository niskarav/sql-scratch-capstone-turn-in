{\rtf1\ansi\ansicpg1251\cocoartf1671\cocoasubrtf400
{\fonttbl\f0\fswiss\fcharset0 Helvetica;\f1\fnil\fcharset0 Menlo-Regular;}
{\colortbl;\red255\green255\blue255;\red127\green127\blue127;\red203\green35\blue57;\red27\green31\blue34;
\red7\green68\blue184;\red6\green33\blue79;\red21\green23\blue26;}
{\*\expandedcolortbl;;\cssrgb\c57046\c57047\c57046;\cssrgb\c84314\c22745\c28627;\cssrgb\c14118\c16078\c18039;
\cssrgb\c0\c36078\c77255;\cssrgb\c1176\c18431\c38431;\cssrgb\c10588\c12157\c13725\c29804;}
\paperw11900\paperh16840\margl1440\margr1440\vieww10800\viewh8400\viewkind0
\pard\tx566\tx1133\tx1700\tx2267\tx2834\tx3401\tx3968\tx4535\tx5102\tx5669\tx6236\tx6803\pardirnatural\partightenfactor0

\f0\fs24 \cf2 --1 Take a look at the first 100 rows of data in the subscriptions table. How many different segments do you see?\
\pard\pardeftab720\sl400\partightenfactor0

\f1 \cf3 \expnd0\expndtw0\kerning0
SELECT\cf4  \cf3 *\cf4 \
\cf3 FROM\cf4  Subscriptions\
\cf3 LIMIT\cf4  \cf5 100\cf4 ;\

\f0 \cf2 --2 Determine the range of months of data provided. Which months will you be able to calculate churn for?\

\f1 \cf3 SELECT\cf4  \cf5 MIN\cf4 (subscription_start) \cf3 as\cf4  \cf6 'Earliest_Start'\cf4 ,\
\pard\pardeftab720\sl400\partightenfactor0
\cf5  MAX\cf4 (subscription_end) \cf3 AS\cf4  \cf6 'Max_Sub_End'\cf4 ,\
 \cf5 MAX\cf4 (subscription_start) \cf3 AS\cf4  \cf6 'Max_Sub_Start'\cf4 ,\
 segment
\f0 \cf2 \
\pard\pardeftab720\sl400\partightenfactor0

\f1 \cf3 FROM\cf4  subscriptions\
\cf3 GROUP BY\cf4  \cf5 4\cf4 \
\cf3 ORDER BY\cf4  \cf5 1\cf4 ,\cf5 2\cf4  \cf3 DESC\cf4 ;\

\f0 \cf2 --The statement below we use for calculating total users of each segment\

\f1 \cf3 SELECT\cf4  segment,\
 \cf5 COUNT\cf4 (DISTINCT Id) \cf3 AS\cf4  \cf6 'Count'\cf4 \
\cf3 FROM\cf4  subscriptions\
\cf3 GROUP BY\cf4  \cf5 1\cf4 ;\

\f0 \cf2 \'973 You\'92ll be calculating the churn rate for both segments (87 and 30) over the first 3 months of 2017 (you can\'92t calculate it for December, since there are no subscription_end values yet). To get started, create a temporary table of months.\

\f1 \cf4 WITH months \cf3 AS\cf4  (\
\pard\pardeftab720\sl400\qr\partightenfactor0
\cf7 \
\pard\pardeftab720\sl400\partightenfactor0
\cf3 SELECT\cf4  \cf6 '2017-01-01'\cf4  \cf3 AS\cf4  first_day,\
 \cf6 '2017-01-31'\cf4  \cf3 AS\cf4  last_day\
\pard\pardeftab720\sl400\qr\partightenfactor0
\cf7 \
\pard\pardeftab720\sl400\partightenfactor0
\cf3 UNION\cf4 \
\pard\pardeftab720\sl400\qr\partightenfactor0
\cf7 \
\pard\pardeftab720\sl400\partightenfactor0
\cf3 SELECT\cf4  \cf6 '2017-02-01'\cf4  \cf3 AS\cf4  first_day,\
 \cf6 '2017-02-28'\cf4  \cf3 AS\cf4  last_day\
\pard\pardeftab720\sl400\qr\partightenfactor0
\cf7 \
\pard\pardeftab720\sl400\partightenfactor0
\cf3 UNION\cf4 \
\pard\pardeftab720\sl400\qr\partightenfactor0
\cf7 \
\pard\pardeftab720\sl400\partightenfactor0
\cf3 SELECT\cf4  \cf6 '2017-03-01'\cf4  \cf3 AS\cf4  first_day,\
 \cf6 '2017-03-31'\cf4  \cf3 AS\cf4  last_day),\

\f0 \cf2 --4 Create a temporary table, cross_join, from subscriptions and your months. Be sure to SELECT every column.\

\f1 \cf4 cross_join \cf3 AS\cf4  (\
\cf3 SELECT\cf4  \cf3 *\cf4  \
\cf3 FROM\cf4  subscriptions \
\cf3 CROSS JOIN\cf4  months),\

\f0 \cf2 --5 Create a temporary table, status, from the cross_join table you created.
\f1 \
\cf4 status \cf3 AS\cf4  (\
\cf3 SELECT\cf4  id, first_day \cf3 AS\cf4  month, \
CASE WHEN (subscription_start \cf3 <\cf4  first_day)\
 \cf3 AND\cf4  (subscription_end \cf3 >\cf4  first_day \cf3 OR\cf4  subscription_end IS \cf3 NULL\cf4 )\
 \cf3 AND\cf4  (segment \cf3 =\cf4  \cf5 87\cf4 )\
 THEN \cf5 1\cf4 \
 ELSE \cf5 0\cf4 \
 END \cf3 AS\cf4  is_active_87,\
CASE WHEN (subscription_start \cf3 <\cf4  first_day)\
 \cf3 AND\cf4  (subscription_end \cf3 >\cf4  first_day \cf3 OR\cf4  subscription_end IS \cf3 NULL\cf4 )\
 \cf3 AND\cf4  (segment \cf3 =\cf4  \cf5 30\cf4 )\
 THEN \cf5 1\cf4 \
 ELSE \cf5 0\cf4 \
 END \cf3 AS\cf4  is_active_30,\

\f0 \cf2 --6 Add an is_canceled_87 and an is_canceled_30 column to the status temporary table. This should be 1 if the subscription is canceled during the month and 0 otherwise.
\f1 \
\cf4 CASE WHEN (subscription_end BETWEEN first_day \cf3 AND\cf4  last_day)\
 \cf3 AND\cf4  (segment \cf3 =\cf4  \cf5 87\cf4 )\
 THEN \cf5 1\cf4 \
 ELSE \cf5 0\cf4 \
END \cf3 AS\cf4  is_canceled_87,\
CASE WHEN (subscription_end BETWEEN first_day \cf3 AND\cf4  last_day)\
 \cf3 AND\cf4  (segment \cf3 =\cf4  \cf5 30\cf4 )\
 THEN \cf5 1\cf4 \
 ELSE \cf5 0\cf4 \
END \cf3 AS\cf4  is_canceled_30\
\cf3 FROM\cf4  cross_join\
),\

\f0 \cf2 --7 Create a status_aggregate temporary table that is a SUM of the active and canceled subscriptions for each segment, for each month.\

\f1 \cf3 SELECT\cf4  month,\
 \cf5 SUM\cf4 (is_active_87) \cf3 AS\cf4  sum_active_87,\
 \cf5 SUM\cf4 (is_active_30) \cf3 AS\cf4  sum_active_30,\
 \cf5 SUM\cf4 (is_canceled_87) \cf3 AS\cf4  sum_canceled_87,\
 \cf5 SUM\cf4 (is_canceled_30) \cf3 AS\cf4  sum_canceled_30\
\cf3 FROM\cf4  status\
\cf3 GROUP BY\cf4  \cf5 1\cf4 \
)\

\f0 \cf2 --8 Calculate the churn rates for the two segments over the three month period. Which segment has a lower churn rate?\

\f1 \cf3 SELECT\cf4  month,\
((\cf5 status_aggregate\cf4 .\cf5 sum_canceled_87\cf3 *\cf5 1\cf4 .\cf5 0\cf4 ) \cf3 /\cf4  (\cf5 status_aggregate\cf4 .\cf5 sum_active_87\cf3 *\cf5 1\cf4 .\cf5 0\cf4 )) \cf3 AS\cf4  \cf6 'Seg_87_Churn'\cf4 ,\
((\cf5 status_aggregate\cf4 .\cf5 sum_canceled_30\cf3 *\cf5 1\cf4 .\cf5 0\cf4 ) \cf3 /\cf4  (\cf5 status_aggregate\cf4 .\cf5 sum_active_30\cf3 *\cf5 1\cf4 .\cf5 0\cf4 )) \cf3 AS\cf4  \cf6 'Seg_30_Churn'\cf4 \
\cf3 FROM\cf4  status_aggregate;\

\f0 \cf2 --The statement below we use for calculating churn rates overall by segment\

\f1 --SELECT ((SUM(status_aggregate.sum_canceled_87)*1.0) / (SUM(status_aggregate.sum_active_87)*1.0)) AS 'Overall Churn 87',\
--((SUM(status_aggregate.sum_canceled_30)*1.0) / (SUM(status_aggregate.sum_active_30)*1.0)) AS 'Overall Churn 30'\
--FROM status_aggregate;}