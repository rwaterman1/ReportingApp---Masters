<%@ Language=VBScript %>
<%option explicit%>
<!--#include file="../systemlib/pageinit.asp"-->
<%

dim oConn,oRs,sql,sql2,x,y,noRecords
dim mth,yr,franNo,franName


dim gtime,pageNo
dim aryRptData,aryRecord,arySections
dim catTable,leaseTable,dlrTrxTable,cusTrxTable
dim royalty,acctFeePercent,plantype,address,datesign,business
dim franPayment,franPaymentCnt,secPayment,secPaymentCnt,adCur
dim gstTax,pstTax,gstDed_Ad,BpAdmin1,BpAdmin2,BtSale1
dim NumBeeps,BeepCost,NumBeeps2,BeepCost2
dim aryTmp(31)						' tmp array used to fill aryRptData
dim aryTmp2(31)						' tmp array hold main page data
dim minRoyAmt						' KMC 05/06/2015
pageNo = 0

for x = 0 to 30			' initialize the tmp array...
	aryTmp(x) = 0
next

const MAIN_PAGE		   = 0	
const CUST_TRXS        = 1
const CONTRACT_BILLING = 2
const LEASE_TRX		   = 3
const SUPPLY_TRX       = 4
const SPE_MISC_DEDUCT  = 5
const REG_MISC_DEDUCT  = 6
const CHARGE_BACKS     = 7

'report data array index constants
const GROUP		 = 0
const COMPANY_NO = 1
const DLR_CODE   = 2
const CUST_NO	 = 3
const CUS_NAME   = 4
const TRX_TYPE	 = 5
const INV_NO     = 6
const DESCR		 = 7
const QUANTITY	 = 8
const TRX_AMT	 = 9
const TRX_TAX	 = 10
const TRX_CLASS	 = 11
const TRX_ROY	 = 12
const CUST_ROY	 = 13
const CONT_BILL	 = 14
const CUR_MONTH  = 15
const ADTL_B_FRN = 16
const CLIENT_SUP = 17
const ADTL_B_OFC = 18
const FF_NBR	 = 19
const FF_PYMNT	 = 20
const CUST_STAT  = 21
const LEASE_NO	 = 22
const MAKE		 = 23
const MODEL		 = 24
const SERIAL	 = 25
const DATE_SIGN  = 26
const PYMNT_NUM  = 27
const PST_TAX	 = 28


const TCB		    = 0
const ACT_B         = 1
const AD_B_FRAN     = 2
const C_SUPPLIES	= 3
const AD_B_OFC      = 4
const C_SALES_TAX	= 5
const AD_B_OFC_COMM = 6
const ROY_TOT		= 7
const FFS			= 8
const FRAN_SUP		= 9
const REG_MSC		= 10
const LEASES		= 11
const C_TAX_FRAN	= 12
const CB			= 13
const SPEC_MSC		= 14
const ROY_ADJ		= 15
const AB_TAX		= 16
const AB_F_TAX		= 17
const AB_O_TAX		= 18
const CS_TAX		= 19
const CS_PST		= 20
const LEASE_PST		= 21
const LEASE_GST		= 22
const GST_DED		= 23
const PST_DED		= 24
const REG_MSC_GST	= 25
const SPC_MSC_GST	= 26
const F_SUP_GST		= 27
const F_SUP_PST		= 28
const CB_GST		= 29
const CB_PST		= 30

set oConn		= getRegionDBConnection

'set oConn		= getDBConnection("\\jknt02\fr_acct\jk_ast")

mth				= Request("txtMonth")
yr				= Request("txtYear")   
franNo			= ucase(trim(Request("txtfranno")))   
gtime			= replace(formatdatetime(now,3),"AM","am")
gtime			= replace(gtime,"PM","pm")
royalty			= 0

' set the tables that will be used to calc a report
catTable    = "cur_cat"
leaseTable  = "cur_leas"
dlrTrxTable = "jkdlrtrx"
cusTrxTable = "jkcustrx"

acctFeePercent = 0

' these are the fields needed from the cur_fran or rpt_fran tables
sql = "select pct_flag,add_pct,ded_ad,ad_cur,num_beeps,beep_cost,num_beeps2,beep_cost2 "		
sql = sql & ",business,bp_admin1,bp_admin2,bt_sale1,fran_pymnt,pymnt_bill,pymnt_totl,take_note,"

'--> KMC 05/06/2015
'sql = sql & "business,sec_pymnt,sec_note,sec_pybill,sec_pytotl,ad_cur"	
sql = sql & "business,sec_pymnt,sec_note,sec_pybill,sec_pytotl,ad_cur,min_roy"	


if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",gst_tax,pst_tax"	
end if

' determine what tables the data will be extracted from...
noRecords = true
sql2 =  " from cur_fran "
sql2 = sql2 & "where dlr_code = '"&franNo&"' "
sql2 = sql2 & "and month  = "&mth
sql2 = sql2 & " and year  = "&yr
sql2 = sql & sql2


set oRs = getRecordset(sql2,oConn)
if oRs.State=1 then
	if not oRs.EOF then		
		noRecords=false					
	end if	
end if

if norecords then
	' if no records were found in previous query, 
	' close the recordset and lets try the history files
	oRs.close
	
	noRecords=true
	
	' extract data from history tables
	catTable    = "rpt_cat"
	leaseTable  = "rpt_leas"
	dlrTrxTable = "dlrtrxhs"			
	cusTrxTable = "custrxhs"
	
	sql2 = " from rpt_fran "	
	sql2 = sql2 & "where dlr_code = '" & franNo & "'"
	sql2 = sql2 & "and month  = "&mth
	sql2 = sql2 & " and year  = "&yr	
	sql2 = sql & sql2
	set oRs = getRecordset(sql2,oConn)
	if oRs.State=1 then
		if not oRs.EOF then				
			noRecords=false			
		end if	
	end if
end if

' no data available... no need to continue...
if noRecords then
	doheader "Franchisee Report","",""
	Response.Write "No record found.<br><br>"
	dofooter
	Response.End
else
	' get the data needed from the previous recordset then
	' close the recordset...
	if trim(oRs("pct_flag")) = "Y" then
		acctFeePercent = oRs("add_pct")
		acctFeePercent = cdbl(acctFeePercent)/100
	end if	
	if trim(oRs("take_note")) = "Y" and cdbl(oRs("pymnt_bill")) > 0 then
		franPaymentCnt =  oRs("pymnt_bill") & " of " & oRs("pymnt_totl")
		franPayment = oRs("fran_pymnt")
	end if
	if trim(oRs("sec_note")) = "Y" and cdbl(oRs("sec_pybill")) > 0 then
		secPaymentCnt =  oRs("sec_pybill") & " of " & oRs("sec_pytotl")
		secPayment  = oRs("sec_pymnt") 
	end if
	adCur     = formatnumber(cdbl(oRs("ad_cur"))/100,4)	
	business  = formatnumber(cdbl(oRs("business"))/100,4)	
	BpAdmin1  = oRs("bp_admin1")
	BpAdmin2  = oRs("bp_admin2")
	BtSale1   = oRs("bt_sale1")
	NumBeeps  = oRs("num_beeps")
	BeepCost  = oRs("beep_cost")
	NumBeeps2 = oRs("num_beeps2")
	BeepCost2 = oRs("beep_cost2")	

	'KMC 05/06/2015
	minRoyAmt = cdbl(oRs("min_roy"))
	'-->
			
	if getRegionalSetting(cCOUNTRY) = "Canada" then			
		gstTax       = oRs("gst_tax")
		pstTax       = oRs("pst_tax")
		gstDed_Ad    = oRs("ded_ad")		
	end if
	oRs.close
