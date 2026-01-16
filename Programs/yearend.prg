
****************************************************************
* NAME: yearend.prg                     DATE: December 28, 1993
* WRITTEN BY: Craig R Hallenberger
* PURPOSE: To total up the spreadsheet database and write a 
*          year end report for each franchisee
****************************************************************
set talk off
PUBLIC  m.tot_contract,	m.actual_bill, m.add_bill_fran, m.client_sup,;
		m.add_bill_off, m.client_sale_tx, m.royalty, m.acct_fee,;
		m.add_b_off_com, m.fran_note, m.find_fee, m.fran_sup, m.reg_misc,;
		m.tot_lease, m.bus_prot, m.bond, m.chrg_back, m.spec_misc,;
		m.tot_mon_rev, m.tot_deduct, m.reg_name, m.reg_code, M.YRLY_INT, ;
		xyear, m.Adv_fee
XYEAR = YEAR(DATE()) -1
select 1
use tmpsprd index tmpsprd alias spread
select 2
use jkdlrfil index jkdlrfil.idx alias FRAN
select 3
use jkcmpfil index jkcmpfil alias reg
SELE 4
USE SPRDHST ALIAS HISTORY
SET ORDER TO COMPANY_NO
DO X_SCREEN WITH "FRANCHISEE YEAR END REPORTS",sys_offc,0
BEGIN = "000000"
END = "999999"
@ 10,1 SAY "BEGINNING FRANCHISEE:" GET M.BEGIN PICT "!!!!!!"
@ 11,1 SAY "ENDING FRANCHISEE:" GET M.END PICT "!!!!!!"
@ 12,1 SAY "BILL YEAR" GET M.XYEAR PICT "9999"
READ
sele FRAN
set filter to between(dlr_code,m.begin,m.end)
SELE SPREAD
SET FILTER TO BETWEEN(DLR_CODE,M.BEGIN,M.END) .AND. ((BILL_MON = 12 .AND. BILL_YEAR = XYEAR-1) .OR. (BILL_YEAR = XYEAR))
go top
SELE HISTORY
SET FILTER TO BETWEEN(DLR_CODE,M.BEGIN,M.END) .AND. ((BILL_MON = 12 .AND. BILL_YEAR = XYEAR-1) .OR. (BILL_YEAR = XYEAR))
GO TOP
SELE FRAN
GO TOP
do setzeros
DO WHILE !EOF()
  DO CALC
  SELE HISTORY
  SEEK FRAN.COMPANY_NO+FRAN.DLR_CODE
  DO WHILE history.dlr_code = FRAN.DLR_CODE .AND. !EOF()
    IF history.BILL_YEAR = m.XYEAR
      do tot_hist
    ENDIF
    SKIP
  ENDDO
  SELE SPREAD
  SEEK FRAN.COMPANY_NO+FRAN.DLR_CODE
  DO WHILE spread.dlr_code = FRAN.DLR_CODE .AND. !EOF()
    IF spread.BILL_YEAR = m.XYEAR
      do tot_spread
    ENDIF
    SKIP
  ENDDO
  DO report
  do setzeros
  SELE FRAN
  SKIP
ENDDO
close all
return
****************************************************************
* Sets the variables back to zero so next franchisee can be totalled
****************************************************************
proc setzeros
	m.tot_contract   = 0
	m.actual_bill    = 0
	m.add_bill_fran  = 0
	m.client_sup     = 0
	m.add_bill_off   = 0
	m.client_sale_tx = 0
	m.royalty        = 0
	m.acct_fee       = 0
	m.add_b_off_com  = 0
	m.fran_note      = 0
	m.find_fee       = 0
	m.fran_sup       = 0
	m.reg_misc       = 0
	m.tot_lease      = 0
	m.bus_prot       = 0
	m.bond           = 0
	m.chrg_back      = 0
	m.spec_misc      = 0
    M.YRLY_INT       = 0

    m.Adv_fee		 = 0			

