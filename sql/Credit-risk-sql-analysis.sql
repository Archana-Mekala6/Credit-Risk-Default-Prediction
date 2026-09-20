
-- 1. DATABASE SETUP & DATA VERIFICATION
create database default_prediction;
use default_prediction;

-- Preview the Loaded dataset
select * 
from default_loan_data
limit 10;

-- checking datatypes
describe default_loan_data;

-- 2. DATA VALIDATION 
-- 2.1 check total records
select count(*) 
from default_loan_data;

-- 2.2 check duplicate_ids
select 
      applicant_id, 
      count(*) as dulicate_count
from default_loan_data 
group by applicant_id
having count(*) > 1;

-- 2.3 check null_values
select
	count(*)-count(cibil_score) as cibil_nulls,
    count(*)-count(monthly_income) as income_nulls,
    count(*)-count(existing_loans_count) as existing_loans_nulls,
    count(*)-count(existing_emi_monthly) as emi_nulls,
    count(*)-count(credit_utilization) as utilization_nulls,
    count(*)-count(credit_inquiries) as inquiries_nulls,
    count(*)-count(late_payments_12m) as late_payments_nulls,
    count(*)-count(loan_amount) as loan_amount_nulls,
    count(*)-count(loan_tenure) as tenure_nulls,
    count(*)-count(default_flag) as target_nulls
from default_loan_data;

-- 2.4 check invalid numeric values 
select * 
from default_loan_data
where monthly_income<=0
      or loan_amount<=0
      or loan_tenure<=0
      or age < 18
      or existing_loans_count <0
      or credit_inquiries <0
      or late_payments_12m <0;

-- 2.5 check for cibil score outside the valid range
select cibil_score
from default_loan_data
where cibil_score<300
     or cibil_score>900;

-- 2.6 Target distribution
select 
     default_flag,
     count(*) as loans
from default_loan_data
group by default_flag;

-- 2.7 check for applicants with no existing loans but a positive EMI
select * 
from default_loan_data
where existing_loans_count=0
  and existing_emi_monthly >0;

-- 2.8 calculate default rate
select 
     count(*) as total_loans,
     sum(default_flag) as defaulted_loans,
     round(100*sum(default_flag)/count(*),2) as default_rate
from default_loan_data;

-- 3.FEAUTE ENGINEERING
alter table default_loan_data
add column dti decimal(10,2),
add column loan_to_income decimal(10,2),
add column cibil_band varchar(20),
add column credit_utilization_band varchar(20),
add column late_payments_band varchar(20),
add column existing_loans_band varchar(20),
add column inquiries_band varchar(20),
add column dti_band varchar(20);

alter table default_loan_data
rename column dti to emi_to_income;

-- 3.1 Calculate Dti 
 update default_loan_data
 set emi_to_income =
       round((existing_emi_monthly/monthly_income)*100,2);

-- 3.2 Calculate loan to income
update default_loan_data
set loan_to_income=
       round(loan_amount/(monthly_income*12),2);
       
-- 3.3 Create Cibil_band
update default_loan_data
set cibil_band=
      case
          when cibil_score is null then 'Missing'
          when cibil_score <600 then 'Poor'
          when cibil_score <700 then 'Fair'
          when cibil_score <750 then 'Good'
          else 'Excellent'
		end;
        
-- 3.4 Create Credit utilizations bands
update default_loan_data
set credit_utilization_band=
       case
           when credit_utilization is null then 'Missing'
           when credit_utilization <30 then 'Low'
           when credit_utilization <50 then 'Moderate'
           when credit_utilization <75 then 'High'
           else 'very High'
        end;
        
-- 3.5 Create late payments band
update default_loan_data
set late_payments_band =
		case
            when late_payments_12m is null then 'Missing'
            when late_payments_12m =0 then 'No Late Payments'
            when late_payments_12m <=2 then 'Low'
            when late_payments_12m <=5 then 'Moderate'
            else 'High'
        end;
        