end if

' get franchisee information...
sql = "select dlr_name,plantype,dlr_addr,dlr_city,dlr_state,dlr_zip,date_sign from jkdlrfil "
sql = sql & "where dlr_code  = '"&franNo&"'"
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then
		franName = trim(oRs("dlr_name"))
		plantype = trim(oRs("plantype"))
		address  = trim(oRs("dlr_addr"))&"<br>"&trim(oRs("dlr_city"))&" "&trim(oRs("dlr_state"))&"  "&trim(oRs("dlr_zip"))
		dateSign = oRs("date_sign")
	end if
	oRs.close
end if

' get royalty
sql = "select max(royalty) "
sql = sql & "from " &  catTable
sql = sql & " where bill_mon  = "&mth
sql = sql & " and bill_year  = "&yr
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then
		royalty = cdbl(oRs(0))
	end if
	oRs.close
end if

'===========================
'  Customer Transactions
'===========================
sql = "select distinct "&CUST_TRXS&" as group,c.cus_name,x.company_no"
sql = sql & ",iif(len(alltrim(x.apply_fran))=6,x.apply_fran,x.dlr_code) as dlr_code"
sql = sql & ",x.cust_no,x.bill_mon,x.bill_year,x.descr,x.inv_no,x.trx_amt,x.trx_tax"
sql = sql & ",x.trx_type,x.trx_class,x.royalty as trx_roy "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",x.pst_tax"
end if
if royalty > 0 then
	' New method of setting customers royalty percentage.	
	sql = sql & ",t.royalty as cust_roy "
	sql = sql & "from "&cusTrxTable&" x "
	sql = sql & "inner join "&catTable&" t on x.cust_no = t.cust_no "
	sql = sql & "inner join jkcusfil c on x.cust_no = c.cust_no "
	sql = sql & "where x.bill_mon = "&mth&" and x.bill_year = "&yr
	sql = sql & " and t.bill_mon = "&mth&" and t.bill_year = "&yr 	
	sql = sql & " and t.dlr_code = iif(len(alltrim(x.apply_fran))=6,x.apply_fran,x.dlr_code) "
else
	' Old method of setting customers royalty percentage.	
	sql = sql & ",c.royalty as cust_roy "
	sql = sql & "from "&cusTrxTable&" x "
	sql = sql & "inner join jkcusfil c on x.cust_no = c.cust_no "
	sql = sql & "where x.bill_mon = "&mth&" and x.bill_year = "&yr
	sql = sql & " and x.dlr_code = c.dlr_code "	
end if
sql = sql & "and iif(len(alltrim(x.apply_fran))=6,x.apply_fran,x.dlr_code)= '"&franNo&"' "
sql = sql & "and x.onReport=.T. "
sql = sql & "order by x.dlr_code, x.cust_no, x.inv_no "
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs,CUST_TRXS
		arySections = arySections & CUST_TRXS & ","
	end if
	oRs.close
end if



'===========================
'  Customer Account Totals
'===========================
sql = "select "&CONTRACT_BILLING&" as group,c.cus_name,"
sql = sql & "t.company_no,t.bill_mon as cur_month,t.bill_year as cur_year,t.dlr_code,t.cust_no,t.cont_bill"
sql = sql & ",t.cur_month,t.adtl_b_frn,t.Client_sup,t.adtl_b_ofc,t.ff_nbr,t.ff_pymnt,t.cust_stat"
sql = sql & ",t.ff_seq, t.royalty, 'I' as trx_type "
sql = sql & "from "&catTable&" t "
sql = sql & "inner join jkcusfil c on t.cust_no = c.cust_no and t.dlr_code = c.dlr_code "
sql = sql & "where t.bill_mon="&mth&" and t.bill_year="&yr
sql = sql & " and t.dlr_code = '"&franNo&"'"
sql = sql & "union "
sql = sql & "select 2 as GROUP,c.cus_name,x.company_no,x.bill_mon as cur_month,x.bill_year as cur_year, "
sql = sql & "x.apply_fran as dlr_code,x.cust_no, 000000.00 as cont_bill, "
sql = sql & "sum(iif(x.trx_class$'BI',iif(x.trx_type='I',x.trx_amt,x.trx_amt*-1),000000.00)) as cur_month, "
sql = sql & "sum(iif(x.trx_class$'E',iif(x.trx_type='I',x.trx_amt,x.trx_amt*-1),000000.00)) as adtl_b_frn, "
sql = sql & "sum(iif(x.trx_class$'S',iif(x.trx_type='I',x.trx_amt,x.trx_amt*-1),000000.00)) as Client_sup, "
sql = sql & "sum(iif(x.trx_class$'O',iif(x.trx_type='I',x.trx_amt,x.trx_amt*-1),000000.00)) as adtl_b_ofc, "
sql = sql & "'                              ' as ff_nbr, "
sql = sql & "000000.00 as ff_pymnt, "
sql = sql & "'1X-'+x.dlr_code as cust_stat, "
sql = sql & "00 as ff_seq,x.Royalty, 'I' as trx_type "
sql = sql & "from "&cusTrxTable&" x "
sql = sql & "inner join jkcusfil c on x.cust_no=c.cust_no "
sql = sql & "where len(alltrim(x.apply_fran)) = 6 "
sql = sql & "and x.bill_mon="&mth&" and x.bill_year="&yr
sql = sql & " and x.apply_fran = '"&franNo&"' "
sql = sql & "and x.onReport=.T. "
sql = sql & "group by 6, 7 "
sql = sql & "order by 6, 7 "
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, CONTRACT_BILLING		
		arySections = arySections & CONTRACT_BILLING & ","
	end if
	oRs.close
end if

'===========================
' Lease Transactions
'===========================
sql = "select "&LEASE_TRX&" as group, 'I' AS trx_type, company_no, dlr_code, bill_mon, bill_year, lease_no, descripton AS DESCR,"
sql = sql & "make, model, serial, date_sign, pymnt_num, pymnt_amt AS trx_amt, pymnt_tax AS trx_tax "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",pymnt_pst as pst_tax "
end if
sql = sql & "from "&leaseTable
sql = sql & " where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and dlr_code = '"&franNo&"' "
sql = sql & "order by date_sign"
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, LEASE_TRX
		arySections = arySections & LEASE_TRX & ","
	end if
	oRs.close
end if

'===========================
' Lease Transactions from jkdlrtrx file
'===========================
sql = "select "&LEASE_TRX&" as group, company_no,dlr_code,bill_mon,bill_year,descr"
sql = sql & ",trx_amt,trx_tax,quantity,trx_class,trx_type "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",pst_tax "
end if
sql = sql & "from "&dlrTrxTable
sql = sql & " where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and dlr_code = '"&franNo&"' "
sql = sql & " and trx_class $ ('LE')"
sql = sql & "and onReport=.t."
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, LEASE_TRX
		arySections = arySections & LEASE_TRX & ","
	end if
	oRs.close
end if


'===========================
' Supply Transactions (&& KMC 06/12/2006 - To Include type "U" - Uniforms - per request from KSC and OK'd by Jill B.)
'===========================
sql = "select "&SUPPLY_TRX&" as group, company_no, dlr_code, bill_mon, bill_year, DESCR, trx_amt, trx_tax,"
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & "pst_tax,"
end if
sql = sql & "quantity, trx_class, trx_type "
sql = sql & "from "&dlrTrxTable
sql = sql & " where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and dlr_code = '"&franNo&"'"
sql = sql & " and trx_class $ ('S')"
sql = sql & " and onReport=.T."
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, SUPPLY_TRX
		arySections = arySections & SUPPLY_TRX & ","
	end if
	oRs.close
