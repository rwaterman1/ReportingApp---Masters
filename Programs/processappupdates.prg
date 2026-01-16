clos all
curVersion="v.2.10.44" 
newStructure=.F.
xCnt=0

*cDataLoc="x:\training\"
*set path to x:\training, i:\frrpts
*cCompNo="OKC991"
*lcanadamaster=.f.

*cDataLoc="i:\jk_aug\"
*set path to i:\jk_aug, i:\frrpts
*cCompNo="AUGA31"
*lcanadamaster=.f.

if !file(cDataLoc+'curRevision.dbf')
	creat table cDataLoc+"curRevision" ;
		(version C(12))
	append blank
	use
endif

if !used('curRevision')
	use cDataLoc+"curRevision" in 0
endif
sele curRevision
if curRevision.version=curVersion
	use
	return && App current - return to calling program.
else
	use
endif			

*--> KMC 03/30/2009 - Moved this code to here and removed from all other locations.
xCnt=0
for xCnt=len(cDataLoc)-1 to 1 step -1
	if substr(cDataLoc,xCnt,1)="\"
		exit
	endif	
endfor	

*--> 02/2004 KMC
*--> Add field to track cancellation entered date if it doesn't already exist.
ChkTable('','jkcusfil','CANENTDAT')  
IF !newStructure
	WAIT window "Customer Data structure being updated..." nowait
	ALTER table jkcusfil add column CanEntDat D
	USE
	WAIT clear
ENDIF

*--> 03/2004 KMC
*--> Add field to store current accounting/admin fee percentage if it doesn't already exist.
ChkTable('','jkcmpfil','ACCT_PERC')  
IF !newStructure
	WAIT window "Company Data structure being updated..." nowait
	ALTER table jkcmpfil add column Acct_Perc N(5,3)
	REPL all Acct_Perc with 3.00
	USE
	WAIT clear
ENDIF

*--> 06/24/2004 KMC
*--> Add dlr_id C(3) to jkdlrfil to track franchisee transfers if it doesn't already exist.
ChkTable('','jkdlrfil','DLR_ID')  
IF !newStructure
	WAIT window "Franchisee Data structure being updated..." nowait
	ALTER table jkdlrfil add column Dlr_ID C(3)
	REPLA all Dlr_ID with "000"
	INDEX on Dlr_ID tag Dlr_ID  && Create index on dlr_id
	USE
	WAIT clear

	*--> KMC 02/16/2006
	*--> Add index on dlr_id to jkdlrfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="JKDLRFIL" and index_to="TAG DLR_ID"
	IF !found()
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "DLR_ID"
		REPLA index_to with "TAG DLR_ID"
		APPEND blank
		REPLA file_name with "DLRTRANHST"
		REPLA index_exp with "COMPANY_NO"
		REPLA index_to with "TAG COMPANY_NO"
		APPEND blank
		REPLA file_name with "DLRTRANHST"
		REPLA index_exp with "DLR_CODE"
		REPLA index_to with "TAG DLR_CODE"
		APPEND blank
		REPLA file_name with "DLRTRANHST"
		REPLA index_exp with "DLR_ID"
		REPLA index_to with "TAG DLR_ID"
	ENDIF
	USE
ENDIF
*-->

*--> 03/2004 KMC
*--> No longer need rpt_data.dbf (using a cursor now),delete it and any associated indexes.
IF file(cDataLoc+"rpt_data.dbf")
	Dele file cDataLoc+"rpt_data.*"
ENDIF

*--> 03/2004 KMC
*--> Table rpt_data no longer used, delete reference to it in ndx_dat.

*--> KMC 02/16/2006
NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
if file(NdxFile)
	use &NdxFile in 0 
else
	USE ndx_dat in 0
endif
*-->
	
SELE ndx_dat
Dele all for file_name="RPT_DATA"
USE

*--> 03/2004 KMC
*--> Create table for tracking account increase/decreases if it does not exist.
IF !FILE(cDataLoc + "incrdecr.dbf")
	WAIT window "Creating Customer Increase/Decrease table..." nowait
	CREATE table cDataLoc + "incrdecr" ;
		(logdate D, ;
		logtime C(8), ;
		sys_cust N(8), ;
		cust_no C(6), ;
		old_amt N(12,2), ;
		new_amt N(12,2))
	SELE incrdecr
	INDEX on logdate tag logdate
	INDEX on sys_cust tag sys_cust
	INDEX on cust_no tag cust_no
	USE
	wait clear
ENDIF

*--> Create indexes for incrdecr if they do not exist already.
IF !FILE(cDataLoc + "incrdecr.cdx")
	USE incrdecr in 0 excl
	SELE incrdecr
	INDEX on logdate tag logdate
	INDEX on sys_cust tag sys_cust
	INDEX on cust_no tag cust_no
	USE
ENDIF

*--> KMC 04/27/2004 Create file for additional customer phone numbers if it does not already exist.
IF !FILE(cDataLoc + "CustPhone.dbf")
	WAIT window "Creating table to store additional Customer Phone numbers..." nowait
	CREAT table cDataLoc + "CustPhone" ;
		(id I, ;
		sys_cust N(8), ;
		phone C(15), ;
		type C(5), ;
		contact C(30))
	INDEX on id tag id
	INDEX on sys_cust tag sys_cust
	USE
	wait clear
ENDIF
*-->

*--> KMC 04/27/2004 Create file for additional franchisee phone numbers if it does not already exist.
IF !FILE(cDataLoc + "FranPhone.dbf")
	WAIT window "Creating table to store additional Franchisee Phone numbers..." nowait
	CREAT table cDataLoc + "FranPhone" ;
		(id I, ;
		dlr_code C(6), ;
		phone C(15), ;
		type C(5), ;
		contact C(30))
	INDEX on id tag id
	INDEX on dlr_code tag dlr_code
	USE
	wait clear
ENDIF
*-->

*--> 06/25/2004 KMC
*--> Add dlr_id C(3) to ckbook to track franchisee transfers if it doesn't already exist.
USE data_loc in 0
SELE data_loc
IF cCompNo="NAT991" or cCompNo="NAT999"
	*--> National Accts and National Accts2 both use same checkbook.  Nat Acct is NAT991,
	*--> Nat Acct2 is NAT999.  In data_loc, NAT000 is the data location for both Nat Acct databases.
	LOCA for company_no=Left(cCompNo,3)+"000"
ELSE
	LOCA for company_no=cCompNo
ENDIF

IF found()
	xFile=(alltrim(data_loc.bank_data)+'\ckbook.dbf')
	IF file(xFile)
		USE &xFile ALIAS checks IN 0
		SELE checks
		x=fcount('checks')
		FOR num=1 to x
			thisfield=field(num,'checks')
			IF alltrim(thisfield)="DLR_ID" && Used to track franchisee transfers.
				newStructure=.t.
			ENDIF
		ENDFOR
		USE
		IF !newStructure
			WAIT window "CheckBook Data structure being updated..." nowait
			ALTER table &xFile add column Dlr_ID C(3)
			SELE ckbook
			USE
			WAIT clear
		ENDIF
	ENDIF
ENDIF
SELE data_loc
USE
*-->

*--> KMC 07/02/2004 Create file for tracking franchise transfers if it does not already exist.
IF !FILE(cDataLoc + "DlrTranHst.dbf")
	CREAT table cDataLoc + "DlrTranHst" ;
		(chngDate D, ;
		company_no C(6), ;
		dlr_code C(6), ;
		Dlr_ID C(3), ;
		dlr_name C(30), ;
		dlr_addr C(30), ;
		dlr_city C(20), ;
		dlr_state C(2), ;
		dlr_zip C(10), ;
		dlr_ssn N(9) , ;
		dlr_fid N(9), ;
		Print1099 C(1))
	USE
ENDIF
*-->

*--> 07/29/2004 KMC
*--> Add "recur" flag in jkdlrtrx and dlrtrxhs - will be used to flag transactions as recurring.
ChkTable('','jkdlrtrx','RECUR')  
IF !newStructure
	WAIT window "Franchisee Transaction Data structure being updated..." nowait
	ALTER table jkdlrtrx add column Recur C(1)
	REPL all Recur with "N"
	USE
	WAIT window "Franchisee Transaction History Data structure being updated..." nowait
	ALTER table dlrtrxhs add column Recur C(1)
	REPL all Recur with "N"
	USE
	WAIT clear
ENDIF

*--> 09/03/2004 KMC
*--> Add "CB" flag in jkdlrfil.
ChkTable('','jkdlrfil','CB')  
IF !newStructure
	WAIT window "Franchisee File Data structure being updated..." nowait
	ALTER table jkdlrfil add column CB C(1)
	REPL all CB with "Y"
	USE
	WAIT clear

	*--> Add index on CB to jkdlrfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="JKDLRFIL" and index_to="TAG CB"
	IF !found()
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "CB"
		REPLA index_to with "TAG CB"
	ENDIF
	USE
ENDIF
*-->

*--> KMC 09/08/2004 Create table for customer areas if it does not already exist.
IF !FILE(cDataLoc + "CustArea.dbf")
	WAIT window "Creating table to store Customer areas..." nowait
	CREAT table cDataLoc + "CustArea" ;
		(id I, ;
		sys_cust I, ;
		cust_no C(6), ;
		descr C(20))
	INDEX on id tag id
	INDEX on sys_cust tag sys_cust
	USE
	wait clear
ENDIF
*-->

*--> 09/08/2004 KMC
*--> Add field to store customer area in service and servhst if it doesn't already exist.
ChkTable('','service','AREA')  
IF !newStructure
	WAIT window "Service Data structure being updated..." nowait
	ALTER table service add column Area C(20)
	INDEX on Area tag Area
	USE
	WAIT clear
ENDIF

ChkTable('','servhst','AREA')  
IF !newStructure
	WAIT window "Service Data structure being updated..." nowait
	ALTER table servhst add column Area C(20)
	USE
	WAIT clear
ENDIF
*-->

*--> 09/21/2004 KMC
*--> Add field to store Collections Rep in jkcusfil if it doesn't already exist.
ChkTable('','jkcusfil','COLL_REP')  
IF !newStructure
	WAIT window "Customer Data structure being updated..." nowait
	ALTER table jkcusfil add column Coll_Rep C(15)
	USE
	WAIT clear
ENDIF
*-->

*--> 10/08/2004 KMC
*--> Add "toFran" and "fromFran" columns in jkleafil.
ChkTable('','jkleafil','TOFRAN')  
IF !newStructure
	WAIT window "Lease File Data structure being updated..." nowait
	ALTER table jkleafil add column TOFRAN C(6)
	ALTER table jkleafil add column FROMFRAN C(6)
	USE
	WAIT clear
ENDIF
*-->

