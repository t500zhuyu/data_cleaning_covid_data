

select * from PortfolioProject..covid_deaths$
order by 3,4;

--select * from PortfolioProject..Covid_Vaccinations$
--order by 3,4;

/* Select the date that we are going to be using */

select Location, date, total_cases,new_cases,total_deaths,population
from PortfolioProject..covid_deaths$
order by 1,2;

select Location, date, total_cases,total_deaths
from PortfolioProject..covid_deaths$
order by 1,2;

-- Looking at total cases vs total deaths
SELECT
  Location,
  date,
  total_cases,
  total_deaths,
  (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM
  PortfolioProject..covid_deaths$
ORDER BY
  1, 2;

-- Looking cases in a specific country in this
-- case Brazil
SELECT
  Location,
  date,
  total_cases,
  total_deaths,
  (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM
  PortfolioProject..covid_deaths$
where location = 'Brazil'
ORDER BY
  1, 2;
-- now in usa
SELECT
  Location,
  date,
  total_cases,
  total_deaths,
  (CAST(total_deaths AS float) / CAST(total_cases AS float)) * 100 AS DeathPercentage
FROM
  PortfolioProject..covid_deaths$
where location like '%states%'
ORDER BY
  1, 2;

-- looking at total cases vs population
SELECT Location, date, total_cases, population,
  (CAST(total_cases AS float) / CAST(population AS float)) * 100 AS PercentPopulationInfected
FROM
  PortfolioProject..covid_deaths$
where location like '%states%'
and continent is not null
ORDER BY
  1, 2;


-- Countries with highest infection rate compared to population
SELECT
  Location,
  total_cases,
  population,
  Max(CAST(total_cases AS float)) as HighestInfectionCount,
  Max(CAST(total_cases AS float) / CAST(population AS float)) * 100 AS PercentPopulationInfected
FROM
  PortfolioProject..covid_deaths$
GROUP BY
  Location,total_cases, population
ORDER BY PercentPopulationInfected desc;

  -- where location like '%states%'


-- this query show how many total deaths are per country
-- here we exclude continent with statement:
 -- where continent is not null, this according with table information

select location, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_deaths$
where continent is not null
group by location
order by TotalDeathCount desc

-- next query shows total deahts by continent
select continent, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_deaths$
where continent is not null
group by continent
order by TotalDeathCount desc


-- showing continents with he highest death per population
select continent, max(cast(Total_deaths as int)) as TotalDeathCount
from portfolioProject..covid_deaths$
where continent is not null
group by continent
order by TotalDeathCount desc

-- global numbers
SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths AS INT)) AS total_deaths,
  CASE
    WHEN SUM(new_cases) = 0 THEN NULL
    ELSE SUM(CAST(new_deaths AS INT)) / SUM(new_cases) * 100
  END AS deathpercentage
FROM
  portfolioProject..covid_deaths$
WHERE
  continent IS NOT NULL
ORDER BY 1, 2;
--GROUP BY date

-- total at total popuilation vs vaccinations

ALTER TABLE PortfolioProject..Covid_Vaccinations$
ALTER COLUMN new_vaccinations INT;
ALTER TABLE PortfolioProject..Covid_Vaccinations$
ALTER COLUMN new_vaccinations BIGINT;

select dea.continent, dea.location, dea.date, dea.population,vac.new_vaccinations
, sum(convert(int, vac.new_vaccinations)) over (partition by dea.location)
from PortfolioProject..covid_deaths$ dea
join PortfolioProject..Covid_Vaccinations$ vac
	on dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null
order by 1,2,3

SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(convert(int, vac.new_vaccinations)) OVER (PARTITION BY dea.location order by dea.location, dea.date)
FROM
  PortfolioProject..covid_deaths$ dea
  JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL
ORDER BY
  1, 2, 3;


SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
  dea.date) as RollingPeopleVaccinated
--  , (RollingPeopleVaccinated/population)*100
FROM
  PortfolioProject..covid_deaths$ dea
  JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL
ORDER BY
  1, 2, 3;

-- using CTE
with PopvsVac (continent, location, date, population, New_Vaccinations, RollingPeopleVaccinated)
as
(
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,
  dea.date) as RollingPeopleVaccinated
--  , (RollingPeopleVaccinated/population)*100
FROM
  PortfolioProject..covid_deaths$ dea
  JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL
--ORDER BY 2, 3
)
select *, (RollingPeopleVaccinated/Population)*100
from PopvsVac



WITH PopvsVac AS (
  SELECT
    dea.continent,
    dea.location,
    dea.date,
    dea.population,
    vac.new_vaccinations,
    SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
  FROM
    PortfolioProject..covid_deaths$ dea
    JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
  WHERE
    dea.continent IS NOT NULL
)
SELECT
  *,
  (RollingPeopleVaccinated / Population) * 100
FROM
  PopvsVac
ORDER BY
  location,
  date;


  -- temp table

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From PortfolioProject..covid_deaths$ dea
Join PortfolioProject..Covid_Vaccinations$ vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3
Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


DROP TABLE IF EXISTS #PercentPopulationVaccinated;

CREATE TABLE #PercentPopulationVaccinated (
  Continent NVARCHAR(255),
  Location NVARCHAR(255),
  Date DATETIME,
  Population NUMERIC,
  New_vaccinations NUMERIC,
  RollingPeopleVaccinated BIGINT
);

INSERT INTO #PercentPopulationVaccinated
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
  PortfolioProject..covid_deaths$ dea
  JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;

SELECT
  *,
  (RollingPeopleVaccinated / Population) * 100
FROM
  #PercentPopulationVaccinated;

-- creating view to store data for later visual

CREATE VIEW PercentPopulationVaccinated AS
SELECT
  dea.continent,
  dea.location,
  dea.date,
  dea.population,
  vac.new_vaccinations,
  SUM(CONVERT(BIGINT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS RollingPeopleVaccinated
FROM
  PortfolioProject..covid_deaths$ dea
  JOIN PortfolioProject..Covid_Vaccinations$ vac ON dea.location = vac.location AND dea.date = vac.date
WHERE
  dea.continent IS NOT NULL;

select * from PercentPopulationVaccinated