end if


'===========================
' Regular  Misc Transactions
'===========================
sql = "select "&REG_MISC_DEDUCT&" as group,company_no,dlr_code,bill_mon,bill_year,"
sql = sql & "descr,trx_amt,trx_tax,quantity,trx_class,trx_type "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",pst_tax "
end if
sql = sql & "from "&dlrTrxTable
sql = sql & " where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and dlr_code = '"&franNo&"'"
sql = sql & " and trx_class $ ('ADHFNRTO') "
sql = sql & "and onReport=.T."
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, REG_MISC_DEDUCT
		arySections = arySections & REG_MISC_DEDUCT & ","
	end if
	oRs.close
end if


'===========================
' Special Misc Transactions
'===========================
sql = "select "&SPE_MISC_DEDUCT&" as group,company_no,dlr_code,bill_mon,bill_year,"
sql = sql & "descr,trx_amt,trx_tax,quantity,trx_class,trx_type "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",pst_tax "
end if
sql = sql & "from "&dlrTrxTable
sql = sql & " where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and dlr_code = '"&franNo&"'"
sql = sql & " and trx_class $ ('BJMPQXGZ') "
sql = sql & "and onReport=.T."
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, SPE_MISC_DEDUCT
		arySections = arySections & SPE_MISC_DEDUCT & ","
	end if
	oRs.close
end if

'===========================
' Charge Backs
'===========================
sql = "select "&CHARGE_BACKS&" as group, d.company_no, d.dlr_code, cus_name, bill_mon, bill_year,"
sql = sql & "descr, trx_amt, trx_tax,trx_class, trx_type "
if getRegionalSetting(cCOUNTRY) = "Canada" then
	sql = sql & ",pst_tax " 
end if
sql = sql & "from "&dlrTrxTable&" d "
sql = sql & "left join jkcusfil on substr(d.DESCR,23,6)=jkcusfil.cust_no "
sql = sql & "and d.dlr_code=jkcusfil.dlr_code "
sql = sql & "where bill_mon="&mth&" and bill_year="&yr
sql = sql & " and d.dlr_code = '"&franNo&"'"
sql = sql & "and trx_class $ ('C') "
sql = sql & "and d.onReport=.T."
set oRs = getRecordset(sql,oConn)
if oRs.state = 1 then
	if not oRs.eof then	
		insRecordsIntoArray oRs, CHARGE_BACKS
		arySections = arySections & CHARGE_BACKS & ","
	end if
	oRs.close
end if

' no sections were set to display then no data was found
if arySections = "" then
	doheader "Franchisee Report","",""
	Response.Write "<br><font class='confirm'>No record found.</font><br><br>"
	dofooter
else
	
	doPage MAIN_PAGE
	Response.Write "<p class='franrptPageBreak'></p>"
	
	aryRptData = split(aryRptData,":")
	arySections = split(arySections,",")
	for x = lbound(arySections) to ubound(arySections) - 1
		doPage arySections(x)	
		if ubound(arySections) - 1 > x then
			Response.Write "<p class='franrptPageBreak'></p>"
		end if
	next
end if

Response.End

'=================================
function doPage(pGrp)
	dim lTitle,laryTmp
	if pGrp = MAIN_PAGE then
		doPageHeader ""

		'--> KMC 07/13/2009
		'doFranchiseHeader franName & "<br>" & address,"P","8/4/2006"
		doFranchiseHeader franName & "<br>" & address, plantype, datesign
		'-->
			
		doMainPageBody	
		doMainFooter
	else
		select case cint(pGrp)
			case CUST_TRXS
				lTitle = "Customer Transactions"		
			case LEASE_TRX
				lTitle = "Leases"
			case CONTRACT_BILLING
				lTitle = "Customer Account Totals"
			case CHARGE_BACKS
				lTitle = "Charge Back Transactions"
			case SPE_MISC_DEDUCT
				lTitle = "Special Miscellenous Transactions"		
			case REG_MISC_DEDUCT
				lTitle = "Miscellenous Transactions"		
			case SUPPLY_TRX
				lTitle = "Supply Transactions"
		end select
		doPageHeader lTitle

		'--> KMC 07/13/2009
		'doFranchiseHeader franName,"P","8/4/2006"
		doFranchiseHeader franName, plantype, datesign
		'-->

		doFieldHeader pGrp,lTitle
		doWriteDetail pGrp,laryTmp
		doRptFooter pGrp,laryTmp
	end if
