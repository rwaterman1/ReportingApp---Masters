* start of report constants.....
#DEFINE _RPT_CUSTOMER_NO 1
#DEFINE _RPT_CURRENT_MONTH_BILLING 2
#DEFINE _RPT_ADDITIONAL_BILLING_FRAN 3 
#DEFINE _RPT_ClIENT_SUPPLIES 4
#DEFINE _RPT_ADDITIONAL_BILLING_OFFICE 5
#DEFINE _RPT_TOTAL_BILLING 6

#DEFINE _RPT_UPDATE 1
#DEFINE _RPT_DELETE 2


*========================================
* Purpose:	
* Parameters:
*		pSysOffice - the office the report will be run for...
*		pDlrCode - the franchise code to be processed...
*========================================
FUNCTION GenerateFranchiseReportData
	PARAMETERS pSysOffice,pBillMonth,pBillYear,pBegFran,pEndFran

	*-------------------------------------------
	* module level declarations....
	EXTERNAL ARRAY mAryCustTot
		
	PRIVATE mCalcBP
	PRIVATE mBillMonth
	PRIVATE mBillYear
	PRIVATE mBegFran
	PRIVATE mEndFran
	PRIVATE mRptDate
	PRIVATE mSysTime
	PRIVATE mSysOffice
	PRIVATE mDlrCode
	PRIVATE mNoteDate
	PRIVATE mfNote1
	PRIVATE mfNote2
	PRIVATE mRebatePercent
	Private	mAcctFee
	PRIVATE mRebateAmt	
	PRIVATE mIdx
	PRIVATE mCustStat
  	PRIVATE mContBill
	
	
	* initialize module level variables
	mCalcBP = .T.
	mBillMonth = pBillMonth
	mBillYear = pBillYear
	mBegFran = ALLTRIM(pBegFran)
	mEndFran = ALLTRIM(pEndFran)
	mRptDate =  CMONTH(DATE()) + " " + LTRIM(STR(DAY(DATE()),2)) + ", " + STR(YEAR(DATE()),4)
	mSysTime = LEFT(TIME(),5)
	mSysOffice= pSysOffice
	mDlrCode = ""
	mNoteDate = ""
	mfNote1 = 0
	mfNote2 = 0
	mRebatePercent = 0
	mAcctFee = 0
	mRebateAmt = 0
	mIdx = 0
	mCustStat = ""
  	mContBill = 0      

	*-------------------------------------------



	*-------------------------------------------
	* needed for customers with multiples ff's
	PRIVATE mFirstOne
	mFirstOne = .t.		
	*-------------------------------------------

	*-------------------------------------------
	* If the file BPasValue exists, you need to treat the jkcmpfil.Business value
	* just as it is, not as a % value.  Added for Australia, their BP is a fixed
	* amount, not a % of revenue.  KMC 10/27/99
	if file('BPasVal')
	  mCalcBP = .F.
	endif    
	*-------------------------------------------

	CLEAR

	*-------------------------------------------
	* open control tables and control variables
	USE jkcmpfil INDEX jkcmpfil IN 1 ALIAS tblCompany 

	PRIVATE mTaxAll
	PRIVATE mBa1
	PRIVATE mBa2
	PRIVATE mBa3
	PRIVATE mBa4
	PRIVATE mBs1
	PRIVATE mBs2
	PRIVATE mBs3
	PRIVATE mBs4
	PRIVATE mRoyalty
	Private mDFFIBPay
	Private mmDFFIBPy1
	Private mDFFIBPy2

	mTaxAll = tblCompany.tax_all
	mBa1 = tblCompany.bt_amtmo1
	mBa2 = tblCompany.bt_amtmo2
	mBa3 = tblCompany.bt_amtmo3
	mBa4 = tblCompany.bt_amtmo4
	mBs1 = tblCompany.bt_sales1
	mBs2 = tblCompany.bt_sales2
	mBs3 = tblCompany.bt_sales3
	mBs4 = tblCompany.bt_sales4
	mRoyalty = tblCompany.royalty
	
	*-------------------	
	* KMC 05/10/2002
	mDFFIBPy1 = tblCompany.FFIBPay  
	* KMC 05/20/2002 To Accomodate WDC's dual UFOC Dates.
	* One for Maryland, one for all others.
	* FFIBPay in jkcmpfil is for All Others, 
	* mDFFIBPay2 is for WDC only, Franchisees in Maryland only.
	if left(tblCompany.company_no,5) = "WDC27"
		mDFFIBPy2 = tblCompany.FFIBPay2
	endif	
	*-------------------
	sele tblCompany
	use
		
	*-------------------------------------------

	*-------------------------------------------
	PRIVATE tmpMon = ""
	tmpMon = STR(mBillMonth ,2)

	IF SET("DATE") = "BRITISH"
	  mNoteDate = gomonth(ctod("05/" + tmpMon + "/" + right(str(mBillYear ),4)),1)
	ELSE
	  mNoteDate = gomonth(ctod(tmpMon + "/05/" + right(str(mBillYear ),4)),1)
	ENDIF
	*-------------------------------------------

	*-------------------------------------------
	* opening data tables...
	
	lMsg = "Opening Databases..."
	WAIT WINDOW lMsg NOWAIT

	SELECT 1
	USE jkdlrfil INDEX jkdlrfil.idx ALIAS tblDlrFil
	set filter to tblDlrFil.status = "Y" .and. between(tblDlrFil.dlr_code, mBegFran, mEndFran) .and. tblDlrFil.company_no = mSysOffice
	go top

	SELECT 2
	USE jkdlrtrx INDEX jkdlrtrx ALIAS tblDlrTrx
	SET FILTER TO company_no = mSysOffice .AND. bill_mon = mBillMonth .and. bill_year = mBillYear
	GO TOP

	SELECT 3
	USE jkcusfil INDEX jkcusfil.idx ALIAS tblCusFil
	GO TOP

	SELECT 4
	use jkcustrx index jkcustrx alias tblCusTrx
	set filter to tblCusTrx.company_no = mSysOffice and tblCusTrx.bill_mon = mBillMonth and tblCusTrx.bill_year = mBillYear
	SET RELATION TO mSysOffice + tblCusTrx.dlr_code + tblCusTrx.cust_no into tblCusFil
	go top

	SELECT 5
	USE jkleafil INDEX jkleafil ALIAS tblLeaseFil

	SELECT 6
	USE jkdnofil INDEX jkdnofil ALIAS tblDlrNote

	SELECT 7 
	USE jkcusff ALIAS tblFF 
	set order to company_no

	SELECT 8
	USE tmpsprd index tmpsprd alias tblSpread
	set filter to bill_mon = mBillMonth .and. bill_year = mBillYear	
	go top

	SELECT 9
	USE jkpstfil alias tblPostFile
	set order to tran_type
	set filter to bill_mon = mBillMonth .and. bill_year = mBillYear
	go top

	use jkactreb order dlr_code in 0 alias tblAcctRebate
	use jktaxtbl order county in 0 alias tblTax
	PRIVATE mLeaseTax
	mLeaseTax = tblTax.lease_tax

	select tblDlrFil
	set rela to dlr_county into tblTax addi
	
	use cur_fran in 0 
	use cur_leas in 0 
	use cur_cat in 0 
	
	*-------------------------------------------

	*-------------------------------------------
	* begin report processing

	Private lMsg
	lMsg = ""
	
	lMsg = "Initializing Tables..."
	WAIT WINDOW lMsg NOWAIT
	initializeTables() 

	SELECT tblDlrFil	
	go top
	DO WHILE .not. EOF() 
		
		lMsg = "Now Processing Franchise " + ALLTRIM(tblDlrFil.dlr_code) + "..."
		WAIT WINDOW lMsg NOWAIT
		mDlrCode = tblDlrFil.dlr_code
		
		* these variables are used throughout the
		* process... here we're just
		* setting the defaults....
		store 0 to ;
			f_cont,f_rev,f_xwrk,CUST_SUPP,f_1_in,f_totl,f_ff,f_ctax,cust_stax,f_royal,f_comm_1_in,;
	        f_lease,f_le_tax,f_supp,f_stax,f_acct,f_bp,f_bond,f_note,f_sec_note,;
	        f_cb,f_misc,f_rom,f_romtax,f_mtax,tot_misc,tax_misc,tot_ro,tax_ro,f_atax,f_fftax,f_rtax,;
	        f_1tax,f_bptax,f_btax,f_ptax,f_pagers,f_pagers2,f_cbtax,f_ff_down,f_ffd_tax,f_adv,f_advtax,;
	        ro_deduct,spec_deduct,tot_deduct,f_due,f_note_tax,f_sectax, MON_INT,f_ad,f_adtax, f_feecr
	    store " " to f_note_num,f_sec_num
	    store .F. to xnote,xnote2,xpage,xpage2			
		store 0 TO trx_ttl, ttl_tax, ttl_trx, m.num_cust
		*----------------------------
			
		generateCustTrx()
		
		generateFranCalc()  

		generateFranLease()

		generateFranSupply()
		
		generateFranMisc()
		
		generateFranRegion()
		
		generateFranCB()
		
		updateSpreadSheet()
		
		generateFranTotals()
		
		skip
		
	enddo
	
