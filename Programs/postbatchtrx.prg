*!*	*--> For testing only
*!*	suspend
*!*	cOfficeName="Denver"
*!*	cCompNo="DEN191"
*!*	cDataLoc="x:\jk_den\"
*!*	*-->

close data all
regionname=cOfficeName
set procedure to TraverseLibrary.prg  && Traverse functions are all in here.

if !file(cDataLoc+'NoBatchAPPost')
	*--> No need to locate AP data path if the file 'NoBatchAPPost' exists in the selected region.
	*--> AP data is not posted in regions where that file exists.
	use data_loc in 0
	sele data_loc
	loca for company_no=cCompNo
	if found()
		APPath=alltrim(Bank_Data)
		oConn=0
		oConn_ADO=""
		oCmd=""
		xServer=""
		curRegion=""

		*--> KMC 10/13/2005
		*for xFldCnt=1 to FCOUNT()
		*	curField=FIELD(xFldCnt)
		*	if curField = 'TRAVERSE_S'
		*		if len(alltrim(traverse_s))>0
		*			*--> Set Connection String for Traverse
		*			xServer=alltrim(traverse_s)
		*			curRegion=alltrim(traverse_d)
		*			oConn=sqlStringConnect("Driver={SQL Server};Server="+xServer+";UID=sa;PWD=jani!king;Database="+curRegion)
		*		endif			
		*		exit
		*	endif
		*endfor	

		Set_oConn() && In Traverse Library
		if oConn=-1
			messagebox("Error connecting to SQL data - contact IT Dept.",48," System Alert")
			CleanUp() && In Traverse Library	
			return
		endif		
		*-->	

		use
	else
		*--> Don't do anything if you can't locate AP data.
		clos data all
		messagebox("Warning - Cannot locate AP data - posting cancelled!",48," System Alert")
		return
	endif
endif
	
*--> Open data sources
use Batch_AP in 0
use Batch_Fran in 0 order id
use Batch_Cust in 0 order id
use jkcusfil in 0 order cust_no

sele Batch_Cust
set rela to cust_no into jkcusfil

*--> 04/05/2005 KMC - Validations to be run before posting.
*--> Verify not posting to a closed period.
sele distinct bill_mon, bill_year from batch_AP where !posted into cursor tmpPost
use jkinvfil in 0
sele tmpPost
go top
do while !eof()
	sele jkinvfil
	loca for bill_mon=tmpPost.bill_mon and  ;
		bill_year=tmpPost.bill_year
	if found() 
		if posted
			messagebox("You cannot post records for period "+alltrim(str(bill_mon))+"-"+alltrim(str(bill_year))+", that period is closed.",16," System Alert")	
			clos data all
			CleanUp() && In Traverse Library	
			return
		endif
	else
		messagebox("You cannot post records for period "+alltrim(str(bill_mon))+"-"+alltrim(str(bill_year))+", that period does not exist.",16," System Alert")	
		clos data all
		CleanUp() && In Traverse Library	
		return
	endif	
	sele tmpPost
	skip
enddo
sele jkinvfil
use
sele tmpPost
use

*-->Don't Post if there are records with bad franchisee numbers.
use jkdlrfil in 0 order dlr_code
sele Batch_Fran
set rela to dlr_code into jkdlrfil addi
set filt to eof('jkdlrfil')
go top
if !eof()
	messagebox("Invalid Franchisee numbers exist, Posting will not occur until they are corrected.",16," System Alert")
	report form InvalidBatchFran Preview
	close data all
	CleanUp() && In Traverse Library	
	return
else
	set rela off into jkdlrfil
	sele jkdlrfil
	use
	sele Batch_Fran
	set filt to
	go top
endif

*-->Don't Post if there are records with bad customer numbers.
sele Batch_Cust
set rela to id into batch_fran addi
set filt to eof('jkcusfil')
go top
if !eof()
	messagebox("Invalid Customer numbers exist, Posting will not occur until they are corrected.",16," System Alert")
	report form InvalidBatchCust Preview
	close data all
	return
else
	set rela off into batch_fran
	set filt to
	go top
endif

*--> Verify transactions don't already exist in jkdlrtrx file.
create cursor tmpTrx ;
	(dlr_code C(6), ;
	inv_date D, ;
	descr C(55), ;
	trx_amt N(12,2), ;
	trx_tax N(12,2))
	