end function
'=================================
function doMainPageBody
	dim lb,lSubTotal,lRegDeduct,lBusiProtect,lSpeDeduct,lTotMonRevenue,lBPAdmin,lTotalDeduct
	dim lAccountingFee
	lSubTotal      = formatnumber(aryTmp2(ACT_B)+aryTmp2(AD_B_FRAN)+aryTmp2(C_SUPPLIES)+aryTmp2(AD_B_OFC),2)		
	lTotMonRevenue = aryTmp2(ACT_B)+aryTmp2(AD_B_FRAN)+aryTmp2(C_SUPPLIES)+aryTmp2(AD_B_OFC)+aryTmp2(C_SALES_TAX)	
	lAccountingFee = round((cdbl(lSubTotal)*cdbl(acctFeePercent)),2)
	lRegDeduct     = aryTmp2(ROY_TOT)+lAccountingFee+cdbl(franPayment)+cdbl(secPayment)
	lRegDeduct     = lRegDeduct+cdbl(aryTmp2(FFS))+cdbl(aryTmp2(FRAN_SUP))+cdbl(aryTmp2(REG_MSC))+aryTmp2(AD_B_OFC_COMM)
	lRegDeduct	   = round(lRegDeduct,2)
	lBusiProtect   = formatnumber((aryTmp2(ACT_B)+aryTmp2(AD_B_FRAN)+aryTmp2(AD_B_OFC))*business,2)	
	lBPAdmin = 0
	if business <> 0 then
		if (lSubTotal-aryTmp2(C_SUPPLIES))> 0 then
			if (lSubTotal-aryTmp2(C_SUPPLIES))<= cdbl(BtSale1) then
				lBPAdmin = BpAdmin1
			else
				lBPAdmin = BpAdmin2
			end if
		end if
	end if
	lSpeDeduct     = (round(lSubTotal*cdbl(adCur),2))+aryTmp2(LEASES)+cdbl(lBusiProtect)+cdbl(lBPAdmin)+aryTmp2(C_SALES_TAX)
	lSpeDeduct     = lSpeDeduct+(cdbl(NumBeeps)*cdbl(BeepCost))+(cdbl(NumBeeps2)*cdbl(BeepCost2))+aryTmp2(SPEC_MSC)
	lSpeDeduct     = lSpeDeduct+aryTmp2(CB)
	lSpeDeduct	   = round(lSpeDeduct,2)
	lTotalDeduct   = round(lSpeDeduct+lRegDeduct,2)
	lb = "<table border='0' width='100%' cellpadding='0' cellspacing='0' class='franRptText'>"
	lb = lb & "<tr>"
	lb = lb & "<td colspan='2' width='70%'>Total Contract Billing</td>"
	lb = lb & "<td align='right'>"&formatnumber(aryTmp2(TCB),2)&"</td>"
	lb = lb & "<td></td>"
	lb = lb & "<td></td>"
	lb = lb & "</tr>"
	lb = lb & "<tr><td colspan='3' nowrap><hr class='franrptHR'></td></tr>"
	Response.Write lb
	'***  CONTRACT BILLING BREAKDOWN ***
	doMainPageRow "Actual Billing",formatnumber(aryTmp2(ACT_B),2),"",""
	doMainPageRow "Additional Billing By Franchisee",formatnumber(aryTmp2(AD_B_FRAN),2),"",""
	doMainPageRow "Client Supplies",formatnumber(aryTmp2(C_SUPPLIES),2),"",""
	doMainPageRow "Addtional Billing By Office",formatnumber(aryTmp2(AD_B_OFC),2),"",""
	doMainPageRow "Subtotal","",lSubTotal,""
	doMainPageRow "Client Sales Tax","",formatnumber(aryTmp2(C_SALES_TAX),2),""
	doMainPageRow "Total Monthly Revenue","","",formatnumber(lTotMonRevenue,2)
	lb = "<tr><td colspan='5'>&nbsp;</td></tr>"
	lb = lb & "<tr><td colspan='5' width='70%'>Franchisee Deductions</td></tr>"
	lb = lb & "<tr><td colspan='3' nowrap><hr class='franrptHR'></td></tr>"
	Response.Write lb
	'***  REGULAR DEDUCTIONS ***
	doMainPageRow "Royalty",formatnumber(aryTmp2(ROY_TOT),2),"",""
	doMainPageRow "Business Support Fee",formatnumber(lAccountingFee,2),"",""
	doMainPageRow "Addtional Billing By Office Comm",formatnumber(aryTmp2(AD_B_OFC_COMM),2),"",""
	doMainPageRow "Franchise Note Payment&nbsp;&nbsp;&nbsp;"&franPaymentCnt,formatnumber(franPayment,2),"",""
	doMainPageRow "Franchise Note Payment #2&nbsp;&nbsp;&nbsp;"&secPaymentCnt,formatnumber(secPayment,2),"",""
	doMainPageRow "Finders Fees (See Customer Account)",formatnumber(aryTmp2(FFS),2),"",""
	doMainPageRow "Franchisee Supplies",formatnumber(aryTmp2(FRAN_SUP),2),"",""
	doMainPageRow "Regular Miscellaneous",formatnumber(aryTmp2(REG_MSC),2),"",""
	doMainPageRow "Subtotal - Regular Deductions","",formatnumber(lRegDeduct,2),""
	lb = "<tr><td colspan='5'>&nbsp;</td></tr>"
	Response.Write lb
	'***  SPECIAL DEDUCTIONS ***
	doMainPageRow "Advertising Fee",formatnumber(lSubTotal*adCur,2),"",""
	doMainPageRow "Total Leases",formatnumber(aryTmp2(LEASES),2),"",""
	doMainPageRow "Business Protection Plan",formatnumber(lBusiProtect,2),"",""
	doMainPageRow "BPP Admin Fee",formatnumber(lBPAdmin,2),"",""
	doMainPageRow "Client Sales Tax",formatnumber(aryTmp2(C_SALES_TAX),2),"",""
	doMainPageRow "Charge Backs",formatnumber(aryTmp2(CB),2),"",""
	doMainPageRow "Pagers",formatnumber(cdbl(NumBeeps)*cdbl(BeepCost),2),"",""
	doMainPageRow "Pagers2",formatnumber(cdbl(NumBeeps2)*cdbl(BeepCost2),2),"",""
	doMainPageRow "Special Miscellaneous",formatnumber(aryTmp2(SPEC_MSC),2),"",""
	doMainPageRow "SubTotal - Special Deductions","",formatnumber(lSpeDeduct,2),""
	doMainPageRow "Total Deductions","","",formatnumber(lTotalDeduct,2)
	lb = "<tr><td colspan='5'>&nbsp;</td></tr>"
	lb = lb & "<td colspan='2' width='70%'>Due To Franchisee</td>"	
	lb = lb & "<td></td>"
	lb = lb & "<td></td>"	
	lb = lb & "<td align='right'>"
	lb = lb & formatnumber(lTotMonRevenue-lTotalDeduct,2)
	lb = lb & "</td>"
	lb = lb & "</tr>"
	lb = lb & "<tr><td colspan='3' nowrap><hr class='franrptHR'></td></tr>"
	Response.Write lb
	lb = "</table>"
	Response.Write lb
end function
'=================================
function doMainFooter()
	dim lb
	lb = "<table border='0'cellpadding='0' cellspacing='3' class='franRptText' width='100%'>"
	lb = lb & "<tr>"
	lb = lb & "<td width='55px' align='center'>Date Paid</td>"	
	lb = lb & "<td style='border-bottom:solid 1pt black'>&nbsp;</td>"
	lb = lb & "<td width='55px' align='center'>Check #</td>"	
	lb = lb & "<td style='border-bottom:solid 1pt black'>&nbsp;</td>"
	lb = lb & "<td width='55px' align='center'>Date Paid</td>"	
	lb = lb & "<td style='border-bottom:solid 1pt black'>&nbsp;</td>"
	lb = lb & "<td width='55px' align='center'>Check #</td>"	
	lb = lb & "<td style='border-bottom:solid 1pt black'>&nbsp;</td>"
	lb = lb & "</tr>"
	lb = lb & "</table>"
	lb = lb & "<table border='0' width='100%' cellpadding='0' cellspacing='3' class='franRptText'>"
	lb = lb & "<tr>"
	lb = lb & "<td width='25px' align='center'>Notes</td>"	
	lb = lb & "<td style='border-bottom:solid 1pt black' colspan='8'>&nbsp;</td>"
	lb = lb & "</tr>"
	lb = lb & "<tr>"
	lb = lb & "<td style='border-bottom:solid 1pt black' colspan='9'>&nbsp;</td>"
	lb = lb & "</tr>"
	lb = lb & "<tr>"
	lb = lb & "<td style='border-bottom:solid 1pt black' colspan='9'>&nbsp;</td>"
	lb = lb & "</tr>"
	lb = lb & "<tr>"
	lb = lb & "<td style='border-bottom:solid 1pt black' colspan='9'>&nbsp;</td>"
	lb = lb & "</tr>"
	lb = lb & "</table>"
	Response.Write lb
end function
'=================================
function doMainPageRow(pCell1,pCell2,pCell3,pCell4)
	dim lb
	lb = "<tr>"
	lb = lb & "<td width='7px'></td>"
	lb = lb & "<td >"&pCell1&"</td>"
	lb = lb & "<td width='150px' align='right'>"&pCell2&"</td>"
	lb = lb & "<td width='150px' align='right'>"&pCell3&"</td>"
	lb = lb & "<td width='150px' align='right'>"&pCell4&"</td>"
	lb = lb & "</tr>"
	Response.Write lb
end function
'=================================
function doPageHeader(pTitle)
	dim lb
	pageNo = pageNo + 1
	lb = "<table class='franRptTable' border='0' align='center' cellPadding='2' cellSpacing='0'>"
	lb = lb & "<tr>"
	lb = lb & "<td rowspan='5' valign='top'><img src='../images/jktop.gif'></td>"
	lb = lb & "<td width='33%' align='center'>FRANCHISE REPORT</td>"
	lb = lb & "<td width='33%' align='right' nowrap>"&FormatDateTime(date,1)&"</td>"
	lb = lb & "</tr>"   
	lb = lb & "<tr>"	
	lb = lb & "<td width='33%' align='center'>"&trim(Request.Cookies(SESSION_STATE)(COOKIE_REGION_PROFILE_NAME))&"</td>"
	lb = lb & "<td align='right'>Time:&nbsp;"&gtime&"</td>"
	lb = lb & "</tr>"	
	lb = lb & "<tr>"	
	lb = lb & "<td align='center' nowrap>BUSINESS FOR THE MONTH OF&nbsp;"&monthname(mth)&" "&yr&"</td>"
	lb = lb & "<td align='right'>page:&nbsp;"&pageNo&"</td>"
	lb = lb & "</tr>"

	if pageNo=1 then
		lb = lb & "<tr>"
		lb = lb & "<td align='center' nowrap>! ! ! Accuracy of this Web App re-print should be verified with book copy ! ! !</td>"
		lb = lb & "</tr>"
	end if

	lb = lb & "<tr>"
	lb = lb & "<td width='33%' align='center'>"&pTitle&"</td>"
	lb = lb & "<td align='right'></td>"
	lb = lb & "</tr>"
	lb = lb & "<tr><td colspan='3'>&nbsp;</td></tr>"
	lb = lb & "<tr><td colspan='3'>"	
	lb = lb & "</td></tr>"	
	lb = lb & "</table>"
	Response.Write lb
