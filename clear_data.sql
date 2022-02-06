-- Loading the data

-- Enable local-infile
-- SET GLOBAL local_infile = 1
-- Then relog
-- mysql --local-infile=1 -u root -p

--QUICKLY MADE TABLE TO IMPORT DATA

CREATE DATABASE houses;

CREATE TABLE houses
(
    UniqueID int,
    ParcelID varchar(30),
    LandUse varchar(30),
    PropertyAddress varchar(50),
    SaleDate date,
    SalePrice int,
    LegalReference varchar(30),
    SoldAsVacant varchar(3),
    OwnerName varchar(40),
    OwnerAddress varchar(50),
    Acreage float,
    TaxDistrict varchar(40),
    LandValue int,
    BuildingValue int,
    TotalValue int,
    YearBuilt int,
    Bedrooms smallint,
    FullBath smallint,
    HalfBath smallint
);

--LOAD DATA (with proper data format)
ALTER TABLE houses
MODIFY COLUMN SaleDate varchar(30);

LOAD DATA LOCAL INFILE '/tmp/Nashville Housing Data for Data Cleaning.csv'
INTO TABLE houses
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '"'
LINES TERMINATED BY '\r\n'
IGNORE 1 ROWS;

UPDATE houses
SET SaleDate = STR_TO_DATE(SaleDate, '%M %d, %Y');

ALTER TABLE houses
MODIFY COLUMN SaleDate date;


-- Populate Property Address data

SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
FROM houses a
JOIN houses b
ON a.ParcelID = b.ParcelID
AND a.UniqueID != b.UniqueID
LIMIT 20;

-- Breaking out Address into individual columns (Address, City, State)

SELECT substr(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1), 
substr(PropertyAddress, POSITION(',' IN PropertyAddress)+1, LENGTH(PropertyAddress))
FROM houses LIMIT 10;


ALTER TABLE houses
ADD COLUMN AddressSplit varchar(50);

UPDATE houses
SET AddressSplit = substr(PropertyAddress, 1, POSITION(',' IN PropertyAddress)-1);

ALTER TABLE houses
ADD COLUMN CitySplit varchar(50);

UPDATE houses
SET CitySplit = substr(PropertyAddress, POSITION(',' IN PropertyAddress)+1, LENGTH(PropertyAddress));


-- Breaking out OwnerAddress into separate columns

SELECT 
SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',1)),',',-1), 
SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',2)),',',-1),
SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',3)),',',-1)
FROM houses LIMIT 10;

ALTER TABLE houses
ADD COLUMN OwnerAddressSplit varchar(50);

UPDATE houses
SET OwnerAddressSplit = SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',1)),',',-1);

ALTER TABLE houses
ADD COLUMN OwnerCitySplit varchar(50);

UPDATE houses
SET OwnerCitySplit = SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',2)),',',-1);

ALTER TABLE houses
ADD COLUMN OwnerStateSplit varchar(50);

UPDATE houses
SET OwnerStateSplit = SUBSTRING_INDEX((SUBSTRING_INDEX(OwnerAddress,',',3)),',',-1);

SELECT OwnerAddress, OwnerAddressSplit, OwnerCitySplit, OwnerStateSplit FROM houses LIMIT 10;

-- Change Y and N into Yes and No in SoldAsVacant

SELECT SoldAsVacant, count(SoldAsVacant)
FROM houses
GROUP BY 1
ORDER BY 2;

UPDATE houses
SET SoldAsVacant = 'Yes'
WHERE SoldAsVacant IN ('Y','Ye');

UPDATE houses
SET SoldAsVacant = 'No'
WHERE SoldAsVacant = 'N';

SELECT SoldAsVacant, count(SoldAsVacant)
FROM houses
GROUP BY 1
ORDER BY 2;

-- Remove duplicates
WITH rownum AS
(
    SELECT *,
    row_number() over (
        PARTITION BY
        ParcelID,
        PropertyAddress,
        SalePrice,
        SaleDate,
        LegalReference
            ORDER BY
            UniqueID
    ) row_num
    FROM houses
)
DELETE FROM
houses USING houses INNER JOIN rownum USING(UniqueID)
WHERE rownum.row_num > 1;

SELECT count(*)
FROM houses a INNER JOIN houses b
ON a.ParcelID = b.ParcelID AND a.PropertyAddress = b.PropertyAddress 
AND a.SalePrice = b.SalePrice AND a.SaleDate = b.SaleDate
AND a.LegalReference = b.LegalReference
AND a.UniqueID < b.UniqueID;


SELECT count(*)
FROM houses;

DELETE a
FROM houses a INNER JOIN houses b
WHERE a.ParcelID = b.ParcelID AND a.PropertyAddress = b.PropertyAddress 
AND a.SalePrice = b.SalePrice AND a.SaleDate = b.SaleDate
AND a.LegalReference = b.LegalReference
AND a.UniqueID < b.UniqueID;



-- Delete unused columns

ALTER TABLE
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress;