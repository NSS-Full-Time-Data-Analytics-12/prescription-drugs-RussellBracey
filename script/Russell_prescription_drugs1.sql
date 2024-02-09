
-- 
--1.   a. Which prescriber had the highest total number of claims
-- 	(totaled over all drugs)? Report the npi and the total number of claims.
    --Join prescriber and prescription tables.
SELECT npi, SUM(prescription.total_claim_count) AS total_claim_count
FROM prescriber
INNER JOIN prescription USING(npi)
WHERE total_claim_count >0
GROUP BY npi
ORDER BY total_claim_count DESC;
	
	
	
-- 1.  b. Repeat the above, but this time report the nppes_provider_first_name, 
-- 	nppes_provider_last_org_name,  specialty_description, and the total number of claims.

SELECT npi, SUM(total_claim_count) AS claim_count,
	   nppes_provider_first_name AS first_name, 
	   nppes_provider_last_org_name AS last_name, 
	   specialty_description
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY npi, first_name, last_name, specialty_description
ORDER BY claim_count DESC;





-- 2. 
--     a. Which specialty had the most total number of claims (totaled over all drugs)?
SELECT specialty_description, SUM(total_claim_count) AS specialty_count
FROM prescriber
INNER JOIN prescription USING(npi)
GROUP BY specialty_description
ORDER BY specialty_count DESC;

--     b. Which specialty had the most total number of claims for opioids?
SELECT specialty_description, SUM(total_claim_count) AS total_claim
FROM prescriber
INNER JOIN prescription USING(npi)
INNER JOIN drug USING(drug_name)
WHERE opioid_drug_flag LIKE 'Y' OR long_acting_opioid_drug_flag LIKE 'Y'
GROUP BY specialty_description
ORDER BY total_claim DESC;
--     c. **Challenge Question:** Are there any specialties that appear in 
--     the prescriber table that have no associated prescriptions in the prescription table?

(SELECT npi
FROM prescriber)
EXCEPT
(SELECT npi
FROM prescription);

SELECT specialty_description,SUM(total_claim_count) AS total_claims
FROM prescriber FULL JOIN prescription USING(npi)
--WHERE total_claim_count IS NULL
GROUP BY specialty_description
ORDER BY total_claims DESC;

SELECT DISTINCT(specialty_description)
FROM prescriber;


--     d. **Difficult Bonus:** *Do not attempt until you have solved all other problems!* 
-- For each specialty, report the percentage of total claims by that specialty 
-- which are for opioids. Which specialties have a high percentage of opioids?

WITH sum_total AS (SELECT DISTINCT(specialty_description), SUM(total_claim_count) AS total_opioids,
							SUM(total_claim_count)OVER() AS sum_total_claims
					FROM prescriber INNER JOIN prescription USING(npi)
									INNER JOIN drug USING(drug_name)
					WHERE opioid_drug_flag = 'Y' OR long_acting_opioid_drug_flag = 'Y'
					GROUP BY specialty_description, total_claim_count)
SELECT specialty_description, total_opioids, sum_total_claims
	   ,ROUND(total_opioids/sum_total_claims,6) AS percent_total_opioids
FROM sum_total
GROUP BY DISTINCT(specialty_description);

SELECT DISTINCT(specialty_description), SUM(total_claim_count) AS total_opioids,
				SUM(total_claim_count)OVER() AS sum_total_claims
FROM prescriber INNER JOIN prescription USING(npi)
				INNER JOIN drug USING(drug_name)
GROUP BY specialty_description, total_claim_count


-- 3. 
--     a. Which drug (generic_name) had the highest total drug cost?
SELECT generic_name, SUM(total_drug_cost)::money AS total_drug_cost
FROM prescription INNER JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY total_drug_cost DESC;


--     b. Which drug (generic_name) has the hightest total cost per day? 
-- 	 **Bonus: Round your cost per day column to 2 decimal places. 
-- 	   Google ROUND to see how this works.**
-- SELECT generic_name, SUM(total_drug_cost)::money/365.25 AS cost_per_day
-- FROM prescription INNER JOIN drug USING(drug_name)
-- GROUP BY generic_name
-- ORDER BY cost_per_day DESC; 

