#US HouseHold Income Data Cleaning 

#upload raw data 
SELECT * 
FROM us_project.us_household_income;

SELECT * 
FROM us_project.us_household_income_statistics;

#immediately fixing a problem to avoid further issues! 
ALTER TABLE  us_project.us_household_income_statistics RENAME COLUMN `ï»¿id` TO `id`;

#seeing how many actually got transferred over 
SELECT COUNT(id)
FROM us_project.us_household_income;

SELECT COUNT(id)
FROM us_project.us_household_income_statistics;

#time to start cleaning! Visually, most things are looking good right off the bat, some mispelling, some zeros 

#checking duplicates
SELECT COUNT(id)
FROM us_project.us_household_income
GROUP BY id 
HAVING COUNT(id) > 1
;

#checking specifics of duplicate information 
SELECT * 
FROM (
SELECT row_id, 
id, 
ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
FROM us_project.us_household_income
) duplicates
WHERE row_num > 1 
;

#actually deleting the info with duplicate information
DELETE FROM us_household_income
WHERE row_id IN (
    SELECT row_id
    FROM (
        SELECT row_id, 
        id, 
        ROW_NUMBER() OVER(PARTITION BY id ORDER BY id) row_num
        FROM us_project.us_household_income
        ) duplicates
    WHERE row_num > 1 )
;

#checking duplicates with other dataset 
SELECT COUNT(id)
FROM us_project.us_household_income_statistics
GROUP BY id 
HAVING COUNT(id) > 1
;
#we do not have any, so nothing else to do here :) 

#checking spelling with states -- looks like georgia needs to change
SELECT DISTINCT State_Name
FROM us_project.us_household_income
ORDER BY 1
; 

#fixed georgia 
UPDATE us_project.us_household_income
SET State_Name = 'Georgia'
WHERE State_Name = 'georia'
; 

#fixed alabama 
UPDATE us_project.us_household_income
SET State_Name = 'Alabama'
WHERE State_Name = 'alabama'
; 

#checking state abbrevations 
SELECT DISTINCT State_ab
FROM us_project.us_household_income
ORDER BY 1
; 

#checking nulls in place column 
SELECT *
FROM us_project.us_household_income
WHERE County = 'Autauga County'
ORDER BY 1
; 

#fixing the null in place 
UPDATE us_household_income
SET Place = 'Autaugaville'
WHERE County = 'Autauga County' 
AND City = 'Vinemont'
;

#there seems to be mistakes in this, lets take a deeper dive (some repetition/mispelling)
SELECT Type, COUNT(Type)
FROM us_project.us_household_income
GROUP BY Type
#ORDER BY 1
; 

#changing type borough and boroughs 
UPDATE us_household_income
SET TYPE = 'Borough'
WHERE TYPE = 'Boroughs' 
; 

#Looking at AWater and ALand column (noticed some zeros earlier) 
SELECT ALand, AWater 
FROM  us_project.us_household_income
WHERE (ALand = 0 or ALand = '' OR ALand IS NULL)
; 

#data is cleaned ! 


#Now time for data exploration 
SELECT * 
FROM us_project.us_household_income;

SELECT * 
FROM us_project.us_household_income_statistics;

#Lets take a look at areas of water and land 


SELECT State_Name, SUM(ALand), SUM(AWater)
FROM us_project.us_household_income
GROUP BY State_Name 
ORDER BY 3 DESC
LIMIT 10
;


#joining the two tables together 
SELECT u.State_Name, County, Type, `Primary`, Mean, Median 
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us 
    ON u.id = us.id
WHERE Mean <> 0
;

SELECT u.State_Name, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us 
    ON u.id = us.id
WHERE Mean <> 0
GROUP BY u.State_Name 
ORDER BY 2 ASC
LIMIT 10
;
#high cost of living places have a pretty high average of salaries too -- most are pretty close to the median too 

SELECT Type, COUNT(Type), ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
FROM us_project.us_household_income u
JOIN us_project.us_household_income_statistics us 
    ON u.id = us.id
WHERE Mean <> 0
GROUP BY 1
HAVING COUNT(Type) > 100 
ORDER BY 4 DESC
LIMIT 20
;
#munincipality is thrown off a little due to there only being 1 entry, same with cdp and county, community and urban have dramatically lower salaries 
#filtering out some data as they do not have many entereies and are outliers to the rest of the data -- really just want to look at the higher volume for right now 

#wanted to see where some of the outliers were below 
SELECT * 
FROM us_project.us_household_income 
WHERE Type = 'Community' ; 


SELECT u.State_Name, City, ROUND(AVG(Mean),1), ROUND(AVG(Median),1)
From us_project.us_household_income u 
JOIN us_project.us_household_income_statistics us 
    ON u.id = us.id 
GROUP BY u.State_Name, City
ORDER BY ROUND(AVG(Mean),1) DESC
; 
#very high average salary cities, seeing there seems to be a cap at 300,000 at the highest average -- additionally some of the more expensive cities to live in most likely. 



