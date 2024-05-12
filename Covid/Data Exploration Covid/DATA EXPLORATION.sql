/*
Covid 19 Data Exploration 

Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types

*/
-- Select useful data

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject.dbo.covidDeaths
order by 1,2


-- total cases vs total deaths
-- we are casting total_deaths as float because while import it imported as nvarchar
-- similar with the total_cases

select location, date, total_cases, total_deaths, (CAST(total_deaths as float)/CAST(total_cases as float))*100 as CanadaDeathPercentage
from PortfolioProject.dbo.covidDeaths
where location like '%canada%'
order by 1,2
-- Results
-- from the looks of it canada has 1.1% chance of deaths due to covid but the data is not updated for the latest (rough estimates)

-- total_cases vs population
-- it shows what percentage of people has gotten covid
select location, date, population, total_cases, (CAST(total_cases as float)/CAST(population as float))*100 as CanadaCovidPercentageInfected
from PortfolioProject.dbo.covidDeaths
where location like '%canada%'
order by 1,2

-- Results
-- 12% of Canada's Population has gotten covid if they were tested, if they have not tested it, that number should vary

-- Country with highest infection rate vs population
select location, population, max(total_cases) as HihestInfectionCountPerCountry, (max(CAST(total_cases as float))/CAST(population as float))*100 as CountryPercentInfected
from PortfolioProject.dbo.covidDeaths
group by location, population
order by CountryPercentInfected desc

-- Results
-- cyprus has the highest percentage per population of people were infected highest

-- country vs highest death count per population
select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.covidDeaths
where continent is not null
group by location
order by TotalDeathCount desc

-- results
-- there are world and high income and upper middle income these are bit of issue since it groups everything regardless
-- there are continents in location
-- to tackle this situation adding 'where continent is not null' to the script

-- same above but for continent
select continent, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.covidDeaths
where continent is not null
group by continent
order by TotalDeathCount desc

-- results
-- the data shows that there is a bit issue, it takes only US but not Canada.

select location, max(cast(total_deaths as int)) as TotalDeathCount
from PortfolioProject.dbo.covidDeaths
where continent is null
group by location
order by TotalDeathCount desc

-- chaning a bit it shows that europe has highest

-- global numbers

select date, sum(new_cases) as TotalCases, sum(cast(new_deaths as int)) as TotalDeaths, 
case
	when sum(new_cases) > 0 then 
		sum(cast(new_deaths as int))/sum(new_cases)*100
	else 
	NUll
END
from PortfolioProject.dbo.covidDeaths
where continent is not null
group by date
order by 1,2

-- reults
-- there are null values that hinder this guy which was handled
-- there are approx 4 days or 5 days before each updates happen

-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, sum( 
	cast(vac.new_vaccinations as float)
) 
over ( 
	partition by dea.location order by dea.location, dea.date
) as RoillingCountPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3

-- results
-- it shows that People were vaccinated at a consistent pace 

-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast (vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
)

Select *,
case
	when Population > 0 then 
		(RollingPeopleVaccinated/Population)*100*100
	else 
	NUll
END
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

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
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated

From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date

Select *, (RollingPeopleVaccinated/Population)*100
From #PercentPopulationVaccinated


-- Creating View to store data for later visualizations
DROP View if exists PercentPopulationVaccinated
Create View PercentPopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(cast(vac.new_vaccinations as float)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
From PortfolioProject..CovidDeaths dea
Join PortfolioProject..CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

select * from PercentPopulationVaccinated