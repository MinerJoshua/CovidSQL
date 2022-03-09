SELECT
	*
FROM
	PortfolioProject..CovidVaccinations
ORDER BY
	2,3

SELECT
	*
FROM
	PortfolioProject..CovidDeaths
ORDER BY
	3,4


--Select Data I will be using
SELECT
	Location,
	Date,
	Total_Cases,
	New_Cases,
	Total_Deaths,
	Population
FROM
	PortfolioProject..CovidDeaths
ORDER BY
	1,2


-- Total Cases Vs Total Deaths
--Shows the Likelihood of dying if you contract Covid in Nigeria
SELECT
	Location,
	Date,
	Total_Cases,
	Total_Deaths,
	(total_deaths/total_cases) *100 AS DeathPercentage
FROM
	PortfolioProject..CovidDeaths
WHERE
	Location = 'Nigeria'
ORDER BY
	1,2


-- Looking at Total Cases Vs Population
--Shows the percentage of population that got Covid
SELECT
	Location,
	Date,
	Total_Cases,
	Population,
	(total_cases/population) *100 AS PercentagePopulationInfected
FROM
	PortfolioProject..CovidDeaths
WHERE
	Location = 'Nigeria'
ORDER BY
	1,2


--Looking at Countries with Highest Infection Rate compared to Population
SELECT
	Location,
	Population,
	MAX(total_cases) as HighestInfectedCount,
	MAX((total_cases/population)) *100 AS PercentagePopulationInfected
FROM
	PortfolioProject..CovidDeaths
WHERE
	continent is not NULL --This removes the non country locations like Africa,North America,Low Income,etc.
GROUP BY
	Location,Population
ORDER BY
	PercentagePopulationInfected DESC


--Looking at Countries with Highest Death Count Per Population
SELECT
	Location,
	Population,
	MAX(CAST(total_deaths as float)) as HighestDeathCount,
	MAX(CAST(total_deaths as float)/population)*100 AS PercentagePopulationDeaths
FROM
	PortfolioProject..CovidDeaths
WHERE
	continent is not NULL --This removes the non country locations like Africa,North America,Low Income,etc.
GROUP BY
	Location,Population
ORDER BY
	PercentagePopulationDeaths DESC


--Continents with the highest death count by Population
	--SELECT 
	--	Location,
	--	MAX(CAST(total_deaths as float)) AS TotalLocationDeaths
	--FROM 
	--	PortfolioProject..CovidDeaths
	--WHERE 
	--	continent is  null -- This selects the locations that are continents
	--GROUP BY 
	--	location
	--ORDER BY 
	--	2 DESC

--Using a SubQuery
SELECT 
	Continent,
	SUM(TotalLocationDeaths) AS TotalContinentDeaths --Group the locations by continent and Sum the total deaths
FROM 
	(
	--This Statement gets the Maximum Amount of Total Deaths Per Location
		SELECT Continent,Location, MAX(CAST(total_deaths as float)) AS TotalLocationDeaths
		FROM PortfolioProject..CovidDeaths
		WHERE Continent is not null --This removes the non country locations like Africa,North America,Low Income,etc.
		GROUP BY Continent,location
	) AS LocationDeathCount
GROUP BY
	Continent
ORDER BY
	2 DESC


--GLOBAL NUMBERS
--Daily Death Percentage Worldwide
SELECT
	Date,
	SUM(new_cases) AS TotalCases,
	SUM(CAST(new_deaths as float)) AS TotalDeaths,
	SUM(CAST(new_deaths as float))/SUM(new_cases) * 100 AS DeathPercentage
FROM
	PortfolioProject..CovidDeaths
WHERE
	Continent is not null --This removes the non country locations like Africa,North America,Low Income,etc.
GROUP BY
	Date
ORDER BY
	1,2

--Looking at Total Population vs Vaccinations


-- Using CTE
With 
	PopVsVac
AS
(
	SELECT 
	cDeaths.Date,
	cDeaths.Continent,
	cDeaths.Location,
	Population,
	New_Vaccinations,
	SUM(CAST(new_vaccinations as float)) OVER (Partition by cDeaths.Location Order by cDeaths.location,cDeaths.date) AS RollingPeopleVAccinated
	FROM
		PortfolioProject..CovidDeaths AS cDeaths
	JOIN
		PortfolioProject..CovidVaccinations AS cVaccine
	ON
		cDeaths.iso_code = cVaccine.iso_code
		AND
		cDeaths.date = cVaccine.date
	WHERE
		cDeaths.Continent is not null

)

SELECT
	*,
	(RollingPeopleVAccinated/Population)*100
FROM
	PopVsVac

	
--Using A Temp Table
DROP Table if exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
	Date datetime,
	Continent nvarchar(255),
	Location nvarchar(255),
	Population numeric,
	NewVaccinations numeric,
	RollingPeopleVaccinated numeric
)
INSERT INTO #PercentPopulationVaccinated
	SELECT 
	cDeaths.Date,
	cDeaths.Continent,
	cDeaths.Location,
	Population,
	New_Vaccinations,
	SUM(CAST(new_vaccinations as float)) OVER (Partition by cDeaths.Location Order by cDeaths.location,cDeaths.date) AS RollingPeopleVAccinated
	FROM
		PortfolioProject..CovidDeaths AS cDeaths
	JOIN
		PortfolioProject..CovidVaccinations AS cVaccine
	ON
		cDeaths.iso_code = cVaccine.iso_code
		AND
		cDeaths.date = cVaccine.date
	WHERE
		cDeaths.Continent is not null

SELECT *
FROM #PercentPopulationVaccinated

--Creating Views for Later Visualization
CREATE View TotalContinentDeaths as
SELECT 
	Continent,
	SUM(TotalLocationDeaths) AS TotalContinentDeaths --Group the locations by continent and Sum the total deaths
FROM 
	(
	--This Statement gets the Maximum Amount of Total Deaths Per Location
		SELECT Continent,Location, MAX(CAST(total_deaths as float)) AS TotalLocationDeaths
		FROM PortfolioProject..CovidDeaths
		WHERE Continent is not null --This removes the non country locations like Africa,North America,Low Income,etc.
		GROUP BY Continent,location
	) AS LocationDeathCount
GROUP BY
	Continent
--ORDER BY
--	2 DESC

Select *
FRom TotalContinentDeaths
ORDER BY 2 DESC