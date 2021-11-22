/* Домашнее задание 05 - Операторы CROSS APPLY, PIVOT, UNPIVOT".*/

USE WideWorldImporters

/* 1. Требуется написать запрос, который в результате своего выполнения 
формирует сводку по количеству покупок в разрезе клиентов и месяцев.
В строках должны быть месяцы (дата начала месяца), в столбцах - клиенты.

Клиентов взять с ID 2-6, это все подразделение Tailspin Toys.
Имя клиента нужно поменять так чтобы осталось только уточнение.
Например, исходное значение "Tailspin Toys (Gasport, NY)" - вы выводите только "Gasport, NY".
Дата должна иметь формат dd.mm.yyyy, например, 25.12.2019.

Пример, как должны выглядеть результаты:
-------------+--------------------+--------------------+-------------+--------------+------------
InvoiceMonth | Peeples Valley, AZ | Medicine Lodge, KS | Gasport, NY | Sylvanite, MT | Jessie, ND
-------------+--------------------+--------------------+-------------+--------------+------------
01.01.2013   |      3             |        1           |      4      |      2        |     2
01.02.2013   |      7             |        3           |      4      |      2        |     1
-------------+--------------------+--------------------+-------------+--------------+------------ */

/*;with cte as (
 select	c.CustomerID as CustomerID
		,substring(c.CustomerName, charindex('(',c.CustomerName)+1, (charindex(')',c.CustomerName)-(charindex('(',c.CustomerName)+1) )) as CustName  
 from Sales.Customers c where c.CustomerID in (2,3,4,5,6))

select  *
	from 
	(	select FORMAT(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1),'dd.MM.yyyy') as [InvoiceMonth]
		,cte.CustName as [CustomerName]
		,count(i.InvoiceID) as KOL
		from Sales.Invoices i join cte on cte.CustomerID = i.CustomerID		
		group by FORMAT(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1),'dd.MM.yyyy'), cte.CustName			
	) 	as ST 
PIVOT (sum(KOL) FOR [CustomerName] in ([Peeples Valley, AZ],[Medicine Lodge, KS] ,[Gasport, NY],[Sylvanite, MT],[Jessie, ND])
	  )  as PVTT
order by [InvoiceMonth];*/
----

--не поняла как сделать сортировку нормально...

;with cte as (
 select	c.CustomerID as CustomerID
		,substring(c.CustomerName, charindex('(',c.CustomerName)+1, (charindex(')',c.CustomerName)-(charindex('(',c.CustomerName)+1) )) as CustName  
 from Sales.Customers c where c.CustomerID in (2,3,4,5,6))

select  *
	from 
	(	select CA.CADate as [InvoiceMonth]
		,cte.CustName as [CustomerName]
		,count(i.InvoiceID) as KOL
		from Sales.Invoices i join cte on cte.CustomerID = i.CustomerID	
		cross apply (select FORMAT(DATEFROMPARTS(YEAR(InvoiceDate),MONTH(InvoiceDate),1),'dd.MM.yyyy') as CADate) as CA
		group by CA.CADate, cte.CustName			
	) 	as ST 
PIVOT (sum(KOL) FOR [CustomerName] in ([Peeples Valley, AZ],[Medicine Lodge, KS] ,[Gasport, NY],[Sylvanite, MT],[Jessie, ND])
	  )  as PVTT
order by [InvoiceMonth];

/* 2. Для всех клиентов с именем, в котором есть "Tailspin Toys"
вывести все адреса, которые есть в таблице, в одной колонке.

Пример результата:
----------------------------+--------------------
CustomerName                | AddressLine
----------------------------+--------------------
Tailspin Toys (Head Office) | Shop 38
Tailspin Toys (Head Office) | 1877 Mittal Road
Tailspin Toys (Head Office) | PO Box 8975
Tailspin Toys (Head Office) | Ribeiroville
----------------------------+-------------------- */

select CustomerName, AddressLine from 
	(
		select CustomerName, DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2
		from Sales.Customers 
		where CustomerName like '%Tailspin Toys%'
	) 	as ST 
UNPIVOT 
	(AddressLine FOR Address in (DeliveryAddressLine1, DeliveryAddressLine2, PostalAddressLine1, PostalAddressLine2)
	)  as UPVTT;

/* 3. В таблице стран (Application.Countries) есть поля с цифровым кодом страны и с буквенным.
Сделайте выборку ИД страны, названия и ее кода так, 
чтобы в поле с кодом был либо цифровой либо буквенный код.

Пример результата:
--------------------------------
CountryId | CountryName | Code
----------+-------------+-------
1         | Afghanistan | AFG
1         | Afghanistan | 4
3         | Albania     | ALB
3         | Albania     | 8
----------+-------------+------- */

select CountryId, CountryName, Code
from 
	(select CountryID
			,CountryName --as cname
			,IsoAlpha3Code as IsoAlpha
			,(CAST(IsoNumericCode as nvarchar(3))) as IsoNum			
	from [Application].Countries
	) as ST
UNPIVOT ([Code] for Iso in (IsoAlpha, IsoNum)) as UNPT;

/* 4. Выберите по каждому клиенту два самых дорогих товара, которые он покупал.
В результатах должно быть ид клиета, его название, ид товара, цена, дата покупки. */


  select c.CustomerID, c.CustomerName, ol.* ---ol.StockItemID, ol.UnitPrice, ol.OrderDate
  from Sales.Customers as c
  cross apply (
  select top 2  ol.StockItemID, ol.UnitPrice, o.OrderDate
  from Sales.OrderLines as ol
   left join Sales.Orders as o on ol.OrderID=o.OrderID
   where o.CustomerID=c.CustomerID
   order by ol.UnitPrice desc
  ) as ol
  order by c.CustomerID;