use jkdlrtrx in 0
sele jkdlrtrx
set filt to trx_class="S" 
sele batch_fran
go top
scan
	if !posted
		sele jkdlrtrx
		loca for bill_mon = batch_fran.bill_mon and ;
			bill_year = batch_fran.bill_year and ;
			descr = batch_fran.descr
		if found()
			scatter memvar
			insert into tmpTrx from memvar		
		endif			
	endif
	sele Batch_Fran
endscan	
sele tmpTrx
go top
if !eof()
	messagebox("Some or all transactions already exist in the Franchisee Transaction file."+Chr(13)+ ;
			   "Review the Duplicate Transaction report and delete records as necessary (Fran Acct & AP)."+CHR(13)+ ;
			   "Once duplicate records have been deleted you can try to Post again.",16," System Alert")
	report form DupBatchTrx Preview
	close data all
	CleanUp() && In Traverse Library
	return
else
	sele tmpTrx
	use
	sele jkdlrtrx
	use
	sele Batch_Fran
	go top
	sele Batch_Cust
	go top
endif
*--> 04/05/2005 

*--> Post transactions
if file(cDataLoc+'NoBatchAPPost')
	*--> KMC 02/22/2005 Don't add AP records if file 'NoBatchAPPost' exists, just mark them as posted.
	Wait window "Marking AP records as Posted..." nowait
	DO MarkAPPosted
else
	Wait window "Now Posting AP records..." nowait

	*--> KMC 09/20/205
	*if file(cDataLoc+'PostToTraverse')
	if !empty(xServer)
	*-->
		Do PostAPTrx_Traverse
	else
		DO PostAPTrx
	endif
endif
Wait window "Now Posting Fran Trx records..." nowait
DO PostFranTrx
Wait window "Now Posting Cust Trx records..." nowait
DO PostCustTrx
*--> all done
wait clear
clos data all

Proc MarkAPPosted
	sele Batch_AP
	scan
		repla Batch_AP.posted with .t.
	endscan
	sele Batch_AP
	use
return	