endfunc

*-------------------------------------------


*===========================================
* start of functions......

*-------------------------------------------
* Purpose: to calculate rebate
*-------------------------------------------
function CalcRebate(rebateElig)
	
	lCurFil4 = select()
	
	IF rebateElig
		DO CASE
			CASE between(m.F_Totl,25000.01,45000.00)
  				mRebatePercent = .5
			CASE BETWEEN(m.F_Totl,45000.01,65000.00)
  				mRebatePercent=1.0
			CASE BETWEEN(m.F_Totl,65000.01,85000.00)
  				mRebatePercent=1.5
			CASE m.F_Totl > 85000.00
  				mRebatePercent=2.0
			OTHERWISE 
  				mRebatePercent=0
		ENDCASE
		mAcctFee = m.f_acct + m.f_atax
		mRebateAmt = round(m.F_Totl * (mRebatePercent / 100),2)
	eLSE
		mRebateAmt = 0.00
  	ENDIF 
  	
  	select(lCurFil4)
  	
endfunc
*-------------------------------------------
* Purpose: to calculate and generate franchise data
*-------------------------------------------
function generateFranCalc
	
	lCusFil2 = SELECT()
	
	* Check value of CalcBP to see how to 
	* calculate BP - used for Austrialia
	if mCalcBP
  		f_bp = round((f_rev + f_xwrk + f_1_in) * (tblDlrFil.business / 100),2)
  	else
    	f_bp = tblDlrFil.business
  	endif 
  	
  	* set module level values..
  	mFNote1 = 0 
	mFNote2 = 0
	
  	f_bp = round((f_rev + f_xwrk + f_1_in) * (tblDlrFil.business / 100),2)
  	if tblDlrFil.ded_ad 
    	f_ad = round((f_rev + f_xwrk + f_1_in + cust_supp) * (tblDlrFil.ad_cur / 100),2)  
  	endif
 	if tblDlrFil.pct_flag = "Y"
    	f_acct = round(f_totl*(tblDlrFil.add_pct / 100),2)
  	endif
  	
  	* set beeper data information...
  	f_pagers = tblDlrFil.num_beeps * tblDlrFil.beep_cost
	f_pagers2 = tblDlrFil.num_beeps2 * tblDlrFil.beep_cost2
  	if f_pagers > 0
     	xpage= .T.
  	endif
	if f_pagers2 > 0
    	xpage2 = .t.
  	endif
  	
  	do case
  		case (f_rev + f_xwrk + f_1_in) <= 0
    		f_bond = 0
  		case (f_rev + f_xwrk + f_1_in) <= mBs1 .and. mBs1 # 0
    		f_bond = mBa1
  		case (f_rev + f_xwrk + f_1_in) <= mBs2 .and. mBs2 # 0
    		f_bond = mBa2
  		case (f_rev + f_xwrk + f_1_in) <= mBs3 .and. mBs3 # 0
    		f_bond = mBa3
  		case (f_rev + f_xwrk + f_1_in) <= mBs4 .and. mBs4 # 0
    		f_bond = mBa4
  	endcase
  	
  	*-----------------
  	* 05/06/2002 KMC 
	* New franchisees signed from jkcmpfil.FFIBPay forward use FF IB Projected Payment schedule and jkplans2. 
	* Must have field FFIBPay (Type Date) in jkcmpfil.  Frans signed AFTER this date use the new FF IB pymnt sched.
    * 05/10/2002 KMC - Changed company.FFIBPay to mDFFIBPay
	
	* 05/20/2002 KMC  - To Accomodate WDC's dual UFOC Dates.
	if left(company_no,5)="WDC27"
		if tblDlrFil.dlr_state="MD"
			mDFFIBPay=mDFFIBPy2
		endif
	else
		mDFFIBPay=mDFFIBPy1
	endif		
  	*-----------------
  	
  	* new note calculation routine....	
	if !empty(mDFFIBPay) and tblDlrFil.date_sign => mDFFIBPay 
 		if tblDlrFil.take_note = "Y"
 			* First Paymnet not yet made.
 			if tblDlrFil.pymnt_bill = 0
 				do case
					case tblDlrFil.plantype = "A"
					
  						*--> pull first payment when revenue meets or exceeds 500.00.
  						IF f_rev => 500.00
     						xnote = .T.
 							f_note = tblDlrFil.tblDlrFil_pymnt
						endif
						
					otherwise 
  						
  						*--> pull first payment when revenue meets or exceeds 1000.00.
  						IF f_rev => 1000.00
     						xnote = .T.
     						f_note = tblDlrFil.tblDlrFil_pymnt
						endif
						
				endcase
				
			else
			
  				*--> pull subsequent payments when revenue meets or exceeds FF IB Payment Amount.
  				IF tblDlrFil.pymnt_bill < tblDlrFil.pymnt_totl AND f_rev >= tblDlrFil.fran_pymnt	 				
					xnote = .T.
   	 	 			f_note = tblDlrFil.fran_pymnt
				endif
				
			ENDIF
			
			f_note_num = ALLTRIM(str(tblDlrFil.pymnt_bill + 1)) + " of " + alltrim(str(tblDlrFil.pymnt_totl))
			mFNote1 =tblDlrFil.pymnt_bill+1
			
			setPostFile(_RPT_UPDATE,"N1")
			
  		else
  		
			setPostFile(_RPT_DELETE,"N1")
			
   		endif
   		
  	else
		
		* original note calculations		
	  	if tblDlrFil.take_note = "Y" .and. tblDlrFil.pymnt_bill < tblDlrFil.pymnt_totl .and. ;
     		((f_rev >= tblDlrFil.min_sales) .or. (mNoteDate >= tblDlrFil.date_2) .or. (tblDlrFil.pymnt_bill > 0))
     	
 			xnote = .T.
 			f_note = tblDlrFil.fran_pymnt
 			f_note_num = ALLTRIM(str(tblDlrFil.pymnt_bill + 1)) + " of " + alltrim(str(tblDlrFil.pymnt_totl))
			mFNote1 = tblDlrFil.pymnt_bill +1  
    	    
    		setPostFile(_RPT_UPDATE,"N1")
     	
  		else
  			
  			setPostFile(_RPT_DELETE,"N1")

   		endif

	  	if tblDlrFil.sec_note = "Y" .and. tblDlrFil.sec_pybill < tblDlrFil.sec_pytotl .and. mNoteDate  > sec_date 
	  	
	    	xnote2 = .T.
			f_sec_note = tblDlrFil.sec_pymnt
			f_sec_num = alltrim(str(tblDlrFil.sec_pybill+1)) + " of " + alltrim(str(tblDlrFil.sec_pytotl))
			mFNote2 = tblDlrFil.sec_pybill + 1
			
			setPostFile(_RPT_UPDATE,"N2")
			 
		else
	     	
	     	setPostFile(_RPT_UPDATE,"N2")
	     	
	  	endif 
  	
  	endif	
	
	CalcRebate(tblDlrFil.RebElig)
	
  	select (lCusFil2) 
 
