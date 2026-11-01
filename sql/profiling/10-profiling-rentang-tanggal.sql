-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1
-- Generation Time: Nov 01, 2026 at 04:33 PM
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
-- Table structure for table `sales_salesorderheader`
--

CREATE TABLE `sales_salesorderheader` (
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
-- Dumping data for table `sales_salesorderheader`
--

INSERT INTO `sales_salesorderheader` (`total_pesanan_online`, `tanggal_awal`, `tanggal_akhir`, `jumlah_tahun`) VALUES
(27659, '2011-05-30 18:30:00', '2014-06-29 18:30:00', 4);

--
-- Indexes for dumped tables
--

--
-- Indexes for table `sales_salesorderheader`
--
ALTER TABLE `sales_salesorderheader`
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
-- Constraints for table `sales_salesorderheader`
--
ALTER TABLE `sales_salesorderheader`
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
