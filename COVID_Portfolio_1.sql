

select * from portfolioproject..CovidDeaths where total_deaths > 10000  order by location, date desc;

select  location, date,total_deaths from PortfolioProject..CovidDeaths where total_deaths > 
(select  avg(CAST(total_deaths AS bigint)) from PortfolioProject..CovidDeaths )  group by location, date,total_deaths;

SELECT CONVERT('1', SIGNED);

select  CAST(total_deaths AS int) from PortfolioProject..CovidDeaths;

-- Global Number 

--Where No Death Recorded.
select distinct(location) From PortfolioProject..CovidDeaths where (CAST(total_cases AS bigint))= 0  and date > '01/01/2019'
order by location asc ;


with 
Covid_Death_per 
as (
select  location, date,continent, (CAST(total_cases AS float)) as TotalCases, ISNULL(total_deaths,0) as TotalDeaths
From PortfolioProject..CovidDeaths
) 
select Location, date, TotalDeaths,TotalCases , Cast( (TotalDeaths/TotalCases) As float) *100 as Death_Per
From Covid_Death_per where TotalCases > 10000 and continent is not null order by location desc, Death_Per asc, date; 


-- Cases adding on each Passing day

select date, sum(CAST ( new_cases as float) ) as Totalcases, sum( cast(new_deaths as float)) as Totaldeaths
,(sum( cast(new_deaths as float))/sum( cast(new_cases as bigint))*100) as Death_Per
From PortfolioProject..CovidDeaths
where continent is not null and new_cases !=0
group by date
order by 1,2 asc;

--Total Cases and Total Deaths, Death Percent thoughout the WORLD

select sum(CAST ( new_cases as float) ) as Totalcases, sum( cast(new_deaths as float)) as Totaldeaths
,(sum( cast(new_deaths as float))/sum( cast(new_cases as bigint))*100) as Death_Per
From PortfolioProject..CovidDeaths
where continent is not null and new_cases !=0;


-- Looking for Total Population Vs Vaccinations

select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as bigint))		 Over ( partition by dea.location)
from PortfolioProject..CovidVaccination vac 
inner join PortfolioProject..CovidDeaths dea 
On dea.location=vac.location and dea.date=vac.date
where dea.continent !=''  and dea.location = 'India'
order by 2,3;

--To find New Vaccination data within a Country increase with Date. 

select vac.date, vac.location, Isnull(nullif(vac.new_vaccinations,''),0) Vaccination_today,  sum( cast(Isnull(nullif(vac.new_vaccinations,''),0) as float)) 
over (partition by vac.location order by vac.location, vac.date ROWS UNBOUNDED PRECEDING) Vaccination_Till_Date 
from PortfolioProject..CovidVaccination vac where vac.continent != '' and vac.location = 'India'
order by vac.location;

-- Use CTE for using Rolling up data
WITH 
PopVsVac (date,location,population,  Vaccination_today, Vaccination_Till_Date) 
As 
(select vac.date, vac.location,vac.population, Isnull(nullif(vac.new_vaccinations,''),0) Vaccination_today,  sum( cast(Isnull(nullif(vac.new_vaccinations,''),0) as float)) 
over (partition by vac.location order by vac.location, vac.date ROWS UNBOUNDED PRECEDING) Vaccination_Till_Date 
from PortfolioProject..CovidVaccination vac where vac.continent != '' 

) select *, (Vaccination_Till_Date/ convert(float  ,population) )*100 vacc_Pop_Per 
from PopVsVac where convert(float  ,population) != 0 
and Vaccination_Till_Date > 0 and 
(Vaccination_Till_Date/ convert(float  ,population) )*100  > 50
order by location ;


-- Implementing it with Temp Table

create table #Per_Population_Vaccinated
(
	continent nvarchar(500),
	location nvarchar(500),
	date datetime,
	population float,
	Vaccination_today numeric,
	Vaccination_till_date numeric
	)


insert into #Per_Population_Vaccinated 
  select vac.continent, vac.location,vac.date, cast( vac.population as float) as Population, 
  cast (Isnull(nullif(vac.new_vaccinations,''),0)  as numeric ) as Vaccination_today,
 sum( cast(Isnull(nullif(vac.new_vaccinations,''),0) as numeric)) 
over (partition by vac.location order by vac.location, vac.date ROWS UNBOUNDED PRECEDING) Vaccination_Till_Date 
from PortfolioProject..CovidVaccination vac
Inner Join PortfolioProject..CovidDeaths dea
ON dea.location=vac.location and 
	dea.date = vac.date
where vac.continent != '' 


select *, (Vaccination_Till_Date/ population )*100 vacc_Pop_Per 
from #Per_Population_Vaccinated where population != 0 
and Vaccination_Till_Date > 0  
order by location ;

-- Creating Views to store Data for Later

create view Per_Population_Vaccinated 
as 
  select vac.continent, vac.location,vac.date, cast( vac.population as float) as Population, 
  cast (Isnull(nullif(vac.new_vaccinations,''),0)  as numeric ) as Vaccination_today,
 sum( cast(Isnull(nullif(vac.new_vaccinations,''),0) as numeric)) 
over (partition by vac.location order by vac.location, vac.date ROWS UNBOUNDED PRECEDING) Vaccination_Till_Date 
from PortfolioProject..CovidVaccination vac
Inner Join PortfolioProject..CovidDeaths dea
ON dea.location=vac.location and 
	dea.date = vac.date
where vac.continent != '' ;