end function
'=====================================================
function doFranchiseHeader(pFranInfo,pPlanType,pDateSign)
	dim lb		
	lb = "<table border='0' cellpadding='0' cellspacing='0' class='franRptText'>"
	lb = lb & "<tr><td colspan='3'>Franchisee</td></tr>"
	lb = lb & "<tr class='row2'>"
	lb = lb & "<td width='100px'>Code</td>"
	lb = lb & "<td colspan='2'>Name</td>"
	lb = lb & "</tr>"
	lb = lb & "<tr>"
	lb = lb & "<td valign='top'>"&franNo&"</td>"
	lb = lb & "<td valign='top' width='55%'>"&pFranInfo&"</td>"
	lb = lb & "<td valign='top' width='33%'>"
	if pPlanType <> "" then		
		lb = lb & "Plan Type:&nbsp;" & pPlanType
	end if
	if pDateSign <> "&nbsp;" then		
		lb = lb & "<br>Date Signed:&nbsp;" & pDateSign
	end if
	lb = lb & "</td>"
	lb = lb & "</tr>"
	lb = lb & "</table>"	
	lb = lb & "<br>"
	Response.Write lb
end function
'=====================================================
function doFieldHeader(pGrp,pTitle)
	dim lb
	lb = "<table border='0' cellspacing='0' class='franRptTablesmtext'>"	
	lb = lb & "<tr><td colspan='11' nowrap>"&pTitle&"</td></tr>"
	lb = lb & "<tr><td colspan='11' nowrap><hr class='franrptHR'></td></tr>"
	lb = lb & "<tr>"
	select case cint(pGrp)
		case CUST_TRXS			
			lb = lb & "<td colspan='2' nowrap>Customer</td>"
			lb = lb & "<td nowrap>I/C</td>"
			lb = lb & "<td  align='center' nowrap>Invoice</td>"
			lb = lb & "<td nowrap>Description</td>"
			lb = lb & "<td align='right'>Fee</td>"
			lb = lb & "<td align='right'>Tax</td>"
			lb = lb & "<td align='right'>Total</td>"
		case CONTRACT_BILLING
			lb = lb & "<td colspan='2' nowrap>Customer</td>"
			lb = lb & "<td align='right' nowrap>Contract<br>Billing</td>"
			lb = lb & "<td align='right' nowrap>Current<br>Month</td>"
			lb = lb & "<td align='right' nowrap>Addtl Bill<br>Franchisee</td>"
			lb = lb & "<td align='right' nowrap>Client<br>Supplies</td>"
			lb = lb & "<td align='right' nowrap>Addtl Bill<br>Office</td>"
			lb = lb & "<td align='right' nowrap>Total</td>"
			lb = lb & "<td align='right' nowrap>Finders<br>Fee Nbr</td>"
			lb = lb & "<td align='right' nowrap>Finders<br>Fee</td>"
		case LEASE_TRX
			lb = lb & "<td align='center' nowrap>Lease Date</td>"
			lb = lb & "<td align='center' nowrap>Lease No.</td>"
			lb = lb & "<td align='left' nowrap>Description & Serial Number</td>"			
			lb = lb & "<td align='center' nowrap>Payment #</td>"
			lb = lb & "<td align='center' nowrap>Amount</td>"
			lb = lb & "<td align='center' nowrap>Tax</td>"
			lb = lb & "<td align='center' nowrap>Total</td>"		
		case SUPPLY_TRX
			lb = lb & "<td nowrap>Description</td>"
			lb = lb & "<td width='50px' align='center' nowrap>Quantity</td>"
			lb = lb & "<td align='right' nowrap>Unit Cost</td>"
			lb = lb & "<td align='right' nowrap>Extended</td>"
			lb = lb & "<td align='right' nowrap>Tax</td>"
			lb = lb & "<td align='right' nowrap>Total Amt</td>"
		case SPE_MISC_DEDUCT
			lb = lb & "<td nowrap>Type</td>"
			lb = lb & "<td align='left' nowrap>Description</td>"
			lb = lb & "<td width='100px' align='right' nowrap>Trx Amt</td>"
			lb = lb & "<td width='100px' align='right' nowrap>Tax</td>"
			lb = lb & "<td width='100px' align='right' nowrap>Total Amt</td>"
		case REG_MISC_DEDUCT
			lb = lb & "<td nowrap>Description</td>"
			lb = lb & "<td width='100px' align='center' nowrap>Quantity</td>"
			lb = lb & "<td align='center' nowrap>Unit Cost</td>"
			lb = lb & "<td align='center' nowrap>Tax</td>"
			lb = lb & "<td align='center' nowrap>Total Amt</td>"
		
		case CHARGE_BACKS
			lb = lb & "<td nowrap>Description</td>"
			lb = lb & "<td align='center' nowrap>Trx Amt.</td>"
			lb = lb & "<td align='center' nowrap>Tax</td>"
			lb = lb & "<td align='center' nowrap>Total Amt.</td>"
		
	end select
	lb = lb & "<tr><td colspan='11' nowrap><hr class='franrptHR'></td></tr>"
	Response.Write lb