return
****************************************************************
* Totals the fields for use in the report
****************************************************************
PROC tot_hist
	m.tot_contract   = m.tot_contract + history.t_contract
	m.actual_bill    = m.actual_bill + history.t_revenue
	m.add_bill_fran  = m.add_bill_fran + history.t_e_work
	m.client_sup     = m.client_sup + history.t_supplies
	m.add_bill_off   = m.add_bill_off + history.t_1_in
	m.client_sale_tx = m.client_sale_tx + history.t_supp_tax + history.t_cont_tax
	m.royalty        = m.royalty + history.t_royalty
	m.acct_fee       = m.acct_fee + history.t_admin
	m.add_b_off_com  = m.add_b_off_com + history.t_1_in_com
	m.fran_note      = m.fran_note + history.t_franchis
	m.find_fee       = m.find_fee + history.t_find_fee + history.t_ff_down
	m.fran_sup       = m.fran_sup + history.t_dlr_sup + history.dlr_sup_tx
	m.reg_misc       = m.reg_misc + history.t_misc_ro
	m.tot_lease      = m.tot_lease + history.t_lease + history.t_lease_tx
	m.bus_prot       = m.bus_prot + history.t_bus_prot
	m.bond           = m.bond + history.t_bond
	m.chrg_back      = m.chrg_back + history.t_chrg_bk
	m.spec_misc      = m.spec_misc + history.t_misc
*    M.YRLY_INT       = M.YRLY_INT + history.t_fran_int
RETURN

PROC tot_spread
	m.tot_contract   = m.tot_contract + spread.t_contract
	m.actual_bill    = m.actual_bill + spread.t_revenue
	m.add_bill_fran  = m.add_bill_fran + spread.t_e_work
	m.client_sup     = m.client_sup + spread.t_supplies
	m.add_bill_off   = m.add_bill_off + spread.t_1_in
	m.client_sale_tx = m.client_sale_tx + spread.t_supp_tax + spread.t_cont_tax
	m.royalty        = m.royalty + spread.t_royalty
	m.acct_fee       = m.acct_fee + spread.t_admin
	m.add_b_off_com  = m.add_b_off_com + spread.t_1_in_com
	m.fran_note      = m.fran_note + spread.t_franchis
	m.find_fee       = m.find_fee + spread.t_find_fee + spread.t_ff_down
	m.fran_sup       = m.fran_sup + spread.t_dlr_sup + spread.dlr_sup_tx
	m.reg_misc       = m.reg_misc + spread.t_misc_ro
	m.tot_lease      = m.tot_lease + spread.t_lease + spread.t_lease_tx
	m.bus_prot       = m.bus_prot + spread.t_bus_prot
	m.bond           = m.bond + spread.t_bond
	m.chrg_back      = m.chrg_back + spread.t_chrg_bk
	m.spec_misc      = m.spec_misc + spread.t_misc
*    M.YRLY_INT       = M.YRLY_INT + SPREAD.t_fran_int

    m.Adv_Fee        = m.Adv_fee + Spread.t_ad 
  
RETURN

****************************************************************
* Writes the report for the franchisee currently in memory
****************************************************************
proc report
select FRAN
M.DLR_CODE = FRAN.DLR_CODE
M.dlr_name = FRAN.dlr_name
m.dlr_street = FRAN.dlr_addr	
m.dlr_city = FRAN.dlr_city
m.dlr_state = FRAN.dlr_state
m.dlr_zip = FRAN.dlr_zip
m.dlr_signed = FRAN.date_sign
select reg
seek FRAN.COMPANY_NO 
if found()
	m.reg_name = TRIM(reg.DSP_NAME)
else
	do reg_error
endif
SELE FRAN
************************************************
*  MODULE: Prints the franchisee yearly report
*      BY: Hung Dao
************************************************
line = '-------------------------------------------------------------'
line_no = 2
SET DEVICE TO PRINT 
DO HEADING
DO FRAN_NAME
DO CONT_BILLING
DO FRAN_DEDUCTION
DO FOOTER
SET DEVICE TO SCREEN
RETURN

****** PRINTS THE REPORT HEADING  *****************
PROC HEADING
clear
rpt_name = 'FRANCHISEE YEARLY REPORT'
bus_yr	 = 'BUSINESS FOR THE YEAR OF '+ STR(XYEAR,4)
SET CENTURY ON
@ line_no,0 SAY 'Time: '+ time()
@ line_no,40 - INT(LEN(rpt_name)/2) SAY M.rpt_name
@ line_no,60 SAY MDY(date())
  line_no = line_no + 1
@ line_no,40 - INT(LEN(m.reg_name)/2) SAY m.reg_name
  line_no = line_no + 1
@ line_no,40 - INT(LEN(bus_yr)/2) SAY bus_yr
* SET CENTURY OFF
RETURN

******* PRINTS THE FRANCHISEE NAME *************
PROC FRAN_NAME
  line_no = line_no + 2
@ line_no,1 SAY 'Franchisee'
  line_no = line_no + 1
@ line_no,1 SAY 'Code'
@ line_no,13 SAY 'Name'
  line_no = line_no + 1
@ line_no,1 SAY m.dlr_code
@ line_no,13 SAY m.dlr_name  
  line_no = line_no + 1
