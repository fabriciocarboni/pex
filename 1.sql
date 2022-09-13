
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22046', '1/1/2010', '10');
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22046', '1/2/2010', '12');
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22046', '1/3/2010', '11');
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22043', '1/1/2010', '14');
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22043', '1/2/2010', '8');
INSERT INTO zip_temps (zip_code, measurement_date ,noon_temp)
VALUES ('22043', '1/3/2010', '18');



select 
	tb.zip_code
	, measurement_date 
	, noon_temp 
from (SELECT zip_code
    , AVG(noon_temp) as avg_amt
     from zip_temps
     group by 1) tb
inner join zip_temps zt2
		on tb.zip_code = zt2.zip_code 
where zt2.noon_temp > tb.avg_amt
order by 1 asc;


-- OR using WITH Clause

with avg_zipcode as (
	SELECT zip_code
	, AVG(noon_temp) as avg_amt
	  from zip_temps
	group by 1
) 
select zt.zip_code, zt.measurement_date, noon_temp  from zip_temps zt
inner join avg_zipcode avg_zc on avg_zc.zip_code = zt.zip_code
where zt.noon_temp > avg_zc.avg_amt
order by 1 asc;