end function
'=====================================================
function doWriteDetail(pGrp,pTotals)
	
	dim laryRecord,ltotalRow,lb,lmulti
	
	redim laryTmp(29) ' redim variable to store group totals
	for y = lbound(aryRptData) to ubound(aryRptData)-1 	
		aryRecord = split(aryRptData(y),"|")
		lmulti = 1
		if cstr(aryRecord(TRX_TYPE)) = "C" then
			lmulti = -1
		end if
		select case cint(pGrp)
			case CUST_TRXS	
				if cint(pGrp) = cint(aryRecord(0)) then 			
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					lb = lb & aryRecord(CUST_NO)
					lb = lb & "</td>"
					lb = lb & "<td nowrap>"		
					lb = lb & aryRecord(CUS_NAME)
					lb = lb & "</td>"
					lb = lb & "<td align='center' nowrap>"		
					lb = lb & aryRecord(TRX_TYPE)
					lb = lb & "</td>"
					lb = lb & "<td align='center' nowrap>"		
					lb = lb & aryRecord(INV_NO)
					lb = lb & "</td>"
					lb = lb & "<td nowrap>"		
					lb = lb & aryRecord(DESCR)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX)))*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "</tr>"
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+(cdbl(aryRecord(TRX_AMT))*lmulti)
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					' CONT_BILL used as holding place for total....
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX)))*lmulti
				end if
			case LEASE_TRX				
				if cint(pGrp) = cint(aryRecord(0)) then 
					lb = "<tr>"
					lb = lb & "<td align='center' nowrap>"
					lb = lb & aryRecord(DATE_SIGN)
					lb = lb & "</td>"
					lb = lb & "<td align='center' nowrap>"		
					lb = lb & aryRecord(LEASE_NO)
					lb = lb & "</td>"
					lb = lb & "<td align='left' nowrap>"							
					lb = lb & aryRecord(DESCR)  & "&nbsp;&nbsp;&nbsp;&nbsp;"
					lb = lb & aryRecord(SERIAL)  
					lb = lb & "</td>"
					lb = lb & "<td align='center' nowrap>"		
					lb = lb & aryRecord(PYMNT_NUM)
					lb = lb & "</td>"				
					lb = lb & "<td align='right' nowrap>"
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX)))*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "</tr>"	
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+(cdbl(aryRecord(TRX_AMT))*lmulti)
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+((cdbl(aryRecord(TRX_TAX))+cdbl(aryRecord(TRX_AMT)))*lmulti)					
				end if
			case CONTRACT_BILLING			
				if cint(pGrp) = cint(aryRecord(0)) then 					
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					lb = lb & aryRecord(CUST_NO)
					lb = lb & "</td>"
					lb = lb & "<td nowrap>"		
					lb = lb & aryRecord(CUS_NAME)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					if len(trim(aryRecord(cust_stat)))>0 then
						lb = lb & aryRecord(CUST_STAT)
					else
						lb = lb & formatnumber(aryRecord(CONT_BILL)*lmulti,2)
					end if
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(CUR_MONTH)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(ADTL_B_FRN)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(CLIENT_SUP)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(ADTL_B_OFC)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(CUR_MONTH))+cdbl(aryRecord(ADTL_B_FRN))+cdbl(aryRecord(CLIENT_SUP))+cdbl(aryRecord(ADTL_B_OFC)))*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"
					if trim(aryRecord(FF_NBR)) <> "" then		
						lb = lb & aryRecord(FF_NBR)
					else
						lb = lb & "None"
					end if
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(FF_PYMNT),2)
					lb = lb & "</td>"
					lb = lb & "</tr>"
					Response.Write lb
					' MODEL used as holding place for total....
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(CONT_BILL))*lmulti)
					laryTmp(CUR_MONTH)=laryTmp(CUR_MONTH)+(cdbl(aryRecord(CUR_MONTH))*lmulti)
					laryTmp(ADTL_B_FRN)=laryTmp(ADTL_B_FRN)+(cdbl(aryRecord(ADTL_B_FRN))*lmulti)
					laryTmp(CLIENT_SUP)=laryTmp(CLIENT_SUP)+(cdbl(aryRecord(CLIENT_SUP))*lmulti)
					laryTmp(ADTL_B_OFC)=laryTmp(ADTL_B_OFC)+(cdbl(aryRecord(ADTL_B_OFC))*lmulti)
					laryTmp(MODEL)=laryTmp(MODEL)+(cdbl(aryRecord(CUR_MONTH))+cdbl(aryRecord(ADTL_B_FRN))*lmulti)
					laryTmp(MODEL)=laryTmp(MODEL)+(cdbl(aryRecord(CLIENT_SUP))+cdbl(aryRecord(ADTL_B_OFC))*lmulti)					
					laryTmp(FF_PYMNT)=laryTmp(FF_PYMNT)+(cdbl(aryRecord(FF_PYMNT))*lmulti)
				end if	
			case CHARGE_BACKS
			
				if cint(pGrp) = cint(aryRecord(0)) then 
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					if aryRecord(cus_name) = NULL then
						lb = lb & aryRecord(DESCR)
					else
						lb = lb  & left(aryRecord(descr),28)+" ("+trim(aryRecord(cus_name))+")  "+trim(right(aryRecord(descr),26))
					end if
					lb = lb & "</td>"					
					lb = lb & "<td align='right' nowrap>"
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX))*lmulti),2)
					lb = lb & "</td>"
					lb = lb & "</tr>"	
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+(cdbl(aryRecord(TRX_AMT))*lmulti)
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_TAX))+cdbl(aryRecord(TRX_AMT))*lmulti)
				end if	
				
			case REG_MISC_DEDUCT
				
				if cint(pGrp) = cint(aryRecord(0)) then 
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					lb = lb & aryRecord(DESCR)
					lb = lb & "</td>"					
					lb = lb & "<td align='right' nowrap>"
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX))*lmulti),2)
					lb = lb & "</td>"
					lb = lb & "</tr>"	
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+(cdbl(aryRecord(TRX_AMT))*lmulti)
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_TAX))+cdbl(aryRecord(TRX_AMT))*lmulti)
				end if
				
			case SPE_MISC_DEDUCT	
				
				if cint(pGrp) = cint(aryRecord(0)) then 
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					lb = lb & getTrxClass(aryRecord(TRX_CLASS))
					lb = lb & "</td>"					
					lb = lb & "<td nowrap>"
					lb = lb & aryRecord(DESCR)
					lb = lb & "</td>"					
					lb = lb & "<td align='right' nowrap>"
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX))*lmulti),2)
					lb = lb & "</td>"
					lb = lb & "</tr>"	
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+(cdbl(aryRecord(TRX_AMT))*lmulti)
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_TAX))+cdbl(aryRecord(TRX_AMT))*lmulti)
				end if
		
			case SUPPLY_TRX	
			
				if cint(pGrp) = cint(aryRecord(0)) then 
					lb = "<tr>"
					lb = lb & "<td nowrap>"
					lb = lb & aryRecord(DESCR)
					lb = lb & "</td>"					
					lb = lb & "<td align='center' nowrap>"
					lb = lb & aryRecord(QUANTITY)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_AMT)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((aryRecord(QUANTITY)*aryRecord(TRX_AMT)*lmulti),2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber(aryRecord(TRX_TAX)*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "<td align='right' nowrap>"		
					lb = lb & formatnumber((cdbl(aryRecord(TRX_AMT))+cdbl(aryRecord(TRX_TAX)))*lmulti,2)
					lb = lb & "</td>"
					lb = lb & "</tr>"	
					Response.Write lb
					laryTmp(TRX_AMT)=laryTmp(TRX_AMT)+((aryRecord(QUANTITY)*aryRecord(TRX_AMT))*lmulti) ' extended price
					laryTmp(TRX_TAX)=laryTmp(TRX_TAX)+(cdbl(aryRecord(TRX_TAX))*lmulti)
					
					'--> KMC 07/09/2008
					'laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_TAX)) + (aryRecord(QUANTITY)*cdbl(aryRecord(TRX_AMT)))*lmulti)
					laryTmp(CONT_BILL)=laryTmp(CONT_BILL)+(cdbl(aryRecord(TRX_TAX)) + (aryRecord(QUANTITY)*cdbl(aryRecord(TRX_AMT))))*lmulti
					'-->
				end if	
			
		end select
		
	next
	
	pTotals = laryTmp
	
end function
'================================
function doRptFooter(pGrp,paryTmp)
	dim lb
	lb = "<tr><td colspan='11' nowrap><hr class='franrptHR'></td></tr>"	
	lb = lb & "<tr>"
	select case cint(pGrp) 
		case CUST_TRXS			
			lb = lb & "<td colspan='5' nowrap>Totals For This Franchisee</td>"
			lb = lb & "<td nowrap width='65px' align='right'>"&formatnumber(paryTmp(TRX_AMT),2)&"</td>"
			lb = lb & "<td nowrap width='65px' align='right'>"&formatnumber(paryTmp(TRX_TAX),2)&"</td>"
			lb = lb & "<td nowrap width='65px' align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"
		case CONTRACT_BILLING		
			lb = lb & "<td colspan='2' nowrap>Totals For This Franchisee</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CUR_MONTH),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(ADTL_B_FRN),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CLIENT_SUP),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(ADTL_B_OFC),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(MODEL),2)&"</td>"
			lb = lb & "<td nowrap align='right'></td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(FF_PYMNT),2)&"</td>"
		case LEASE_TRX
			lb = lb & "<td  colspan='4'nowrap>Totals Leases</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_AMT),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_TAX),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"			
		case CHARGE_BACKS
			lb = lb & "<td nowrap>Totals Charge Backs</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_AMT),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_TAX),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"
		case REG_MISC_DEDUCT
		
		case SPE_MISC_DEDUCT
			lb = lb & "<td nowrap colspan='2'>Totals Special</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_AMT),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_TAX),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"
		
		
		case SUPPLY_TRX
			lb = lb & "<td colspan='3' nowrap>Totals Supplies</td>"			
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_AMT),2)&"</td>"
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(TRX_tax),2)&"</td>" ' extended price
			lb = lb & "<td nowrap align='right'>"&formatnumber(paryTmp(CONT_BILL),2)&"</td>"
		
	end select	
	lb = lb & "</tr>"
	lb = lb & "</table>"	
	Response.Write lb
