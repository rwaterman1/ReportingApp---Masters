clos all
clea all
set dele on

rptName = "RNO_Fran_Leads"
curPath = "\\jkfradb\fr_acct\jk_rno\"
fDate = gomonth(date(),-24)
lDate = date()

sele id, createdate, status, fname, lname, email, city, state, hphone, leadsource, heardfrom ;
	from curPath + "franleads" ;
where between(createdate,fDate,lDate) ;
and status = "Active" and empty(solddate) and "@" $ email ;
into cursor tmpData

sele tmpData
copy to "i:\tmp\" + rptName type xls

clos all