-- 3.6 create dti band
update default_loan_data 
set dti_band=
         case
             when emi_to_income is null then 'missing'
             when emi_to_income <=10 then 'Very Low'
             when emi_to_income  <=20 then 'Low'
             when emi_to_income <=30 then 'Moderate'
             when emi_to_income <=40 then 'High'
             else 'Very High'
          end;
          
-- 3.7 Create existing loans band          
update default_loan_data
set existing_loans_band=
    case
        when existing_loans_count is null then 'Missing'
		when existing_loans_count =0 then 'None'
		when existing_loans_count <=2 then 'Low'
	    when existing_loans_count <=4 then 'Moderate'
        else 'High'
	end;
    
-- 3.8 Create credit Inquiries band
update default_loan_data
set inquiries_band=
     case
         when credit_inquiries is null then 'Missing'
         when credit_inquiries =0 then 'None'
         when credit_inquiries <= 2 then 'Low'
         when credit_inquiries <=5 then 'Moderate'
         else 'High'
     end;    
-- 3.9 Verify Feature Engineering
select 
      applicant_id,
      emi_to_income,
      dti_band,
      loan_to_income,
      cibil_score,
      cibil_band,
      credit_utilization,
      credit_utilization_band,
      late_payments_12m,
      late_payments_band,
      credit_inquiries,
      inquiries_band,
      existing_loans_count,
      existing_loans_band
 from default_loan_data
 limit 10;
 
-- 4.EXPLORATORY DATA ANALYSIS

-- 4.1 Measure Overall portfolio summary 
select 
     count(*) as total_loans,
     sum(loan_amount) as total_loan_amt,
     sum(default_flag) as defaulted_loans,
     sum(
        case 
            when default_flag =1 then loan_amount
            else 0
		end) as defaulted_loan_amt,
	 round(avg(interest_rate),2) as avg_int_rate,
     round(avg(cibil_score),2) as avg_cibil_score,
     round(avg(emi_to_income),2) as avg_emi_to_income,
     round(avg(default_flag)*100,2) as default_rate
from default_loan_data; 
/*
OUTPUT: 
 total_loans  total_loan_amt  defaulted_loans  defaulted_loan_amt  avg_int_rate  avg_cibil_score  avg_emi_to_income   default_rate
    25000       3961431000        1535             281053000          20.71         615.29              21.35             6.14
*/

-- 4.2 Compare default rates across across cibil risk segment
select 
      cibil_band,
      count(*) as total_loans,
      sum(default_flag) as defaulted_loans,
      round(avg(default_flag)*100,2) as default_rate
from default_loan_data 
group by cibil_band
order by default_rate desc;
/*
OUTPUT:
cibil_band	total_loans	defaulted_loans	default_rate
Poor	       9811	         1311         	13.36
Fair	       12981	     215	         1.66
Good	       1878       	 9	             0.48
Excellent	   330	         0	             0.00
*/
-- 4.3 Compare Default rates across Credit utilization risk band 
select 
      credit_utilization_band,
      count(*) as total_loans,
      sum(default_flag) as defaults,
      round(avg(default_flag)*100,2) as default_rate
from default_loan_data 
group by credit_utilization_band
order by default_rate desc;
/*
OUTPUT:
credit_utilization_band	   total_loans 	defaults	default_rate
very High	                    1236          241           19.50
High	                        7125          732	        10.27
Moderate		                9515          420            4.41
Low		                        7124          142            1.99 
*/

-- 4.4 Compare default rate by Late payments risk bands 
select 
     late_payments_band,
     count(*) as total_loans,
     sum(default_flag) as defaults,
     round(avg(default_flag)*100,2) as default_rate
from default_loan_data 
group by late_payments_band
order by default_rate desc; 
/*
OUTPUT:  
late_payments_band	total_loans	defaults	default_rate
High                    151	      64	       42.38
Moderate	            4498      697	       15.50
Low	                    13941	  679	        4.87
No Late Payments	    6410	  95	        1.48
*/

-- 4.5 Compare default rate across Dti band 
select   
     dti_band,
     count(*) as total_loans,
     sum(default_flag) as defaults,
     round(avg(default_flag)*100,2) as default_rate