endfunc

*-------------------------------------------
* Purpose: to generate customer transactions page...
*-------------------------------------------
FUNCTION generateCustTrx()
	
	Private lCustNo
	PRIVATE lIdx
	PRIVATE lArySize 
	lCusFil = SELECT()
		
	lCustNo = ""
	lIdx = 1
	
	* verify the franchise has customers
	* transactions....
	sele tblCusTrx
  	seek mSysOffice + mDlrCode
	if eof()   	  	
		SELECT(lCusFil)
	    return
	endif
	
	* create a dummy array with at least one row
	* this is done here so that all the following procedures can
	* access the data
	DIMENSION mAryCusTot(1,6)
	* set the default on the first array to empty....
	mAryCusTot(1,_RPT_CUSTOMER_NO) = ""
	mAryCusTot(1,_RPT_CURRENT_MONTH_BILLING) = 0
	mAryCusTot(1,_RPT_ADDITIONAL_BILLING_FRAN) = 0
   	mAryCusTot(1,_RPT_ClIENT_SUPPLIES) = 0
	mAryCusTot(1,_RPT_ADDITIONAL_BILLING_OFFICE) = 0
	mAryCusTot(1,_RPT_TOTAL_BILLING) = 0
	
	* load and set the size of the array	
	lArySize = loadArray(@mAryCusTot)
		  
 	* process transaction as long as the franchise
 	* has transactions...
 	sele tblCusTrx
 	do while mDlrCode = tblCusTrx.dlr_code
 	
 		* get the index to the customer currently
 		* being processed....
    	lIdx = findArray(tblCusTrx.cust_no,_RPT_CUSTOMER_NO,@lArySize,@mAryCusTot)
        	
    	* set the contract billing if applicable...
    	if !((tblCusFil.canc_date < date()) .and. (tblCusFil.canc_date#CTOD("  /  /  ")))
			if !(tblCusFil.seconddate#CTOD("  /  /  ") .and. tblCusFil.seconddate < DATE())
		    	f_cont = f_cont + tblCusFil.cont_bill
			endif
		endif    	

		* process records for current customer....
		do while mAryCusTot(lIdx,_RPT_CUSTOMER_NO) = tblCusTrx.cust_no
      		
      		* set the multiply by varible	
      		IF tblCusTrx.trx_type = 'I'
	        	multiply = 1
	      	ELSE
	        	multiply = -1
	      	ENDIF
 			
 			ttl_trx = ttl_trx + (trx_amt * multiply)
 			ttl_tax = ttl_tax + (trx_tax * multiply)
 			trx_ttl = trx_ttl + ((trx_amt + trx_tax)* multiply)
 			
 			* perform calculations based on tranaction class... 			
 			DO CASE
        		CASE trx_class = "B"
          			mAryCusTot(lIdx,_RPT_CURRENT_MONTH_BILLING) = mAryCusTot(lIdx,_RPT_CURRENT_MONTH_BILLING) + (trx_amt * multiply)
          			f_rev = f_rev + (trx_amt * multiply)
          			f_royal = f_royal + round(((trx_amt * (tblCusFil.royalty / 100)) * multiply),4)
          			f_ctax = f_ctax +  ROUND((trx_tax * multiply),2)
        		CASE trx_class = "E"
          			mAryCusTot(lIdx,_RPT_ADDITIONAL_BILLING_FRAN) = mAryCusTot(lIdx,_RPT_ADDITIONAL_BILLING_FRAN) + (trx_amt * multiply)
          			f_xwrk = f_xwrk + (trx_amt * multiply)
          			f_royal = f_royal + round(((trx_amt * (tblCusFil.royalty / 100)) * multiply),4)
          			f_ctax = f_ctax +  ROUND((trx_tax * multiply),2)
        		CASE trx_class = "S"
         			mAryCusTot(lIdx,_RPT_ClIENT_SUPPLIES) = mAryCusTot(lIdx,_RPT_ClIENT_SUPPLIES) + (trx_amt * multiply)
          			CUST_SUPP = CUST_SUPP + (trx_amt * multiply)
          			f_royal = f_royal + round(((trx_amt * (tblCusFil.royalty / 100)) * multiply),4)
          			cust_stax = cust_stax +  ROUND((trx_tax * multiply),2)
        		CASE trx_class $ "OI"
          			mAryCusTot(lIdx,_RPT_ADDITIONAL_BILLING_OFFICE) = mAryCusTot(lIdx,_RPT_ADDITIONAL_BILLING_OFFICE) + (trx_amt * multiply)
          			f_1_in = f_1_in + (trx_amt * multiply)
          			f_comm_1_in = f_comm_1_in + round(((trx_amt *((tblCusTrx.royalty - tblCusFil.royalty) / 100)) * multiply),2)
          			f_royal = f_royal + round(((trx_amt * (tblCusFil.royalty / 100)) * multiply),4)
          			f_ctax = f_ctax + ROUND((trx_tax * multiply),2)
      		ENDCASE
      		
      		* total it up....
 			mAryCusTot(lIdx,_RPT_TOTAL_BILLING) = mAryCusTot(lIdx,_RPT_TOTAL_BILLING) + (trx_amt * multiply)
      		f_totl = f_totl +(trx_amt * multiply)
      	
      		skip
 	
 		ENDDO
 		 	
    enddo
    
    * round total down to 2 
  	* decimal places for totals.
  	f_royal = round(f_royal,2)
        
    * save data...
    insertIntoCat(lArySize)
    
  	release mAryCusTot
  
  	select(lCusFil)

endfunc
*-------------------------------------------
* Purpose: to initialize tables that are going to be
* 		   use to store generate report data...
* 		   Delete old records just before creating new ones
*-------------------------------------------
FUNCTION initializeTables()

	lCurFile = SELECT()
	
	sele cur_fran
	dele all for Month = mBillMonth and Year = mBillYear;
	and company_no = mSysOffice and dlr_code = mDlrCode 

	sele cur_leas
	dele all for bill_mon = mBillMonth and bill_year = mBillYear;
	and company_no = mSysOffice and dlr_code = mDlrCode

	sele cur_cat
	dele all for bill_mon = mBillMonth and bill_year = mBillYear;
	and company_no = mSysOffice and dlr_code = mDlrCode

	
	SELECT(lCurFile)
	
ENDFUNC
*-------------------------------------------
* Purpose: to load the array referenced in the parameter...
*		   the function will dynamically add a row to the
*		   array based need.
* Parameters: 
*		pArray = a reference an array...
*-------------------------------------------
function loadArray(pArray)
	
	PRIVATE lCnt
	
	lCnt = 1  

  	sele tblFF  
  	seek msysoffice + mdlrcode 	
          		
  	* currently this test must be done to produce correct resutls....
  	do while tblff.dlr_code = mdlrcode and .not. eof()
		 if (tblff.ff_hold = "Y" and str(tblff.ff_holdyr,4) + str(tblff.ff_holdmon,2) <= str(mbillyear,4) + str(mbillmonth,2)) ;
          		  .or. (tblff.ff_pybill >= tblff.ff_pytotl) ;
          		  .or. (tblff.ff_balance <= 0 ) ;
          		  .or. (str(tblff.ff_year,4) + str(tblff.ff_start,2) > str(mbillyear,4) + str(mbillmonth,2))
          		  
          	skip
          	loop		  
          endif
      		  
  		  * if lCnt is greater than one, the dummy record
  		  * created in the calling function has been used and
  		  * the a row needs to be added...  		  
  		  if lCnt > 1  		  	 			
  			 dimension pArray(lcnt,6)  	
  			 lCnt= lCnt+ 1
  		  ELSE
  		  	 lCnt= lCnt+ 1
  		  endif
  			 
  		  * set the customer number and the default for
  		  pArray(lCnt-1,_RPT_CUSTOMER_NO) = tblff.cust_no
    	  pArray(lCnt-1,_RPT_CURRENT_MONTH_BILLING) = 0
     	  pArray(lCnt-1,_RPT_ADDITIONAL_BILLING_FRAN) = 0
   	 	  pArray(lCnt-1,_RPT_ClIENT_SUPPLIES) = 0
     	  pArray(lCnt-1,_RPT_ADDITIONAL_BILLING_OFFICE) = 0
    	  pArray(lCnt-1,_RPT_TOTAL_BILLING) = 0
  		  
  		  skip
  		  	
    	  DO while pArray(lCnt-1,_RPT_CUSTOMER_NO) = tblff.cust_no and not eof()
    		skip
    	  ENDDO
    	     	 
      	
  	ENDDO
  	
  	* return the size o the array...
	RETURN lCnt-1

endfunc


*-------------------------------------------
* Purpose: to find the index of the data being serach in the
* 		   module level array... this is currently being used to
* 		   get the index of the customer currently being processed...
* 		   if the customer no is not found in the array, its added...
* Parameters:
*		plookFor = this the data being search for...
* 		plookCol = the column to search in...
*		plookLen = the len of the array being searched...
*				   passed by reference and updated if a new
*				   row is entered...
*		pArray = the array being processed... passed by reference
*				 and updated by added a critiria not found...
* Return: 
*		lIdx = the index of the row data is located on or added...
*-------------------------------------------
FUNCTION findArray(plookFor,plookCol,plookLen,pArray)
	
	private lIdx
	PRIVATE lRes
	lIdx = 0
	lRes = .F.
	
	* loop through array and search for the
	* matching criteria
  	FOR xy = 1 to plookLen
  		IF LEN(pArray(xy,plookCol))= 0  		
  			lIdx = 0	
  			exit
  		ENDif 		
  		IF plookFor = pArray(xy,plookCol)    		    		
  			lIdx = xy
    		lRes = .T.		
      		EXIT      			
      	endif	    	
  	NEXT xy
  	
  	* if no match is found then add the a 
  	* new row and set customer number and defaults
  	IF lRes = .F.
  	
  		* add a new row to the array
  		DIMENSION pArray(xy,6)
  		
  		* set the value for the new row...
  		pArray(xy,_RPT_CUSTOMER_NO) = plookFor
    	pArray(xy,_RPT_CURRENT_MONTH_BILLING) = 0
    	pArray(xy,_RPT_ADDITIONAL_BILLING_FRAN) = 0
   	 	pArray(xy,_RPT_ClIENT_SUPPLIES) = 0
    	pArray(xy,_RPT_ADDITIONAL_BILLING_OFFICE) = 0
    	pArray(xy,_RPT_TOTAL_BILLING) = 0 
    	
    	* set the array size to the new value    	 
    	plookLen = xy  	
    	
    	* set the idx to the new item    	
  		lIdx = xy
  		
  	endif
  	
  	* return the index where the 
  	* item was found or added...
	RETURN lIdx
	
endfunc
*-------------------------------------------
* Purpose: to process finder's fee's
*-------------------------------------------
function processFFs()

	lCusFil3 = select()
	
	lSeq1 = .f.  
		
  	sele tblFF
  	SEEK mSysOffice + tblCusFil.dlr_code + tblCusFil.cust_no
	
	if FOUND()
    	do while .not. eof() .and. tblCusFil.cust_no = tblFF.cust_no
      		ff_num = "None"
		    ff_amt = 0
      		ff_dp = .f.
      		do case
      			case tblFF.calc_fact $ "SF"
		        	
		        	if tblFF.ff_dwnpd = "N"
		          		ff_dp = .t.
			            ff_amt = ff_dwnamt
				        ff_num = "Down Pmt"
		          		if tblFF.add_on = "Y"
		            		ff_amt = ff_amt + tblFF.ff_pyamt
		            		ff_num = "1 of " + alltrim(str(tblFF.ff_pytotl))
		            		ff_dp = .f.
		          		endif      
        			else
          				ff_amt = tblFF.ff_pyamt
          				ff_num = alltrim(str(tblFF.ff_pybill+1)) + " of " + alltrim(str(tblFF.ff_pytotl))  
        			endif
		        	if ff_amt >= tblFF.ff_balance 
		          		ff_amt = tblFF.ff_balance
		          		ff_num = "Final Pmt"
		        	endif
		        	if tblFF.ff_pybill+1 = tblFF.ff_pytotl
		          		ff_num = "Final Pmt"
		        	endif 
		        	 
      			case tblFF.calc_fact = "M"
        			
        			if tblDlrFil.NewFF and str(ff_year,4) + str(ff_start,2) >= str(year(tblDlrFil.ffdate),4) + str(month(tblDlrFil.ffdate),2)
          				NEW_FF_PERC = .05
        			else
          				NEW_FF_PERC = .1
        			endif
        			if tblFF.ff_dwnpd = "N"
          				ff_dp = .t.     
          				ff_amt = (mAryCusTot(mIdx,2) - (tblFF.ffcredit +  tblFF.ff_adjtot)) * (tblFF.ff_down / 100)
          				ff_num = "Down Pmt"
          				if tblFF.add_on = "Y"            
            				ff_amt = ff_amt + ((mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * M.NEW_FF_PERC)
            				ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"
            				ff_dp = .f.
          				endif      
        			else
          				ff_amt = (mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * M.NEW_FF_PERC
          				ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"  
        			endif          
        			if ff_amt >= tblFF.ff_balance 
          				ff_amt = tblFF.ff_balance
          				ff_num = "Final Pmt"
        			endif
        			if tblFF.ff_pybill+1 = tblFF.ff_pytotl
          				ff_num = "Final Pmt"
        			endif  
        			
      			case tblFF.calc_fact = "L"
      	
        			if tblFF.ff_dwnpd = "N"        			
          				ff_dp = .t.
          				ff_amt = (mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * (tblFF.ff_down / 100)
          				ff_num = "Down Pmt"
          				if tblFF.add_on = "Y"            
            				ff_amt = ff_amt + ((mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * .1)
            				if ff_pytotl=99
              					ff_num = "10% of Currnt"
            				else  
              					ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"
            				endif
            				ff_dp = .f.
          				endif      
        			else          
          				ff_amt = (mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * .1
          				if ff_pytotl=99
            				ff_num = "10% of Currnt"
          				else  
            				ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"
          				endif
        			endif          
        			
      			case tblFF.calc_fact = "P"
		        	
		        	if tblFF.ff_dwnpd = "N"
		          		ff_dp = .t.
		          		ff_amt = (mAryCusTot(mIdx,2) - tblFF.ffcredit) * (tblFF.ff_down / 100)
		          		ff_num = "Down Pmt"
		          		if tblFF.add_on = "Y"
		            		ff_amt = ff_amt + ((mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * .1)
		            		if ff_pytotl=99
		              			ff_num = "10% of Currnt"
		            		else  
		              			ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"
		            		endif
		            		ff_dp = .f.
		          		endif      
		        	else          
		          		ff_amt = (mAryCusTot(mIdx,2)-(tblFF.ffcredit + tblFF.ff_adjtot)) *.1
		          		if ff_pytotl=99
		            		ff_num = "10% of Currnt"
		          		else  
		            		ff_num = alltrim(str(round(((tblFF.ff_amtpaid + ff_amt) / tblFF.ff_tot) * 100,2),6,2)) + "% of Totl"
		          		endif
		        	endif          
		        	
      			case tblFF.calc_fact = "A"
        			
        			if tblFF.ff_dwnpd = "N"
          				ff_dp = .t.
          				ff_amt = (mAryCusTot(mIdx,2) - tblFF.ffcredit) * (tblFF.ff_down/100)
          				ff_num = "Down Pmt"
          				if tblFF.add_on = "Y"            
		            		ff_amt = ff_amt + ((mAryCusTot(mIdx,2) - (tblFF.ffcredit + tblFF.ff_adjtot)) * .1)
		            		ff_num = "10% of Currnt"
		            		ff_dp = .f.
		          		endif      
		        	else
		          		ff_amt = (mAryCusTot(mIdx,2)-(tblFF.ffcredit + tblFF.ff_adjtot)) * .1
		          		ff_num = "10% of Currnt"
		        	endif          
		        	
      			endcase
		      	
		      	if (tblFF.ff_hold = "Y" AND str(tblFF.ff_holdyr,4) + str(tblFF.ff_holdmon,2) <= str(mBillYear,4) + str(mBillMonth,2)) ;
		          	.or. (tblFF.ff_pybill >= tblFF.ff_pytotl) ;
		          	.or. (tblFF.ff_balance <=0 ) ;
		          	.or. (str(tblFF.ff_year,4) + str(tblFF.ff_start,2) > str(mBillyear,4) + str(mBillMonth,2)) 
		        		ff_num = "None"
		        		ff_amt = 0
		      	endif
		      	
      			if ff_dp 
        			f_ff_down = f_ff_down + ff_amt
      			else
        			f_ff = f_ff + ff_amt
      			endif
      
      			* for past reports
      			lCusFil4 = select()
      			sele cur_cat
		  		* Needed for customers with multiple finders fees
		  		if ff_amt<>0  && 06/11/2002 KMC - Don't FF records that have 0 for the payment amount.  
			      	if mFirstOne = .t.  
					   	repla ff_seq with tblFF.ff_seq
					   	repla ff_nbr with ff_num
					   	repla ff_pymnt with ff_amt
					    mFirstOne = .f.
			   	   	else
					    append blank
					  	repla company_no with mSysOffice
					   	repla bill_mon with mBillMonth
					   	repla bill_year with mBillYear
					   	repla dlr_code with mDlrCode
					   	repla cust_no with mAryCusTot(mIdx,_RPT_CUSTOMER_NO)
					   	repla ff_seq with tblFF.ff_seq
					   	repla cust_stat with mCustStat
					   	repla ff_nbr with ff_num
					   	repla ff_pymnt with ff_amt
	 			  	endif      
 		  
				
      				select tblPostFile
      				seek mSysOffice + mDlrCode + tblCusFil.cust_no + "FF" + ALLTRIM(STR(tblFF.FF_SEQ))
      				if eof() 
						appe blank
	    				REPL company_no with mSysOffice, dlr_code with mDlrCode, cust_no with tblCusFil.cust_no,;
   	    				bill_mon with mBillMonth, bill_year with mBillYear, tran_type with "FF" + ALLTRIM(STR(tblFF.FF_SEQ)),;
  	    				tran_num with iif(ff_dp,0,99), tran_amt with ff_amt
 	  				else
       					REPL tran_num with iif(ff_dp,0,99),tran_amt with ff_amt
      				endif
      			endif
      			
      			SELECT(lCusFil4)
      			      
      		skip
      
    	enddo
    	
  	endif
  	
  	select (lCusFil3)     
  	
endfunc
*-------------------------------------------
* Purpose: to process franchise leases
*-------------------------------------------
function generateFranLease
	
	lCusFil2 = SELECT()
	
	PRIVATE lLeaseNo = ""
	
    sele tblLeaseFil
    seek mSysOffice + mDlrCode
   
    do while .not. eof() .and. mDlrCode = tblLeaseFil.dlr_code
    	lLeaseNo = tblLeaseFil.lease_no
    	IF pymnt_bill < pymnt_totl and ;
    	  (stop # "Y" or (stop = "Y" and ((stop_mon > mBillMonth and stop_year = mBillYear) or stop_year > mBillYear))) 
             
            *--> 03/12/2002 KMC - Code altered so old leases that were taxed month by month
        	*--> can now exist and work with new leases that are taxed 100% up front.
        	*--> Need to verify that jkleafil.paymnt_tax on leases with Tax charged monthly 
	        *--> is correct and that jkleafil.paymnt_tax on leases that charged 100% up front 
    	    *--> is set to 0.        
       		if pymnt_bill = 0
        		lpay_num = "Down Pmt"
        		lpay_amt = tblLeaseFil.paymnt_amt * tblLeaseFil.pymnt_adv
        		if mTaxAll = "Y"
 					lpay_tax = round((tblLeaseFil.paymnt_amt * tblLeaseFil.Pymnt_totl) * (mLeaseTax / 100),2)
        		else
					lpay_tax = round((tblLeaseFil.paymnt_amt * tblLeaseFil.Pymnt_adv) * (tblLeaseFil.Paymnt_Tax / 100),2)
        		endif
        	else
        		lpay_num = alltrim(str(PYMNT_bill + 1)) + " of " + alltrim(str(PYMNT_totl))
        		lpay_amt = tblLeaseFil.paymnt_amt
        		lpay_tax = round(tblLeaseFil.paymnt_amt * (tblLeaseFil.Paymnt_Tax / 100),2)
        	endif			
        
        	f_lease = f_lease + lpay_amt
        	f_le_tax = f_le_tax + lpay_tax
        	        	
        	*--> Populate current lease data.
        	lCurFil3 = select()        	                	
	        sele cur_leas
	        append blank
	        repla company_no with mSysOffice
	        repla bill_mon with mBillMonth
	        repla bill_year with mBillYear
	        repla dlr_code with mDlrCode
	        repla lease_no with tblLeaseFil.lease_no
	        repla descripton with tblLeaseFil.descripton
	        repla make with tblLeaseFil.make
	        repla model with tblLeaseFil.model
	        repla serial with tblLeaseFil.serial
	        repla date_sign with tblLeaseFil.date_sign
	        repla pymnt_num with lpay_num
	        repla pymnt_amt with lpay_amt
	        repla pymnt_tax with lpay_tax 

	    	
        	select tblPostFile
        	seek mSysOffice + mDlrCode + "FRANCH" + lLeaseNo 
        	if eof()
	         	APPE BLANK
 	         	REPL company_no with mSysOffice,dlr_code with mDlrCode,cust_no with "FRANCH",;
 	            bill_mon with mBillMonth,bill_year with mBillYear,tran_type with lLeaseNo,;
 	            tran_num with iif(tblLeaseFil.pymnt_bill=0,tblLeaseFil.pymnt_adv,tblLeaseFil.pymnt_bill + 1),tran_amt with lpay_amt + lpay_tax
 	   		else
  	        	REPL tran_num with iif(tblLeaseFil.pymnt_bill=0,tblLeaseFil.pymnt_adv,tblLeaseFil.pymnt_bill + 1),tran_amt with lpay_amt + lpay_tax
  	   		endif
        	
        	select (lCurFil3 )     
        	
      	endif
      	
      	skip
      	
    enddo
    
    select tblDlrTrx
    seek mDlrCode + "L"
    do while .NOT. eof() .AND. tblDlrTrx.trx_class = "L" .and. tblDlrTrx.dlr_code = mDlrCode
      	if trx_type = "I"
        	multiply = 1
     	else
        	multiply = -1
     	endif
      	f_lease = f_lease + (tblDlrTrx.trx_amt * multiply)
      	f_le_tax = f_le_tax + (tblDlrTrx.trx_tax * multiply)
      	skip      	
    enddo   
           
    seek mDlrCode + "E"
    do while .NOT. EOF() .AND. tblDlrTrx.trx_class = "E" .and. tblDlrTrx.dlr_code = mDlrCode     	      	
      	if trx_type = "I"
        	multiply = 1
      	else
        	multiply = -1
      	endif            	
      	f_lease = f_lease + (tblDlrTrx.trx_amt * multiply)
      	f_le_tax = f_le_tax + (tblDlrTrx.trx_tax * multiply)      	
      	skip      	
    enddo          
	    
    select (lCusFil2)     
    
endfunc
*-------------------------------------------
* Purpose: to generate the supply report...
*-------------------------------------------
function generateFranSupply
	
	lCurFil2 = SELECT()
  	
  	select tblDlrTrx
  	seek mDlrCode + "S"  	
  	do while .not. eof() .and. mDlrCode = tblDlrTrx.dlr_code .and. tblDlrTrx.trx_class = "S"        
    	if tblDlrTrx.trx_type = 'C'
      		multiply = -1
    	else
      		multiply = 1
    	endif
    	f_supp = f_supp + ((tblDlrTrx.trx_amt * quantity) * multiply)
    	f_stax = f_stax + ROUND((tblDlrTrx.trx_tax * multiply),2)    	
    	skip
  	enddo 
  	
  SELECT(lCurFil2)     
  
endfunc
*-------------------------------------------
* Purpose: to generate the miscellenous report...
*-------------------------------------------
function generateFranMisc
	
	lCurFil2 = select()
	
	select tblDlrTrx  
	
  	seek mDlrCode + "B"  	
  	typex = "Bond"
  	do MiscReport WITH "B",f_bond,f_btax
 	
 	seek mDlrCode + "J" 	
  	typex = "Advertising"
  	do MiscReport with "J",f_ad,f_adtax
  
  	seek mDlrCode + "M"
  	typex = "Misc"
  	do MiscReport with "M",f_misc,f_mtax

  	*--> 10/9/2001 KMC
  	seek mDlrCode + "Z"
  	typex = "Donation"
  	do MiscReport with "Z",f_misc,f_mtax
  	*--> KMC	

  	seek mDlrCode + "P"
  	typex = "Bus Prot"
  	do MiscReport with "P",f_bp,f_bptax
  	
  	seek mDlrCode + "Q"
  	typex = "Pagers"
  	do MiscReport with "Q",f_pagers,f_ptax

  	*  X code for advances
  	*  These transactions were added so that the advances could be
  	*  seperated for the special trust account recap
  	*  these amount are reported as special miscellanious on the dealer
  	*  reports and on the spreadsheet
  	*
  	seek mDlrCode + "X"
  	typex = "Advance"
  	do MiscReport with "X",f_adv,f_advtax

  	* KMC 08/24/2000 Changed to keep advances out of misc total on spreadsheet.
  	* put back for STA recap - took advances column off spreadsheet - just like old spreadsheet.
   	f_misc = f_misc + f_adv
   	f_mtax = f_mtax + f_advtax
  	* KMC

  	seek mDlrCode + "G"
  	typex = "Neg. Roll-Over"
  	do MiscReport with "G",f_misc,f_mtax
	
	select(lCurFil2)

endfunc
*-------------------------------------------
* Purpose: to generate the miscellenous report...
* Parameters:  not sure why we're passing memory value....
*-------------------------------------------
function MiscReport
	PARAMETERS m.a_class,m.tot,m.tax

	do while .not. eof() .and. mDlrCode = tblDlrTrx.dlr_code .and. tblDlrTrx.trx_class = m.a_class
    	if tblDlrTrx.trx_type = 'C'
      		multiply = -1
    	else
      		multiply = 1
    	endif
    	m.tot = m.tot + (tblDlrTrx.trx_amt * tblDlrTrx.quantity * multiply)
    	m.tax = m.tax + (tblDlrTrx.trx_tax * multiply)
    	m.tot_misc = m.tot_misc + (tblDlrTrx.trx_amt * tblDlrTrx.quantity * multiply)
    	m.tax_misc = m.tax_misc + (tblDlrTrx.trx_tax * multiply)
    	
    	skip
	enddo  
ENDFUNC
*-------------------------------------------
* Purpose: 	
* Parameters:  none
*-------------------------------------------
FUNCTION generateFranRegion
	
	lCurFil2 = SELECT()
	
  	select tblDlrTrx
  	
  	seek mDlrCode + "A"
  	typex = "Acct & Admin"
 	do MiscReport2 WITH "A",f_acct,f_Atax
 	 
  	seek mDlrCode + "D"
  	typex = "Finders Fees"
  	do MiscReport2 with "D",f_ff,f_fftax
  
  	seek mDlrCode + "H"
  	typex = "Finders Fees"
  	do MiscReport2 with "H",f_ff_down,f_ffd_tax
  
  	seek mDlrCode + "F"
  	typex = "Franchise Note"
  	do MiscReport2 with "F",f_note,f_note_tax
  	
  	seek mDlrCode + "N"
  	typex = "Second Note"
  	do MiscReport2 with "N",f_sec_note,f_sectax  

  	seek mDlrCode + "R"
  	typex = "Royalty"
  	do MiscReport2 with "R",f_royal,f_rtax
  	
  	seek mDlrCode + "T"
  	typex = "Addtl Bill Comm"
  	do MiscReport2 with "T",f_comm_1_in,f_1tax
  	
  	seek mDlrCode + "O"
  	typex = "Misc RO"
  	do MiscReport2 with "O",f_rom,f_romtax
 	
 	SELECT(lCurFil2)
 
endfunc
*-------------------------------------------
* Purpose: to generate the miscellenous report 2...
* Parameters:  not sure why we're passing memory value....
*-------------------------------------------
function MiscReport2
	PARAMETERS m.a_class,m.tot,m.tax
	
	* the calling function selected the table....
 	do while .not. eof() .and. mDlrCode = tblDlrTrx.dlr_code .and. tblDlrTrx.trx_class = m.a_class   
	    if tblDlrTrx.trx_type = 'C'
	      multiply = -1
	    else
	      multiply = 1
	    endif
	    m.tot = m.tot + (tblDlrTrx.trx_amt * tblDlrTrx.quantity * multiply)
	    m.tax = m.tax + (tblDlrTrx.trx_tax * multiply)
	    m.tot_ro = m.tot_ro + (tblDlrTrx.trx_amt * tblDlrTrx.quantity*  multiply)
	    m.tax_ro = m.tax_ro + (tblDlrTrx.trx_tax * multiply)
	    skip
  enddo
return      
*-------------------------------------------
* Purpose: to generate the charge back report..
* Parameters:  none
*-------------------------------------------
function generateFranCB
	
	lCusFil2 = SELECT()
  	
  	select tblDlrTrx
  	
  	seek mDlrCode + "C"
  	do while .not. eof() .and. mDlrCode = tblDlrTrx.dlr_code .and. tblDlrTrx.trx_class = "C"    
    	IF tblDlrTrx.trx_type = 'C'
    		multiply = -1
    	ELSE
      		multiply = 1
    	ENDIF
        
    	f_cb = f_cb + (tblDlrTrx.trx_amt * multiply)
    	f_cbtax = f_cbtax + (tblDlrTrx.trx_tax * multiply)
    
    	if trx_type="I" 
    		f_feecr= f_feecr + Tax + Roy_cb + Acct_cb + Adv_cb + BP_cb
    	endif
    	
    
    	SKIP
    	
	enddo      
  	
  	SELECT(lCusFil2)
  
RETURN
*-------------------------------------------
* Purpose: to update spreadsheet information
* Parameters:  none
*-------------------------------------------
function updateSpreadSheet

	lCusfil2 = SELECT()

  	ro_deduct = ROUND(f_royal + f_rtax + f_acct + f_atax + f_comm_1_in + f_1tax + ;
                f_ff + f_fftax + f_supp + f_stax + f_rom + f_romtax + ;
                f_note + f_sec_note + f_ff_down + f_ffd_tax,2)
 
	* 08/24/2000 KMC Added in f_adv+f_advtax
 	* took back out KMC
 	spec_deduct = ROUND(f_lease + f_le_tax + f_bp + f_bptax + f_bond + f_btax + f_cb + ;
                  f_ctax + cust_stax + f_cbtax + f_misc + f_mtax + f_pagers + ;
                  f_pagers2 + f_ptax + f_ad + f_adtax,2)
 
 	tot_deduct = ro_deduct + spec_deduct
    f_due = f_totl + ROUND(f_ctax,2) + ROUND(cust_stax,2) - tot_deduct
   
    select tblSpread
  	seek mSysOffice + mDlrCode
  	if eof()
    	appe blank
  	endif
  	repl company_no with mSysOffice, dlr_code with mDlrCode, cust_no with "FRANCH", dlr_name with tblDlrFil.dlr_name,;
       bill_mon with mBillMonth, bill_year with mBillYear, t_contract with F_CONT, t_revenue with f_rev,;
       t_supplies with cust_supp,t_franchis with f_note, t_bus_prot with f_bp + f_bptax,;       
       t_bond with f_bond + f_btax, t_lease with f_lease, t_lease_tx with f_le_tax,;
       t_royalty with f_royal + f_rtax, t_find_fee with f_ff + f_fftax, t_ff_down with f_ff_down + f_ffd_tax,;
       t_supp_tax with cust_stax,t_misc with f_misc + f_mtax, t_e_work with f_xwrk,;
       t_1_in with f_1_in,t_1_in_com with f_comm_1_in + f_1tax,t_dlr_sup with f_supp,;
       t_admin with f_acct + f_atax,t_chrg_bk with f_cb + f_cbtax,t_advance with f_adv + f_advtax,;
       t_inv_ttl with f_totl + cust_stax + f_ctax,t_deduct with ro_deduct - mRebateAmt, t_ttl_ded with tot_deduct,;
       t_due_dlr with iif(f_due > 0,f_due,0),t_frm_dlr with iif(f_due < 0,f_due,0),;
       t_misc_ro with f_rom + f_romtax, t_cont_tax with f_ctax, dlr_sup_tx with f_stax, t_sec_note with f_sec_note,;
       t_pager with f_pagers + f_pagers2 + f_ptax, t_acctreb with mRebateAmt,;
       t_ad with f_ad + f_adtax, fees_cr with f_feecr

  	select tblAcctRebate
  	seek mSysOffice + mDlrCode + str(mBillYear,4) + str(mBillMonth,2)
  	if eof() and mRebateAmt > 0
		appe blank
	   	repl company_no with mSysOffice,dlr_code with mDlrCode, ;
	    	bill_mon with mBillMonth,bill_year with mBillYear, ;
	    	GrossRev with m.f_totl, AcctFee with mAcctFee, ;
	    	RebateAmt with mRebateAmt, RebatePerc with mRebatePercent
	   sele tblDlrFil
	   repl tblDlrFil.RebBal with tblDlrFil.RebBal + mRebateAmt
  	else
	    OldRebate = tblAcctRebate.RebateAmt
	    repl GrossRev with m.f_totl, AcctFee with mAcctFee, ;
	         RebateAmt with mRebateAmt, RebatePerc with mRebatePercent
	    sele tblDlrFil
	    repl tblDlrFil.RebBal with tblDlrFil.RebBal - OldRebate + mRebateAmt 
  	ENDIF
  
  	SELECT(lCusFil2)
  
ENDFUNC
*-------------------------------------------
* Purpose: to update spreadsheet information
* Parameters:  none
*-------------------------------------------
function generateFranTotals
  
	lCusFil2 = SELECT()
  
	*--> 08/28/2000 KMC for past reports
	scatter memvar
	insert into cur_fran from memvar
	sele cur_fran
	repla month with mBillMonth
	repla year with mBillYear
	repla royalty with mRoyalty 
	repla bp_admin1 with mBa1
	repla bp_admin2 with mBa2
	repla bt_sale1 with mBs1
	repla bt_sale2 with mBs2	
	repla afr_cur with mRebateAmt
	repla afr_bal with tblDlrFil.rebbal
	repla pymnt_bill with mFNote1
	repla sec_pybill with mFNote2
	*--> 08/28/2000

	SELECT(lCusFil2)

endfunc
*-------------------------------------------
* Purpose: 	to insert the data from the array into table...
* Parameters:  
*		pArraySize = the size of the array
*-------------------------------------------
function insertIntoCat(pArraySize)

  	sele tblCusFil
  	
  	* round total down to 2 
  	* decimal places for totals.
  	f_royal = round(f_royal,2)
  	
	mCustStat = ""
	mContBill  = 0
	
    mIdx = 1
    
    do while mIdx <= pArraySize    
    	
		seek mSysOffice + mDlrCode + mAryCusTot(mIdx,_RPT_CUSTOMER_NO)       
			
		* save data for history reporting.....
		if (tblCusFil.canc_date < date()) .and. (tblCusFil.canc_date#CTOD("  /  /  "))					
			mCustStat = "CANCELLED"
		else
			if (tblCusFil.seconddate < date()) .and. (tblCusFil.seconddate#CTOD("  /  /  "))			
				mCustStat = "TRANSFERED"
			else	    	
	    		mContBill = tblCusFil.cont_bill
			ENDIF		
		endif          
			
		lCusFil2 = select()
    	mFirstOne =.t.  
    	sele cur_cat
  		append blank
    	repla company_no with mSysOffice
    	repla bill_mon with mBillMonth
    	repla bill_year with mBillYear
    	repla dlr_code with mDlrcode
    	repla cust_no with mAryCusTot(mIdx,_RPT_CUSTOMER_NO)
    	repla cont_bill with mContBill 
 	   	repla cur_month with  mAryCusTot(mIdx,_RPT_CURRENT_MONTH_BILLING)
    	repla adtl_b_frn with mAryCusTot(mIdx,_RPT_ADDITIONAL_BILLING_FRAN) 
    	repla client_sup with mAryCusTot(mIdx,_RPT_ClIENT_SUPPLIES)
	    repla adtl_b_ofc with mAryCusTot(mIdx,_RPT_ADDITIONAL_BILLING_OFFICE)
	    repla cust_stat WITH mCustStat
    	sele (lCusFil2)  
    	
  		=processFFs() 
  		 		
		mCustStat = ""  	
		mContBill  = 0
    
    	mIdx = mIdx + 1
	    	
  enddo
   
ENDFUNC
*-------------------------------------------
* Purpose: 	to insert ot remove a record from the post file
* Parameters:  
*		pMode = determines wether the recprod will be 
*				added or removed....
*		pTranType = determines whether the transaction is for the first
*					note or the second note...  valid values are "N1" and "N2"
*-------------------------------------------
FUNCTION setPostFile(pMode,pTranType)
	
	lCusFil3 = select()
	
	select tblPostFile
	seek mSysOffice + mDlrCode + "FRANCH" + pTranType
	
	IF pMode = _RPT_UPDATE		
    		   		
    	if eof()
  			appe blank
  			
  			* determine which note is being processed to populate 
  			* the correct fields
  			IF pTranType = "N1"
   				repl company_no with mSysOffice,dlr_code with mDlrCode,cust_no with "FRANCH",;
   				bill_mon with mBillMonth, bill_year with mBillYear,tran_type with pTranType,;
   				tran_num with tblDlrFil.pymnt_bill + 1,tran_amt with tblDlrFil.fran_pymnt
   			ELSE
				REPL company_no with tblDlrFil.company_no,dlr_code with mDlrCode,cust_no with "FRANCH",;
				bill_mon with mBillMonth, bill_year with mBillYear, tran_type with pTranType,;
				tran_num with tblDlrFil.sec_pybill + 1,tran_amt with tblDlrFil.sec_pymnt
   			ENDIF
   			
		ELSE

  			* determine which note is being processed to populate 
  			* the correct fields
  			IF pTranType = "N1"
   				REPL tran_num with tblDlrFil.pymnt_bill + 1,tran_amt with tblDlrFil.fran_pymnt
   			ELSE
   				REPL tran_num with tblDlrFil.sec_pybill + 1,tran_amt with tblDlrFil.sec_pymnt
   			ENDIF
   			
   		endif
     	
  	else
 	
 		* Remove payment record if one 
 		* exists and payment was not taken.
 		if found()
 			delete
 		endif	  
	 
	endif
	 
	 select (lCusFil3)   

endfunc