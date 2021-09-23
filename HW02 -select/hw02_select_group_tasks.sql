/* Домашнее задание по курсу MS SQL Server Developer в OTUS.
Занятие "02 - Оператор SELECT и простые фильтры, GROUP BY, HAVING".
*/

USE WideWorldImporters

/* 1. Все товары, в названии которых есть "urgent" или название начинается с "Animal".
Вывести: ИД товара (StockItemID), наименование товара (StockItemName).
Таблицы: Warehouse.StockItems.*/

TODO: 
SELECT StockItemID
      ,StockItemName     
  FROM Warehouse.StockItems as w
  WHERE StockItemName LIKE '%urgent%' 
	 or StockItemName LIKE 'Animal%';

/* 2. Поставщиков (Suppliers), у которых не было сделано ни одного заказа (PurchaseOrders).
Сделать через JOIN, с подзапросом задание принято не будет.
Вывести: ИД поставщика (SupplierID), наименование поставщика (SupplierName).
Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders.
По каким колонкам делать JOIN подумайте самостоятельно.*/

TODO: 
/*select s.SupplierID from Purchasing.Suppliers as s
except select po.SupplierID from Purchasing.PurchaseOrders as po*/

select distinct s.SupplierID, s.SupplierName
from Purchasing.Suppliers as s
left join Purchasing.PurchaseOrders as po on po.SupplierID = s.SupplierID
where po.SupplierID is null
order by s.SupplierID;


/*3. Заказы (Orders) с ценой товара (UnitPrice) более 100$ 
либо количеством единиц (Quantity) товара более 20 штук
и присутствующей датой комплектации всего заказа (PickingCompletedWhen).
Вывести:
* OrderID
* дату заказа (OrderDate) в формате ДД.ММ.ГГГГ
* название месяца, в котором был сделан заказ
* номер квартала, в котором был сделан заказ
* треть года, к которой относится дата заказа (каждая треть по 4 месяца)
* имя заказчика (Customer)
Добавьте вариант этого запроса с постраничной выборкой,
пропустив первую 1000 и отобразив следующие 100 записей.

Сортировка должна быть по номеру квартала, трети года, дате заказа (везде по возрастанию).

Таблицы: Sales.Orders, Sales.OrderLines, Sales.Customers.
*/

TODO: 
SELECT --ROW_NUMBER() OVER(ORDER BY o.[OrderID]) AS RoNum 
	  o.[OrderID]	  
	  ,format(o.[OrderDate],'dd.MM.yyyy') as OrderDat
	  ,case
		when month(o.[OrderDate])=1 then 'YAN'
		when month(o.[OrderDate])=2 then 'FEB'
		when month(o.[OrderDate])=3 then 'MAR'
		when month(o.[OrderDate])=4 then 'APR'
		when month(o.[OrderDate])=5 then 'MAY'
		when month(o.[OrderDate])=6 then 'JUN'
		when month(o.[OrderDate])=7 then 'JUL'
		when month(o.[OrderDate])=8 then 'AUG'
		when month(o.[OrderDate])=9 then 'SEP'
		when month(o.[OrderDate])=10 then 'OCT'
		when month(o.[OrderDate])=11 then 'NOV'
		when month(o.[OrderDate])=12 then 'DEC'
	   end as OrderMonth
	  ,DATEPART(quarter,o.[OrderDate]) as OrderQuarter
	  ,case
        when month(o.[OrderDate]) BETWEEN 1 AND 4  then 'I'
        when month(o.[OrderDate]) BETWEEN 5 AND 8  then 'II'
        when month(o.[OrderDate]) BETWEEN 9 AND 12 then 'III'
	   end as OrderThird
     -- ,o.[CustomerID] 
	  ,c.[CustomerName]
	 -- ,ol.UnitPrice
	 -- ,ol.quantity
	  ,ol.PickingCompletedWhen	
    
  FROM Sales.Orders as o
  left join  Sales.OrderLines as ol on ol.OrderID= o.OrderID
  left join Sales.Customers as c on c.CustomerID = o.CustomerID
  WHERE (ol.UnitPrice > 100 or ol.quantity > 20) and 
  ol.PickingCompletedWhen is not null    
  ORDER BY OrderQuarter, OrderThird, OrderDat;

----

--DECLARE 
--@pagesize BIGINT = 1000, @pagerow BIGINT = 100;

SELECT o.[OrderID]	  
	  ,format(o.[OrderDate],'dd.MM.yyyy') as OrderDat
	  ,case
		when month(o.[OrderDate])=1 then 'YAN'
		when month(o.[OrderDate])=2 then 'FEB'
		when month(o.[OrderDate])=3 then 'MAR'
		when month(o.[OrderDate])=4 then 'APR'
		when month(o.[OrderDate])=5 then 'MAY'
		when month(o.[OrderDate])=6 then 'JUN'
		when month(o.[OrderDate])=7 then 'JUL'
		when month(o.[OrderDate])=8 then 'AUG'
		when month(o.[OrderDate])=9 then 'SEP'
		when month(o.[OrderDate])=10 then 'OCT'
		when month(o.[OrderDate])=11 then 'NOV'
		when month(o.[OrderDate])=12 then 'DEC'
	   end as OrderMonth
	  ,DATEPART(quarter,o.[OrderDate]) as OrderQuarter
	  ,case
        when month(o.[OrderDate]) BETWEEN 1 AND 4  then 'I'
        when month(o.[OrderDate]) BETWEEN 5 AND 8  then 'II'
        when month(o.[OrderDate]) BETWEEN 9 AND 12 then 'III'
	   end as OrderThird 
	  ,c.[CustomerName]
	  ,ol.PickingCompletedWhen	
    
  FROM Sales.Orders as o
	  left join  Sales.OrderLines as ol on ol.OrderID= o.OrderID
	  left join Sales.Customers as c on c.CustomerID = o.CustomerID
 
  WHERE (ol.UnitPrice > 100 or ol.quantity > 20) 
		and ol.PickingCompletedWhen is not null    
  ORDER BY OrderQuarter, OrderThird, OrderDat asc 
  OFFSET 1000 ROWS Fetch FIRST 100 Rows Only;