from default_loan_data 
group by dti_band 
order by default_rate desc;
/*
OUTPUT:
dti_band    total_loans	  defaults	default_rate
Very High	    643	         153	   23.79
High	        3731	     446	   11.95
missing	        500	          35	   7.00
Moderate	    9191	     604	   6.57
Low	            8013	     262	   3.27
Very Low	    2922	      35	   1.20
 */
 
 -- 4.6 Compare default rate across employment types
 select
       emp_type,
       count(*) as total_loans,
       sum(default_flag) as defaults,
       round(avg(default_flag)*100,2) as default_rate 
from default_loan_data 
group by emp_type
order by default_rate desc;
/*
OUTPUT:
 emp_type	                 total_loans	defaults	default_rate
Business Owner	                3700	       275	        7.43
Salaried - Government	        3806	       255	        6.70
Salaried - Private	           11258	       660	        5.86
Salaried - PSU	                2488	       138	        5.55
Self-Employed Professional	    3748	       207	        5.52
*/

-- 4.7 Analyse default rate across combined  cibil band and loan purposes	
    select
	   cibil_band,
       loan_purpose,
	   count(*) as total_loans,
       sum(default_flag) as defaults,
       round(avg(default_flag)*100,2) as default_rate 
from default_loan_data 
group by cibil_band,loan_purpose
order by default_rate desc;
/*
OUTPUT:
cibil_band	 loan_purpose	        total_loans  defaults  default_rate
Poor	     Debt Consolidation	       996	        146	      14.66
Poor	     Wedding	               1371	        201	      14.66
Poor	     Business Expansion	       767	        102	      13.30
Poor	     Medical Emergency	       1235	        163	      13.20
Poor	     Vehicle Purchase	       1014	        133	      13.12
Poor	     Education	               952	        123	      12.92
Poor	     Personal Expense	       2161	        277	      12.82
Poor	     Home Renovation	       1315	        166       12.62
Fair	     Personal Expense	       2950	        62	      2.10
Fair	     Home Renovation	       1695	        30	      1.77
Fair	     Education	               1268	        22	      1.74
Fair	     Business Expansion	       1064	        18	      1.69
Fair	     Vehicle Purchase	       1243	        20	      1.61
Fair	     Debt Consolidation	       1238	        17	      1.37
Fair	     Wedding	               1796	        24	      1.34
Good	     Business Expansion	       154	        2	      1.30
Fair	     Medical Emergency	       1727	        22	      1.27
Good	     Vehicle Purchase	       185	        2	      1.08
Good	     Personal Expense	       426	        3	      0.70
Good	     Education	               186	        1	      0.54
Good	     Home Renovation	       241	        1	      0.41
Good	     Wedding	               249	        0         0.00
Good	     Debt Consolidation	       199	        0	      0.00
Good	     Medical Emergency	       238	        0	      0.00
*/

-- 4.8 Analyse default rates across combined cibil band and dti band risk segments
with combined_risk as 
  (select 
	  cibil_band,
      dti_band,
	  count(*) as total_loans,
      sum(default_flag) as defaults,
      round(avg(default_flag)*100,2) as default_rate 
  from default_loan_data 
  group by cibil_band,dti_band)
select cibil_band,dti_band,total_loans,defaults,default_rate
from combined_risk 
where total_loans >100
order by default_rate desc;
/*
OUTPUT:
cibil_band	 dti_band	 total_loans  defaults  default_rate
Poor	     Very High	     487	     143	    29.36
Poor	     High	         2165	     407	    18.80
Poor	     missing	     218	     28	        12.84
Poor	     Moderate	     4043	     506	    12.52
Poor	     Low	         2356	     201	    8.53
Fair	     Very High	     153	     10	        6.54
Poor	     Very Low	     542	     26	        4.80
Fair	     High	         1485	     39	        2.63
Fair	     missing	     235	     6	        2.55
Fair	     Moderate	     4631	     96	        2.07
Fair	     Low	         4726	     56	        1.18
Good	     Low	         799	     5	        0.63
Fair	     Very Low	     1751	     8	        0.46
Good	     Moderate	     472	     2          0.42
Good	     Very Low	     484	     1          0.21
Excellent	 Very Low	     145	     0	        0.00
Excellent	 Low	         132	     0	        0.00
*/

