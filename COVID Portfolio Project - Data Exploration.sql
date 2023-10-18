--COVID SQL Data Cleaning – Portfolio Project

--Changed data type for the date column to datetime
ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN date datetime

--Changed datatypes of total_cases and total_deaths from varchar to numeric to calculate %death rate:

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_cases INT

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_cases numeric

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_deaths INT

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN total_deaths numeric

--Calculating total cases VS total deaths
SELECT DISTINCT location, date, total_deaths,total_cases,(total_deaths/NULLIF(total_cases,0)*100) AS DeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
ORDER BY 1,2 DESC

--So, there were false results in Death Percentage due to lower total_cases than total deaths, 237 rows.
SELECT DISTINCT location, date, total_deaths,total_cases,(total_deaths/NULLIF(total_cases,0)*100) AS DeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
WHERE DeathPercentage>100 
ORDER BY 1,2 DESC

DELETE FROM [dbo].[CovidDeaths]
WHERE DeathPercentage>100


--In Egypt:
SELECT DISTINCT location, date, total_deaths,total_cases,(total_deaths/NULLIF(total_cases,0)*100) AS EgyptDeathPercentage
FROM PortfolioProjects.dbo.CovidDeaths
WHERE location LIKE 'egypt'
ORDER BY 2 DESC

--Therefore, as of 27/9/2023, every COVID patient has a 4.8% chance of dying.

--Calculate the percentage of population who are COVID positive in Egypt:

SELECT location, date,total_cases,population,(total_cases/population)*100 AS PercentageCovidPostv
FROM PortfolioProjects..CovidDeaths
WHERE location = 'Egypt'
ORDER BY 1,2


--Query the Countries with highest infection rates VS population:

SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX(total_cases/population)*100 AS PercentageInfected
FROM PortfolioProjects..CovidDeaths
GROUP BY location, population
ORDER BY PercentageInfected DESC

--Create view to calculate percentage, for further visualization:

CREATE VIEW GlobalPercentageInfected AS
SELECT location,population,MAX(total_cases) AS HighestInfectionCount,MAX(total_cases/population)*100 AS PercentageInfected
FROM PortfolioProjects..CovidDeaths
GROUP BY location, population


--Query the Countries with highest death rates VS population:

SELECT continent,location,MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent != ''
GROUP BY location,continent
ORDER BY 3 DESC

--Query the total death count by continent:

SELECT location,MAX(total_deaths) AS TotalDeathCount
FROM PortfolioProjects..CovidDeaths
WHERE continent = '' AND location NOT LIKE '%income%' 
GROUP BY location
ORDER BY 2 DESC

--Calculate the global death rate:

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_cases INT

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_cases numeric

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_deaths INT

ALTER TABLE [dbo].[CovidDeaths]
ALTER COLUMN new_deaths numeric

SELECT date,SUM(new_cases) AS total_cases,SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS GlobalDeathPercentage
FROM PortfolioProjects..CovidDeaths
GROUP BY date
ORDER BY date

--Create view to calculate percentage, for further visualization:

CREATE VIEW GlobalDeathPercentage AS
SELECT date,SUM(new_cases) AS total_cases,SUM(new_deaths) AS total_deaths, SUM(new_deaths)/SUM(NULLIF(new_cases,0))*100 AS WorldDeathPercentage
FROM PortfolioProjects..CovidDeaths
GROUP BY date

SELECT *
FROM GlobalDeathPercentage

--Join CovidDeaths Table with CovidVaccinations Table:
SELECT *
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

--Calculate the Percentage of Population who were vaccinated:

--So, we calculate total people vaccinated then put into a CTE table to calculate the percentage of people vaccinated VS population

ALTER TABLE [dbo].[CovidVaccinations]
ALTER COLUMN new_vaccinations int

ALTER TABLE [dbo].[CovidVaccinations]
ALTER COLUMN new_vaccinations numeric

SELECT dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations,
SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.continent != '' AND dea.location NOT LIKE '%income%' 
ORDER BY 2,3


--Creat CTE table:
WITH VaccVsPop (Continent,location,date,population,new_vaccinations,rollingpeoplevaccinated) AS
	(	
		SELECT dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations,
		SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rollingpeoplevaccinated
		FROM PortfolioProjects..CovidDeaths dea
		JOIN PortfolioProjects..CovidVaccinations vac
		ON dea.location = vac.location
		AND dea.date = vac.date
		WHERE dea.continent != '' AND dea.location NOT LIKE '%income%' 
	)

	SELECT *,(rollingpeoplevaccinated/population)*100 AS PercentageVaccinated
	FROM VaccVsPop
	ORDER BY PercentageVaccinated DESC


--Another approach can be by creating a temp table:
CREATE TABLE #PercentagePopVaccinated
	(
		continent varchar(255),location varchar(255),date datetime,population numeric,
		new_vaccinations numeric,rollingpeoplevaccinated numeric
	)

INSERT INTO #PercentagePopVaccinated
SELECT dea.continent,dea.location,dea.date,dea.population,vac.new_vaccinations,SUM(vac.new_vaccinations) OVER (PARTITION BY dea.location 
ORDER BY dea.location,dea.date) AS RollingPeopleVaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date

SELECT *,(RollingPeopleVaccinated/Population)*100 AS PercentageVaccinated
FROM #PercentagePopVaccinated
ORDER BY PercentageVaccinated DESC

ALTER TABLE [dbo].[CovidVaccinations]
ALTER COLUMN [people_fully_vaccinated] bigint

ALTER TABLE [dbo].[CovidVaccinations]
ALTER COLUMN [people_fully_vaccinated] numeric

--Calculate percentage of population in Egypt who recieved the vaccinations:
--Checking data:

SELECT dea.location,dea.date,dea.population,vac.total_vaccinations,vac.people_vaccinated,vac.people_fully_vaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.location = 'Egypt' AND vac.total_vaccinations!=0
ORDER BY date

--Create view to calculate percentage to use for visualization:

CREATE VIEW PercentagePopulVaccEgy AS
SELECT dea.location,dea.date,dea.population,vac.total_vaccinations,vac.people_vaccinated,vac.people_fully_vaccinated,
(vac.total_vaccinations/dea.population)*100 AS PercentagePopVaccinated
FROM PortfolioProjects..CovidDeaths dea
JOIN PortfolioProjects..CovidVaccinations vac
ON dea.location = vac.location
AND dea.date = vac.date
WHERE dea.location = 'Egypt' AND vac.total_vaccinations!=0


--Create view to calculate percentage to use for visualization:

SELECT location,date,people_vaccinated,people_fully_vaccinated, total_vaccinations, SUM(total_vaccinations)
FROM PortfolioProjects..CovidVaccinations
WHERE continent != ''
GROUP BY location,date,total_vaccinations,people_vaccinated,people_fully_vaccinated


CREATE VIEW totalvacc AS
SELECT location,date, total_vaccinations, SUM(total_vaccinations) AS totalvacc
FROM PortfolioProjects..CovidVaccinations
WHERE continent != ''
GROUP BY location,date,total_vaccinations





