# Data Engineer Challenge

**1. SQL**

Write a query that would return the rows representing days that were hotter than average for the zip code, given a table named ZIP_TEMPS with a primary key {ZIP_CODE, MEASUREMENT_DATE} and a third non-key value NOON_TEMP. NOON_TEMP is the temperature being compared. Example of data follows.
```ZIP_CODE (PK)	MEASUREMENT_DATE (PK)	NOON_TEMP
22046	1/1/2010	10
22046	1/2/2010	12
22046	1/3/2010	11
22043	1/1/2010	14
22043	1/2/2010	8
22043	1/3/2010	18
Given the data above, this should be the output.
ZIP_CODE (PK)	MEASUREMENT_DATE (PK)	NOON_TEMP
22043	1/3/2010	18
22043	1/1/2010	14
22046	1/2/2010	12
```

**2. Procedural Logic and pl/pgsql**

Write a pl/pgsql function that:
- Uses only numeric datatypes and functions—no VARCHAR, CHAR, TEXT, etc.
- In other words, character/string functions such as REVERSE, LEFT, RIGHT, SUBSTR, etc are not to be used in your solution.
- Accepts a INTEGER parameter
- If the provided value is less than zero the function should error out with a good error message
- If the provided value is zero the function should return successfully but report back to the client a message indicating zero was passed
- Returns a INTEGER value that has the digits from the input parameter in reverse order. If the input value ends in one or more zeroes those zeroes will not appear in the returned numeric value, since they would be leading zeroes
```
create or replace function my_function(_number integer) returns integer
as
$$
declare
	my_variable integer;
    rev integer:=0;

  begin
   if _number < 0 then
   		raise exception 'The number % entered is less than zero', _number
   		using hint = 'Please inform a number grater than zero';
   elseif _number = 0 then
   		raise notice 'The number entered is % ', _number;
   		my_variable = 0;
   		return my_variable;
   else
		while(_number > 0)
		loop
			rev = rev * 10 + mod(_number,10);
			_number = _number/10;
		end loop;
		raise notice 'Reverse of number is %', rev;
		return rev;
   		
   end if;
   return _number;
end;
$$ language plpgsql;

SELECT * FROM my_function(000012345000);
```

**3. Scripting/maintenance**

Assuming we have 100M rows like above (or from exercise 3) and there are more tables in our (production) DB linked to this one and there are also triggers and online users/processes. You need to delete only records related to one zipcode or a group of zipcodes. A straightforward “delete” times out after 10 minutes. How to approach the task differently? Write sample code.

**A.** One approach would be creating a new table with the data without the zicode we want to exclude. Once it's done, reindex the table and rename it to the original name.

Other solution could be creating a query where I can select only the zipcodes I want to delete, given the fact that zip_codes and date are PK and then create a temporary table only with these values.

Some considerations:
- I would run in a time slot where we have less concurrence and load in DB. Also if possible/make sense send a communication to the users regarding the maintenance period;
- If allowed turn off job batch processes;
- Regardless the approach chosen, if possible I would test in a dev environment and measure the results if space/costs is not be a problem;


Approach 1

Create a new table for production without the zipcodes we want to exclude. In doing that I would like to discuss this approach with the team and architect because we could create this new table and creating some partitions in zipcode,measurement_date in case of any cleanup needed in the future. Also we would need to re-index the table as the original.

```
CREATE TABLE NEW_ZIP_CODES AS (SELECT * 
                              FROM ZIP_CODES
                              WHERE ZIP_CODE NOT BETWEEN (group of zipcodes)
                              AND MEASUREMENT_DATE NOT BETWEEN (DATE1 AND DATE2))

```

Approach 2

Create a table with the data we need to delete.

```
CREATE records_to_delete as 
    SELECT * FROM zip_codes 
    WHERE zip_code IN (range of zipcodes)
    AND measurement_date IN (range of dates);

DELETE zip_codes zc 
inner join records_to_delete rc
where zc.zip_code in (SELECT zip_code FROM records_to_delete where rc.zip_code = zc.zip_code)
```

**4.** **Unique index**

Describe the output of the following commands and explain.
```
create table abc ( a bigint, b bigint, c text);
create unique index abc_ux on abc (a,b);

insert into abc values (1,2,‘c’);
insert into abc values (1,null,‘c’);
insert into abc values (2,null,‘d’);
insert into abc values (2,null,‘d’);

select * from abc;
```
**A.** PostgreSQL treats NULL as distinct value, therefore, we can have multiple NULL values in a column with a UNIQUE index. This allow me for example insert multiple times the second line and on.
```
Updated Rows	4
Query	create table abc ( a bigint, b bigint, c text);
	create unique index abc_ux on abc (a,b);
	insert into abc values (1,2,'c');
	insert into abc values (1,null,'c');
	insert into abc values (2,null,'d');
	insert into abc values (2,null,'d')
Finish time	Tue Sep 13 14:12:05 WEST 2022
```
![alt](https://i.ibb.co/cJGhskL/abc-table.png)

However, if we create the same table setting column a,b not null, it won't allow us to insert duplicated data:
```
Updated Rows	1
Query	create table abcd ( a bigint not null, b bigint not null, c text);
	create unique index abcd_ux on abc (a,b);
	insert into abcd values (1,2,'c')
Finish time	Tue Sep 13 14:15:17 WEST 2022

insert into abcd values (1,null,'c');

SQL Error [23502]: ERROR: null value in column "b" of relation "abcd" violates not-null constraint
  Detail: Failing row contains (1, null, c).
```
![alt](https://i.ibb.co/CnRP1Tj/abcd-table.png)


**5. Production**

You wrote a complex query that scans multiple tables utilizing union and grouping, and it runs fine in development and staging environments which has a full prod copy. However, when you tried it first in real production it timed out. You decided to rerun it almost immediately and it successfully finished in less than a minute. How this can be explained?

**A.** As far as I understand it can be query cache. The database must bring most recent result or part of it to the memory. Also but I'm not sure because I do not understand the details of the database engine, it could be dirty reads, which means that if there were some running transaction and the commit was not performed yet my select could be "freeze" until the current transaction commit is done.