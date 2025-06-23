-- Create sequences for auto-incrementing IDs
CREATE SEQUENCE address_seq START 1;
CREATE SEQUENCE account_seq START 1;
CREATE SEQUENCE category_seq START 1;
CREATE SEQUENCE product_seq START 1;
CREATE SEQUENCE shop_seq START 1;
CREATE SEQUENCE wishlist_seq START 1;
CREATE SEQUENCE billing_seq START 1;
CREATE SEQUENCE order_seq START 1;
CREATE SEQUENCE return_seq START 1;
CREATE SEQUENCE review_seq START 1;
CREATE SEQUENCE coupon_seq START 1;
CREATE SEQUENCE tracking_seq START 1;
CREATE SEQUENCE saved_address_seq START 1;

-- Create base user table
CREATE TABLE USER_ACCOUNT (
    UserID INT PRIMARY KEY DEFAULT nextval('account_seq'),
    Email VARCHAR(100) UNIQUE NOT NULL CHECK (Email LIKE '%@%.%'),
    Name VARCHAR(50) NOT NULL,
    Surname VARCHAR(50) NOT NULL,
    Password VARCHAR(50) NOT NULL,
    Bdate DATE,
    Sex CHAR(1) CHECK (Sex IN ('M', 'F', 'O')),
    Country VARCHAR(50),
	UserType VARCHAR(9) CHECK (UserType IN ('customer', 'shopowner')),
	CustomerType VARCHAR(9) CHECK (CustomerType IN ('regular', 'exclusive')),
    Due_date DATE,
	Tax_no VARCHAR(10) UNIQUE CHECK (LENGTH(Tax_no) = 10)
);