end function
'================================
function insRecordsIntoArray(poRs,pType)
	dim y,idx,ltmp
	do until poRs.eof or not Response.IsClientConnected
		for y = 0 to poRs.fields.count - 1
			idx = getIndex(ucase(poRs.Fields(y).name))
			if isnumeric(idx) then 
				if isnull(poRs.Fields(y).value) then				
					aryTmp(idx) = 0
				else
					aryTmp(idx) = replace(poRs.Fields(y).value,":"," - ")
				end if
			end if
		next		
		for y = lbound(aryTmp) to ubound(aryTmp)
			aryRptData = aryRptData & aryTmp(y) & "|"
			aryTmp(y) = ""
		next
		aryRptData = aryRptData & ":"	
	
		' set up first page totals in tmp array
		calcRecord poRs,pType	
	
		poRs.movenext
	loop

	
	'--> KMC 05/06/2015
	if pType = "1" then
		if minRoyAmt > round(aryTmp2(ROY_TOT),2) then
			aryTmp2(ROY_TOT) = minRoyAmt
		else
			aryTmp2(ROY_TOT) = round(aryTmp2(ROY_TOT),2)
		end if
		'-->
	end if	
	'-->

end function
'================================
function calcRecord(poRs,pType)	
	dim lmulti
	lmulti = -1
	if trim(poRs("trx_type"))="I" then
		lmulti = 1
	end if
	select case cint(poRs(group))
			case CUST_TRXS															
			
				sumCustomerTransactions poRs,lmulti
								
			case CONTRACT_BILLING
			
				if trim(poRs("cust_stat")) = "" then
					aryTmp2(TCB) = aryTmp2(TCB) +	cdbl(oRs("cont_bill"))
				end if
				aryTmp2(FFS) = aryTmp2(FFS) +	cdbl(oRs("ff_pymnt"))
			
			case LEASE_TRX
				
				aryTmp2(LEASES) = aryTmp2(LEASES) + ((cdbl(oRs("trx_amt"))+ cdbl(oRs("trx_tax"))) * lmulti)	
				' if canada override previous seting
				if getRegionalSetting(cCOUNTRY) = "Canada" then					
					aryTmp2(LEASES) = aryTmp2(LEASES) + (cdbl(oRs("trx_amt")) * lmulti)
					aryTmp2(LEASE_GST) = aryTmp2(LEASE_GST) + (cdbl(oRs("trx_tax")) * lmulti)
					aryTmp2(LEASE_PST) = aryTmp2(LEASE_PST) + (cdbl(oRs("pst_tax")) * lmulti)
				end if
			
			case SUPPLY_TRX
							
				aryTmp2(FRAN_SUP) = aryTmp2(FRAN_SUP) + ((cdbl(oRs("trx_amt"))*clng(oRs("quantity")))+cdbl(oRs("trx_tax"))) * lmulti
				' if canada override previous seting
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(FRAN_SUP) = aryTmp2(FRAN_SUP) + (cdbl(oRs("trx_amt"))+cdbl(oRs("quantity"))) * lmulti
					aryTmp2(F_SUP_GST) = aryTmp2(F_SUP_GST) + cdbl(oRs("trx_tax")) * lmulti
					aryTmp2(F_SUP_PST) = aryTmp2(F_SUP_PST) + cdbl(oRs("pst_tax")) * lmulti
				end if
			
			case REG_MISC_DEDUCT
			
				aryTmp2(REG_MSC) = aryTmp2(REG_MSC) + round(((cdbl(oRs("trx_amt"))*cdbl(oRs("quantity")))+cdbl(oRs("trx_tax"))) * lmulti,2)
				' if canada override previous seting
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(REG_MSC) = aryTmp2(REG_MSC) + (cdbl(oRs("trx_amt"))*cdbl(oRs("quantity"))) * lmulti
					aryTmp2(REG_MSC_GST) = aryTmp2(REG_MSC_GST) + cdbl(oRs("trx_tax")) * lmulti					
				end if
			
			case SPE_MISC_DEDUCT
										
				aryTmp2(SPEC_MSC) = aryTmp2(SPEC_MSC) + ((cdbl(oRs("trx_amt"))*cdbl(oRs("quantity")))+cdbl(oRs("trx_tax")))* lmulti
				' if canada override previous seting
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(SPEC_MSC) = aryTmp2(SPEC_MSC) + (cdbl(oRs("trx_amt"))*cdbl(oRs("quantity"))) * lmulti
					aryTmp2(SPC_MSC_GST) = aryTmp2(SPC_MSC_GST) + cdbl(oRs("trx_tax")) * lmulti					
				end if
				
			case CHARGE_BACKS
				
				aryTmp2(CB) = aryTmp2(CB) + cdbl(oRs("trx_amt")) * lmulti
				' if canada override previous seting
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(CB_GST) = aryTmp2(CB_GST)
					aryTmp2(CB_PST) = aryTmp2(CB_PST)					
					aryTmp2(CB_GST) = aryTmp2(CB_GST) + (cdbl(oRs("trx_tax")) * lmulti)
					aryTmp2(CB_PST) = aryTmp2(CB_PST) + (cdbl(oRs("pst_tax")) * lmulti)					
				end if
							
		end select
		
		if getRegionalSetting(cCOUNTRY) = "Canada" then
			regionSpecificCalcs
		end if
		