-- 4.9 Default rate by cibil band compared with overall default rate
select 
      cibil_band,
      round(avg(default_flag)*100,2) as default_rate,
      round(
            avg(default_flag)*100 - 
            (select avg(default_flag)*100
            from default_loan_data),2) as difference
from default_loan_data
group by cibil_band
order by default_rate desc;  
/*
OUTOUT:
cibil_band	default_rate	difference
Poor	       13.36	       7.22
Fair	        1.66	      -4.48
Good	        0.48	      -5.66
Excellent	    0.00	      -6.14
*/
 
-- 4.10 Rank dti bands by default rate
with dti_default as
    (select 
          dti_band,
          count(*) as total_loans,
          sum(default_flag) as defaults,
          round(avg(default_flag)*100,2) as default_rate
	from default_loan_data
    group by dti_band)
select 
    dti_band,
    total_loans,
    defaults,
    default_rate,
    dense_rank() over (order by default_rate desc) as risk_rank
from dti_default
order by risk_rank;
/* 
OUTPUT:
dti_band   total_loans	defaults	default_rate	risk_rank
Very High	   643	      153	       23.79	        1
High	       3731    	  446	       11.95	        2
missing	       500	       35	        7.00            3
Moderate	   9191	      604	        6.57	        4
Low	           8013	      262	        3.27	        5
Very Low	   2922	       35	        1.20	        6
*/

-- 4.11 highest default rate loan purpose within each employment type
with emp_purpose_risk as (
   select 
        emp_type,
        loan_purpose,
        count(*) as total_loans,
        round(avg(default_flag)*100,2) as default_rate
    from default_loan_data
    group by emp_type,loan_purpose),
ranked as (
    select 
         *,
         row_number() over(partition by emp_type order by default_rate desc) as rank_risk
    from emp_purpose_risk)
select * 
from ranked 
where rank_risk = 1
order by default_rate desc;
/* 
OUTPUT:
 emp_type	                    loan_purpose	     total_loans	default_rate	rank_risk
Business Owner	              Business Expansion	         301	       9.30	            1
Self-Employed Professional	  Debt Consolidation	         367	       8.17	            1
Salaried - Government	      Business Expansion	         286	       7.69         	1
Salaried - PSU	              Debt Consolidation	         224	       7.59	            1
Salaried - Private	          Wedding	                     1554	       6.24	            1
*/

-- 4.12 cumulative share of loans by loan purpose
with purpose_summary as(
   select 
      loan_purpose,
      count(*) as total_loans
   from default_loan_data
   group by loan_purpose)
select 
     loan_purpose,
     total_loans,
     round(
          total_loans*100/
          sum(total_loans) over() ,2) as loan_share,
     round(
           sum(total_loans) over ( order by total_loans desc)*100/
           sum(total_loans) over() , 2) as cummulative_loan_share
 from purpose_summary
 order by total_loans desc;
 /* 
 OUPUT:
loan_purpose	  total_loans	loan_share	cummulative_loan_share
Personal Expense	 5600	       22.40	       22.40
Wedding	             3462	       13.85	       36.25
Home Renovation	     3291	       13.16	       49.41
Medical Emergency	 3239	       12.96	       62.37
Vehicle Purchase	 2475	        9.90	       72.27
Debt Consolidation	 2470	        9.88	       82.15
Education	         2447	        9.79	       91.94
Business Expansion	 2016	        8.06	       100.00
*/

-- creating view
create view pd_risk_default as 
select 
     age,
     city_tier,
     state,
     emp_type,
     vintage_years,
     monthly_income,
     existing_loans_count,
     existing_emi_monthly,
     credit_inquiries,
     loan_amount,
     loan_tenure,
     loan_purpose,
     collateral_provided,
     cibil_score,
     default_flag,
     emi_to_income
from default_loan_data;


select * from pd_risk_default limit 5;

     
     
	
     


 
