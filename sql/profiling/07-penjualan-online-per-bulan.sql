-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 01, 2026 at 04:35 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.2.12

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `adventureworks`
--

-- --------------------------------------------------------

--
-- Table structure for table `h`
--

CREATE TABLE `h` (
  `SalesOrderID` int(11) NOT NULL COMMENT 'Primary key.',
  `RevisionNumber` tinyint(3) UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Incremental number to track changes to the sales order over time.',
  `OrderDate` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Dates the sales order was created.',
  `DueDate` datetime(6) NOT NULL COMMENT 'Date the order is due to the customer.',
  `ShipDate` datetime(6) DEFAULT NULL COMMENT 'Date the order was shipped to the customer.',
  `Status` tinyint(3) UNSIGNED NOT NULL DEFAULT 1 COMMENT 'Order current status. 1 = In process; 2 = Approved; 3 = Backordered; 4 = Rejected; 5 = Shipped; 6 = Cancelled',
  `OnlineOrderFlag` tinyint(1) NOT NULL DEFAULT 1 COMMENT '0 = Order placed by sales person. 1 = Order placed online by customer.',
  `SalesOrderNumber` varchar(25) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci NOT NULL COMMENT 'Unique sales order identification number.',
  `PurchaseOrderNumber` varchar(50) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Customer purchase order number reference. ',
  `AccountNumber` varchar(30) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Financial accounting number reference.',
  `CustomerID` int(11) NOT NULL COMMENT 'Customer identification number. Foreign key to Customer.BusinessEntityID.',
  `SalesPersonID` int(11) DEFAULT NULL COMMENT 'Sales person who created the sales order. Foreign key to SalesPerson.BusinessEntityID.',
  `TerritoryID` int(11) DEFAULT NULL COMMENT 'Territory in which the sale was made. Foreign key to SalesTerritory.SalesTerritoryID.',
  `BillToAddressID` int(11) NOT NULL COMMENT 'Customer billing address. Foreign key to Address.AddressID.',
  `ShipToAddressID` int(11) NOT NULL COMMENT 'Customer shipping address. Foreign key to Address.AddressID.',
  `ShipMethodID` int(11) NOT NULL COMMENT 'Shipping method. Foreign key to ShipMethod.ShipMethodID.',
  `CreditCardID` int(11) DEFAULT NULL COMMENT 'Credit card identification number. Foreign key to CreditCard.CreditCardID.',
  `CreditCardApprovalCode` varchar(15) DEFAULT NULL COMMENT 'Approval code provided by the credit card company.',
  `CurrencyRateID` int(11) DEFAULT NULL COMMENT 'Currency exchange rate used. Foreign key to CurrencyRate.CurrencyRateID.',
  `SubTotal` decimal(19,4) NOT NULL DEFAULT 0.0000 COMMENT 'Sales subtotal. Computed as SUM(SalesOrderDetail.LineTotal)for the appropriate SalesOrderID.',
  `TaxAmt` decimal(19,4) NOT NULL DEFAULT 0.0000 COMMENT 'Tax amount.',
  `Freight` decimal(19,4) NOT NULL DEFAULT 0.0000 COMMENT 'Shipping cost.',
  `TotalDue` decimal(19,4) NOT NULL COMMENT 'Total due from customer. Computed as Subtotal + TaxAmt + Freight.',
  `Comment` varchar(128) CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci DEFAULT NULL COMMENT 'Sales representative comments.',
  `rowguid` varchar(64) NOT NULL COMMENT 'ROWGUIDCOL number uniquely identifying the record. Used to support a merge replication sample.',
  `ModifiedDate` timestamp NOT NULL DEFAULT current_timestamp() COMMENT 'Date and time the record was last updated.'
) ENGINE=InnoDB DEFAULT CHARSET=latin1 COLLATE=latin1_swedish_ci COMMENT='General sales order information.';

--
-- Dumping data for table `h`
--

