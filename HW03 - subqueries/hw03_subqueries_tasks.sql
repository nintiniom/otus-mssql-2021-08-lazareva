/* Домашнее задание 03 - Подзапросы, CTE, временные таблицы".
Задания выполняются с использованием базы данных WideWorldImporters.
Описание WideWorldImporters от Microsoft:
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-what-is
* https://docs.microsoft.com/ru-ru/sql/samples/wide-world-importers-oltp-database-catalog
*/
-- ---------------------------------------------------------------------------
-- Задание - написать выборки для получения указанных ниже данных.
-- Для всех заданий, где возможно, сделайте два варианта запросов:
--  1) через вложенный запрос
--  2) через WITH (для производных таблиц)
-- ---------------------------------------------------------------------------

USE WideWorldImporters

/* 1. Выберите сотрудников (Application.People), которые являются продажниками (IsSalesPerson), 
и не сделали ни одной продажи 04 июля 2015 года. 
Вывести ИД сотрудника и его полное имя. 
Продажи смотреть в таблице Sales.Invoices.*/

TODO: 
SELECT PersonID
      ,FullName      
      --,IsSalesperson 
  FROM [Application].People
  WHERE IsSalesperson = 1 
  and PersonID not in (select SalespersonPersonID from Sales.Invoices where InvoiceDate = '2015-07-04')
  ORDER BY PersonID;
--------------------
SELECT PersonID
      ,FullName        
  FROM [Application].People
  WHERE IsSalesperson = 1 
  and NOT EXISTS (select SalespersonPersonID from Sales.Invoices 
			    	where SalespersonPersonID = People.PersonID and InvoiceDate = '2015-07-04')
  ORDER BY PersonID;
--------------------
/*WITH CTE AS
(select SalespersonPersonID, count(InvoiceID) as k
 from Sales.Invoices where InvoiceDate = '20150704'
 group by SalespersonPersonID) 
SELECT PersonID
      ,FullName       
  FROM [Application].People
  join CTE on CTE.SalespersonPersonID = People.PersonID
  WHERE IsSalesperson = 1 and CTE.k<>0
  ORDER BY PersonID;*/
 go ----

/* 2. Выберите товары с минимальной ценой (подзапросом). Сделайте два варианта подзапроса. 
Вывести: ИД товара, наименование товара, цена.*/

TODO: 
with cte as
(SELECT StockItemID, StockItemName, min(UnitPrice) as MinPrice
	FROM Warehouse.StockItems
	group by StockItemID, StockItemName) 
	select *
	  FROM cte;

with cte as
(SELECT StockItemID, StockItemName, min(UnitPrice) as MinPrice
	FROM Warehouse.StockItems
	group by StockItemID,StockItemName) 
	select  s.StockItemID, s.StockItemName, cte.MinPrice
	  FROM Warehouse.StockItems s 
	  left join cte on cte.StockItemID=s.StockItemID;


/* 3. Выберите информацию по клиентам, которые перевели компании пять максимальных платежей 
из Sales.CustomerTransactions. 
Представьте несколько способов (в том числе с CTE). */

TODO: 
SELECT CustomerID
      ,CustomerName           
  FROM Sales.Customers
  where CustomerID in (select top 5 CustomerID from Sales.CustomerTransactions	
					   order by TransactionAmount desc);

with cte as
(select top 5 CustomerID from Sales.CustomerTransactions	
					   order by TransactionAmount desc)
select distinct c.CustomerID, c.CustomerName         
  FROM Sales.Customers c join cte on cte.CustomerID=c.CustomerID;

/* 4. Выберите города (ид и название), в которые были доставлены товары, 
входящие в тройку самых дорогих товаров, а также имя сотрудника, 
который осуществлял упаковку заказов (PackedByPersonID). */

TODO: 
SELECT --distinct
	   c.CityID
	  ,c.CityName 
	  ,p.FullName  as PackedPersonName 

  FROM [Application].Cities c 
  left join Sales.Customers cs on cs.DeliveryCityID = c.CityID
  left join Sales.Invoices i on i.CustomerID = cs.CustomerID  
  left join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID 
  left join [Application].People p on p.PersonID = i.PackedByPersonID

  where il.StockItemID in (select top 3 si.StockItemID from Warehouse.StockItems si order by UnitPrice desc)
  --order by c.CityID, c.CityName, p.FullName 
  ;

-- ---------------------------------------------------------------------------
-- Опциональное задание
-- ---------------------------------------------------------------------------
-- Можно двигаться как в сторону улучшения читабельности запроса, 
-- так и в сторону упрощения плана\ускорения. 
-- Сравнить производительность запросов можно через SET STATISTICS IO, TIME ON. 
-- Если знакомы с планами запросов, то используйте их (тогда к решению также приложите планы). 
-- Напишите ваши рассуждения по поводу оптимизации. 

-- 5. Объясните, что делает и оптимизируйте запрос
 SET STATISTICS TIME ON;
SELECT 
	Invoices.InvoiceID, 
	Invoices.InvoiceDate,
	(SELECT People.FullName
		FROM Application.People
		WHERE People.PersonID = Invoices.SalespersonPersonID
	) AS SalesPersonName,
	SalesTotals.TotalSumm AS TotalSummByInvoice, 
	(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId 
			FROM Sales.Orders
			WHERE Orders.PickingCompletedWhen IS NOT NULL	
				AND Orders.OrderId = Invoices.OrderId)	
	) AS TotalSummForPickedItems
FROM Sales.Invoices 
	JOIN
	(SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	FROM Sales.InvoiceLines
	GROUP BY InvoiceId
	HAVING SUM(Quantity*UnitPrice) > 27000) AS SalesTotals
		ON Invoices.InvoiceID = SalesTotals.InvoiceID
ORDER BY TotalSumm DESC;
-- --
TODO: 
/* Выбираем информацию по инвойсам, общая сумма по которым больше 27.000 и сумму по строкам завершенного заказа. */
SELECT Invoices.InvoiceID 
	  ,Invoices.InvoiceDate
	  ,People.FullName AS SalesPersonName
	  ,SalesTotals.TotalSumm AS TotalSummByInvoice
	  ,(SELECT SUM(OrderLines.PickedQuantity*OrderLines.UnitPrice)
		FROM Sales.OrderLines
		WHERE OrderLines.OrderId = (SELECT Orders.OrderId FROM Sales.Orders 
									WHERE Orders.PickingCompletedWhen IS NOT NULL	
									AND Orders.OrderId = Invoices.OrderId)	
	   ) AS TotalSummForPickedItems
FROM Sales.Invoices 
	 JOIN (SELECT InvoiceId, SUM(Quantity*UnitPrice) AS TotalSumm
	  	   FROM Sales.InvoiceLines
	  	   GROUP BY InvoiceId
		   HAVING SUM(Quantity*UnitPrice) > 27000
		   ) AS SalesTotals
	 ON Invoices.InvoiceID = SalesTotals.InvoiceID
	 LEFT JOIN [Application].People 
	 ON People.PersonID = Invoices.SalespersonPersonID
ORDER BY TotalSumm DESC;