@ line_no,13 SAY m.dlr_street
  line_no = line_no + 1
@ line_no,13 SAY m.dlr_city
@ line_no,28 SAY m.dlr_state
@ line_no,33 SAY m.dlr_zip
@ line_no,55 SAY 'Date signed: '
@ line_no,68 SAY m.dlr_signed
RETURN

********* PRINTS Total contract billing **********
PROC CONT_BILLING
  line_no = line_no + 2
@ line_no,1 SAY 'TOTAL CONTRACT BILLING:'
@ line_no,40 SAY m.tot_contract PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,1 SAY line
  line_no = line_no + 1
@ line_no,3 SAY 'Actual Billing'
@ line_no,40 SAY m.actual_bill PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Additional Billing By Franchisee'
@ line_no,40 SAY m.add_bill_fran PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Client Supplies'
@ line_no,40 SAY m.client_sup PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Additional Billing By Office'
@ line_no,40 SAY m.add_bill_off PICTURE '999,999.99'     
  m.subtotal = m.actual_bill + m.add_bill_fran + m.client_sup + m.add_bill_off     
  line_no = line_no + 1
@ line_no,3 SAY 'SUBTOTAL'
@ line_no,52 SAY m.subtotal PICTURE '999,999.99'
  line_no = line_no + 2
@ line_no,3 SAY 'Client Sales Tax'
@ line_no,52 SAY m.client_sale_tx PICTURE '999,999.99'
  m.tot_mon_rev = m.subtotal + m.client_sale_tx
  line_no = line_no + 1
@ line_no,3 SAY 'Total Monthly Revenue'
@ line_no,65 SAY m.tot_mon_rev PICTURE '999,999.99'
RETURN

************ PRINTS Franchisee deductions ************
PROC FRAN_DEDUCTION
  line_no = line_no + 3
@ line_no,1 SAY 'FRANCHISEE DEDUCTIONS:'
  line_no = line_no + 1
@ line_no,1 SAY line
  line_no = line_no + 1
@ line_no,3 SAY 'Royalty'
@ line_no,40 SAY m.royalty PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Accounting Fee'
@ line_no,40 SAY m.acct_fee PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Additional Billing By Office Comm.'
@ line_no,40 SAY m.add_b_off_com PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Franchise Note Payment'
@ line_no,40 SAY m.fran_note PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Finders Fee (see customer account)'
@ line_no,40 SAY m.find_fee PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Franchisee Supplies'
@ line_no,40 SAY fran_sup PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Regular Miscellaneous'
@ line_no,40 SAY m.reg_misc PICTURE '999,999.99'
  m.reg_deduct = m.royalty + m.acct_fee + m.add_b_off_com + m.fran_note + m.find_fee + m.fran_sup + m.reg_misc
  line_no = line_no + 1
@ line_no,3 SAY 'SUBTOTAL - Regular Deductions'
@ line_no,52 SAY m.reg_deduct PICTURE '999,999.99'
  line_no = line_no + 2
@ line_no,3 SAY 'Total Leases (see leases)'
@ line_no,40 SAY m.tot_lease PICTURE '999,999.99'
  line_no = line_no + 1

@ line_no,3 SAY 'Advertising Fee'
@ line_no,40 SAY m.Adv_Fee PICTURE '999,999.99'
  line_no = line_no + 1

@ line_no,3 SAY 'Business Protection Administration Fee'
@ line_no,40 SAY m.bus_prot PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Bond'
@ line_no,40 SAY m.bond PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Client Sales Tax'
@ line_no,40 SAY m.client_sale_tx PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Charge Backs'
@ line_no,40 SAY m.chrg_back PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Special Miscellaneous'
@ line_no,40 SAY m.spec_misc PICTURE '999,999.99'
  m.spec_deduct = m.tot_lease + m.bus_prot + m.bond + m.client_sale_tx + m.chrg_back + m.spec_misc + m.adv_fee
  line_no = line_no + 1
@ line_no,3 SAY 'SUBTOTAL - Special Deductions'
@ line_no,52 SAY m.spec_deduct PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,3 SAY 'Total Deductions'
  m.tot_deduct = m.reg_deduct + m.spec_deduct
@ line_no,65 SAY m.tot_deduct PICTURE '999,999.99' 
  line_no = line_no + 2
@ line_no,1 SAY 'DUE TO FRANCHISEE:'
  m.due = m.tot_mon_rev - m.tot_deduct
@ line_no,65 SAY m.due PICTURE '999,999.99'
  line_no = line_no + 1
@ line_no,1 SAY line
RETURN

************  PRINTS THE FOOTER ********************
PROC FOOTER
   line_no = line_no + 3