Proc PostAPTrx_Traverse
	crea cursor tmpSqlStr (xSqlStr M) && to store SQL string for troubleshooting purposes.

	Set_BatchID() && In Traverse Library

	*--> Get TransID from Traverse's stored procedure.
	Get_TransID("AP",0," ") && In Traverse Library - Parameters FunctionID, isInt, TransID
	*-->

	sele Batch_AP
	scan
		*--> KMC 11/08/2012 - Don't post trx's with a 0 amount to Traverse.
		*if !Batch_AP.posted 
		if !Batch_AP.posted and Batch_AP.tran_amt<>0 
		*-->
			*-->Insert into tblAPTransHeader	

			*--> KMC 10/13/2005
			oCmd.execute && See Get_TransID Function in Traverse Library
			TransID=oCmd.parameters(3).value
			*-->

			*--> KMC 09/20/2012 Additional code to set discount.
			vendorid=trim(Batch_AP.ven_code)
			
			xsql = "select v.termscode,c.DiscPct from tblapvendor v "
			xsql = xsql + "inner join tblApTermsCode c on v.TermsCode = c.TermsCode "
			xsql = xsql + "where VendorID = '" + vendorid + "'"

			x=SQLEXEC(oConn, xsql, 'myCursor') 

			if x=-1
				wait window "SQL Connection error - Obtaining Discount " + TransID
				CleanUp() && In Traverse Library	
				return
			endif
			
			trxamt = Batch_AP.tran_amt

			*--> KMC 11/08/2012 - Don't post 0 amount invoices to Traverse.

			sele myCursor
			TermsCode = myCursor.termscode
	
			*--> KMC 10/24/2012 - Change to account for non-discounted transactions.
			*if myCursor.discpct>0
			*	xDiscAmt = round(trxamt * (myCursor.discpct/100),2)
			*	CashDisc = str(abs(xDiscAmt),12,2)
			*	*--> KMC 10/03/2012 - Per Jeanette, CashDiscFgn needs to be the same as CashDisc
			*	*CashDiscFgn = str(abs(trxamt - xDiscAmt),12,2) 
			*	CashDiscFgn = str(abs(xDiscAmt),12,2)
			*endif
			xDiscAmt = round(trxamt * (myCursor.discpct/100),2)
			CashDisc = str(abs(xDiscAmt),12,2)
			*--> KMC 10/03/2012 - Per Jeanette, CashDiscFgn needs to be the same as CashDisc
			*CashDiscFgn = str(abs(trxamt - xDiscAmt),12,2) 
			CashDiscFgn = str(abs(xDiscAmt),12,2)
			*-->
			
			sele myCursor
			use
			*--> KMC 09/20/2012
			wait window "Adding Vendor Transaction "+TransID+" - "+curRegion nowait
			BatchID="Import"
			WhseID=""
			*VendorID=Batch_AP.ven_code
			InvoiceNum=Batch_AP.inv_no
			InvoiceDate=dtoc(batch_AP.inv_date)
			TransType=iif(Batch_AP.tran_amt<0,"-1","01")
			PONum=""
			DistCode="01"
			*TermsCode="N4510"
			DueDate1=dtoc(Batch_AP.due_date)
			DueDate2=""
			DueDate3=""
			DiscDueDate=dtoc(Batch_AP.due_date) && KMC 07/30/2012 - Added per Jeanette Johnson - field was added to Traverse DB during recent update.
	
			*--> KMC 10/03/2012 - Per Jeanette.
			*PmtAmt1=str(abs(Batch_AP.tran_amt),12,2)
			PmtAmt1=str(abs(Batch_AP.tran_amt-xDiscAmt),12,2)
			*-->

			PmtAmt2="0.00"
			PmtAmt3="0.00"
			SubTotal=str(abs(Batch_AP.tran_amt),12,2)
			SalesTax="0.00"
			Freight="0"
			Misc="0"
			*CashDisc="0"
			PrePaidAmt="0.00"
			CurrencyID="DOLLAR"
			ExchRate="1"
	
			*--> KMC 10/03/2012 - Per Jeanette.
			*PmtAmt1Fgn=str(abs(Batch_AP.tran_amt),12,2)
			PmtAmt1Fgn=str(abs(Batch_AP.tran_amt-xDiscAmt),12,2)
			*-->
		
			PmtAmt2Fgn="0.00"
			PmtAmt3Fgn="0.00"
			SubTotalFgn=str(abs(Batch_AP.tran_amt),12,2)
			SalesTaxFgn="0.00"
			FreightFgn="0.00"
			MiscFgn="0.00"
			*CashDiscFgn="0.00"
			PrePaidAmtFgn="0.00"		
			*--> KMC 10/13/2005 per Bennye, post to current GL period of date transaction imported into fran acct.
			*PostDate=dtoc(batch_AP.inv_date)
			*GLPeriod=str(month(Batch_AP.inv_date))
			*FiscalYear=str(year(Batch_AP.inv_date))
			PostDate=dtoc(Batch_AP.tran_date)
			GLPeriod=str(month(Batch_AP.tran_date))
			FiscalYear=str(year(Batch_AP.tran_date))
			*--> 	

			Ten99Invoice="0"
			Status="0"
			Notes=""
			TaxGrpId="N/A"
			TaxableYN="0"
			Taxable="0"
			NonTaxable=str(abs(Batch_AP.tran_amt),12,2)
			TaxableFgn="0"
			NonTaxableFgn=str(abs(Batch_AP.tran_amt),12,2)
			TaxClassFreight="0"
			TaxClassMisc="0"
			TaxLocID1="N/A"
			TaxAmt1="0"
			TaxAmt1Fgn="0"
			TaxAmt2="0"
			TaxAmt2Fgn="0"
			TaxAmt3="0"
			TaxAmt3Fgn="0"
			TaxAmt4="0"
			TaxAmt4Fgn="0"
			TaxAmt5="0"
			TaxAmt5Fgn="0"
			TaxAdjClass="0"
			TaxAdjLocId="0"
			TaxAdjAmt="0"
			TaxAdjAmtFgn="0"
			*BankID=""
			*ChkGlPeriod="00"
			*ChkFiscalYear="0000"
		
			sql1 = "insert into tblAPTransHeader (TransID, batchID, VendorID, InvoiceNum, InvoiceDate, TransType,"
			sql1 = sql1 + " DistCode, TermsCode, DueDate1, DiscDueDate, PmtAmt1, PmtAmt2, PmtAmt3, Subtotal, SalesTax, Freight,"
			sql1 = sql1 + " Misc, CashDisc, PrepaidAmt, CurrencyID, ExchRate, PmtAmt1Fgn, PmtAmt2Fgn, PmtAmt3Fgn,"
			sql1 = sql1 + " SubtotalFgn, SalesTaxFgn, FreightFgn, MiscFgn, CashDiscFgn, PrePaidAmtFgn, PostDate,"
			sql1 = sql1 + " GLPeriod, FiscalYear, Ten99InvoiceYN, Status, TaxGrpID, TaxableYN, Taxable, NonTaxable, TaxableFgn, "
			sql1 = sql1 + " NonTaxableFgn, TaxClassFreight, TaxClassMisc, TaxLocID1, TaxAmt1, TaxAmt1Fgn, TaxAmt2,"
			sql1 = sql1 + " TaxAmt2Fgn, TaxAmt3, TaxAmt3Fgn, TaxAmt4, taxAmt4Fgn, TaxAmt5, TaxAmt5Fgn, TaxAdjClass,"
			sql1 = sql1 + " TaxAdjAmt, TaxAdjAmtFgn)" 	

			sql2 = + " VALUES ('" + TransId + "', '" + BatchId + "', '" + VendorID + "', '" + InvoiceNum +"', '" + InvoiceDate + "', "
			sql2 = sql2 + TransType + ", '" + DistCode +"', '" + TermsCode + "', '" + DueDate1 + "',  '" + DiscDueDate + "', "  + PmtAmt1 + ", "
			sql2 = sql2 + PmtAmt2 + ", " + PmtAmt3 + ", " + SubTotal + ", "  + SalesTax + ", " + Freight + ", " + Misc + ", "
			sql2 = sql2 + CashDisc + ", " + PrepaidAmt + ", '" + CurrencyID + "', " + ExchRate + ", " + PmtAmt1Fgn + ", "
			sql2 = sql2 + PmtAmt2Fgn + ", " + PmtAmt3Fgn + ", " + SubTotalFgn + ", " + SalesTaxFgn + ", " + FreightFgn + ", "
			sql2 = sql2 + MiscFgn + ", " + CashDiscFgn + ", " + PrepaidAmtFgn + ", '" 
			sql2 = sql2 + PostDate + "', " + GlPeriod + ", " + FiscalYear + ", " + Ten99Invoice + ", " + Status + ", '"
			sql2 = sql2 + TaxGrpID +"', " + TaxableYN + ", " + Taxable + ", " + NonTaxable + ", " + TaxableFgn + ", "
			sql2 = sql2 + NonTaxableFgn + ", " + TaxClassFreight + ", " + TaxClassMisc + ", '" + TaxLocID1 +"', "
			sql2 = sql2 + TaxAmt1 + ", " + TaxAmt1Fgn + ", " + TaxAmt2 + ", " + TaxAmt2Fgn + ", " + TaxAmt3 + ", "
			sql2 = sql2 + TaxAmt3Fgn + ", " + TaxAmt4 + ", " + TaxAmt4Fgn + ", " + TaxAmt5 + ", " + TaxAmt5Fgn + ", "
			sql2 = sql2 + TaxAdjClass + ", " + TaxAdjAmt + ", " + TaxAdjAmtFgn + ")"  
		
			*--> Store SQL Statement for testing purposes
			sele tmpSqlStr
			append blank
			repla xSqlStr with sql1+sql2	
			x=SQLEXEC(oConn, sql1+sql2) 
	
			if x=-1
				wait window "SQL Connection error - Adding Transaction " + TransID
				sele tmpSqlStr
				modi memo xSqlStr	
				*--> KMC 06/16/2006
				CleanUp() && In Traverse Library	
				return
				*-->
			endif

			*-->Insert into tblAPTransDetailTax
			wait window "Adding Vendor Transaction Invoice Tax "+TransID+" - "+curRegion nowait
			*TransID && Already Set
			TaxLocID="N/A"
			TaxClass="0"
			ExpAcct="6335"
			TaxAmt="0"
			Refundable="0"
			Taxable="0"
			NonTaxable=str(abs(Batch_AP.tran_amt),12,2)
			RefundAcct="6335"
			InvcNum=Batch_AP.inv_no
			taxAmtFgn="0"
			TaxableFgn="0"
			NonTaxableFgn=str(abs(Batch_AP.tran_amt),12,2)
			RefundableFgn="0"
		
			sql1 = "insert into tblAPTransInvoiceTax (TransID, TaxLocID, TaxClass, ExpAcct, TaxAmt, Refundable, Taxable, NonTaxable, "
			sql1 = sql1 + " RefundAcct, InvcNum, TaxAmtFgn, TaxableFgn, NonTaxableFgn, refundableFgn)"		
			sql2 = + " VALUES ('" + TransId + "', '" + TaxLocID + "', " + TaxClass + ", '" + ExpAcct +"', " + TaxAmt + ", "
			sql2 = sql2 + Refundable + ", " + Taxable +", " + NonTaxable + ", '" + RefundAcct + "', '"  + InvcNum + "', "
			sql2 = sql2 + TaxAmtFgn + ", " + TaxableFgn + ", " + NonTaxableFgn + ", "  + RefundableFgn + ")"  
		
			*--> Store SQL Statement for testing purposes
			sele tmpSqlStr
			append blank
			repla xSqlStr with sql1+sql2
		
			x=SQLEXEC(oConn, sql1+sql2) 
			if x=-1
				wait window "SQL Connection error - Adding Transaction Invoice Tax" + TransID 
				sele tmpSqlStr
				modi memo xSqlStr	

				*--> KMC 06/16/2006
				CleanUp() && In Traverse Library	
				return
				*-->
			endif

			*-->Insert into tblAPTransDetail	
			wait window "Adding AP Transaction Detail "+TransID+" - "+curRegion nowait
			*TransID && Already Set
			EntryNum="1"
			PartType="0"
			xDesc=alltrim(Batch_Ap.Tran_Desc)
			GLAcct=Batch_AP.Account
			Qty="1"
			QtyBase="1"
			UnitCost=str(abs(Batch_AP.tran_amt),12,2)
			UnitCostFgn=str(abs(Batch_AP.tran_amt),12,2)
			ExtCost=str(abs(Batch_AP.tran_amt),12,2)
			ExtCostFgn=str(abs(Batch_AP.tran_amt),12,2)
			GlDesc="Cost - Supplies - Franchisee"  
			HistSeqNum='0'
			TaxClass='0'
			ConversionFactor='0'
			LottedYN='0'
			InItemYN='0'
		
			sql1 = "insert into tblAPTransDetail (TransID, EntryNum, PartType, [Desc], GLAcct, Qty, QtyBase, UnitCost, UnitCostFgn, "
			sql1 = sql1 + " ExtCost, ExtCostFgn, GLDesc, HistSeqNum, TaxClass, ConversionFactor, LottedYN, InItemYN)"		
			sql2 = + " VALUES ('" + TransId + "', " + EntryNum + ", " + PartType + ", '" + xDesc +"', '" + GLAcct + "', "
			sql2 = sql2 + Qty + ", " + QtyBase +", " + UnitCost + ", " + UnitCostFgn + ", "  + ExtCost + ", "
			sql2 = sql2 + ExtCostFgn + ", '" + GlDesc + "', " + HistSeqNum + ", " + TaxClass + ", "  + ConversionFactor + ", "
			sql2 = sql2 + LottedYN + ", " + InItemYN + ")"  
			*--> Store SQL Statement for testing purposes
			sele tmpSqlStr
			append blank
			repla xSqlStr with sql1+sql2	
			x=SQLEXEC(oConn, sql1+sql2) 
			if x=-1
				wait window "SQL Connection error - Adding AP Detail Transaction " + TransID 
				sele tmpSqlStr
				modi memo xSqlStr	
				*--> KMC 06/16/2006
				CleanUp() && In Traverse Library	
				return
				*-->
			endif

			*xCnt=xCnt+1
			sele batch_AP
			repl Batch_AP.Posted with .t.
		endif

		*--> KMC 11/08/2012 - This is to flag 0 amount trx's as posted.
		*--> Traverse errors on 0 amount trx's, so they are skipped when posting, but still flagged as posted.
		if !Batch_AP.posted and Batch_AP.tran_amt = 0
			repla Batch_AP.Posted with .t.		
		endif
		*-->	
