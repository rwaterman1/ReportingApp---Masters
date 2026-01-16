Function Set_oConn
	for xFldCnt=1 to FCOUNT()
		curField=FIELD(xFldCnt)
		if curField = 'TRAVERSE_S' 
			if len(alltrim(traverse_s))>0
				*--> Set Connection String for Traverse
				xServer=alltrim(traverse_s)
				curRegion=alltrim(traverse_d)
				SQLUsr=alltrim(traverse_p)

				*-> KMC 10/20/2005
				*oConn=sqlStringConnect("Driver={SQL Server};Server="+xServer+";UID=sa;PWD=jani!king;Database="+curRegion)
				oConn=sqlStringConnect("Driver={SQL Server};Server="+xServer+";"+SQLUsr+";Database="+curRegion)
				*-->
				
				oConn_ADO = CREATEOBJECT("adodb.connection")

				*--> KMC 10/25/2005
				*oConn_ADO.open("Driver={SQL Server};Server="+xServer+";UID=sa;PWD=jani!king;Database="+curRegion)
				oConn_ADO.open("Driver={SQL Server};Server="+xServer+";"+SQLUsr+";Database="+curRegion)
				*-->
				
			endif			
			exit
		endif
	endfor	
return

Function Set_BatchID
	sql="select * from tblAPBatch where batchId='Import'"
	x=SQLEXEC(oConn, sql) 
	sele SQLResult
	go top
	if EOF()
		sql="insert into tblAPBatch (batchID, [Desc], lock, hold, RptStat1, RptStat2, RptStat3, RptStat4)"
		sql=sql+" values ('Import','Imported Afflink Transactions',0,0,1,0,0,0)"

		*--> Store SQL Statement for testing purposes
		sele tmpSqlStr
		append blank
		repla xSqlStr with sql

		x=SQLEXEC(oConn, sql) 
		if x=-1
			wait window "SQL Connection error - Adding tblAPBatch record" 
			sele tmpSqlStr
			modi memo xSqlStr
		endif
	endif
return 

Function Get_TransID
	Parameters FunctionID, isInt, TransID
	oCmd = CREATEOBJECT("adodb.command")
	oCmd.activeconnection=oConn_ADO
	oCmd.commandtext = "trvsp_NextTransId"
	oCmd.commandtype = 4
	oCmd.parameters.refresh
	oCmd.parameters(1).value=FunctionID
	oCmd.parameters(2).value=isInt
	oCmd.parameters(3).value=TransID
Return

Procedure CleanUp
	if oConn<>0
		sqldisconnect(oConn)
		release oConn
		oConn_ADO.Close
	endif
	set procedure to 	
return