*--> 12/08/2004 KMC
*--> Add dlr_id C(3) in tmpsprd to track franchisee transfers if it doesn't already exist.
ChkTable('','tmpsprd','DLR_ID')  
IF !newStructure
	WAIT window "Spreadsheet Data structure being updated..." nowait
	ALTER table tmpsprd add column Dlr_ID C(3)
	REPLA all Dlr_ID with "000"
	INDEX on Dlr_ID tag Dlr_ID  && Create index on dlr_id
	USE
	WAIT clear

	*--> KMC 02/16/2006
	*--> Add index on dlr_id to tmpsprd in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="TMPSPRD" and index_to="TAG DLR_ID"
	IF !found()
		APPEND blank
		REPLA file_name with "TMPSPRD"
		REPLA index_exp with "DLR_ID"
		REPLA index_to with "TAG DLR_ID"
	ENDIF
	USE
ENDIF
*-->

*--> 12/08/2004 KMC
*--> Add Print1099 C(1) in jkdlrfil - Print 1099 flag.
ChkTable('','jkdlrfil','PRINT1099')  
IF !newStructure
	WAIT window "Franchisee Data structure being updated..." nowait
	ALTER table jkdlrfil add column Print1099 C(1)
	REPLA all Print1099 with "Y"
	INDEX on Print1099 tag Print1099  && Create index on Print1099
	USE
	WAIT clear

	*--> Add index on Print1099 to jkdlrfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="JKDLRFIL" and index_to="TAG PRINT1099"
	IF !found()
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "PRINT1099"
		REPLA index_to with "TAG PRINT1099"
	ENDIF
	USE
ENDIF
*-->

*--> 12/08/2004 KMC
*--> Add Print1099 C(1) in dlrtranhst - Print 1099 flag.
ChkTable('','dlrtranhst','PRINT1099')  
IF !newStructure
	WAIT window "Franchisee History Data structure being updated..." nowait
	ALTER table dlrtranhst add column Print1099 C(1)
	INDEX on Print1099 tag Print1099  && Create index on Print1099
	USE
	WAIT clear

	*--> Add index on Print1099 to jkdlrfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="DLRTRANHST" and index_to="TAG PRINT1099"
	IF !found()
		APPEND blank
		REPLA file_name with "DLRTRANHST"
		REPLA index_exp with "PRINT1099"
		REPLA index_to with "TAG PRINT1099"
	ENDIF
	USE
ENDIF
*-->

*--> 12/13/2004 KMC
*--> Add Name_1099 C(40) in jkdlrfil.
ChkTable('','jkdlrfil','NAME_1099')  
IF !newStructure
	WAIT window "Franchisee Data structure being updated..." nowait
	ALTER table jkdlrfil add column NAME_1099 C(40)
	REPLA all NAME_1099 with dlr_name
	USE
	WAIT clear
ENDIF
*-->

*--> 12/13/2004 KMC
*--> Add Name_1099 C(40) in dlrtranhst
ChkTable('','dlrtranhst','NAME_1099')  
IF !newStructure
	WAIT window "Franchisee Transfer History Data structure being updated..." nowait
	ALTER table dlrtranhst add column NAME_1099 C(40)
	REPLA all NAME_1099 with dlr_name
	USE
	WAIT clear
ENDIF
*-->

*--> 02/01/2005 KMC
*--> Add royalty field to jkdlrfil N(5,2).
ChkTable('','jkdlrfil','ROYALTY')  
IF !newStructure
	WAIT window "Franchisee Data structure being updated..." nowait
	use jkcmpfil in 0 
	xRoyalty=jkcmpfil.royalty
	sele jkcmpfil
	use
	ALTER table jkdlrfil add column royalty N(5,2)
	REPLA all royalty with xRoyalty
	sele jkdlrfil
	USE
	WAIT clear
ENDIF
*-->

*--> 02/02/2005 KMC
*--> Add GST_No field to jkcmpfil C(15) for Canadian Regions.
if "$" $ cDataLoc
	ChkTable('','jkcmpfil','GST_NO')  
	IF !newStructure
		WAIT window "Company File Data structure being updated..." nowait
		ALTER table jkcmpfil add column GST_NO C(15)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> 02/02/2005 KMC
*--> Add GST_No field to jkdlrfil C(15) for Canadian Regions.
if "$" $ cDataLoc
	ChkTable('','jkdlrfil','GST_NO')  
	IF !newStructure
		WAIT window "Franchisee Data structure being updated..." nowait
		ALTER table jkdlrfil add column GST_NO C(15)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> KMC 02/04/2005
*--> Code was in PrintFranReport.ProcessReport back in 2003.
*--> Moved here 02/05/2005 in order to keep all structural updates in one location.
*--> Update cur_cat with royalty field if necessary.
ChkTable('','cur_cat','ROYALTY')  
IF !newStructure
	WAIT WINDOW "Updating Cur_Cat Structure..." NOWAIT
	ALTER TABLE cur_cat ADD COLUMN royalty N(5,2)
	USE
	WAIT CLEAR
ENDIF
*--> do same thing for rpt_cat
ChkTable('','rpt_cat','ROYALTY')  
IF !newStructure
	WAIT WINDOW "Updating Rpt_Cat Structure..." NOWAIT
	ALTER TABLE rpt_cat ADD COLUMN royalty N(5,2)
	use
	WAIT CLEAR
ENDIF
*-->

*--> 02/08/2005 KMC
*--> Add GST_No C(15) and GST_Tax N(5,2) to rpt_fran - Canadian regions only.
if "$" $ cDataLoc
	ChkTable('','rpt_fran','GST_NO')  
	IF !newStructure
		WAIT window "Franchisee Data structure being updated..." nowait
		ALTER table rpt_fran add column GST_NO C(15)
		ALTER table rpt_fran add column GST_Tax N(7,4)
		ALTER table rpt_fran add column PST_Tax N(7,4)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> 02/08/2005 KMC
*--> Add GST_No C(15) and GST_Tax N(5,2) to cur_fran - Canadian regions only.
if "$" $ cDataLoc
	ChkTable('','cur_fran','GST_NO')  
	IF !newStructure
		WAIT window "Franchisee Data structure being updated..." nowait
		ALTER table cur_fran add column GST_NO C(15)
		ALTER table cur_fran add column GST_Tax N(7,4)
		ALTER table cur_fran add column PST_Tax N(7,4)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> KMC 02/16/2005
*--> Update jkcusfil add inv_msg field C(70)
ChkTable('','jkcusfil','INV_MSG')  
IF !newStructure
	USE jkcusfil IN 0 EXCL
	WAIT WINDOW "Updating Customer File Structure..." NOWAIT
	ALTER TABLE JKCusfil ADD COLUMN inv_msg C(70)
	use
	WAIT CLEAR
ENDIF
USE
*--> do same thing for jkctlfil C(70)
ChkTable('','jkctlfil','INV_MSG')  
IF !newStructure
	USE jkctlfil IN 0 EXCL
	WAIT WINDOW "Updating Company File Structure..." NOWAIT
	ALTER TABLE JKctlfil ADD COLUMN inv_msg C(70)
	USE
	WAIT CLEAR
ENDIF
USE
*--> do same thing for jkcustrx - but add two msg fields
ChkTable('','jkcustrx','INV_MSG')  
IF !newStructure
	USE jkcustrx IN 0 EXCL
	WAIT WINDOW "Updating Customer Transaction Structure..." NOWAIT
	ALTER TABLE JKCustrx ADD COLUMN inv_msg C(70)
	ALTER TABLE JKCustrx ADD COLUMN inv_msg2 C(70)
	USE
	WAIT CLEAR
ENDIF
USE
*--> do same thing for custrxhs - but add two msg fields.
ChkTable('','custrxhs','INV_MSG')  
If !newStructure
	USE custrxhs IN 0 EXCL
	WAIT WINDOW "Updating Customer Transaction History Structure..." NOWAIT
	ALTER TABLE custrxhs ADD COLUMN inv_msg C(70)
	ALTER TABLE custrxhs ADD COLUMN inv_msg2 C(70)
	USE
	WAIT CLEAR
ENDIF
USE
*-->

*--> KMC 02/21/2005
*--> Update cur_leas add pymnt_pst N(6,2) - Canadian Regions Only.
IF "$" $ cDataLoc
	ChkTable('','cur_leas','PYMNT_PST')  
	IF !newStructure
		USE cur_leas IN 0 EXCL
		WAIT WINDOW "Updating Current Lease File Structure..." NOWAIT
		ALTER TABLE cur_leas ADD COLUMN pymnt_pst N(6,2)
		SELE cur_leas
		USE
		WAIT CLEAR
	ENDIF
ENDIF
USE
*--> Update rpt_leas add pymnt_pst N(6,2) - Canadian Regions Only.
if "$" $ cDataLoc
	ChkTable('','rpt_leas','PYMNT_PST')  
	IF !newStructure
		USE rpt_leas IN 0 EXCL
		WAIT WINDOW "Updating Report Lease File Structure..." NOWAIT
		ALTER TABLE rpt_leas ADD COLUMN pymnt_pst N(6,2)
		USE
		WAIT CLEAR
	ENDIF
ENDIF
USE

*--> KMC 02/21/2005
*--> Update jkleafil add PST_Tax N(5,2) - Canadian Regions Only.
IF "$" $ cDataLoc
	ChkTable('','jkleafil','PST_TAX')  
	IF !newStructure
		USE jkleafil IN 0 EXCL
		WAIT WINDOW "Updating Lease File Structure..." NOWAIT
		ALTER TABLE jkleafil ADD COLUMN pst_tax N(6,3)
		USE
		WAIT CLEAR
	ENDIF
ENDIF
USE

*--> KMC 02/21/2005
*--> Update jktaxtbl add PST_Rate N(7,4) - Canadian Regions Only.
IF "$" $ cDataLoc
	ChkTable('','jktaxtbl','PST_RATE')  
	IF !newStructure
		USE jktaxtbl IN 0 EXCL
		WAIT WINDOW "Updating Tax Table File Structure..." NOWAIT
		ALTER TABLE jktaxtbl ADD COLUMN pst_rate N(7,4)
		USE
		WAIT CLEAR
	ENDIF
ENDIF

*--> KMC 02/23/2005 Add "Ext" field for additional customer phone numbers if it does not already exist.
ChkTable('','custphone','EXT')  
If !newStructure
	WAIT WINDOW "Updating custphone Structure..." NOWAIT
	ALTER TABLE custphone ADD COLUMN ext C(6)
	ALTER TABLE custphone ALTER COLUMN phone C(10) && Reduce field to C(10) from C(15)
	USE
	WAIT CLEAR
ENDIF
*-->

*--> KMC 02/23/2005 Add "Ext" field for additional franchisee phone numbers if it does not already exist.
ChkTable('','franphone','EXT')  
If !newStructure
	WAIT WINDOW "Updating franphone Structure..." NOWAIT
	ALTER TABLE franphone ADD COLUMN ext C(6)
	ALTER TABLE franphone ALTER COLUMN phone C(10) && Reduce field to C(10) from C(15)
	USE
	WAIT CLEAR
