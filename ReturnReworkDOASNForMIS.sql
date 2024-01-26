DECLARE @TransDateTime VARCHAR(14)=dbo.FormatDate(getdate(),'YYYYMMDDHHNNSS')
DECLARE @TransDateTime_1 VARCHAR(14)=dbo.FormatDate(DATEADD(MINUTE,-40,GETDATE()),'YYYYMMDDHHNNSS')
SELECT @TransDateTime,@TransDateTime_1

 
CREATE TABLE #ReworkSN (SN VARCHAR (50), WO varchar(50))

INSERT INTO #ReworkSN
SELECT A.SerialNumber, A.WorkOrder FROM vwSMT_REWORK AS A with(nolock) inner join vwRework_WO AS B with(nolock) ON A.WorkOrder = B.WO
WHERE  /*B.ClosedFlag = 'N' AND*/ B.Reason LIKE '%DOA%' AND A.TransDateTime BETWEEN @TransDateTime_1 AND @TransDateTime
Group by A.SerialNumber, A.WorkOrder

--DELETE FROM #ReworkSN WHERE LEN(SN)<>10
IF EXISTS (SELECT TOP 1 1 FROM #ReworkSN)
BEGIN
	IF EXISTS (SELECT TOP 1 1 FROM [10.96.22.43].QMB_OneGDS.DBO.SSNL_Temp A with(nolock),#ReworkSN B with(nolock) WHERE A.SERNUM collate DATABASE_DEFAULT =B.SN AND A.SNTYPE='R')
	BEGIN
		DELETE B FROM  [10.96.22.43].QMB_OneGDS.DBO.SSNL_Temp A,#ReworkSN B WHERE A.SERNUM collate DATABASE_DEFAULT =B.SN AND A.SNTYPE='R' 
	END
	IF EXISTS (SELECT TOP 1 1 FROM #ReworkSN)
	BEGIN
	     INSERT INTO [10.96.22.43].QMB_OneGDS.DBO.SSNL_Temp (SOLDTO,SERNUM,SNTYPE,TRNTIM)
		 --SELECT 'SEL',SN,'R',GETDATE () FROM #ReworkSN	
		 Select C.Customer, A.SN, 'R', GETDATE()
		 From #ReworkSN AS A with(nolock) inner join vwSAP_WO_LIST AS B with(nolock) ON A.WO = B.WO inner join modelName AS C with(nolock) ON B.ModelName = C.ModelName
	     
	     insert into QMS_LOG(System_Name,Event_No,SN,[User_Name],Desc1,Trans_Date)
	     SELECT 'ReworkSNForMIS','1',SN,'ReturnReworkSNForMIS',SN,GETDATE() FROM #ReworkSN
	END
END
DROP TABLE #ReworkSN