*@ line_no,1 SAY 'Date Paid _________ Check # ________  Date Paid __________ Check # ________'
*  line_no = line_no + 2
*@ line_no,1 SAY 'Note:     _________________________________________________________________'
*  line_no = line_no + 2
*@ line_no,1 SAY '          _________________________________________________________________'
*  line_no = line_no + 2
*@ line_no,1 SAY '          _________________________________________________________________'
IF M.YRLY_INT > 0
   LINE_NO = LINE_NO + 1
   @ LINE_NO,11 SAY 'Interest Paid on Franchisee note for the Year is'
   @ LINE_NO,60 SAY M.YRLY_INT PICTURE '$$$,$$9.99' 
ENDIF
RETURN

***********************************************************
* displays error after searching region database
***********************************************************
proc reg_error
clear
@ 5,8 say 'Could not find region name for '+m.reg_code+' !!' 
wait
return

PROC dlr_error
clear
@ 5,8 say 'Could not find franchisee name for '+m.dlr_code+' !!'
wait
return



PROC x_screen
  PARA x_title,x_offc,x_mon
  x_col = (80-len(alltrim(x_title)))/2
  clear
  @ 1,0 TO 23,79 DOUBLE
  @ 3,1 TO 3,78  DOUBLE
  @ 3, 0 SAY 'Ì'
  @ 3,79 SAY '¹'
  @ 2,2 SAY iif(empty(x_offc),' ','Office: ' + x_offc)
  @ 2,x_col say x_title
  @ 2,61 say iif(x_mon = 0,' ','Current Month:') 
  @ 2,76 say iif(x_mon = 0,' ',str(x_mon,2))
  release all like x_*
return



*****************************************************************
* DO CALCULATION OF INTEREST
*****************************************************************
PROCEDURE CALC
M.TOT_INT = 0
M.FIRSTPAY = 0
M.NUM_PAY = 0
sele SPREAD
SEEK FRAN.COMPANY_NO + FRAN.DLR_CODE
TINT = 0
XBAL = 0
PRINC = fran.FRAN_AMT-fran.DWN_pYMNT
XINT = (fran.INTEREST/12)/100
sele HISTORY
seek fran.company_no + fran.dlr_code
YR_BILL  = 0
DO WHILE DLR_CODE = FRAN.DLR_CODE 
  IF T_FRANCHISE # 0 AND ((BILL_MON = 12 AND BILL_YEAR = XYEAR-1) OR (BILL_mON < 12 AND BILL_YEAR = XYEAR))
    YR_BILL = YR_BILL +1
  ENDIF
  SKIP
ENDDO
sele SPREAD
SEEK FRAN.COMPANY_nO + FRAN.DLR_CODE
DO WHILE DLR_CODE = FRAN.DLR_CODE
  IF T_FRANCHISE # 0 AND ((BILL_MON = 12 AND BILL_YEAR = XYEAR-1) OR (BILL_mON < 12 AND BILL_YEAR = XYEAR))
    YR_BILL = YR_BILL +1
  ENDIF
  SKIP
ENDDO

FOR XY = 1 TO fran.PYMNT_BILL-YR_bILL
  XBAL = XBAL+(FRAN.FRAN_PYMNT-ROUND(((PRINC-XBAL)*XINT),2))
ENDFOR
bINT = 0
sele HISTORY
SEEK FRAN.COMPANY_NO + FRAN.DLR_CODE
if yr_bill = 0
  return
endif
DO WHILE DLR_CODE = FRAN.DLR_CODE
  IF T_FRANCHISE # 0 AND ((BILL_MON = 12 AND BILL_YEAR = XYEAR-1) OR (BILL_mON < 12 AND BILL_YEAR = XYEAR))
    BINT = BINT + round(((PRINC-XBAL)*XINT),2)
    XBAL = XBAL+(t_franchise-round(((PRINC-XBAL)*XINT),2))
  ENDIF
  SKIP
ENDDO
sele SPREAD
SEEK FRAN.COMPANY_NO + FRAN.DLR_CODE
DO WHILE DLR_CODE = FRAN.DLR_CODE
  IF T_FRANCHISE # 0 AND ((BILL_MON = 12 AND BILL_YEAR = XYEAR-1) OR (BILL_mON < 12 AND BILL_YEAR = XYEAR))
    BINT = BINT + round(((PRINC-XBAL)*XINT),2)
    XBAL = XBAL+(t_franchise-round(((PRINC-XBAL)*XINT),2))
  ENDIF
  SKIP
ENDDO
M.YRLY_INT = BINT
RETURN
