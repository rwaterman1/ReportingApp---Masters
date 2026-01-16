sele cb.dlr_code, dlr.dlr_name, cb.cust_no, cust.cus_name, cb.inv_no, ;
	cb.cb_date, cb.cb_amt+cb.tax as cb_amt, cb.paid_amt from jkcbfil cb ;
	inner join jkdlrfil dlr on dlr.dlr_code=cb.dlr_code ;
	inner join jkcusfil cust on cust.cust_no=cb.cust_no ;
	where year(cb.cb_date)=2000 ;
	order by dlr_code, cust_no into cursor cb
use jkcbpay in 0 order inv_no
sele cb
set rela to inv_no into jkcbpay
repo form cbhistory preview