endscan

*--> KMC 09/20/2005
CleanUp() && In Traverse Library
*-->
return

Proc PostAPTrx
	*--> Open AP control file and lock it until AP posting completes.
	use APPath+"\Transact" in 0
	sele Transact
	flock()
	if lastkey()=27 
		*--> User pressed ESC before we got a lock - bail out.
		clos all
		messagebox("Unable to lock control file, no AP Trx posting occured!")
		return
	endif	

	sele Batch_AP
	scan
		if !Batch_AP.posted
			*--> Set transaction number
			sele Transact
			APTrx=padl(alltrim(str(transact.tran_no+1)),10,"0")
			repla transact.tran_no with transact.tran_no+1	

			*--> Set Pay_Hd variables.
			sele Batch_AP
			tran_no=APTrx
			ven_code=Batch_AP.ven_code
			tran_date=date()
			tran_desc=Batch_AP.tran_desc
			inv_no=Batch_AP.inv_no
			ref_no=alltrim(str(Batch_AP.id)) && Reference to Batch_AP record
			due_date=Batch_AP.due_date
			posted="N"
			tran_amt=Batch_AP.tran_amt
			tran_paid=.f.
			account=Batch_AP.Account
			hold=.f.
			inv_date=Batch_AP.inv_date
			gl_posted=.f.
			gl_period=month(inv_date)
			gl_year=year(inv_date)
			sch_pay_dt=Batch_AP.due_date
			*-->

			*--> Set Pay_Dtl variables (that were not already set from Pay_Hd).
			*tran_no= already set
			*account= already set
			desc=Batch_AP.tran_desc
			amount=Batch_AP.tran_amt
			*-->
	
			*--> Insert Pay_Hd record.
			xPay_Hd=APPath+"\pay_hd"
			insert into &xPay_Hd from memvar
			*--> Insert Pay_Dtl record.
			xPay_Dtl=APPath+"\pay_dtl"
			insert into &xPay_Dtl from memvar
			*--> Mark record as posted.
			repla Batch_AP.posted with .t.
		endif
	endscan	

	*--> Close Transact - releasing lock.
	sele Transact
	use

	*--> Close tables used for AP transactions.
	sele Batch_AP
	use
