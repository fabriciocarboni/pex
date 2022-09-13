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
