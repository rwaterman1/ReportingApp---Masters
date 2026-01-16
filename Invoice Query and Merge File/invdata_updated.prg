CLEAR
CLOSE DATA
SET EXCL OFF
SET DELE ON
SET TALK OFF
SET SAFE OFF
SET CENT ON

cDataLoc = "x:\toronto$\"
cDataLoc = "x:\jk_buf\"

mBillMon=6
mBillYr=2007

WAIT WINDOW "Retrieving Records..." NOWAIT

cOrder=" A.cust_no,A.inv_no "

IF "$" $ cDataLoc
	mgst = "b.gst_no AS gst_no"
	mpst = "a.pst_tax AS pst_tax"
ELSE
	mgst = "SPACE(15) AS gst_no"
	mpst = "0 AS pst_tax"
ENDIF

SELE b.dsp_name, b.rem_addr, b.rem_city, b.rem_state, b.rem_zip, b.phone,&mgst, ;
	c.dlr_code, c.dlr_name,;
	d.cust_no,d.cus_name,d.cus_name2,d.cus_addr,d.cus_addr2,d.cus_city,d.cus_state,d.cus_zip,d.po_1,d.slsmn_no,;
	d.bill_name,d.bill_name2,d.bill_addr,d.bill_addr2,d.bill_city,d.bill_state,d.bill_zip, ;
	a.inv_no, ;
	a.DESCR,a.due_date,a.inv_date,a.trx_amt,a.trx_tax,a.trx_class,&mpst,a.trx_type,a.quantity,a.pri_tot,;
	a.desc_var1,a.desc_var2,a.desc_var3,a.desc_var4,a.desc_var5,a.desc_var6,;
	a.pri_tot1,a.pri_tot2,a.pri_tot3,a.pri_tot4,a.pri_tot5,a.pri_tot6,;
	a.pri_var1,a.pri_var2,a.pri_var3,a.pri_var4,a.pri_var5,a.pri_var6,;
	a.qty_var1,a.qty_var2,a.qty_var3,a.qty_var4,a.qty_var5,a.qty_var6,;
	a.inv_msg,a.inv_msg2,a.prntinv,;
	SPACE(15) AS p_due_date, ;
	SPACE(10) AS p_inv_date, ;
	SPACE(14) AS p_phone, ;
	SPACE(35) AS p_for_l1,;
	SPACE(35) AS p_for_l2,;
	SPACE(35) AS p_for_l3,;
	SPACE(35) AS p_for_l4,;
	SPACE(35) AS p_for_l5, ;
	SPACE(3) AS pqty1, ;
	SPACE(3) AS pqty2, ;
	SPACE(3) AS pqty3, ;
	SPACE(3) AS pqty4, ;
	SPACE(3) AS pqty5, ;
	SPACE(3) AS pqty6, ;
	SPACE(3) AS pqty7, ;
	SPACE(3) AS pqty8, ;
	SPACE(50) AS pdes1, ;
	SPACE(50) AS pdes2, ;
	SPACE(50) AS pdes3, ;
	SPACE(50) AS pdes4, ;
	SPACE(50) AS pdes5, ;
	SPACE(50) AS pdes6, ;
	SPACE(50) AS pdes7, ;
	SPACE(50) AS pdes8, ;
	SPACE(10) AS puni1, ;
	SPACE(10) AS puni2, ;
	SPACE(10) AS puni3, ;
	SPACE(10) AS puni4, ;
	SPACE(10) AS puni5, ;
	SPACE(10) AS puni6, ;
	SPACE(10) AS puni7, ;
	SPACE(10) AS puni8, ;
	SPACE(10) AS pext1, ;
	SPACE(10) AS pext2, ;
	SPACE(10) AS pext3, ;
	SPACE(10) AS pext4, ;
	SPACE(10) AS pext5, ;
	SPACE(10) AS pext6, ;
	SPACE(10) AS pext7, ;
	SPACE(10) AS pext8, ;
	SPACE(10) AS pamtofsale, ;
	SPACE(10) AS ptaxhead, ;
	SPACE(10) AS ptax, ;
	SPACE(10) AS ppsthead, ;
	SPACE(10) AS ppsttax, ;
	SPACE(10) AS ptotal ;
	FROM cDataLoc+'jkcustrx' a  ;
	LEFT JOIN cDataLoc+'jkcmpfil' b ON a.company_no = b.company_no ;
	LEFT JOIN cDataLoc+'jkdlrfil' c ON a.dlr_code = c.dlr_code ;
	LEFT JOIN cDataLoc+'jkcusfil' d ON a.cust_no = d.cust_no ;
	WHERE a.trx_class = 'B' AND ;
	a.trx_amt + a.trx_tax > 0 AND ;
	a.bill_mon = mBillMon AND ;
	a.bill_year = mBillYr  ;
	ORDER BY &cOrder ;
	INTO DBF invdata