return

Proc PostFranTrx
	*--> Open control file and lock it until Fran Trx posting completes.
	use jkctlfil in 0 
	sele jkctlfil
	flock()
	if lastkey()=27 
		*--> User pressed ESC before we got a lock - bail out.
		clos all
		messagebox("Unable to lock control file, no Fran Trx posting occured!")
		return
	endif	

	Sele Batch_Fran
	scan
		if !Batch_Fran.posted 
							
			*--> Set transaction number
			sele jkctlfil
			FrnTrx=jkctlfil.fn_lstrx
			repla jkctlfil.fn_lstrx with jkctlfil.fn_lstrx+1

			*--> Set JKdlrtrx variables.
			company_no=Batch_Fran.company_no
			dlr_code=Batch_Fran.dlr_code
			bill_mon=Batch_Fran.bill_mon
			bill_year=Batch_Fran.bill_year
			descr=Batch_Fran.Descr
			trx_amt=Batch_Fran.trx_amt
			trx_class="S"
			trx_tax=Batch_Fran.trx_tax
			Quantity=Batch_Fran.quantity
			Trx_no=FrnTrx
			trx_type=Batch_Fran.trx_type
			due_date=Batch_Fran.due_date

			*--> KMC 04/25/2005 - Set inv_date based on date posting occurs - eff_date can be the physical invoice date.
			*inv_date=Batch_Fran.inv_date
			*eff_date=date()
			inv_date=date()
			eff_date=Batch_Fran.inv_date
			*-->

			mach_gen=.t.
			resell=Batch_Fran.resell
			inv_type=Batch_Fran.trx_type

			*--> Insert Jkdlrtrx record.
			insert into jkdlrtrx from memvar

			*--> Mark record as posted.
			repla Batch_Fran.posted with .t.
		endif
	endscan

	*--> Close jkctlfil - releasing lock.
	sele jkctlfil
	use

	*--> Close tables used for Fran transactions.
	sele Batch_Fran
	use