INSERT INTO `h` (`bulan`, `jumlah_pesanan`, `unit_terjual`, `nilai_penjualan`) VALUES
('2011-05', 9, 9, 28408.86),
('2011-06', 142, 142, 462870.65),
('2011-07', 155, 155, 502613.42),
('2011-08', 149, 149, 481417.11),
('2011-09', 160, 160, 512273.82),
('2011-10', 176, 176, 566493.68),
('2011-11', 227, 227, 724225.84),
('2011-12', 189, 189, 603407.28),
('2012-01', 195, 195, 621511.20),
('2012-02', 177, 177, 577539.79),
('2012-03', 221, 221, 708208.00),
('2012-04', 208, 208, 660545.81),
('2012-05', 222, 222, 669431.50),
('2012-06', 246, 246, 483411.54),
('2012-07', 273, 273, 530501.23),
('2012-08', 212, 212, 377480.46),
('2012-09', 216, 216, 393529.14),
('2012-10', 219, 219, 379742.76),
('2012-11', 314, 314, 545253.32),
('2012-12', 244, 244, 444478.64),
('2013-01', 301, 301, 537349.17),
('2013-02', 247, 247, 444926.11),
('2013-03', 309, 309, 526284.73),
('2013-04', 324, 324, 545184.70),
('2013-05', 341, 434, 590917.65),
('2013-06', 555, 1486, 842870.38),
('2013-07', 1579, 3827, 869365.10),
('2013-08', 1686, 4080, 1041239.42),
('2013-09', 1617, 3972, 1052943.06),
('2013-10', 1795, 4451, 1309504.97),
('2013-11', 2004, 4985, 1622285.82),
('2013-12', 1878, 4681, 1379042.76),
('2014-01', 1961, 4866, 1537675.33),
('2014-02', 1763, 4294, 1358106.83),
('2014-03', 2124, 5296, 1666091.20),
('2014-04', 2098, 5261, 1805994.88),
('2014-05', 2218, 5583, 1908059.49),
('2014-06', 905, 2047, 47491.55);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `h`
--
ALTER TABLE `h`
  ADD PRIMARY KEY (`SalesOrderID`),
  ADD UNIQUE KEY `rowguid` (`rowguid`),
  ADD UNIQUE KEY `AK_SalesOrderHeader_rowguid` (`rowguid`),
  ADD UNIQUE KEY `AK_SalesOrderHeader_SalesOrderNumber` (`SalesOrderNumber`),
  ADD KEY `IX_SalesOrderHeader_CustomerID` (`CustomerID`),
  ADD KEY `IX_SalesOrderHeader_SalesPersonID` (`SalesPersonID`),
  ADD KEY `FK_SalesOrderHeader_Address_BillToAddressID` (`BillToAddressID`),
  ADD KEY `FK_SalesOrderHeader_Address_ShipToAddressID` (`ShipToAddressID`),
  ADD KEY `FK_SalesOrderHeader_CreditCard_CreditCardID` (`CreditCardID`),
  ADD KEY `FK_SalesOrderHeader_CurrencyRate_CurrencyRateID` (`CurrencyRateID`),
  ADD KEY `FK_SalesOrderHeader_ShipMethod_ShipMethodID` (`ShipMethodID`),
  ADD KEY `FK_SalesOrderHeader_SalesTerritory_TerritoryID` (`TerritoryID`);

--
-- Constraints for dumped tables
--

--
-- Constraints for table `h`
--
ALTER TABLE `h`
  ADD CONSTRAINT `FK_SalesOrderHeader_Address_BillToAddressID` FOREIGN KEY (`BillToAddressID`) REFERENCES `person_address` (`AddressID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_Address_ShipToAddressID` FOREIGN KEY (`ShipToAddressID`) REFERENCES `person_address` (`AddressID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_CreditCard_CreditCardID` FOREIGN KEY (`CreditCardID`) REFERENCES `sales_creditcard` (`CreditCardID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_CurrencyRate_CurrencyRateID` FOREIGN KEY (`CurrencyRateID`) REFERENCES `sales_currencyrate` (`CurrencyRateID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_Customer_CustomerID` FOREIGN KEY (`CustomerID`) REFERENCES `sales_customer` (`CustomerID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_SalesPerson_SalesPersonID` FOREIGN KEY (`SalesPersonID`) REFERENCES `sales_salesperson` (`BusinessEntityID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_SalesTerritory_TerritoryID` FOREIGN KEY (`TerritoryID`) REFERENCES `sales_salesterritory` (`TerritoryID`) ON DELETE NO ACTION ON UPDATE NO ACTION,
  ADD CONSTRAINT `FK_SalesOrderHeader_ShipMethod_ShipMethodID` FOREIGN KEY (`ShipMethodID`) REFERENCES `purchasing_shipmethod` (`ShipMethodID`) ON DELETE NO ACTION ON UPDATE NO ACTION;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