/*4. Заказы поставщикам (Purchasing.Suppliers),
которые должны быть исполнены (ExpectedDeliveryDate) в январе 2013 года
с доставкой "Air Freight" или "Refrigerated Air Freight" (DeliveryMethodName)
и которые исполнены (IsOrderFinalized).
Вывести:
* способ доставки (DeliveryMethodName)
* дата доставки (ExpectedDeliveryDate)
* имя поставщика
* имя контактного лица принимавшего заказ (ContactPerson)

Таблицы: Purchasing.Suppliers, Purchasing.PurchaseOrders, Application.DeliveryMethods, Application.People.
*/

TODO: 
select  dm.DeliveryMethodName
		,po.ExpectedDeliveryDate
		,s.SupplierName
		,p.FullName as ContactPerson

from Purchasing.PurchaseOrders as po 
	left join Application.DeliveryMethods as dm on dm.DeliveryMethodID = po.DeliveryMethodID 
	left join Purchasing.Suppliers as s on s.SupplierID = po.SupplierID
	left join Application.People as p on p.PersonID = po.ContactPersonID 

where po.ExpectedDeliveryDate between '2013-01-01' and '2013-01-31'
	  and dm.DeliveryMethodName in ('Air Freight','Refrigerated Air Freight')
	  and po.IsOrderFinalized is not null;

/* 5. Десять последних продаж (по дате продажи) с именем клиента и именем сотрудника,
который оформил заказ (SalespersonPerson).
Сделать без подзапросов. */

TODO: 
SELECT TOP 10 o.OrderID  
      ,o.OrderDate  
	  ,c.CustomerName 
	  ,p.FullName as SalespersonPerson
  FROM Sales.Orders as o
  left join Application.People as p on p.PersonID = o.SalespersonPersonID
  left join Sales.Customers as c on c.CustomerID = o.CustomerID
  order by o.OrderDate desc

/* 6. Все ид и имена клиентов и их контактные телефоны,
которые покупали товар "Chocolate frogs 250g".
Имя товара смотреть в таблице Warehouse.StockItems.*/

TODO: 
SELECT distinct c.CustomerID
      ,c.CustomerName    
      ,c.PhoneNumber
      ,c.FaxNumber         
    
  FROM Sales.Customers c 
	  left join Sales.Orders o on o.CustomerID = c.CustomerID
	  left join Sales.OrderLines ol on ol.OrderID = o.OrderID
	  left join Warehouse.StockItems si on si.StockItemID = ol.StockItemID
 where si.StockItemName = 'Chocolate frogs 250g';

/* 7. Посчитать среднюю цену товара, общую сумму продажи по месяцам
Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Средняя цена за месяц по всем товарам
* Общая сумма продаж за месяц

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.*/

TODO: 
SELECT year(i.InvoiceDate) as InvoiceYear
	  ,month(i.InvoiceDate) as InvoiceMonth
      ,avg(ct.TransactionAmount) TransactionAmount_avg
	  ,sum(ct.TransactionAmount) TransactionAmount_sum
  FROM Sales.Invoices i
  left join Sales.CustomerTransactions ct on ct.InvoiceID = i.InvoiceID 

  group by year(i.InvoiceDate)
		  ,month(i.InvoiceDate)

  order  by year(i.InvoiceDate)
			,month(i.InvoiceDate);

/* 8. Отобразить все месяцы, где общая сумма продаж превысила 10 000

Вывести:
* Год продажи (например, 2015)
* Месяц продажи (например, 4)
* Общая сумма продаж

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.*/

TODO: 
SELECT year(i.InvoiceDate) InvoiceYear
	  ,month(i.InvoiceDate) InvoiceMonth      
	  ,sum(ct.TransactionAmount) TransactionAmountSum
  FROM Sales.Invoices i 
  left join Sales.CustomerTransactions ct on ct.InvoiceID = i.InvoiceID 
  group by year(i.InvoiceDate), month(i.InvoiceDate)
  having sum(ct.TransactionAmount) > 10000;

/* 9. Вывести сумму продаж, дату первой продажи
и количество проданного по месяцам, по товарам,
продажи которых менее 50 ед в месяц.
Группировка должна быть по году,  месяцу, товару.

Вывести:
* Год продажи
* Месяц продажи
* Наименование товара
* Сумма продаж
* Дата первой продажи
* Количество проданного

Продажи смотреть в таблице Sales.Invoices и связанных таблицах.*/

TODO:
SELECT year(i.InvoiceDate) InvoiceYear
	  ,month(i.InvoiceDate) InvoiceMonth
	  ,il.StockItemID Item --si.StockItemName
	  ,sum(ct.TransactionAmount) TransactionAmountSum
	  ,min(i.InvoiceDate) InvoiceFirst     
	  ,sum(il.Quantity) ItemQuantity
	  
  FROM Sales.Invoices i 
  left join Sales.CustomerTransactions ct on ct.InvoiceID = i.InvoiceID 
  left join Sales.InvoiceLines il on il.InvoiceID = i.InvoiceID
  --left join Warehouse.StockItems si on si.StockItemID = il.StockItemID
  group by year(i.InvoiceDate), month(i.InvoiceDate), il.StockItemID
  having sum(il.Quantity) < 50
  order by year(i.InvoiceDate), month(i.InvoiceDate), il.StockItemID;