IF _TALLY = 0
	WAIT CLEAR
	MESSAGEBOX("Nothing to process!",48,"Alert")
	RETURN
ENDIF


* Populate invoice print fields
* So, no formula is required in the Word merge document. (difficult to put formula and print condition in the Word document)
SELE invdata
SCAN
	REPL p_due_date WITH IIF(trx_class<>"B","Upon Receipt",DTOC(due_date))
	REPL p_inv_date WITH DTOC(inv_date)
	REPL p_phone WITH "("+LEFT(STR(phone),3)+") "+SUBSTR(STR(phone),4,3)+"-"+SUBSTR(STR(phone),7,4)
	REPL p_for_l1 WITH IIF(bill_name=cus_name AND ;
		bill_addr=cus_addr AND ;
		bill_addr2=cus_addr2,"Same as Sold To",cus_name)
	REPL p_for_l2 WITH IIF(bill_name=cus_name AND ;
		bill_addr=cus_addr AND ;
		bill_addr2=cus_addr2,"",cus_name2)
	REPL p_for_l3 WITH IIF(bill_name=cus_name AND ;
		bill_addr=cus_addr AND ;
		bill_addr2=cus_addr2,"",cus_addr)
	REPL p_for_l4 WITH IIF(bill_name=cus_name AND ;
		bill_addr=cus_addr AND ;
		bill_addr2=cus_addr2,"",cus_addr2)
	REPL p_for_l5 WITH IIF(bill_name=cus_name AND ;
		bill_addr=cus_addr AND ;
		bill_addr2=cus_addr2,"",ALLTRIM(cus_city)+", "+cus_state+ "  "+cus_zip )

	REPL pqty1 WITH IIF(DESCR="CLIENT SUPPLIES", ALLTRIM(STR(qty_var1)),ALLTRIM(STR(quantity)))
	REPL pdes1 WITH IIF(trx_class="S", desc_var1,DESCR)
	REPL puni1 WITH IIF(trx_class="S",ALLTRIM(STR(pri_var1,8,2)),IIF(trx_type="I",ALLTRIM(STR(trx_amt,8,2)),ALLTRIM(STR(trx_amt*-1,8,2))))
	REPL pext1 WITH IIF(trx_class="S",ALLTRIM(STR(pri_tot1,8,2)),IIF(trx_type="I",ALLTRIM(STR(trx_amt,8,2)),ALLTRIM(STR(trx_amt*-1,8,2))))

	REPL pqty2 WITH IIF(DESCR="CLIENT SUPPLIES",IIF(qty_var2=0 ,"",ALLTRIM(STR(qty_var2))),IIF(qty_var1=0,"",ALLTRIM(STR(qty_var1))))
	REPL pdes2 WITH IIF(trx_class="S",desc_var2,desc_var1)
	REPL puni2 WITH IIF(trx_class="S",IIF(pri_var2=0 ,"",ALLTRIM(STR(pri_var2,8,2))),IIF(pri_var1=0,"",ALLTRIM(STR(pri_var1,8,2))))
	REPL pext2 WITH IIF(trx_class="S",IIF(pri_tot2=0 ,"",ALLTRIM(STR(pri_tot2,8,2))),IIF(pri_tot1=0,"",ALLTRIM(STR(pri_tot1,8,2))))

	REPL pqty3 WITH IIF(DESCR="CLIENT SUPPLIES",IIF(qty_var3=0 ,"",ALLTRIM(STR(qty_var3))),IIF(qty_var2=0,"",ALLTRIM(STR(qty_var2))))
	REPL pdes3 WITH IIF(trx_class="S",desc_var3,desc_var2)
	REPL puni3 WITH IIF(trx_class="S",IIF(pri_var3=0 ,"",ALLTRIM(STR(pri_var3,8,2))),IIF(pri_var2=0,"",ALLTRIM(STR(pri_var2,8,2))))
	REPL pext3 WITH IIF(trx_class="S",IIF(pri_tot3=0 ,"",ALLTRIM(STR(pri_tot3,8,2))),IIF(pri_tot2=0,"",ALLTRIM(STR(pri_tot2,8,2))))

	REPL pqty4 WITH IIF(DESCR="CLIENT SUPPLIES",IIF(qty_var4=0 ,"",ALLTRIM(STR(qty_var4))),IIF(qty_var3=0,"",ALLTRIM(STR(qty_var3))))
	REPL pdes4 WITH IIF(trx_class="S",desc_var4,desc_var3)
	REPL puni4 WITH IIF(trx_class="S",IIF(pri_var4=0 ,"",ALLTRIM(STR(pri_var4,8,2))),IIF(pri_var3=0,"",ALLTRIM(STR(pri_var3,8,2))))
	REPL pext4 WITH IIF(trx_class="S",IIF(pri_tot4=0 ,"",ALLTRIM(STR(pri_tot4,8,2))),IIF(pri_tot3=0,"",ALLTRIM(STR(pri_tot3,8,2))))

	REPL pqty5 WITH IIF(DESCR="CLIENT SUPPLIES",IIF(qty_var5=0 ,"",ALLTRIM(STR(qty_var5))),IIF(qty_var4=0,"",ALLTRIM(STR(qty_var4))))
	REPL pdes5 WITH IIF(trx_class="S",desc_var5,desc_var4)
	REPL puni5 WITH IIF(trx_class="S",IIF(pri_var5=0 ,"",ALLTRIM(STR(pri_var5,8,2))),IIF(pri_var4=0,"",ALLTRIM(STR(pri_var4,8,2))))
	REPL pext5 WITH IIF(trx_class="S",IIF(pri_tot5=0 ,"",ALLTRIM(STR(pri_tot5,8,2))),IIF(pri_tot4=0,"",ALLTRIM(STR(pri_tot4,8,2))))

	REPL pqty6 WITH IIF(DESCR="CLIENT SUPPLIES",IIF(qty_var6=0 ,"",ALLTRIM(STR(qty_var6))),IIF(qty_var5=0,"",ALLTRIM(STR(qty_var5))))
	REPL pdes6 WITH IIF(trx_class="S",desc_var6,desc_var5)
	REPL puni6 WITH IIF(trx_class="S",IIF(pri_var6=0 ,"",ALLTRIM(STR(pri_var6,8,2))),IIF(pri_var5=0,"",ALLTRIM(STR(pri_var5,8,2))))
	REPL pext6 WITH IIF(trx_class="S",IIF(pri_tot6=0 ,"",ALLTRIM(STR(pri_tot6,8,2))),IIF(pri_tot5=0,"",ALLTRIM(STR(pri_tot5,8,2))))

	REPL pqty7 WITH IIF(DESCR="CLIENT SUPPLIES","",IIF(qty_var6=0,"",ALLTRIM(STR(qty_var6,8,2))))
	REPL pdes7 WITH IIF(trx_class="S","",desc_var6)
	REPL puni7 WITH IIF(trx_class="S","",IIF(pri_var6=0,"",ALLTRIM(STR(pri_var6,8,2))))
	REPL pext7 WITH IIF(trx_class="S","",IIF(pri_tot6=0,"",ALLTRIM(STR(pri_tot6,8,2))))

	REPL pqty8 WITH IIF(trx_class="S",ALLTRIM(STR(quantity)),"")
	REPL pdes8 WITH IIF(trx_class="S",DESCR,"")
	REPL puni8 WITH IIF(trx_class="S","TOTAL","")
	REPL pext8 WITH IIF(trx_class="S",ALLTRIM(STR(pri_tot,8,2)),"")

	REPL pamtofsale WITH IIF(trx_type="I",ALLTRIM(STR(trx_amt,8,2)),ALLTRIM(STR(trx_amt*-1,8,2)))

	IF "$" $ cDataLoc
		REPL ptaxhead WITH "GST"
		REPL ptax WITH   IIF(trx_type="I",ALLTRIM(STR(trx_tax,8,2)),ALLTRIM(STR(trx_tax*-1,8,2)))

		REPL ppsthead WITH "PST"
		REPL ppsttax WITH IIF(trx_type="I",ALLTRIM(STR(pst_tax,8,2)),ALLTRIM(STR(pst_tax*-1,8,2)))

		REPL ptotal WITH IIF(trx_type="I",ALLTRIM(STR(trx_amt+trx_tax+pst_tax,8,2)), ;
			ALLTRIM(STR(trx_amt+trx_tax+pst_tax*-1,8,2)))
	ELSE
		REPL ptaxhead WITH "Sales Tax"
		REPL ptax WITH IIF(trx_type="I",ALLTRIM(STR(trx_tax,8,2)),ALLTRIM(STR(trx_tax*-1,8,2)))

		REPL ptotal WITH IIF(trx_type="I",ALLTRIM(STR(trx_amt+trx_tax,8,2)), ;
			ALLTRIM(STR(trx_amt+trx_tax*-1,8,2)))
	ENDIF
ENDSCAN

WAIT CLEAR
BROW

copy to invoice_data type delimited with tab

CLOSE DATA