SELECT generic_name,ROUND(SUM(total_drug_cost)/SUM(total_day_supply),2)::money AS cost_per_day
FROM prescription INNER JOIN drug USING(drug_name)
GROUP BY generic_name
ORDER BY cost_per_day;
--4. 
--     a. For each drug in the drug table, return the drug name and then a column 
-- 	named 'drug_type' which says 'opioid' for drugs which have opioid_drug_flag = 'Y', 
-- 	says 'antibiotic' for those drugs which have antibiotic_drug_flag = 'Y', and says 
-- 	'neither' for all other drugs.

SELECT drug_name,
	CASE WHEN opioid_drug_flag = 'Y' then 'opioid'
		 WHEN antibiotic_drug_flag = 'Y' then 'antibiotic'
	     ELSE 'neither' END AS drug_type
FROM drug
ORDER BY drug_type;

--     b. Building off of the query you wrote for part a, determine whether more was 
-- 	spent (total_drug_cost) on opioids or on antibiotics. Hint: Format the total 
-- 	costs as MONEY for easier comparision.

WITH drug_type AS(SELECT drug_name,
				  CASE WHEN opioid_drug_flag = 'Y' then 'opioid'
		 			   WHEN antibiotic_drug_flag = 'Y' then 'antibiotic'
	     			   ELSE 'neither' END AS drug_type
				  FROM drug
				  ORDER BY drug_type)
SELECT drug_type, SUM(total_drug_cost)::money AS total_cost
FROM prescription INNER JOIN drug_type USING(drug_name)
GROUP BY drug_type
ORDER BY total_cost DESC;



-- 5. 
--     a. How many CBSAs are in Tennessee? **Warning:** The cbsa table contains information for all states, not just Tennessee.
SELECT cbsaname,cbsa
FROM cbsa
WHERE cbsaname ILIKE '%TN%'
ORDER BY cbsaname;

SELECT DISTINCT cbsa, cbsaname
FROM cbsa
WHERE cbsaname LIKE '%TN%';

--     b. Which cbsa has the largest combined population? Which has the smallest? Report the CBSA name and total population.
SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER By total_pop DESC
LIMIT 1;

SELECT cbsaname, SUM(population) AS total_pop
FROM cbsa INNER JOIN population USING(fipscounty)
GROUP BY cbsaname
ORDER By total_pop
LIMIT 1;

--     c. What is the largest (in terms of population) county which is not included in a CBSA? 
--         Report the county name and population.

SELECT county, SUM(population) AS sum_pop
FROM cbsa FULL JOIN fips_county USING(fipscounty)
		  FULL JOIN population USING(fipscounty)
WHERE cbsa IS NULL AND population IS NOT NULL
GROUP BY county, cbsa
ORDER BY sum_pop DESC
LIMIT 1;

-- 6. 
--     a. Find all rows in the prescription table where total_claims is at least 3000.
--        Report the drug_name and the total_claim_count.

SELECT drug_name, total_claim_count
FROM prescription
WHERE total_claim_count >=3000;


--     b. For each instance that you found in part a, add a column that indicates whether the drug is an opioid.
SELECT drug_name, total_claim_count,
	   CASE WHEN opioid_drug_flag = 'Y' then 'opioid'
	   ELSE 'not opioid' END AS drug_type
FROM prescription INNER JOIN drug USING(drug_name)
WHERE total_claim_count >=3000;



--     c. Add another column to you answer from the previous part which gives the prescriber first and last name 
--       associated with each row.

SELECT nppes_provider_first_name AS first_name
	   ,nppes_provider_last_org_name AS last_name
	   ,drug_name, total_claim_count
	   ,CASE WHEN opioid_drug_flag = 'Y' then 'opioid'
	    ELSE 'not opioid' END AS drug_type
FROM prescription INNER JOIN drug USING(drug_name)
				  INNER JOIN prescriber USING(npi)
WHERE total_claim_count >=3000;



-- 7. The goal of this exercise is to generate a full list of all pain management specialists
-- in Nashville and the number of claims they had for each opioid. 
-- **Hint:** The results from all 3 parts will have 637 rows.

--     a. First, create a list of all npi/drug_name combinations for pain management specialists
-- 	(specialty_description = 'Pain Managment') in the city of Nashville (nppes_provider_city = 'NASHVILLE'), 
-- 	where the drug is an opioid (opiod_drug_flag = 'Y'). **Warning:** Double-check your query before running it.
-- 	You will only need to use the prescriber and drug tables since you don't need the claims numbers yet.
SELECT *
FROM prescriber CROSS JOIN drug
WHERE specialty_description = 'Pain Management' 
							AND nppes_provider_city 
							ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y';