ENDIF
*-->

*--> 02/23/2005 KMC
*--> Add "Ext" to custleadcontacts table C(6).
if file('custleads\custleadcontacts.dbf')
	ChkTable('custleads\','custleadcontacts','EXT')  
	If !newStructure
		WAIT WINDOW "Updating Customer Lead Contacts Phone Structure..." NOWAIT
		ALTER TABLE custleads\custleadcontacts ADD COLUMN ext C(6)
		ALTER TABLE custleads\custleadcontacts ALTER COLUMN phone C(10) && Reduce field to C(10) from C(14)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 03/25/2005 KMC
*--> Expand custleads.company from C(30) to C(40).
if file('custleads\custleads.dbf')
	newStructure=.T.
	USE custleads\custleads
	if len(company)<>40
		newStructure=.F.
	endif
	USE
	IF !newStructure
		WAIT window "Customer Leads Company field being extended..." nowait
		ALTER table custleads\custleads alter column Company C(40)
		USE
		WAIT clear
	ENDIF
endif
*-->

*----------------------------------------------------*
* Updates related to Consolidated Billing.
*----------------------------------------------------*
*--> 06/24/2005 KMC
*--> Add "ConsolBill" to jkinvfil table N(8).
ChkTable('','jkinvfil','CONSOLBILL')  
If !newStructure
	WAIT WINDOW "Updating JkInvFil adding field ConsolBill..." NOWAIT
	ALTER TABLE jkinvfil ADD COLUMN consolbill N(8)
	WAIT CLEAR
ENDIF
USE
*-->

*--> 06/24/2005 KMC
*--> Add "MasterAcct" L and "Parent" N(8) to jkcusfil.
ChkTable('','jkcusfil','MASTERACCT')  
If !newStructure
	WAIT WINDOW "Updating JKcusfil adding fields MasterAcct and Parent..." NOWAIT
	ALTER TABLE jkcusfil ADD COLUMN masteracct L
	ALTER TABLE jkcusfil ADD COLUMN parent N(8)
	WAIT CLEAR
ENDIF
USE
*-->

*--> 06/24/2005 KMC
*--> Add "Parent" N(8) and "ConsolBill" C(9) to jkarofil.
ChkTable('','jkarofil','PARENT')  
If !newStructure
	WAIT WINDOW "Updating JKarofil adding fields Parent and ConsolBill..." NOWAIT
	ALTER TABLE jkarofil ADD COLUMN parent N(8)
	ALTER TABLE jkarofil ADD COLUMN ConsolBill C(9)
	WAIT CLEAR
ENDIF
USE
*-->

*--> 06/24/2005 KMC
*--> Add "Parent" N(8) and "ConsolBill" C(9) to arohist.
ChkTable('','arohist','PARENT')  
If !newStructure
	WAIT WINDOW "Updating AroHist adding fields Parent and ConsolBill..." NOWAIT
	ALTER TABLE arohist ADD COLUMN parent N(8)
	ALTER TABLE arohist ADD COLUMN ConsolBill C(9)
	WAIT CLEAR
ENDIF
USE
*-->

*--> 06/27/2005 KMC
*--> Add "Parent" N(8) and "ConsolBill" C(9) to jkcustrx.
ChkTable('','jkcustrx','PARENT')  
If !newStructure
	WAIT WINDOW "Updating JKarofil adding fields Parent and ConsolBill..." NOWAIT
	ALTER TABLE jkcustrx ADD COLUMN parent N(8)
	ALTER TABLE jkcustrx ADD COLUMN ConsolBill C(9)
	WAIT CLEAR
ENDIF
USE
*-->

*--> 06/27/2005 KMC
*--> Add "Parent" N(8) and "ConsolBill" C(9) to custrxhs.
ChkTable('','custrxhs','PARENT')  
If !newStructure
	WAIT WINDOW "Updating CusTrxHs adding fields Parent and ConsolBill..." NOWAIT
	ALTER TABLE custrxhs ADD COLUMN parent N(8)
	ALTER TABLE custrxhs ADD COLUMN ConsolBill C(9)
	WAIT CLEAR
ENDIF
USE
*-->

*----------------------------------------------------*
* End of Updates related to Consolidated Billing.
*----------------------------------------------------*

*--> 07/18/2005 KMC
*--> Add "SystemId" I and "SystemPath" C(40) to data_loc.
if file('data_loc.dbf')
	ChkTable('','data_loc','SYSTEMID')  
	If !newStructure
		WAIT WINDOW "Updating Data_Loc adding fields SystemID and SystemPath..." NOWAIT
		ALTER TABLE data_loc ADD COLUMN SystemID I
		ALTER TABLE data_loc ADD COLUMN SystemPath C(40)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 07/21/2005 KMC
*--> Drop fields "c_callfreq" and "cs_callfre" from jkcusfil.
ChkTable('','jkcusfil','C_CALLFREQ')  
If newStructure
	WAIT WINDOW "Updating JKcusfil dropping field c_callfreq..." NOWAIT
	ALTER TABLE jkcusfil DROP COLUMN c_callfreq
	WAIT WINDOW "Updating JKcusfil dropping field cs_callfre..." NOWAIT
	ALTER TABLE jkcusfil DROP COLUMN cs_callfre
	WAIT CLEAR
ENDIF
USE
*-->

*--> 07/21/2005 KMC
*--> Add "CPIAdj" C(1) to jkcusfil.
ChkTable('','jkcusfil','CPIADJ')  
If !newStructure
	WAIT WINDOW "Updating JKcusfil adding field CPIAdj..." NOWAIT
	ALTER TABLE jkcusfil ADD COLUMN CPIAdj L
	WAIT CLEAR
ENDIF
USE
*-->

*--> 09/08/2005 KMC
*--> Add "Type" to incrdecr table C(3).
if file('incrdecr.dbf')
	ChkTable('','incrdecr','TYPE')  
	If !newStructure
		WAIT WINDOW "Updating Customer Increase/Decrease Structure..." NOWAIT
		ALTER TABLE incrdecr ADD COLUMN type C(3)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 01/12/2006 KMC
*--> Add column resume_d D to jkcusfil
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','RESUME_D')  
	If !newStructure
		WAIT WINDOW "Updating Customer File, Adding field resume_d..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN resume_d D
		repla all for !empty(seconddate) and !empty(secondfran) ;
			flag with "T", canc_date with seconddate, resume_d with {  / /  }
		repla all for class_type="One-Time Clean" and cont_bill>0 and crteinv="Y" flag with "A" class_type with "Unknown"
		repla all for class_type="One-Time Clean" and cont_bill=0 and crteinv<>"Y" flag with "O"
		repla all for flag="I" and !empty(canc_date) flag with "C"
		repla all for !empty(secondfran) and !empty(seconddate) and flag<>"T" flag with "T" canc_date with seconddate
		repla all for flag="T" and class_type="One-Time Clean" class_type with "Unknown"
		WAIT CLEAR
	ENDIF
	use
endif
*-->

*--> KMC 02/16/2006
*--> Update fradb\dos_usr.domain to 50 characters (used for email addresses)
*--> This code will only work when the FRADB is in the same folder as the regions fracct data (jk_xxx folders). 
*--> Really only applies to Master installations.
UserTbl=left(cDataLoc,xCnt)+"FRADB\DOS_Usr.dbf"
if file(UserTbl)
	use &UserTbl in 0
	sele dos_usr
	if len(dos_usr.domain)<50
		use
		wait window "Updating User table, setting email address length to 50..." nowait
		alter table &UserTbl alter column domain C(50)
		sele dos_usr
		use
		wait clear
	endif
endif		
*-->

*--> 02/17/2006 KMC
*--> Add "Printd1099" to jkinvfil table D.
if file('jkinvfil.dbf')
	ChkTable('','jkinvfil','PRINTD1099')  
	If !newStructure
		WAIT WINDOW "Updating JKINVFIL Structure..." NOWAIT
		ALTER TABLE jkinvfil ADD COLUMN Printd1099 D
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 02/17/2006 KMC
*--> Add Fed_ID field to jkcmpfil C(10) for US Regions.
if !"$" $ cDataLoc
	ChkTable('','jkcmpfil','FED_ID')  
	IF !newStructure
		WAIT window "Company File Data structure being updated..." nowait
		ALTER table jkcmpfil add column Fed_Id C(10)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> KMC 03/15/2006 Create table MastRptData if it does not already exist.
IF !FILE(cDataLoc + "MastRptData.dbf")
	wait window "Adding Master Report Table..." nowait
	CREAT table cDataLoc + "MastRptData" ;
		(company_no C(6), ;
		bill_mon N(2), ;
		bill_year N(4), ;
		GTRPct N(5,2), ;
		FFPct N(5,2), ;
		FranName1 C(30), ;
		Signed1 D, ;
		Plan1 C(5), ;
		FranDP1 N(10,2), ;
		FranPct1 N(5,2), ;
		FranName2 C(30), ;
		Signed2 D, ;
		Plan2 C(5), ;
		FranDP2 N(10,2), ;
		FranPct2 N(5,2), ;
		FranName3 C(30), ;
		Signed3 D, ;
		Plan3 C(5), ;
		FranDP3 N(10,2), ;
		FranPct3 N(5,2), ;
		FranName4 C(30), ;
		Signed4 D, ;
		Plan4 C(5), ;
		FranDP4 N(10,2), ;
		FranPct4 N(5,2), ;
		FranNotPct N(5,2), ;
		RevOther N(10,2), ;
		RevOthPct N(5,2), ;
		AmtOther N(10,2), ;
		GstHstPct N(5,2), ;
		GTRcPct N(5,2), ;
		FFcPct N(5,2), ;
		FranDPcPct N(5,2), ;
		FranNTcPct N(5,2), ;
		PrepBy C(30), ;
		PrepDate D)
	index on company_no tag company_no
	index on bill_mon tag bill_mon
	index on bill_year tag bill_year	
	USE
	wait clear
ENDIF

*--> Add indexes for new table	
NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
if file(NdxFile)
	use &NdxFile in 0 
else
	USE ndx_dat in 0
endif
	
SELE ndx_dat
Loca for file_name="MASTRPTDATA" and index_to="TAG COMPANY_NO"
if !found()
	APPEND blank
	REPLA file_name with "MASTRPTDATA"
	REPLA index_exp with "COMPANY_NO"
	REPLA index_to with "TAG COMPANY_NO"
	APPEND blank
	REPLA file_name with "MASTRPTDATA"
	REPLA index_exp with "BILL_MON"
	REPLA index_to with "TAG BILL_MON"
	APPEND blank
	REPLA file_name with "MASTRPTDATA"
	REPLA index_exp with "BILL_YEAR"
	REPLA index_to with "TAG BILL_YEAR"
	USE
ENDIF
use
*-->

*--> 03/15/2006 KMC
*--> Add Royalty Credit fields to MastRptData table.
if file('MastRptData.dbf')
	ChkTable('','MastRptData','GTRCPCT')  
	If !newStructure
		WAIT WINDOW "Updating MastRptData Structure..." NOWAIT
		ALTER TABLE MastRptData ADD COLUMN GTRcPct N(5,2)
		ALTER TABLE MastRptData ADD COLUMN FFcPct N(5,2)
		ALTER TABLE MastRptData ADD COLUMN FranDPcPct N(5,2)
		ALTER TABLE MastRptData ADD COLUMN FranNTcPct N(5,2)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 04/04/2006 KMC
*--> Add "CBInv" to jkcmpfil C(1).
if file('jkcmpfil.dbf')
	ChkTable('','jkcmpfil','CBINV')  
	If !newStructure
		WAIT WINDOW "Updating Company File Structure..." NOWAIT
		ALTER TABLE jkcmpfil ADD COLUMN CBINV C(1)
		REPLA ALL CBINV with "Y"
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 04/04/2006 KMC
*--> Add "NatAcct" to jkcusfil C(1).
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','NATACCT')  
	If !newStructure
		WAIT WINDOW "Updating Customer File Structure..." NOWAIT
		ALTER TABLE jkcusfil DROP COLUMN THIRDFRAN  && Drop this field - has not been used in years.
		ALTER TABLE jkcusfil DROP COLUMN THIRDDATE  && Drop this field - has not been used in years.
		ALTER TABLE jkcusfil ADD COLUMN NATACCT C(1)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 04/12/2006 KMC
*--> Add "apply_fran" to jkcustrx and custrxhs C(6) and update fields as necessary.
if file('jkcustrx.dbf')
	ChkTable('','jkcustrx','APPLY_FRAN')  
	If !newStructure
		WAIT WINDOW "Updating Customer Transaction File Structure..." NOWAIT
		ALTER TABLE jkcustrx ADD COLUMN apply_fran C(6)
		ALTER TABLE custrxhs ADD COLUMN apply_fran C(6)
		ALTER TABLE jkarofil ALTER COLUMN apply_to C(6)
		ALTER TABLE arohist ALTER COLUMN apply_to C(6)
		sele arohist
		repla all apply_to with ""
		use
		sele jkarofil
		repl all apply_to with ""
		set order to inv_no

		sele jkcustrx
		repl all for trx_type="I" and len(alltrim(apply_to))=6 apply_fran with apply_to
		set rela to inv_no into jkarofil
		set filt to trx_type="I" and len(alltrim(apply_to))=6
		go top
		do while !eof()
			repla jkarofil.apply_to with jkcustrx.apply_fran
			skip
		enddo	
		use

		sele custrxhs
		repl all for trx_type="I" and len(alltrim(apply_to))=6 apply_fran with apply_to
		set rela to inv_no into jkarofil
		set filt to trx_type="I" and len(alltrim(apply_to))=6
		do while !eof()
			repla jkarofil.apply_to with jkcustrx.apply_fran
			skip
		enddo	
		use

		sele jkarofil
		use

		WAIT CLEAR
	ENDIF
endif
*-->

*--> KMC 04/17/2006 - New tables needed for new Customer complaint function in the Web App.
IF !FILE(cDataLoc + "Complaints.dbf")
	CREATE table cDataLoc + "Complaints" ;
		(id I UNIQUE, ;
		sys_cust I, ;
		cust_no C(6), ;
		userid I, ;
		initdate T, ;
		closedate T, ;
		feecharged N(6,2))
	index on sys_cust tag sys_cust
	index on cust_no tag cust_no
	index on initdate tag initdate
	index on closedate tag closedate
	USE

	CREATE table cDataLoc + "Keys" ;
		(table C(20) UNIQUE, ;
		nextid I)
	append blank
	repla table with "COMPLAINTS"
	use
	
	ALTER table cDataLoc + "jkcusfil" alter column atrisk C(1)
	repla all for atrisk="T" atrisk with "A"
	repla all for atrisk<>"A" atrisk with ""
	use
	
	*--> Add indexes for new tables
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	
	SELE ndx_dat
	
	*--> KMC 05/22/06 - No longer using a DBC for custleads and franleads (free tables now).
	*--> Only the DBC's had nothing in ndx_dat.index_exp.
	dele all for empty(index_exp)  
	
	Loca for file_name="COMPLAINTS" and index_to="TAG ID"
	if !found()
		APPEND blank
		REPLA file_name with "COMPLAINTS"
		REPLA index_exp with "ID"
		REPLA index_to with "TAG ID"
		APPEND blank
		REPLA file_name with "COMPLAINTS"
		REPLA index_exp with "SYS_CUST"
		REPLA index_to with "TAG SYS_CUST"
		APPEND blank
		REPLA file_name with "COMPLAINTS"
		REPLA index_exp with "CUST_NO"
		REPLA index_to with "TAG CUST_NO"
		APPEND blank
		REPLA file_name with "COMPLAINTS"
		REPLA index_exp with "INITDATE"
		REPLA index_to with "TAG INITDATE"
		APPEND blank
		REPLA file_name with "COMPLAINTS"
		REPLA index_exp with "CLOSEDATE"
		REPLA index_to with "TAG CLOSEDATE"
		APPEND blank
		REPLA file_name with "KEYS"
		REPLA index_exp with "TABLE"
		REPLA index_to with "TAG TABLE"
	ENDIF
	use
	wait clear
ENDIF
*-->

*--> 06/07/2006 KMC
*--> Add field onReport L and editDate D to jkcustrx, jkdlrtrx, custrxhs and dlrtrxhs.
ChkTable('','jkcustrx','ONREPORT')  
IF !newStructure
	WAIT window "Customer Transaction File Data structure being updated..." nowait
	ALTER table jkcustrx add column onReport L
	ALTER table jkcustrx add column EditDate D
	REPLA ALL onReport with .T.
	USE
	WAIT clear
ENDIF

ChkTable('','jkdlrtrx','ONREPORT')  
IF !newStructure
	WAIT window "Franchisee Transaction File Data structure being updated..." nowait
	ALTER table jkdlrtrx add column onReport L
	ALTER table jkdlrtrx add column EditDate D
	REPLA ALL onReport with .T.
	USE
	WAIT clear
ENDIF

ChkTable('','custrxhs','ONREPORT')  
IF !newStructure
	WAIT window "Customer Transaction History File Data structure being updated..." nowait
	ALTER table custrxhs add column onReport L
	ALTER table custrxhs add column EditDate D
	REPLA ALL onReport with .T.
	USE
	WAIT clear
ENDIF

ChkTable('','dlrtrxhs','ONREPORT')  
IF !newStructure
	WAIT window "Franchisee Transaction History File Data structure being updated..." nowait
	ALTER table dlrtrxhs add column onReport L
	ALTER table dlrtrxhs add column EditDate D
	REPLA ALL onReport with .T.
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 07/10/2006
ChkTable('','jkcusfil','CUS_EXT')  
IF !newStructure
	WAIT window "Customer File Data structure being updated..." nowait
	ALTER table jkcusfil add column cus_ext C(6)
	ALTER table jkcusfil add column bill_ext C(6)
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 07/14/2006
ChkTable('','jkcmpfil','CPIINCR')  && KMC 07/19/2006 - Corrected CPIIncr to all upper case.
IF !newStructure
	WAIT window "Customer File Data structure being updated..." nowait
	ALTER table jkcmpfil add column CPIincr C(1)
	repla all CPIincr with "Y"
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 08/07/2006
ChkTable('','jkcmpfil','ROYONCS')  && Flag for Royalty on Client Supplies (needed for Austin).
IF !newStructure
	WAIT window "Customer File Data structure being updated..." nowait
	ALTER table jkcmpfil add column RoyOnCS C(1)
	repla all RoyOnCS with "Y"
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 10/17/2006
IF !FILE(cDataLoc + "Data1099.dbf")
	wait window "Adding 1099 Data Table..." nowait
	create table cDataLoc+"Data1099" ;
		(company_no C(6), ;
		ven_fran C(10), ;
		source C(10), ;
		bill_mon N(2), ;
		bill_year N(4), ;
		print1099 C(1), ;
		dlr_code C(6), ;
		dlr_id C(3), ;
		name_1099 C(40), ;
		dlr_addr C(30), ;
		dlr_city C(20), ;
		dlr_state C(2), ;
		dlr_zip C(10), ;
		ssn_fid C (11), ;
		ckdate D, ;
		cknumber C(8), ;
		ckpayee C(30), ;
		satype C(2), ;
		amount N(12,2), ;
		correction C(1), ;
		lastupdate D, ;
		printed D, ;
		rptYear N(4))
	use
	WAIT clear
else
	ChkTable('','Data1099','RPTYEAR')  && Add column rptYear (1099 Report Year).
	IF !newStructure
		WAIT window "1099 Data file structure being updated..." nowait
		ALTER table data1099 add column rptYear N(4)
		USE
		WAIT clear
	endif	
ENDIF
*-->

*--> KMC 11/08/2006
IF !FILE(cDataLoc + "PDSetting.dbf")
	wait window "Adding Past Due Setting Table..." nowait
	create table cDataLoc+"PDSetting" ;
		(Months N(3), ;
		SysCust L, ;
		ExclNetCr L, ;
		ExclNat L)
	append blank
	repla Months with 6
	repla SysCust with .F.
	repla ExclNetCr with .F.
	repla ExclNat with .F.
	use
	WAIT clear
ENDIF
*-->

*--> KMC 11/17/2006
ChkTable('','jkdlrtrx','NUM_LEFT')  && Number of months left for Recurring Fran Trx's.
IF !newStructure
	WAIT window "Franchisee Transaction File Data structure being updated..." nowait
	ALTER table jkdlrtrx add column Num_Left N(3)
	repla all for recur="Y" num_left with 999
	USE
	WAIT clear
ENDIF
ChkTable('','dlrtrxhs','NUM_LEFT')  && Number of months left for Recurring Fran Trx's.
IF !newStructure
	WAIT window "Franchisee Transaction Archive File Data structure being updated..." nowait
	ALTER table dlrtrxhs add column Num_Left N(3)
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 02/07/2007
newStructure=.F.
use jkcmpfil in 0
sele jkcmpfil
curFFFactor=jkcmpfil.ff_factor
repla jkcmpfil.ff_factor with jkcmpfil.ff_factor+.1
if jkcmpfil.ff_factor=curFFFactor+.1
	newStructure=.T.
	repla jkcmpfil.ff_factor with curFFFactor
	use
else
	use
	WAIT window "Company File Data structure being updated..." nowait
	Alter table jkcmpfil alter column ff_factor N(4,1)
	use
	wait clear	
endif
*-->			

*--> KMC 02/22/2007
ChkTable('','jkfrnhst','REASON')  && Cancellation Reason.
IF !newStructure
	WAIT window "Declined Account History File Data structure being updated..." nowait
	ALTER table jkfrnhst add column Reason C(25)
	USE
	WAIT clear
ENDIF

*--> Create and populate table with Declined Reasons if it does not alreaady exist.
IF !FILE(cDataLoc + "ReasonDeclined.dbf")
	wait window "Adding Reason Declined Table..." nowait
	create table cDataLoc+"ReasonDeclined" ;
		(reason C(25)) 
	append blank
	append blank
	repla reason with "Accessibility"
	append blank
	repla reason with "Alarms"
	append blank
	repla reason with "Bid Low"
	append blank
	repla reason with "Cash Flow"
	append blank
	repla reason with "Cleaning Schedule"
	append blank
	repla reason with "Day Porter"
	append blank
	repla reason with "Difficult Account"
	append blank
	repla reason with "Distance"
	append blank
	repla reason with "Equipment Requirements"
	append blank
	repla reason with "Location"
	append blank
	repla reason with "No Response From Fran"
	append blank
	repla reason with "Payroll"
	append blank
	repla reason with "Personal Reasons"
	append blank
	repla reason with "Service Hours"
	append blank
	repla reason with "Size - Too Big"
	append blank
	repla reason with "Size - Too Small"
	append blank
	repla reason with "Staffing Issues"
	append blank
	repla reason with "Unknown"
	WAIT clear && KMC 02/23/2007
endif	
*-->

*--> KMC 03/19/2007
ChkTable('','jkcusfil','SQR_FT') 
IF !newStructure
	WAIT window "Square Footage field being added to jkcusfil..." nowait
	ALTER table jkcusfil add column sqr_ft N(9)
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 03/21/2007
ChkTable('','incrdecr','REASON') 
IF !newStructure
	WAIT window "Adding field 'Reason' to IncrDecr table..." nowait
	ALTER table incrdecr add column Reason C(50)
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 10/12/2007
ChkTable('','jkcmpfil','CUS_TERM') 
IF !newStructure
	WAIT window "Adding field 'Cus_Term' to jkcmpfil table..." nowait
	ALTER table jkcmpfil add column cus_term N(3)
	sele jkcmpfil
	repla all cus_term with 36
	USE
	WAIT clear
ENDIF

ChkTable('','jkcusfil','AGREEUSED') 
IF !newStructure
	WAIT window "Adding field 'AgreeUsed' to jkcusfil table..." nowait
	ALTER table jkcusfil add column agreeused C(9)
	sele jkcusfil
	index on agreeused tag agreeused
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 06/02/2008
*--> Only do this for Non-Canadian Regions.
if ! "$" $ cDataLoc
	ChkTable('','jkdlrfil','BPPADMIN') 
	IF !newStructure
		WAIT window "Adding field 'BPPAdmin' to jkdlrfil table..." nowait
		ALTER table jkdlrfil add column BPPADMIN C(1)
		sele jkdlrfil

		*--> KMC 06/02/2008
		if cCompNo="HOU051"
			repla all BPPAdmin with "N"
		else
			repla all BPPAdmin with "Y"
		endif
		*-->
			
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> KMC 10/07/2008 - Expand Address line to 40 for jkdlrfil and dlrtrxhs.
use cDataLoc+"jkdlrfil" in 0 
sele jkdlrfil
if len(dlr_addr)<40
	wait window "Updating Franchisee Address Field..." nowait
	use
	alter table cDataLoc+"jkdlrfil" alter column dlr_addr C(40)
	use
	wait clear	
else
	use
endif	
use cDataLoc+"dlrtranhst" in 0 
sele dlrtranhst
if len(dlr_addr)<40
	wait window "Updating Franchisee Trandfer History Address Field..." nowait
	use
	alter table cDataLoc+"dlrtranhst" alter column dlr_addr C(40)
	use
	wait clear	
else
	use
endif	
*-->

*--> KMC 10/20/2008 - Add table to track customer address changes.
IF !FILE(cDataLoc + "CusAddrHst.dbf")
	wait window "Adding Customer Address History Table..." nowait
	create table cDataLoc+"CusAddrHst" ;
		(sys_cust I, ;
		cust_no C(6), ;
		cus_addr C(30), ;
		cus_addr2 C(30), ;
		cus_city C(20), ;
		cus_state C(2), ;
		cus_zip C(10), ;
		changedate D, ;
		changetime C(8), ;
		username C(25), ;
		source C(6))

	index on sys_cust tag sys_cust
	index on cust_no tag cust_no
	index on changedate tag changedate
	inde on username tag username
	index on source tag source

	use

	*--> Add indexes for new table
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif

	SELE ndx_dat
	Loca for file_name="CUSADDRHST" and index_to="TAG SYS_CUST"
	if !found()
		APPEND blank
		REPLA file_name with "CUSADDRHST"
		REPLA index_exp with "SYS_CUST"
		REPLA index_to with "TAG SYS_CUST"
		APPEND blank
		REPLA file_name with "CUSADDRHST"
		REPLA index_exp with "CUST_NO"
		REPLA index_to with "TAG CUST_NO"
		APPEND blank
		REPLA file_name with "CUSADDRHST"
		REPLA index_exp with "CHANGEDATE"
		REPLA index_to with "TAG CHANGEDATE"
 		APPEND blank
		REPLA file_name with "CUSADDRHST"
		REPLA index_exp with "USERNAME"
		REPLA index_to with "TAG USERNAME"
		APPEND blank
		REPLA file_name with "CUSADDRHST"
		REPLA index_exp with "SOURCE"
		REPLA index_to with "TAG SOURCE"
	ENDIF
	USE

	WAIT clear
ENDIF
*-->

*--> 11/04/2008 KMC
*--> Add fields last_renew, term and exp_date to jkdlrfil D.
ChkTable('','jkdlrfil','LAST_RENEW')  
IF !newStructure
	WAIT window "Franchisee File Data structure being updated..." nowait
	ALTER table jkdlrfil add column last_renew D
	ALTER table jkdlrfil add column term C (3)
	ALTER table jkdlrfil add column exp_date D

	repla all last_renew with date_sign
	*--> KMC 04/09/2009 - Since all Masters may not use the same terms that we use, do not set.
	*repla all term with "20"
	*repla all for !empty(last_renew) exp_date with gomonth(last_renew,val(alltrim(term))*12)-1
	*-->
	
	index on term tag term
	index on exp_date tag exp_date

	USE
	WAIT clear
ENDIF
*-->

*--> KMC 01/28/2009 - Add new Business Fee column to tables as neccessary for Canada Masters.
if lCanadaMaster
	ChkTable('','jkcmpfil','BUSNS_PCT')  
	IF !newStructure
		WAIT window "JKCmpFil Data structure being updated..." nowait
		ALTER table jkcmpfil add column busns_pct N(6,3)
		USE
	ENDIF	
	ChkTable('','jkdlrfil','BUSNS_PCT')  
	IF !newStructure
		WAIT window "JKDlrfil Data structure being updated..." nowait
		ALTER table jkdlrfil add column busns_pct N(6,3)
		USE
	ENDIF	
	ChkTable('','cur_fran','BUSNS_PCT')  
	IF !newStructure
		WAIT window "Cur_Fran Data structure being updated..." nowait
		ALTER table cur_fran add column busns_pct N(6,3)
		USE
	ENDIF	
	ChkTable('','rpt_fran','BUSNS_PCT')  
	IF !newStructure
		WAIT window "Rpt_Fran Data structure being updated..." nowait
		ALTER table rpt_fran add column busns_pct N(6,3)
		USE
	ENDIF	
	ChkTable('','tmpsprd','T_BUSNS_F')  
	IF !newStructure
		WAIT window "TmpSprd Data structure being updated..." nowait
		ALTER table tmpsprd add column t_busns_f N(10,2)
		USE
	ENDIF	
	WAIT CLEAR
ENDIF
*-->

*--> KMC 03/25/2009 - Update tables as necessary with new fields needed by call center (some used by old TM system too).
ChkTable('custleads\','custleads','CONTEXPIRE') 
IF !newStructure
	WAIT window "Adding field 'ContExpire' to CustLeads table..." nowait
	ALTER table custleads\custleads alter column email C(50)
	ALTER table custleads\custleads add column contexpire D
	ALTER table custleads\custleads add column cb_time C(5)
	ALTER table custleads\custleads add column cb_ampm C(2)
	alter table custleads\custleads add column lst_attmpt D
	alter table custleads\custleads add column attmpt_cnt N(2,0)
	repl all for !isnull(custleads.lastcontac) custleads.lst_attmpt with custleads.lastcontac
	repl all custleads.lastcontac with {  \  \  }
	repl all custleads.attmpt_cnt with 0
	index on lst_attmpt tag lst_attmpt
	index on attmpt_cnt tag attmpt_cnt
	index on cb_ampm tag cb_ampm && KMC 05/29/2009
	sele custleads
	use

	ALTER table custleads\custleadcalls add column cb_time C(5)
	ALTER table custleads\custleadcalls add column cb_ampm C(2)
	sele custleadcalls
	use

	ALTER table custleads\clcallhst add column cb_time C(5)
	ALTER table custleads\clcallhst add column cb_ampm C(2)
	sele clcallhst
	use

	*--> Add new indexes for custleads
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif

	SELE ndx_dat

	*--> KMC 05/21/2009
	*Loca for file_name="CUSTLEADS" and index_to="TAG LST_ATTMPT"
	Loca for file_name="CUSTLEADS\CUSTLEADS" and index_to="TAG LST_ATTMPT"

	if !found()
		APPEND blank
		*--> KMC 05/21/2009
		*REPLA file_name with "CUSTLEADS"
		REPLA file_name with "CUSTLEADS\CUSTLEADS"
		REPLA index_exp with "LST_ATTMPT"
		REPLA index_to with "TAG LST_ATTMPT"

		APPEND blank
		*--> KMC 05/21/2009
		*REPLA file_name with "CUSTLEADS"
		REPLA file_name with "CUSTLEADS\CUSTLEADS"
		REPLA index_exp with "ATTMPT_CNT"
		REPLA index_to with "TAG ATTMPT_CNT"

		*--> kmc 05/29/2009
		APPEND blank
		REPLA file_name with "CUSTLEADS\CUSTLEADS"
		REPLA index_exp with "CB_AMPM"
		REPLA index_to with "TAG CB_AMPM"
		*-->
	ENDIF

	*--> Add these indexes if they don't already exist.
	Loca for file_name="JKDLRFIL" and index_to="TERM"
	if !found()
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "TERM"
		REPLA index_to with "TAG TERM"
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "EXP_DATE"
		REPLA index_to with "TAG EXP_DATE"
	ENDIF

	USE

	wait clear
ENDIF
*-->

*--> KMC 04/07/2009 - Add table CallNoteOpt if it does not exist.
*--> This code will only work when the FRADB is in the same folder as the regions fracct data (jk_xxx folders). 
*--> Really only applies to Master installations.
UserTbl=left(cDataLoc,xCnt)+"FRADB\DOS_Usr.dbf"
if file(UserTbl)
	tblCallNoteOpt=left(cDataLoc,xCnt)+"fradb\callnoteopt.dbf"
	if !file(tblCallNoteOpt)
		create table left(cDataLoc,xCnt)+"fradb\callnoteopt" ;
			(id I, ;
			note C(125))
		sele callnoteopt
		index on id tag id
		
		*--> Populate table CallNoteOpt.
		id=1
		insert into callnoteopt from memvar
		repl note with "Cleaning Included in lease."
		
		id=2
		insert into callnoteopt from memvar
		repl note with "Contact unhappy, giving current co. second chance."

		id=3
		insert into callnoteopt from memvar
		repl note with "Happy with current service."

		id=4
		insert into callnoteopt from memvar
		repl note with "Happy, previous customer, positive towards us."

		id=5
		insert into callnoteopt from memvar
		repl note with "Intersted, unable to talk now."

		id=6
		insert into callnoteopt from memvar
		repl note with "Interested, wants bid when current contract expires."

		id=7
		insert into callnoteopt from memvar
		repl note with "Just hired new cleaning company."

		id=8
		insert into callnoteopt from memvar
		repl note with "Long term contract, stay in touch."

		id=9
		insert into callnoteopt from memvar
		repl note with "Not in."

		id=10
		insert into callnoteopt from memvar
		repl note with "Not interested, do not call again."

		id=11
		insert into callnoteopt from memvar
		repl note with "Not interested at this time."

		id=12
		insert into callnoteopt from memvar
		repl note with "Previous customer, cancelled for non-performance."

		id=13
		insert into callnoteopt from memvar
		repl note with "Unhappy with current service."

		use

		 *--> Add appropriate keys.
		use left(cDataLoc,xCnt)+"fradb\keys.dbf" 
		sele keys
		loca for table = "CALLNOTEOPT"
		if !found()
			append blank
			repl table with "CALLNOTEOPT"
			repla nextid with 14
		endif
		use
		
	endif

	*--> KMC 04/07/2009 - Add table WAUpdates if it does not exist.
	*-> This code will only work when the FRADB is in the same folder as the regions fracct data (jk_xxx folders). 
	*-> Really only applies to Master installations.
	UserTbl=left(cDataLoc,xCnt)+"FRADB\DOS_Usr.dbf"
	if file(UserTbl)
		tblWAUpdates=left(cDataLoc,xCnt)+"fradb\waupdates.dbf"
		if !file(tblWAUpdates)
			create table left(cDataLoc,xCnt)+"fradb\waupdates" ;
				(id I, ;
				published T, ;
				shortdesc C(50), ;
				status C(1), ;
				module I, ;
				type C(1), ;
				priority I, ;
				descr M)	

			sele WAUpdates
			index on id tag id
			index on published tag published
			index on module tag module	
			use
			
			*--> Add appropriate keys.
			use left(cDataLoc,xCnt)+"fradb\keys.dbf" 
			sele keys
			loca for table = "WAUPDATES"
			if !found()
				append blank
				repl table with "WAUPDATES"
				repla nextid with 1
			endif
			use
		endif	
	endif	
endif
*-->

*--> 05/08/2009 KMC
*--> Add fields Contact C(50) to jkdlrfil if it does not alredy exist.
ChkTable('','jkdlrfil','CONTACT')  
IF !newStructure
	WAIT window "Franchisee File Data structure being updated..." nowait
	ALTER table jkdlrfil add column contact C(50)
	index on contact tag contact
	USE
	WAIT clear

	*--> Add index on Contact to jkdlrfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="JKDLRFIL" and index_to="TAG CONTACT"
	IF !found()
		APPEND blank
		REPLA file_name with "JKDLRFIL"
		REPLA index_exp with "CONTACT"
		REPLA index_to with "TAG CONTACT"
	ENDIF
	USE
ENDIF

ChkTable('','dlrtranhst','CONTACT')  
IF !newStructure
	WAIT window "Franchisee File Data structure being updated..." nowait
	ALTER table dlrtranhst add column contact C(50)
	index on contact tag contact
	USE
	WAIT clear

	*--> Add index on Contact to dlrtranhst in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif
	*-->
	
	SELE ndx_dat
	LOCA for file_name="DLRTRANHST" and index_to="TAG CONTACT"
	IF !found()
		APPEND blank
		REPLA file_name with "DLRTRANHST"
		REPLA index_exp with "CONTACT"
		REPLA index_to with "TAG CONTACT"
	ENDIF
	USE
ENDIF
*-->

*--> KMC 07/02/2010 - Add table of AR Status's.
*-> This code will only work when the FRADB is in the same folder as the regions fracct data (jk_xxx folders). 
*-> Really only applies to Master installations.
UserTbl=left(cDataLoc,xCnt)+"FRADB\DOS_Usr.dbf"
if file(UserTbl)
	tblARStatus=left(cDataLoc,xCnt)+"fradb\ARStatus.dbf"
	if !file(tblARStatus)
		create table left(cDataLoc,xCnt)+"FRADB\ARStatus" ;
			(id I, ;
			status C(25))
		
		sele ARStatus
		index on id	tag id unique
		index on status tag status

		*--> Populate table ARStatus.
		id=1
		insert into ARStatus from memvar
		repl status with "Bankruptcy"
		
		id=2
		insert into ARStatus from memvar
		repl status with "In Litigation"
	
		id=3
		insert into ARStatus from memvar
		repl status with "Net 60 Days"
	
		id=4
		insert into ARStatus from memvar
		repl status with "Net 90 Days"
	
		id=5
		insert into ARStatus from memvar
		repl status with "Normal"
		
		id=6
		insert into ARStatus from memvar
		repl status with "Referred to Collections"
	
		id=7
		insert into ARStatus from memvar
		repl status with "Slow Pay"
	
		id=8
		insert into ARStatus from memvar
		repl status with "Uncollectable"
	
		id=9
		insert into ARStatus from memvar
		repl status with "Net 45 Days"

		id=10
		insert into ARStatus from memvar
		repl status with "National Account"

		use
	
		 *--> Add appropriate keys.
		use left(cDataLoc,xCnt)+"fradb\keys.dbf" 
		sele keys
		loca for table = "ARSTATUS"
		if !found()
			append blank
			repl table with "ARSTATUS"
			repla nextid with 9
		endif
		use
	
	ENDIF
ENDIF
*-->

*--> KMC 07/02/2010
ChkTable('','jkcusfil','ARSTATUS')  
IF !newStructure
	WAIT window "Adding column ARStatus to JKCusfil..." nowait
	ALTER table jkcusfil add column ARStatus C(25)
	USE
	wait clear
ENDIF	
*-->

*--> KMC 09/08/2010 - Update table regions as appropriate.
*-> This code will only work when the FRADB is in the same folder as the regions fracct data (jk_xxx folders). 
*-> Really only applies to Master installations.
RegionsTbl=left(cDataLoc,xCnt)+"FRADB\Regions.dbf"
if file(RegionsTbl)
	ChkTable(left(cDataLoc,xCnt)+'FraDB\','regions','ACCTSERVER')
	IF !newStructure
		wait window "Updating Regions Table..." nowait
		ALTER table &RegionsTbl add column AcctServer C(25)
		ALTER table &RegionsTbl add column AcctPwd C(25)
		ALTER table &RegionsTbl add column AcctDB C(25)
		sele regions
		use
	endif
	ChkTable(left(cDataLoc,xCnt)+'FraDB\','regions','REDIRECT')
	IF !newStructure
		ALTER table &RegionsTbl add column Redirect C(30)
		sele regions
		use
	endif
	ChkTable(left(cDataLoc,xCnt)+'FraDB\','regions','COUNTRY')
	IF !newStructure
		ALTER table &RegionsTbl add column Country C(30)
		sele regions
		use
	endif	
	wait clear
endif
*-->

*--> KMC 10/27/2010
ChkTable('','jkcusfil','ARSTATDATE') 
IF !newStructure
	WAIT window "Adding field 'ARStatDate' to jkcusfil table..." nowait
	ALTER table jkcusfil add column arstatdate D
	sele jkcusfil
	USE
	WAIT clear
ENDIF
*-->

*--> 11/17/2010 KMC
*--> Expand Customer, Franchisee and Lead email address fields to C(50).
if file('custleads\custleads.dbf')
	newStructure=.T.
	USE custleads\custleads
	if len(email)<50
		newStructure=.F.
	endif
	USE
	IF !newStructure
		WAIT window "Customer Leads email address field being extended..." nowait
		ALTER table custleads\custleads alter column email C(50)
		USE
		WAIT clear
	ENDIF
endif
if file('franleads\franleads.dbf')
	newStructure=.T.
	USE franleads\franleads
	if len(email)<50
		newStructure=.F.
	endif
	USE
	IF !newStructure
		WAIT window "Franchise Leads email address field being extended..." nowait
		ALTER table franleads\franleads alter column email C(50)
		USE
		WAIT clear
	ENDIF
endif
if file('jkdlrfil.dbf')
	newStructure=.T.
	USE jkdlrfil
	if len(email)<50
		newStructure=.F.
	endif
	USE
	IF !newStructure
		WAIT window "Franchisee email address field being extended..." nowait
		ALTER table jkdlrfil alter column email C(50)
		USE
		WAIT clear
	ENDIF
endif
if file('jkcusfil.dbf')
	newStructure=.T.
	USE jkcusfil
	if len(email1)<50
		newStructure=.F.
	endif
	USE
	IF !newStructure
		WAIT window "Customer email address fields being extended..." nowait
		ALTER table jkcusfil alter column email1 C(50)
		ALTER table jkcusfil alter column email2 C(50)
		USE
		WAIT clear
	ENDIF
endif
*-->

*--> KMC 01/28/2011
*--> Expand dlr_addr field in data1099 to match field length in jkdlrfil and dlrtranhst.
use cDataLoc+"data1099" in 0 
sele data1099
if len(dlr_addr)<40
	wait window "Updating Data1099 Address Field..." nowait
	use
	alter table cDataLoc+"data1099" alter column dlr_addr C(40)
	use
	wait clear	
else
	use
endif	
*-->

*--> 02/15/2011 KMC
*--> Add AmtOthDes field to MastRptData table.
if file('MastRptData.dbf')
	ChkTable('','MastRptData','AMTOTHDES')  
	If !newStructure
		WAIT WINDOW "Updating MastRptData Structure..." NOWAIT
		ALTER TABLE MastRptData ADD COLUMN 	AmtOthDes C(40)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 03/10/2011
ChkTable('','jkcmpfil','I_OTC') 
IF !newStructure
	WAIT window "Adding field 'i_otc' to jkcmpfil table..." nowait  && Initial / One-Time Clean default Commission Percantage
	ALTER table jkcmpfil add column i_otc N(5,2)
	WAIT window "Adding field 'adtl_b_ofc' to jkcmpfil table..." nowait && Additional Bill - Office default Commission Percentage
	ALTER table jkcmpfil add column adtl_b_ofc N(5,2)
	sele jkcmpfil
	repla all i_otc with 5.0
	repla all adtl_b_ofc with 5.0 
	USE
	WAIT clear
ENDIF
*-->

*--> KMC 01/16/2012
ChkTable('','tmpsprd','NO_CB_RES') 
IF !newStructure
	WAIT window "Adding field 'no_cb_res' to tmpsprd table..." nowait  && No CB Reserve to hold back from DRO.
	ALTER table tmpsprd add column no_cb_res N(8,2)
	sele tmpsprd
	USE
	WAIT clear
ENDIF
*-->

*--> 09/16/2011 KMC
*--> Add End_Date to AFRebPct table.
if file('AFRebPct.dbf')
	ChkTable('','AFRebPct','END_DATE')  
	If !newStructure
		WAIT WINDOW "Updating Acct Fee Rebate Table Structure..." NOWAIT
		ALTER TABLE AFRebPct ADD COLUMN end_date D
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 01/27/2012 KMC
*--> Add column Notes C(100) to jkcusfil table.
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','NOTES')  
	If !newStructure
		WAIT WINDOW "Updating Customer Table Structure..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN notes C(100)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> 05/10/2012 KMC
*--> Add column tech_pct N(5,2) to jkcmpfil table.
if file('jkcmpfil.dbf')
	ChkTable('','jkcmpfil','TECH_PERC')  
	If !newStructure
		WAIT WINDOW "Updating Company File Table Structure..." NOWAIT
		ALTER TABLE jkcmpfil ADD COLUMN tech_perc N(5,2)
		Replace all tech_perc with 0.00
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add column t_tech_fee N(9,2) to tmpsprd table.
if file('tmpsprd.dbf')
	ChkTable('','tmpsprd','T_TECH_FEE')  
	If !newStructure
		WAIT WINDOW "Updating Spreadsheet Table Structure..." NOWAIT
		ALTER TABLE tmpsprd ADD COLUMN t_tech_fee N(9,2)
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add columns tech_pct N(5,2) and ded_tech C(1) to jkdlrfil table.
if file('jkdlrfil.dbf')
	ChkTable('','jkdlrfil','TECH_PCT')  
	If !newStructure
		WAIT WINDOW "Updating Franchisee File Table Structure..." NOWAIT
		ALTER TABLE jkdlrfil ADD COLUMN tech_pct N(5,2)
		ALTER TABLE jkdlrfil ADD COLUMN ded_tech C(1)
		Replace all tech_pct with 0.00
		Replace all ded_tech with "N"
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add columns tech_pct N(5,2) and ded_tech C(1) to cur_fran table.
if file('cur_fran.dbf')
	ChkTable('','cur_fran','TECH_PCT')  
	If !newStructure
		WAIT WINDOW "Updating Franchise Report Current Data File Table Structure..." NOWAIT
		ALTER TABLE cur_fran ADD COLUMN tech_pct N(5,2)
		ALTER TABLE cur_fran ADD COLUMN ded_tech C(1)
		Replace all tech_pct with 0.00
		Replace all ded_tech with "N"
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add columns tech_pct N(5,2) and ded_tech C(1) to rpt_fran table.
if file('rpt_fran.dbf')
	ChkTable('','rpt_fran','TECH_PCT')  
	If !newStructure
		WAIT WINDOW "Updating Franchise Report History Data File Table Structure..." NOWAIT
		ALTER TABLE rpt_fran ADD COLUMN tech_pct N(5,2)
		ALTER TABLE rpt_fran ADD COLUMN ded_tech C(1)
		WAIT CLEAR
		Replace all tech_pct with 0.00
		Replace all ded_tech with "N"
	ENDIF
	USE
endif
*-->

*--> KMC 05/30/2012
*--> These fields are only applicable to Canadian Masters
if lCanadaMaster
	*--> Add columns billadjpct and ded_adjpct to jkdlrfil table.
	if file('jkdlrfil.dbf')
		ChkTable('','jkdlrfil','BILLADJPCT')  
		If !newStructure
			WAIT WINDOW "Updating Franchise File Table Structure..." NOWAIT
		ALTER TABLE jkdlrfil ADD COLUMN BillAdjPct N(5,2)
		ALTER TABLE jkdlrfil ADD COLUMN ded_adjpct C(1)
		Replace all BillAdjPct with 00.00
		Replace all ded_adjpct with "N"
		WAIT CLEAR
		ENDIF
	ENDIF
	USE
	
	*--> Add column ROBCA to jkcmpfil table.
	if file('jkcmpfil.dbf')
		ChkTable('','jkcmpfil','ROBCA')  
		If !newStructure
			WAIT WINDOW "Updating Company File Table Structure..." NOWAIT
		ALTER TABLE jkcmpfil ADD COLUMN ROBCA C(6)  && ROBCA stores the Regional Office Billing Component holding account (customer).
		WAIT CLEAR
		ENDIF
	endif
	USE
endif
*-->

*--> KMC 08/03/2012
*--> Add columns t_tech_pct N(9,2) jkrptfil table.
if file('jkrptfil.dbf')
	ChkTable('','jkrptfil','T_TECH_FEE')  
	If !newStructure
		WAIT WINDOW "Updating Corp Dues Report (jkrptfil) Table Structure..." NOWAIT
		ALTER TABLE jkrptfil ADD COLUMN t_tech_fee N(9,2)
		WAIT CLEAR
		Replace all t_tech_fee with 0.00
	ENDIF
	USE
endif
*-->

*--> KMC 10/19/2012
*--> Add column contact C(50) to cur_fran table.
if file('cur_fran.dbf')
	ChkTable('','cur_fran','CONTACT')  
	If !newStructure
		WAIT WINDOW "Updating Franchisee History Table Structure..." NOWAIT
		ALTER TABLE cur_fran ADD COLUMN contact C(50)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 10/19/2012
*--> Add columns contact C(50) to rpt_fran table.
if file('rpt_fran.dbf')
	ChkTable('','rpt_fran','CONTACT')  
	If !newStructure
		WAIT WINDOW "Updating Franchisee History Table Structure..." NOWAIT
		ALTER TABLE rpt_fran ADD COLUMN contact C(50)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 12/13/2012
*--> If len(cur_fran.dlr_addr)<40 increase to 40.
if file('cur_fran.dbf')
	use cur_fran
	if len(cur_fran.dlr_addr)<40
		use
		WAIT WINDOW "Updating Franchisee History Table Structure..." NOWAIT
		ALTER TABLE cur_fran ALTER COLUMN dlr_addr C(40)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 12/13/2012
*--> If len(rpt_fran.dlr_addr)<40 increase to 40.
if file('rpt_fran.dbf')
	use rpt_fran
	if len(rpt_fran.dlr_addr)<40
		use
		WAIT WINDOW "Updating Franchisee History Table Structure..." NOWAIT
		ALTER TABLE rpt_fran ALTER COLUMN dlr_addr C(40)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 12/13/2012
*--> Add column claimstat C(1) to jkcusfil.
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','CLAIMSTAT')  
	If !newStructure
		WAIT WINDOW "Updating Customer Table Structure..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN claimstat C(1)
		index on claimstat tag claimstat
		WAIT CLEAR
	ENDIF
	USE

	*--> Add index on claimstat to jkcusfil in ndx_dat.
	NdxFile=left(cDataLoc,xCnt)+"IndexFiles\ndx_dat.dbf"
	if file(NdxFile)
		use &NdxFile in 0 
	else
		USE ndx_dat in 0
	endif

	SELE ndx_dat

	*--> KMC 12/22/2017
	*LOCA for file_name="JKCUSFIL" and index_to="CLAIMSTAT"
	LOCA for file_name="JKCUSFIL" and index_to="TAG CLAIMSTAT"
	*-->
	
	IF !found()
		APPEND blank
		REPLA file_name with "JKCUSFIL"
		REPLA index_exp with "CLAIMSTAT"
		REPLA index_to with "TAG CLAIMSTAT"
	ENDIF
	USE
endif
*-->

*--> KMC 07/23/2014
*--> Add column afr_elig C(1) to jkcusfil.
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','AFR_ELIG')  
	If !newStructure
		WAIT WINDOW "Updating Customer Trx Table Structure..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN afr_elig C(1)
		repla all afr_elig with "Y"
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add column afr_elig C(1) to cur_cat.
if file('cur_cat.dbf')
	ChkTable('','cur_cat','AFR_ELIG')  
	If !newStructure
		WAIT WINDOW "Updating Customer Cust Acct Totals Table Structure..." NOWAIT
		ALTER TABLE cur_cat ADD COLUMN afr_elig C(1)
		repla all afr_elig with "Y"
		WAIT CLEAR
	ENDIF
	USE
endif

*--> Add column afr_elig C(1) to rpt_cat.
if file('rpt_cat.dbf')
	ChkTable('','rpt_cat','AFR_ELIG')  
	If !newStructure
		WAIT WINDOW "Updating Historical Cust Acct Totals Table Structure..." NOWAIT
		ALTER TABLE rpt_cat ADD COLUMN afr_elig C(1)
		repla all afr_elig with "Y"
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 09/25/2014 KMC Only needed for CanadaMasters
if file('MastRptData.dbf') and "$" $ cDataLoc
	*--> KMC 04/11/2017 - Corrected to all caps for field being tested.
	*ChkTable('','MastRptData','AmtOther2')  
	ChkTable('','MastRptData','AMTOTHER2')  
	*-->
	If !newStructure
		WAIT WINDOW "Updating MastFranRpt Table Structure..." NOWAIT
		ALTER TABLE MastRptData ADD COLUMN AmtOther2 N(10,2)
		ALTER TABLE MastRptdata ADD COLUMN AmtOthDes2 C(40)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 01/21/2015 - Add column min_roy N(9,2) to cur_fran table.
if file('cur_fran.dbf')
	ChkTable('','cur_fran','MIN_ROY')  
	If !newStructure
		WAIT WINDOW "Updating Franchise Report Current Data File Table Structure..." NOWAIT
		ALTER TABLE cur_fran ADD COLUMN min_roy N(9,2)
		Replace all min_roy with 0.00
		WAIT CLEAR
	ENDIF
	USE
endif

*--> KMC 01/21/2015 - Add column min_roy N(9,2) to rpt_fran table.
if file('rpt_fran.dbf')
	ChkTable('','rpt_fran','MIN_ROY')  
	If !newStructure
		WAIT WINDOW "Updating Franchise Report Current Data File Table Structure..." NOWAIT
		ALTER TABLE rpt_fran ADD COLUMN min_roy N(9,2)
		Replace all min_roy with 0.00
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 03/20/2017
*--> If len(lockbox.dest)<12 increase to 12.
if file('lockbox.dbf')
	use lockbox
	if len(lockbox.dest)<12
		use
		WAIT WINDOW "Updating LockBox Table Structure..." NOWAIT
		ALTER TABLE lockbox ALTER COLUMN dest C(12)
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 12/11/2017
*--> Expand address and rem_addr from 30 to 40 characters.
use cDataLoc+"jkcmpfil" in 0 
sele jkcmpfil
if len(address)<40
	wait window "Updating Company File Address Field..." nowait
	use
	alter table cDataLoc+"jkcmpfil" alter column address C(40)
	alter table cDataLoc+"jkcmpfil" alter column rem_addr C(40)
	use
	wait clear	
else
	use
endif	
*-->

*--> KMC 12/22/2017 - Add column to store Franchisee's bank info and ACH status.
if file('jkdlrfil.dbf')
	ChkTable('','jkdlrfil','ROUTINGNUM')  
	If !newStructure
		WAIT WINDOW "Updating Franchise Data File Table Structure..." NOWAIT
		ALTER TABLE jkdlrfil ADD COLUMN routingnum C(9)
		ALTER TABLE jkdlrfil ADD COLUMN accountnum C(17)
		ALTER TABLE jkdlrfil ADD COLUMN accounttyp C(8)
		ALTER TABLE jkdlrfil ADD COLUMN achactive C(1)
		repla all ACHActive with "N"
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 07/10/2019 - Add column to last_renew date.
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','LAST_RENEW')  
	If !newStructure
		WAIT WINDOW "Updating Customer Data File Table Structure..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN last_renew D
		repla all last_renew with date_start  && Pre-populate last_renew with value of date_start.
		WAIT CLEAR
	ENDIF
	USE
endif
*-->

*--> KMC 02/03/2020
*--> Add field 'leadid' to jkcusfil so that when customer record is created from lead import, system will know the source lead.
if file('jkcusfil.dbf')
	ChkTable('','jkcusfil','LEADID')
	If !newStructure
		WAIT WINDOW "Updating structure of jkcusfil - adding leadid field..." NOWAIT
		ALTER TABLE jkcusfil ADD COLUMN LeadID I
		wait clear
	endif	
	use
endif	
*-->

*--> KMC 02/10/2020
*--> Update tables jkdlrtrx, jkcbfil, jkcbpay and jkregnd to accomodate charging back tech fee.
if file('jkdlrtrx.dbf')
	ChkTable('','jkdlrtrx','TECH_P')
	If !newStructure
		WAIT WINDOW "Updating structure of jkdlrtrx..." NOWAIT
		ALTER TABLE jkdlrtrx ADD COLUMN tech_p N(5,2)
		ALTER TABLE jkdlrtrx ADD COLUMN tech_cb N(9,2)
		wait clear
	endif	
	use
endif	
if file('jkcbfil.dbf')
	ChkTable('','jkcbfil','TECH_P')
	If !newStructure
		WAIT WINDOW "Updating structure of jkcbfil..." NOWAIT
		ALTER TABLE jkcbfil ADD COLUMN tech_p N(5,2)
		ALTER TABLE jkcbfil ADD COLUMN tech_cb N(9,2)
		wait clear
	endif	
	use
endif	
if file('jkcbpay.dbf')
	ChkTable('','jkcbpay','TECH')
	If !newStructure
		WAIT WINDOW "Updating structure of jkcbpay..." NOWAIT
		ALTER TABLE jkcbpay ADD COLUMN tech N(9,2)
		wait clear
	endif	
	use
endif	
if file('jkregnd.dbf')
	ChkTable('','jkregnd','TECH')
	If !newStructure
		WAIT WINDOW "Updating structure of jkregnd..." NOWAIT
		ALTER TABLE jkregnd ADD COLUMN tech N(9,2)
		wait clear
	endif	
	use
endif	
*-->

*--> KMC 09/29/2021
*--> Expand email1 and emal2 from 50 to 60 characters.
use cDataLoc+"jkcusfil" in 0 
sele jkcusfil
if len(email1)<40
	wait window "Expanding email address field..." nowait
	use
	alter table cDataLoc+"jkcusfil" alter column email1 C(60)
	alter table cDataLoc+"jkcusfil" alter column email2 C(60)
	use
	wait clear	
else
	use
endif	
*-->

*--> KMC 09/29/2021
tmpSprd_updated = .f.  && KMC 03/30/2022 - Added as flag to be used to indentify if cur_fran and rpt_fran need bt_sale1 columns expanded.
use cDataLoc+"tmpsprd" in 0 
sele tmpsprd
thisFranIntVal = tmpsprd.t_contract
tstValue = 123456789.12
repla tmpsprd.t_contract with tstValue
if tmpsprd.t_contract = tstValue
	repla tmpsprd.t_contract with thisFranIntVal
	sele tmpsprd
	use
else
	tmpSprd_updated = .t.  && KMC 03/30/2022
	repla tmpsprd.t_contract with thisFranIntVal
	*--> KMC 05/06/2021
	*copy to cDataLoc + "_bu_tmpsprd_" + strtran(dtoc(date()),"/","_")
	copy to cDataLoc + "_bu_tmpsprd_" + strtran(dtoc(date()),"/","") + "." + strtran(time(),":","")
	*-->
	use	
	wait window "Updating tmpsprd structure..." nowait
	alter table cDataLoc + "tmpsprd" alter column t_contract 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_revenue 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_supplies 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_bus_prot 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_bond	 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_lease 		N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_lease_tx	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_royalty 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_find_fee 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_supp_tax 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_misc 		N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_e_work 		N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_1_in 		N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_1_in_com 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_dlr_sup 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_admin 		N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_chrg_bk 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_advance 	N(10,2)
	alter table cDataLoc + "tmpsprd" alter column t_inv_ttl 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_deduct 		N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_ttl_ded 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_due_dlr 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_frm_dlr 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_misc_ro 	N(12,2)
	alter table cDataLoc + "tmpsprd" alter column t_acctreb 	N(10,2)
	use

	use cDataLoc + "cur_cat" in 0
	sele cur_cat
	*--> KMC 05/06/2021
	*copy to cDataLoc + "_bu_cur_cat_" + strtran(dtoc(date()),"/","_")
	copy to cDataLoc + "_bu_cur_cat_" + strtran(dtoc(date()),"/","") + "." + strtran(time(),":","")
	*-->
	use

	wait window "Updating cur_cat structure..." nowait
	alter table cDataLoc + "cur_cat" alter column cont_bill 	N(12,2)
	alter table cDataLoc + "cur_cat" alter column cur_month 	N(12,2)
	alter table cDataLoc + "cur_cat" alter column adtl_b_frn 	N(12,2)
	alter table cDataLoc + "cur_cat" alter column client_sup 	N(12,2)
	alter table cDataLoc + "cur_cat" alter column adtl_b_ofc 	N(12,2)
	use
		
	use cDataLoc + "rpt_cat" in 0
	sele rpt_cat
	*--> KMC 05/06/2021
	*copy to cDataLoc + "_bu_rpt_cat_" + strtran(dtoc(date()),"/","_")
	copy to cDataLoc + "_bu_rpt_cat_" + strtran(dtoc(date()),"/","") + "." + strtran(time(),":","")
	*-->
	use
	
	wait window "Updating rpt_cat structure..." nowait
	alter table cDataLoc + "rpt_cat" alter column cont_bill 	N(12,2)
	alter table cDataLoc + "rpt_cat" alter column cur_month 	N(12,2)
	alter table cDataLoc + "rpt_cat" alter column adtl_b_frn 	N(12,2)
	alter table cDataLoc + "rpt_cat" alter column client_sup 	N(12,2)
	alter table cDataLoc + "rpt_cat" alter column adtl_b_ofc 	N(12,2)
	use
	wait clear
endif
*-->

*--> KMC 09/29/2021
*--> Expand numeric fields (bt_sales1 thru bt_sales4) in jkcmpfil from N(6,0) to N(8,0)
*--> Expand numeric fields (bt_sale1 and bt_sale2) in jkcmpfil from N(6,0) to N(8,0)

*--> KMC 02/23/2022
*--> Test to see if table structure needs updated.

*--> KMC 03/30/2022 - use tmpSprd_udpated flag now.
*use cur_fran in 0
*sele cur_fran
*curBPSaleAmt = cur_fran.bt_sale2
*repla bt_sale2 with 12345678
*if cur_fran.bt_sale2 <> 12345678
*	sele cur_fran
*	repla bt_sale2 with curBPSaleAmt
*	use
*-->
if tmpSprd_updated && KMC 03/30/2022
	wait window "Expanding BPP/Bond fields..." nowait
	alter table cDataLoc+"jkcmpfil" alter column bt_sales1 N(8,0)
	alter table cDataLoc+"jkcmpfil" alter column bt_sales2 N(8,0)
	alter table cDataLoc+"jkcmpfil" alter column bt_sales3 N(8,0)
	alter table cDataLoc+"jkcmpfil" alter column bt_sales4 N(8,0)
	use
	alter table cDataLoc+"cur_fran" alter column bt_sale1 N(8,0)
	alter table cDataLoc+"cur_fran" alter column bt_sale2 N(8,0)  && KMC 10-15-2021
	use
	alter table cDataLoc+"rpt_fran" alter column bt_sale1 N(8,0)	
	alter table cDataLoc+"rpt_fran" alter column bt_sale2 N(8,0)  && KMC 10-15-2021 	
	use
	wait clear	
*-->
*--> KMC 03/30/2022 - No longer needed.
*else
*	sele cur_fran
*	repla bt_sale2 with curBPSaleAmt
*	use
*-->
endif

*--> KMC 02/23/2022
*--> Expand jkcusfil.email1 and email2 from C(50) to C(75).
use cDataLoc + "jkcusfil" in 0
if len(jkcusfil.email1)<75
	sele jkcusfil
	use
	wait window "Expanding Customer email fields to 75 characters..." nowait
	alter table cDataLoc+"jkcusfil" alter column email1 C(75)
	alter table cDataLoc+"jkcusfil" alter column email2 C(75)
	wait clear
	use
else
	sele jkcusfil
	use
endif
*-->

use cDataLoc+"curRevision" in 0
sele curRevision
repla version with curVersion
use
Clos data all

*--> KMC 02/23/2005
*--> Parameters are:
*--> xPath - Additional Path info (if needed) to table to be updated.
*--> xTable - Table whose structure is being checked.
*--> xField - Field name being tested for.
FUNC ChkTable
	PARAMETERS xPath, xTable, xField
	newStructure=.F.
	xFullPath=xPath+xTable
	USE &xFullPath IN 0
	SELE &xTable
	x=FCOUNT(xTable)
	FOR num=1 TO x
		thisfield=FIELD(num,xTable)
		IF ALLTRIM(thisfield)=xField
			newStructure=.T.
		ENDIF
	ENDFOR
	USE
	return newStructure
ENDFUNC