-- Create address related tables
CREATE TABLE SAVED_ADDRESS (
    AddressNo INT DEFAULT nextval('saved_address_seq'),
    UserID INTEGER NOT NULL,
    Door_No VARCHAR(10) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Zipcode VARCHAR(5) NOT NULL CHECK (LENGTH (Zipcode) = 5),
    Telephone_number VARCHAR(20) NOT NULL,
    Street VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
	PRIMARY KEY (AddressNo, UserID),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE DELIVERY_ADDRESS (
    AddressNo INT PRIMARY KEY DEFAULT nextval('address_seq'),
    UserID INTEGER NOT NULL,
    Door_No VARCHAR(10) NOT NULL,
    Country VARCHAR(50) NOT NULL,
    Zipcode VARCHAR(5) NOT NULL CHECK (LENGTH (Zipcode) = 5),
    Telephone_number VARCHAR(20) NOT NULL,
    Street VARCHAR(100) NOT NULL,
    City VARCHAR(50) NOT NULL,
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE PICKUPPOINT (
    Address_no INTEGER PRIMARY KEY,
    Available_hours TIME NOT NULL,
    Locker_no VARCHAR(20),
    IsAutomat BOOLEAN NOT NULL,
    FOREIGN KEY (Address_no) REFERENCES DELIVERY_ADDRESS(AddressNo) ON DELETE CASCADE
);

CREATE TABLE CUSTOM_ADDRESS (
    Address_no INTEGER PRIMARY KEY,
    Title VARCHAR(100) NOT NULL,
    FOREIGN KEY (Address_no) REFERENCES DELIVERY_ADDRESS(AddressNo) ON DELETE CASCADE
);

-- Create product related tables
CREATE TABLE CATEGORY (
    CategoryID INT PRIMARY KEY DEFAULT nextval('category_seq'),
    Name VARCHAR(50) NOT NULL,
    ParentCategoryID INTEGER,
    FOREIGN KEY (ParentCategoryID) REFERENCES CATEGORY(CategoryID) ON DELETE SET NULL
);

CREATE TABLE PRODUCT (
    ProductID INT PRIMARY KEY DEFAULT nextval('product_seq'),
    Brand VARCHAR(50) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Description TEXT,
    Type VARCHAR(50) NOT NULL,
    CategoryID INTEGER NOT NULL,
    FOREIGN KEY (CategoryID) REFERENCES CATEGORY(CategoryID) ON DELETE CASCADE
);

CREATE TABLE MEDIA (
    URL VARCHAR(200) NOT NULL,
    ProductID INTEGER NOT NULL,
    Date DATE,
    Type VARCHAR(5),
    PRIMARY KEY (URL, ProductID),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

CREATE TABLE PRODUCT_FEATURES (
    ProductID INTEGER NOT NULL,
    Features TEXT NOT NULL,
    PRIMARY KEY (ProductID, Features),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE
);

-- Create shop related tables
CREATE TABLE SHOP (
    ShopID INT DEFAULT nextval('shop_seq'),
    OwnerUserID INTEGER NOT NULL,
    Address TEXT NOT NULL,
    Income DECIMAL(15, 2) DEFAULT 0.00 NOT NULL,
    Rating DECIMAL(3, 2) CHECK (Rating BETWEEN 0 AND 5),
    MERSIS VARCHAR(16) UNIQUE NOT NULL CHECK (LENGTH(MERSIS) = 16),
    PRIMARY KEY (ShopID, OwnerUserID),
    FOREIGN KEY (OwnerUserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE SHOP_PRODUCT (
    ProductID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Stock INTEGER NOT NULL CHECK (Stock >= 0),
    Price DECIMAL(10, 2) NOT NULL CHECK (Price >= 0),
    PRIMARY KEY (ProductID, ShopID, OwnerUserID),
    FOREIGN KEY (ProductID) REFERENCES PRODUCT(ProductID) ON DELETE CASCADE,
    FOREIGN KEY (ShopID, OwnerUserID) REFERENCES SHOP(ShopID, OwnerUserID) ON DELETE CASCADE
);

-- Create payment related tables
CREATE TABLE REGISTERED_CARDS (
    UserID INTEGER NOT NULL,
    Cvv CHAR(3) NOT NULL,
    Card_no VARCHAR(16) NOT NULL,
    Name VARCHAR(100) NOT NULL,
    Due_date DATE NOT NULL,
    PRIMARY KEY (UserID, Card_no),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE COUPON (
    Coupon_no INTEGER PRIMARY KEY DEFAULT nextval('coupon_seq'),
    Due_date DATE NOT NULL,
    status VARCHAR(7) NOT NULL CHECK (status IN ('expired', 'valid')),
    Amount INTEGER NOT NULL
);

CREATE TABLE COUPON_USER_ACCOUNT (
    UserID INTEGER NOT NULL,
    Coupon_no INTEGER NOT NULL,
    PRIMARY KEY (UserID, Coupon_no),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (Coupon_no) REFERENCES COUPON(Coupon_no) ON DELETE CASCADE
);

-- Create shopping related tables
CREATE TABLE WISHLIST (
    UserID INTEGER NOT NULL,
    WishlistID INT DEFAULT nextval('wishlist_seq'),
    PRIMARY KEY (UserID, WishlistID),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE SHOPPING_CART (
    UserID INTEGER PRIMARY KEY,
    Coupon_no INTEGER,
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (Coupon_no) REFERENCES COUPON(Coupon_no) ON DELETE SET NULL
);

CREATE TABLE CART_INCLUDES_SHOP_PRODUCT (
    UserID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (UserID, ShopID, ProductID),
    FOREIGN KEY (UserID) REFERENCES SHOPPING_CART(UserID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE
);

-- Create logistics and order related tables
CREATE TABLE LOGISTICS (
	Name VARCHAR(100) PRIMARY KEY,
    Type VARCHAR(30) NOT NULL
);

CREATE TABLE BILLING_INFORMATION (
    BillingID INT PRIMARY KEY DEFAULT nextval('billing_seq'),
    UserID INTEGER NOT NULL,
    CFlag BOOLEAN NOT NULL,
    Cvv CHAR(3) CHECK (LENGTH(Cvv) = 3),
    Card_no VARCHAR(16) CHECK (LENGTH(Card_no) = 16),
    Name VARCHAR(100),
    Card_Due_Date DATE,
    GCFlag BOOLEAN NOT NULL,
    GiftCard_Due_Date DATE,
    Code VARCHAR(20),
	Amount DECIMAL(10, 2),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE ORDER_TABLE (
    UserID INTEGER NOT NULL,
    OrderID INT DEFAULT nextval('order_seq'),
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('inprogress', 'shipping', 'completed')),
    Date DATE NOT NULL,
    Bill DECIMAL(10, 2),
    BillingID INTEGER NOT NULL,
    AddressNo INTEGER NOT NULL,
    PRIMARY KEY (UserID, OrderID),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (BillingID) REFERENCES BILLING_INFORMATION(BillingID) ON DELETE CASCADE,
    FOREIGN KEY (AddressNo) REFERENCES DELIVERY_ADDRESS(AddressNo) ON DELETE CASCADE
);

CREATE TABLE ORDER_ITEM (
	Tracking_number INTEGER DEFAULT nextval('tracking_seq'),
    UserID INTEGER NOT NULL,
    OrderID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
	Status VARCHAR(9) NOT NULL CHECK (Status IN ('shipping', 'delivered')),
    LogisticsName VARCHAR(50),
    PRIMARY KEY (UserID, OrderID, ShopID, ProductID, OwnerUserID),
    FOREIGN KEY (UserID, OrderID) REFERENCES ORDER_TABLE(UserID, OrderID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE,
    FOREIGN KEY (LogisticsName) REFERENCES LOGISTICS(Name) ON DELETE SET NULL
);

-- Create additional functionality tables
CREATE TABLE SHOP_PRODUCT_IN_WISHLIST (
    ProductID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    UserID INTEGER NOT NULL,
    WishlistID INTEGER NOT NULL,
    PRIMARY KEY (ProductID, ShopID, UserID, WishlistID),
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE,
    FOREIGN KEY (UserID, WishlistID) REFERENCES WISHLIST(UserID, WishlistID) ON DELETE CASCADE
);

CREATE TABLE CONVERSATION (
    UserID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Question TEXT NOT NULL,
    Answer TEXT,
    PRIMARY KEY (UserID, ShopID, ProductID, Question),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE
);

CREATE TABLE REVIEW (
    UserID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Review_no INT DEFAULT nextval('review_seq'),
    Date DATE NOT NULL,
    Rating INTEGER NOT NULL CHECK (Rating BETWEEN 1 AND 5),
    Text TEXT,
    PRIMARY KEY (UserID, ShopID, ProductID, Review_no),
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE
);

CREATE TABLE DISCOUNT (
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OwnerUserID INTEGER NOT NULL,
    Rate DECIMAL(5, 2) NOT NULL CHECK (Rate >= 0 AND Rate <= 100),
    Due_Date DATE NOT NULL,
    PRIMARY KEY (ShopID, ProductID, OwnerUserID),
    FOREIGN KEY (ProductID, ShopID, OwnerUserID) REFERENCES SHOP_PRODUCT(ProductID, ShopID, OwnerUserID) ON DELETE CASCADE
);

CREATE TABLE RETURN_ITEM (
    UserID INTEGER NOT NULL,
    ReturnID INT DEFAULT nextval('return_seq'),
    OwnerUserID INTEGER NOT NULL,
    ShopID INTEGER NOT NULL,
    ProductID INTEGER NOT NULL,
    OrderID INTEGER NOT NULL,
    Description TEXT,
    Status VARCHAR(20) NOT NULL CHECK (Status IN ('pending', 'in progress', 'approved')),
    Quantity INTEGER NOT NULL CHECK (Quantity > 0),
    PRIMARY KEY (UserID, ReturnID, OwnerUserID, ShopID, ProductID, OrderID),
    FOREIGN KEY (UserID, OwnerUserID, OrderID, ShopID, ProductID) REFERENCES ORDER_ITEM(UserID, OwnerUserID, OrderID, ShopID, ProductID) ON DELETE CASCADE,
    FOREIGN KEY (UserID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE
);

CREATE TABLE CONTRIBUTORS (
    ContributorID INTEGER NOT NULL,
    OwnerID INTEGER NOT NULL,
    WishlistID INTEGER NOT NULL,
    PRIMARY KEY (ContributorID, OwnerID, WishlistID),
    FOREIGN KEY (ContributorID) REFERENCES USER_ACCOUNT(UserID) ON DELETE CASCADE,
    FOREIGN KEY (OwnerID, WishlistID) REFERENCES WISHLIST(UserID, WishlistID) ON DELETE CASCADE
);