use AdventureWorks2014


create database AdwentureDWSeminarski
go

use AdwentureDWSeminarski
go

create table DIM_SalesTerritory
(
	SalesTerritoryKey int not null identity(1,1),
	SalesTerritoryId int not null,
	TerritoryName nvarchar(50) not null,
	CountryRegionCode nvarchar(3) not null,
	TerritoryGroup nvarchar(50) not null,
	constraint PK_DIMSalesTerritory primary key(SalesTerritoryKey)
)
go

insert into DIM_SalesTerritory
select
	TerritoryID,
	Name,
	CountryRegionCode,
	[Group]
from
	AdventureWorks2014.Sales.SalesTerritory
go



create table DIM_Product
(
	ProductKey int not null identity(1,1),
	ProductId int not null,
	ProductName nvarchar(50) not null,
	Color nvarchar(15) not null,
	ProductSubCategoryName nvarchar(50) not null,
	ProductCategoryName nvarchar(50) not null,
	ProductModelName nvarchar(50) not null,
	constraint PK_DimProduct primary key(ProductKey)

)
go


insert into DIM_Product
select 
	p.ProductID,
	p.Name,
	isnull(p.Color,'N/A'),
	isnull(psc.Name,'N/A'),
	isnull(pc.Name,'N/A'),
	isnull(pm.Name,'N/A')
from
	AdventureWorks2014.Production.Product p left join AdventureWorks2014.Production.ProductSubcategory psc
		on p.ProductSubcategoryID=psc.ProductSubcategoryID
	left join AdventureWorks2014.Production.ProductCategory pc
		on pc.ProductCategoryID=psc.ProductCategoryID
	left join AdventureWorks2014.Production.ProductModel pm
	on p.ProductModelID=pm.ProductModelID
go


select * from DIM_Product
go



create table DIM_Date
(
	DateKey int not null ,
	Date datetime not null,
	Year int not null,
	Quarter int not null,
	Month int not null,
	Day int not null,
	constraint PK_DimDate primary key(DateKey)
)
go


insert into DIM_Date
select distinct
	 (YEAR(OrderDate) * 10000 + MONTH(OrderDate) * 100 + DAY(OrderDate)) DateKey,
	OrderDate,
	YEAR(OrderDate),
	CASE
		when MONTH(OrderDate) <=3 then 1
		when MONTH(OrderDate) >3 and  MONTH(OrderDate)<=6 then 2
		when MONTH(OrderDate) >6 and MONTH(OrderDate)<=9 then 3
		when MONTH(OrderDate) >9 and MONTH(OrderDate)<=12 then 4
	END,
	MONTH(OrderDate),
	DAY(OrderDate)
from AdventureWorks2014.Sales.SalesOrderHeader

select * from DIM_Date




create table FACT_Sales
(
	SalesKey int not null identity(1,1),
	SaleId int not null,
	DimSalesTerritoryKey int not null,
	DimProductKey int not null,
	DimDateKey int not null,
	OrderQty int not null,
	UnitPrice money not null,
	constraint PK_Sales primary key(SalesKey),
	constraint FK_Sales_SalesTerritory foreign key(DimSalesTerritoryKey) references DIM_SalesTerritory(SalesTerritoryKey),
	constraint FK_Sales_Product foreign key(DimProductKey) references DIM_Product(ProductKey),
	constraint FK_Sales_Date foreign key(DimDateKey) references DIM_Date(DateKey)
)
go



insert into FACT_Sales
select
	soh.SalesOrderID,
	dst.SalesTerritoryKey,
	dp.ProductKey,
	dt.DateKey,
	sod.OrderQty,
	sod.UnitPrice
from
	AdventureWorks2014.Sales.SalesOrderHeader soh
		inner join AdventureWorks2014.Sales.SalesOrderDetail
		sod 
	on sod.SalesOrderID=soh.SalesOrderID
	inner join AdventureWorks2014.Sales.SalesTerritory st
	on soh.TerritoryID=st.TerritoryID
	inner join AdventureWorks2014.Production.Product p
	on sod.ProductID=p.ProductID
	 left join AdventureWorks2014.Production.ProductSubcategory psc
	 on p.ProductSubcategoryID=psc.ProductSubcategoryID
	 left join AdventureWorks2014.Production.ProductCategory pc on psc.ProductCategoryID=pc.ProductCategoryID
	 inner join DIM_SalesTerritory dst
	 on st.TerritoryID=dst.SalesTerritoryId
	 inner join DIM_Product dp
		on p.ProductID=dp.ProductId
	 inner join DIM_Date dt
		on soh.OrderDate=dt.Date
order by sod.SalesOrderID
go



create table FACT_SalesFreight
(
	SalesFreightKey int not null identity(1,1),
	SaleId int not null,
	DimSalesTerritoryKey int not null,
	DimDateKey int not null,
	Freight money not null,
	constraint PK_SalesFreight primary key(SalesFreightKey),
	constraint FK_SalesFreight_SalesTerritory foreign key(DimSalesTerritoryKey) references
	DIM_SalesTerritory(SalesTerritoryKey),
	constraint FK_SalesFreight_DimDate foreign key(DimDateKey) references DIM_Date(DateKey)
)
go

insert into FACT_SalesFreight
select distinct
	soh.SalesOrderID,
	dst.SalesTerritoryKey,
	dt.DateKey,
	soh.Freight
from
	AdventureWorks2014.Sales.SalesOrderHeader soh
		inner join AdventureWorks2014.Sales.SalesOrderDetail
		sod 
	on sod.SalesOrderID=soh.SalesOrderID
	inner join AdventureWorks2014.Sales.SalesTerritory st
	on soh.TerritoryID=st.TerritoryID
	 inner join DIM_SalesTerritory dst
	 on st.TerritoryID=dst.SalesTerritoryId
	 inner join DIM_Date dt
		on soh.OrderDate=dt.Date
order by soh.SalesOrderID
go

select * from FACT_SalesFreight
go