--     b. Next, report the number of claims per drug per prescriber. Be sure to include all combinations, whether or 
-- 	not the prescriber had any claims. You should report the npi, the drug name, and the number of claims (total_claim_count).

SELECT prescriber.npi
	   ,drug_name
	   ,total_claim_count
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING(drug_name, npi)
WHERE specialty_description ILIKE 'Pain Management' 
							AND nppes_provider_city 
							ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count DESC;


				
--     c. Finally, if you have not done so already, fill in any missing values for total_claim_count with 0. 
-- 	Hint - Google the COALESCE function.

SELECT prescriber.npi
	   ,drug_name
	   ,COALESCE(total_claim_count, 0)
FROM prescriber CROSS JOIN drug
				LEFT JOIN prescription USING(drug_name, npi)
WHERE specialty_description ILIKE 'Pain Management' 
							AND nppes_provider_city 
							ILIKE 'NASHVILLE' AND opioid_drug_flag = 'Y'
ORDER BY total_claim_count;
		  
		  --BONUS
-- 		  1. How many npi numbers appear in the prescriber table but not in 
			--the prescription table?
SELECT COUNT(prescriber.npi) AS prescriber_npi
FROM prescriber LEFT JOIN prescription USING(npi)
WHERE prescription.npi IS NULL;

-- 2.
--     a. Find the top five drugs (generic_name) prescribed by prescribers with
          --the specialty of Family Practice.
SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
--     b. Find the top five drugs (generic_name) prescribed by prescribers with 
		--the specialty of Cardiology.
SELECT *
FROM prescriber;

SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5;
--     c. Which drugs are in the top five prescribed by Family Practice prescribers
        --and Cardiologists? Combine what you did for parts a and b into a single query 
		--to answer this question.

(SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Family Practice'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5)

UNION ALL

(SELECT generic_name, SUM(total_claim_count) AS total_claims
FROM prescriber INNER JOIN prescription USING(npi)
				LEFT JOIN drug USING(drug_name)
WHERE specialty_description = 'Cardiology'
GROUP BY generic_name
ORDER BY total_claims DESC
LIMIT 5);

-- 3. Your goal in this question is to generate a list of the top prescribers in each of 
--     the major metropolitan areas of Tennessee.
--     a. First, write a query that finds the top 5 prescribers in Nashville in terms of
       --the total number of claims (total_claim_count) across all drugs. Report the npi, 
	   --the total number of claims, and include a column showing the city.
SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;

--     b. Now, report the same for Memphis.

SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5;
    
--     c. Combine your results from a and b, along with the results for Knoxville
         --and Chattanooga.
(SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Nashville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)

UNION ALL
		 
(SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Memphis'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)	 

UNION ALL

(SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Knoxville'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5)

UNION ALL
		 
(SELECT nppes_provider_city, npi, SUM(total_claim_count) AS total_claims 
FROM prescriber INNER JOIN prescription USING(npi)
WHERE nppes_provider_city ILIKE 'Chattanooga'
GROUP BY npi, nppes_provider_city
ORDER BY total_claims DESC
LIMIT 5);


-- 4. Find all counties which had an above-average number of overdose deaths.
	--Report the county name and number of overdose deaths.
SELECT *
FROM overdose_deaths;
		
SELECT *
FROM fips_county;

SELECT AVG(overdose_deaths)
FROM overdose_deaths;

SELECT county, overdose_deaths
FROM fips_county INNER JOIN overdose_deaths
				 ON fips_county.fipscounty::numeric = overdose_deaths.fipscounty
WHERE overdose_deaths>(SELECT AVG(overdose_deaths)
					  FROM overdose_deaths)
ORDER BY overdose_deaths;

--TRYING A DIFFERENT SOLUTION

-- WITH avg_overdose AS(SELECT county, overdose_deaths
-- 	                 ,ROUND(AVG(overdose_deaths)OVER(),2) AS avg_overdose_deaths
-- 					 FROM overdose_deaths INNER JOIN fips_county 
-- 					                      ON fips_county.fipscounty::numeric = overdose_deaths.fipscounty)
-- SELECT overdose_deaths
-- FROM overdose_deaths
-- WHERE overdose_deaths > avg_overdose;
									
									
 --5     a. Write a query that finds the total population of Tennessee.
   --     b. Build off of the query that you wrote in part a to write a query 
		--that returns for each county that county's name, its population, 
	--and the percentage of the total population of Tennessee that is contained in that county.