return

Proc PostCustTrx
	*--> Open control file and lock it until Cust Trx posting completes.
	use jkinvfil in 0 order key
	sele jkinvfil
	flock()
	if lastkey()=27 
		*--> User pressed ESC before we got a lock - bail out.
		clos all
		messagebox("Unable to lock control file, no Fran Trx posting occured!")
		return
	endif	

	Sele Batch_Cust
	set rela to company_no+STR(bill_year,4)+STR(bill_mon,2) into jkinvfil addi
	
	do while !eof()
		xID=Batch_Cust.ID
		xCust=Batch_Cust.cust_no
		xRecCnt=0
		xCurCust=jkcusfil.cus_name
		do while !eof() and id=xID and cust_no=xCust 
			if !Batch_Cust.posted 
				xRecCnt=xRecCnt+1
				if xRecCnt=1

					*--> Get invoice number.
					sele jkinvfil
					xInvNo=padl(alltrim(str(jkinvfil.inv_no)),8,"0")
					repla jkinvfil.inv_no with jkinvfil.inv_no+1
					
					*--> Set main data values.
					sele Batch_Cust
					sys_cust=Batch_Cust.sys_cust
					company_no=Batch_Cust.company_no
					dlr_code=Batch_Cust.dlr_code
					cust_no=Batch_Cust.cust_no
					bill_mon=Batch_Cust.bill_mon
					bill_year=Batch_Cust.bill_year
					descr="CLIENT SUPPLIES"
					due_date=Batch_Cust.due_date
					eff_date=date()
					inv_date=Batch_Cust.inv_date
					inv_no=xInvNo
					royalty=Batch_Cust.royalty
					sep_inv="Y"
					trx_class="S"
					trx_type="I"
					prntinv=Batch_Cust.prntinv
					credit=.F.  && KMC 12/02/2004 - Field not used, but set to .f. just in case.
					
					*--> Add the record.
					insert into jkcustrx from memvar
					repla jkcustrx.quantity with 0			
				endif

				*--> Update appropriate fields for each individual item.
				xDesc="jkcustrx.Desc_Var"+alltrim(str(xRecCnt))
				repla &xDesc with Batch_Cust.descr
				xPriVar="jkcustrx.Pri_Var"+alltrim(str(xRecCnt))
				repla &xPriVar with (Batch_Cust.itm_amt)+iif(Batch_Cust.markup<>0,Batch_Cust.Itm_Amt*Batch_Cust.markup/100,0)
				xQtyVar="jkcustrx.Qty_Var"+alltrim(str(xRecCnt))
				repla &xQtyVar with Batch_Cust.quantity
				xPriTot="jkcustrx.Pri_Tot"+alltrim(str(xRecCnt))
				repla &xPriTot with Batch_Cust.trx_amt

				*--> Update totals.
				repla jkcustrx.quantity with jkcustrx.quantity+Batch_Cust.quantity
				repla jkcustrx.trx_amt with jkcustrx.trx_amt+(Batch_Cust.trx_amt)
				repla jkcustrx.trx_tax with jkcustrx.trx_tax+Batch_Cust.trx_tax
				repla jkcustrx.pri_tot with jkcustrx.pri_tot+(Batch_Cust.trx_amt)
				repla jkcustrx.qty_tot with jkcustrx.qty_tot+Batch_Cust.quantity

				*--> Mark record as posted.
				repla Batch_Cust.posted with .t.

				*--> reset count if you get to 6, only 6 items allowed per jkcustrx record.
				if xRecCnt=6
					xRecCnt=0
					DO PostAR
					sele Batch_Cust
				endif	
			endif						
			skip
		enddo
		if xRecCnt<>0
			skip -1
			DO PostAR
			sele Batch_Cust
			skip	
		endif
	enddo	

	*--> Close jkinvfil - releasing lock.
	sele jkinvfil
	use

	*--> Close tables used for Cust transactions.
	sele Batch_Cust
	use
return

Procedure PostAR
	insert into jkarofil from memvar
	sele jkarofil
	repla cust_name with xCurCust
	repla item_type with "I"
	repla itm_amt with jkcustrx.trx_amt
	repla itm_tax with jkcustrx.trx_tax	
	repl item_class with "S"
	repla date_due with jkcustrx.due_date
	repla date_inv with jkcustrx.inv_date 
return
