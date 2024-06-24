

SELECT *
FROM PorfolioProject..CovidDeath
WHERE Continent is not null
ORDER BY 3,4

--Select *
--From PorfolioProject..CovidVaccinations
--Order by 3,4

--Select datas

SELECT Location, date, total_cases, new_cases, total_deaths, Population
FROM PorfolioProject..CovidDeath
WHERE Continent is not null
ORDER BY 1,2


--Total cases vs total deaths of percentage wise in U.S
--Provides the likelyhood of dying if you infected as Covid 

SELECT Location, date, total_cases,total_deaths, (CAST(total_deaths AS FLOAT)/CAST(total_cases AS FLOAT))*100 AS 'DeathPercentage'
FROM PorfolioProject..CovidDeath
WHERE Location like '%states%'
	  AND Continent is not null
ORDER BY 1,2


--Total cases vs population of percentage wise in U.S
--Provides the percentage of population that have gotten Covid

SELECT Location, date, Population, total_cases, (CAST(total_cases AS FLOAT)/CAST(Population AS FLOAT))*100 AS 'InfectionPercentage'
FROM PorfolioProject..CovidDeath
WHERE Location like '%states%'
	  AND Continent is not null
ORDER BY 1,2


--Provide the country that has highest infection rate compared to population 
SELECT Location, Population,
	   MAX(CAST(total_cases AS FLOAT)) AS 'HighestInfectionCount',
	   MAX(CAST(total_cases AS FLOAT)) / MAX(CAST(Population AS FLOAT))*100 AS 'PopulationInfectionRate'
FROM PorfolioProject..CovidDeath
WHERE Continent is not null
GROUP BY Location, Population
ORDER BY PopulationInfectionRate desc


--Provide the country with highest death per population
SELECT Location,
	   MAX(CAST(total_deaths AS BIGINT)) AS 'TotalDeathCount'
FROM PorfolioProject..CovidDeath
WHERE Continent is not null
GROUP BY Location
ORDER BY TotalDeathCount desc

--Provide the Continents with highest death count per population
SELECT Continent,
	   MAX(CAST(total_deaths AS BIGINT)) AS 'TotalDeathCount'
	   FROM PorfolioProject..CovidDeath
WHERE Continent is not null
GROUP BY Continent
ORDER BY TotalDeathCount desc

--Provide the Global Number of weekly report
SELECT date, SUM(new_cases) AS total_cases,
	   SUM(CONVERT(BIGINT,new_deaths)) As total_deaths,
	   SUM(CONVERT(BIGINT,new_deaths))/ NULLIF(SUM(new_cases),0)*100 AS 'DeathPercentage'
FROM PorfolioProject..CovidDeath
WHERE Continent is not null
GROUP BY date
ORDER BY 1,2

--Provide the number of the people in the wholrd that are vaccinated

SELECT 
     dea.continent, 
     dea.location, 
     dea.date, 
     dea.population, 
     vac.new_vaccinations,
     SUM(CAST(vac.new_vaccinations AS BIGINT)) OVER (PARTITION BY dea.Location ORDER BY dea.Location, dea.Date) AS PeopleVaccinated
FROM 
     PorfolioProject..CovidDeath dea
JOIN 
     PorfolioProject..CovidVaccinations vac ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE  
     dea.continent IS NOT NULL
ORDER BY 
     2, 3;



--Using CTE to perform Calculation on Partition By in previous query
WITH PopvsVac (Continent, Location, Date, Population, new_vaccination, PeopleVaccinated)
AS
(
SELECT 
     dea.continent, 
     dea.location, 
     dea.date, 
     dea.population, 
     vac.new_vaccinations,
     SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS PeopleVaccinated
FROM 
     PorfolioProject..CovidDeath dea
     JOIN PorfolioProject..CovidVaccinations vac ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE  
     dea.continent IS NOT NULL
)
SELECT *, (PeopleVaccinated/Population)*100
FROM PopvsVac;

-- Create temporary table
CREATE TABLE #PercentPopulationVaccinated
(
    Continent NVARCHAR(255),
    Location NVARCHAR(255),
    Date DATETIME,
    Population NUMERIC,
    New_Vaccinations NUMERIC, 
    PeopleVaccinated NUMERIC
);

-- Insert data into temporary table
INSERT INTO #PercentPopulationVaccinated (Continent, Location, Date, Population, New_Vaccinations, PeopleVaccinated)
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS PeopleVaccinated
FROM 
    PorfolioProject..CovidDeath dea
JOIN 
    PorfolioProject..CovidVaccinations vac ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE  
    dea.continent IS NOT NULL;

-- Select from temporary table with percentage calculation
SELECT 
    *,
    (PeopleVaccinated / NULLIF(Population, 0)) * 100 AS PercentPopulationVaccinated
FROM 
    #PercentPopulationVaccinated;

-- Drop the temporary table after use
DROP TABLE #PercentPopulationVaccinated;


--Creat View for later use of Visualization

Create View PercentPopulationVaccinated as
SELECT 
    dea.continent, 
    dea.location, 
    dea.date, 
    dea.population, 
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.Location ORDER BY dea.Date) AS PeopleVaccinated
FROM 
    PorfolioProject..CovidDeath dea
JOIN 
    PorfolioProject..CovidVaccinations vac ON dea.Location = vac.Location AND dea.Date = vac.Date
WHERE  
    dea.continent IS NOT NULL;


SELECT *
FROM PercentPopulationVaccinated
