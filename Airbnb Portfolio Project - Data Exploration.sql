--Airbnb SQL Data Exploration

--Correct data type for the ID column:

Alter Table [dbo].[Airbnb_Open_Data - Copy]
Alter Column id INT 


--Change empty cells in "host identity verified" to Unconfirmed:

SELECT [host_identity_verified], 
	CASE WHEN [host_identity_verified]='unconfirmed' THEN 'Unconfirmed'
	 WHEN [host_identity_verified]='verified' THEN 'Verified'
	ELSE 'Unconfirmed'
	END
FROM [dbo].[Airbnb_Open_Data - Copy]

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET [host_identity_verified] = CASE WHEN [host_identity_verified]='unconfirmed' THEN 'Unconfirmed'
	 WHEN [host_identity_verified]='verified' THEN 'Verified'
	ELSE 'Unconfirmed'
	END

--Removing empty rows under "neighbourhood group" column:

SELECT [neighbourhood group] AS Empty
FROM [dbo].[Airbnb_Open_Data - Copy]
WHERE [neighbourhood group] = ''

DELETE FROM [dbo].[Airbnb_Open_Data - Copy]
WHERE [neighbourhood group] = ''


--Correcting data entry in "neighbourhood group" column, changing "brookln" to "Brooklyn" and "manhatan" to "Manhattan":

SELECT [neighbourhood group],
	CASE WHEN [neighbourhood group]='brookln' THEN 'Brooklyn'
	WHEN [neighbourhood group]='manhatan' THEN 'Manhattan'
	ELSE [neighbourhood group]
	END
FROM [dbo].[Airbnb_Open_Data - Copy]

 
UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET [neighbourhood group]=CASE WHEN [neighbourhood group]='brookln' THEN 'Brooklyn'
	WHEN [neighbourhood group]='manhatan' THEN 'Manhattan'
	ELSE [neighbourhood group]
	END

--Rechecking table:

SELECT *
FROM [dbo].[Airbnb_Open_Data - Copy]


--Removing empty cells under "instant bookable" column:

SELECT instant_bookable, COUNT(instant_bookable)
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY instant_bookable

DELETE FROM [dbo].[Airbnb_Open_Data - Copy]
WHERE instant_bookable = ''


--Removing empty cells under "construction year" column:

SELECT [Construction year], COUNT([construction year]) AS Num_of_Constructionsperyear
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY [Construction Year]
ORDER BY 2 DESC

DELETE FROM [dbo].[Airbnb_Open_Data - Copy]
WHERE [Construction Year]=''


--Correcting data entry in columns "price" and "service fee" by removing the dollar sign:

SELECT REPLACE(price,'$','')
FROM [dbo].[Airbnb_Open_Data - Copy]

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET price=REPLACE(price,'$','')

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET [service fee]=REPLACE([service fee],'$','')


 
--Removing empty cells under "price" column:

SELECT price, COUNT(price)
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY price
HAVING price=''

DELETE FROM [dbo].[Airbnb_Open_Data - Copy]
WHERE price=''


--Correcting empty cells under "service fee" column by changing empty cells to "no service fee":

SELECT [service fee],
	CASE WHEN [service fee]='' THEN 'No Service Fee'
	ELSE [service fee]
	END
FROM [dbo].[Airbnb_Open_Data - Copy]

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET [service fee] = CASE WHEN [service fee]='' THEN 'No Service Fee'
	ELSE [service fee]
	END


--Changed data type of column host listings count from varchar to INT:

ALTER TABLE [dbo].[Airbnb_Open_Data - Copy]
ADD hostlistingcount INT;

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET hostlistingcount=CONVERT(INT,[calculated host listings count])

SELECT [neighbourhood group], SUM(hostlistingcount)
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY [neighbourhood group]


--Calculated total number of listings for each neighbourhood and neighbourhood group :


SELECT [neighbourhood group],[neighbourhood], SUM(hostlistingcount)
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY [neighbourhood group],[neighbourhood]
ORDER BY 3 DESC


SELECT *
FROM [dbo].[Airbnb_Open_Data - Copy]



----Changed data type of column host listings count from varchar to INT:

ALTER TABLE [dbo].[Airbnb_Open_Data - Copy]
ADD numofreviews INT;

UPDATE [dbo].[Airbnb_Open_Data - Copy]
SET numofreviews=CONVERT(INT,[number of reviews])


--Calculated total number of listings for each neighbourhood and neighbourhood group :

SELECT [neighbourhood group],[neighbourhood],SUM([numofreviews]) TotalReviews
FROM [dbo].[Airbnb_Open_Data - Copy]
GROUP BY [neighbourhood group],[neighbourhood]
ORDER BY 3 DESC


--Removing irrelevant columns not needed in my visualization:

ALTER TABLE [dbo].[Airbnb_Open_Data - Copy]
DROP COLUMN [host name],[minimum nights],[calculated host listings count],[number of reviews]

ALTER TABLE [dbo].[Airbnb_Open_data - Copy]
DROP COLUMN [last review],[availability 365]



--Removing duplicate rows:

WITH RownumCTE AS(
  SELECT *, 
	ROW_NUMBER() OVER(
	PARTITION BY name,
				[host id],
				[neighbourhood group],
				neighbourhood,
				[room type],
				[Construction year],
				price
	ORDER BY 
			id
			) rownumber
FROM [dbo].[Airbnb_Open_Data - Copy]
)

DELETE
FROM RownumCTE
WHERE rownumber>1

SELECT *
FROM [dbo].[Airbnb_Open_Data - Copy]