end function
'================================
function regionSpecificCalcs(poRs)
	dim lBilled,lGSTDed,lPSTDed,lTotAdvFee
	
	lBilled = aryTmp2(ACT_B) +aryTmp2(AD_B_FRAN) +aryTmp2(AD_B_OFC)+ aryTmp2(C_SUPPLIES)
	lGSTDed = 0
	if trim(poRs("pct_flag")) = "Y"  then ' GST on accounting fee
		lGSTDed = round(round(cdbl(lBilled)*(cdbl(poRs("add_pct"))/100),2)*(cdbl(gstTax)/100),2)
	end if
	
	lGSTDed = lGSTDed + aryTmp2(F_SUP_GST) 
	lGSTDed = lGSTDed + aryTmp2(REG_MSC_GST) 
	lGSTDed = lGSTDed + aryTmp2(SPC_MSC_GST) 
	lGSTDed = lGSTDed + aryTmp2(LEASE_GST) 
	lGSTDed = lGSTDed + aryTmp2(CB_GST) 
	lGSTDed = lGSTDed + aryTmp2(F_SUP_GST) 
	
	if gstDed_Ad then
		lTotAdvFee = round((aryTmp2(ACT_B)+aryTmp2(AD_B_FRAN)+aryTmp2(AD_B_OFC)+aryTmp2(C_SUPPLIES))*adcur,2)
		lGSTDed = lGSTDed + round(lTotAdvFee*cdbl(gstTax)/100,2)
	end if
	
	lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*Business*(lBilled-aryTmp2(C_SUPPLIES)),2)
	
	if lCanadaMaster then 'KMC 10/25/2005 For Canada Masters (non-Toronto) to accomodate their Ins & Risk Mgt Fee.
		if lbilled <> 0 then			
			if (lBilled*(BpAdmin1/100) + BpAdmin2) < BtSale1 then
				lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*cdbl(BtSale1),2)
			else
				lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*(lBilled*(cdbl(BpAdmin1)/100) + cdbl(BpAdmin2)),2)
			end if
		end if
	else
		' GST on Bond
		if business = 0 then					
			lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*0,2)
		elseif lBilled - aryTmp2(C_SUPPLIES) <= 0 then
			lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*0,2)
		elseif lBilled - aryTmp2(C_SUPPLIES) <= cdbl(BtSale1) then
			lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*cdbl(BpAdmin1),2)
		else
			lGSTDed = lGSTDed + round((cdbl(gstTax)/100)*cdbl(BpAdmin2),2)
		end if
		
	end if
	
	lGSTDed = lGstDed + (cdbl(NumBeeps)*cdbl(BeepCost))*(cdbl(gstTax)/100)
	lGSTDed = lGstDed + (cdbl(NumBeeps2)*cdbl(BeepCost2))*(cdbl(gstTax)/100)
	aryTmp2(GST_DED) = lGSTDed
	
	lPSTDed = aryTmp2(F_SUP_PST) +aryTmp2(LEASE_PST) +aryTmp2(CS_PST)+ aryTmp2(CB_PST) 
	lPSTDed = lPSTDed + (cdbl(NumBeeps)*cdbl(BeepCost))*(cdbl(oRs("pst_tax"))/100) 
	lPSTDed = lPSTDed + (cdbl(NumBeeps2)*cdbl(BeepCost2))*(cdbl(oRs("pst_tax"))/100) 
	aryTmp2(PST_DED) = lPSTDed
	
end function
'================================
function sumCustomerTransactions(poRs,pMulti)
	dim lroyPercentage
	
	select case trim(poRs("trx_class"))
		case "B"  ' Actual Billing
				
				aryTmp2(ACT_B) = aryTmp2(ACT_B) + (cdbl(oRs("trx_amt")) * pmulti)				
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(AB_TAX) = aryTmp2(AB_TAX) + (cdbl(oRs("trx_tax")) * pmulti)
				end if
											
		case "E"  ' Additional Billing by Franchise
				
				aryTmp2(AD_B_FRAN) = aryTmp2(AD_B_FRAN) + (cdbl(oRs("trx_amt")) * pmulti)
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(AB_F_TAX) = aryTmp2(AB_F_TAX) + (cdbl(oRs("trx_tax")) * pmulti)
				end if
				
		case "I","O" ' Additional Billing By Office & Commission
				
				aryTmp2(AD_B_OFC) = aryTmp2(AD_B_OFC) + (cdbl(oRs("trx_amt")) * pmulti)				
				aryTmp2(AD_B_OFC_COMM) = aryTmp2(AD_B_OFC_COMM) + (round((((cdbl(oRs("trx_roy"))-cdbl(oRs("cust_roy")))/100)*cdbl(oRs("trx_amt"))),2)*pmulti)
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(AB_O_TAX) = aryTmp2(AB_O_TAX) + (cdbl(oRs("trx_tax")) * pmulti)
				end if
		
		case "S" ' Client Supplies	
			
				aryTmp2(C_SUPPLIES) = aryTmp2(C_SUPPLIES) + (cdbl(oRs("trx_amt")) * pmulti)
				if getRegionalSetting(cCOUNTRY) = "Canada" then
					aryTmp2(CS_TAX) = aryTmp2(CS_TAX) + (cdbl(oRs("trx_tax")) * pmulti)
					aryTmp2(CS_PST) = aryTmp2(CS_PST) + (cdbl(oRs("pst_tax")) * pmulti)
				end if	
						
		end select
		
		if not (trim(poRs("trx_class")) = "S" and cdbl(oRs("trx_roy")) = 0) then							
			aryTmp2(ROY_TOT) = aryTmp2(ROY_TOT) + (cdbl(oRs("cust_roy"))/100)*cdbl(oRs("trx_amt"))* pmulti
		end if
				
		aryTmp2(C_SALES_TAX) = aryTmp2(C_SALES_TAX) + (cdbl(oRs("trx_tax")) * pmulti)
		
end function
'================================
function getTrxClass(s)
	select case ucase(s)
		case "Q"
			getTrxClass = "Pagers"
			exit function
		case "X"
			getTrxClass = "Advance"
			exit function
		case "G"
			getTrxClass = "Neg Roll-Over"
			exit function
		case "Z"
			getTrxClass = "Donation"
			exit function
		case "B"
			getTrxClass = "Bond"
			exit function
		case "J"
			getTrxClass = "Advertising"
			exit function
		case "M"
			getTrxClass = "Misc"
			exit function
		case "P"
			getTrxClass = "Bus Prot"
			exit function
		case "N"
			getTrxClass = "Second Note"
			exit function
		case "R"
			getTrxClass = "Royalty"
			exit function
		case "T"
			getTrxClass = "Addtl Bill Ofc Comm"
			exit function
		case "O"
			getTrxClass = "Misc"
			exit function
		case "A"
			getTrxClass = "Business Support Fee"
			exit function
		case "D"
			getTrxClass = "Finders Fees"
			exit function
		case "H"
			getTrxClass = "FF's Down"
			exit function
		case "F"
			getTrxClass = "Franchise Note"
			exit function
		case else
			getTrxClass = ""
			exit function
	end select	
end function
'================================
function getIndex(s)
	getindex = ""
	select case ucase(s)
	case "GROUP"
		getIndex= 0
		exit function
	case "COMPANY_NO" 
		getIndex = 1
		exit function	
	case "DLR_CODE"   
		getIndex = 2
		exit function
	case "CUST_NO"
		 getIndex = 3
		 exit function
	case "CUS_NAME"  
		getIndex = 4
		exit function
	case "TRX_TYPE"	 
		getIndex = 5
		exit function
	case "INV_NO"    
		getIndex = 6
		exit function
	case "DESCR"		 
		getIndex = 7
		exit function
	case "QUANTITY"	 
		getIndex = 8
		exit function
	case "TRX_AMT"	 
		getIndex = 9
		exit function
	case "TRX_TAX"	 
		getIndex = 10
		exit function
	case "TRX_CLASS"	 
		getIndex = 11
		exit function
	case "TRX_ROY"	 
		getIndex = 12
		exit function
	case "CUST_ROY"	 
		getIndex = 13
		exit function
	case "CONT_BILL"	 
		getIndex = 14
		exit function
	case "CUR_MONTH"  
		getIndex = 15
		exit function
	case "ADTL_B_FRN" 
		getIndex = 16
		exit function
	case "CLIENT_SUP" 
		getIndex = 17
		exit function
	case "ADTL_B_OFC" 
		getIndex = 18
		exit function
	case "FF_NBR"	 
		getIndex = 19
		exit function
	case "FF_PYMNT"	 
		getIndex = 20
		exit function
	case "CUST_STAT"  
		getIndex = 21
		exit function
	case "LEASE_NO"	 
		getIndex = 22
		exit function
	case "MAKE"		 
		getIndex = 23
		exit function
	case "MODEL"		 
		getIndex = 24
		exit function
	case "SERIAL"	 
		getIndex = 25
		exit function
	case "DATE_SIGN"  
		getIndex = 26
		exit function
	case "PYMNT_NUM"  
		getIndex = 27
		exit function
	case "PST_TAX"	 
		getIndex = 28
		exit function
	end select
end function
'================================
%>