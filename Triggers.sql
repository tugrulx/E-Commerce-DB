-- Updating user's customer type if due date is expired

CREATE OR REPLACE FUNCTION public.check_due_date()
 RETURNS trigger
AS $$
BEGIN
	IF NEW.Usertype = 'customer' THEN
        RETURN NEW;
    END IF;
	
    IF NEW.CustomerType = 'exclusive' AND NEW.Due_date < CURRENT_DATE THEN
        NEW.CustomerType := 'regular';
		NEW.Due_date := NULL;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_customer_type BEFORE
INSERT OR UPDATE ON
    public.user_account FOR EACH ROW EXECUTE FUNCTION check_due_date()

-- Order related triggers updating stock, emptying ordered cart, emptying carts if stock == 0
CREATE OR REPLACE FUNCTION handle_order_operations()
RETURNS TRIGGER AS $$
BEGIN
    -- Insert items from shopping cart into order items
    INSERT INTO ORDER_ITEM (UserID, OrderID, ShopID, ProductID, OwnerUserID, Quantity, Status, LogisticsName)
    SELECT 
        NEW.UserID,
        NEW.OrderID,
        cart.ShopID,
        cart.ProductID,
        cart.OwnerUserID,
        cart.Quantity,
        'shipping',
		CASE
			WHEN ua.CustomerType = 'regular' THEN '3. Parti Kargo'
            WHEN ua.CustomerType = 'exclusive' THEN 'Premium Kargo'
		END AS LogisticsName
    FROM CART_INCLUDES_SHOP_PRODUCT cart
	JOIN USER_ACCOUNT ua ON  ua.UserID = NEW.UserID
    WHERE cart.UserID = NEW.UserID;

    -- Update stock levels
    UPDATE shop_product as sp
    SET stock = sp.stock - cisp.quantity
    FROM cart_includes_shop_product as cisp
    WHERE cisp.userid = NEW.userid
    AND sp.productid = cisp.productid
    AND sp.shopid = cisp.shopid
    AND sp.owneruserid = cisp.owneruserid;
    
    -- Delete items from carts where stock is 0
    DELETE FROM cart_includes_shop_product cisp
    USING shop_product sp
    WHERE cisp.productid = sp.productid
    AND cisp.shopid = sp.shopid
    AND cisp.owneruserid = sp.owneruserid
    AND sp.stock = 0;
    
    -- Clear the user's shopping cart
    DELETE FROM cart_includes_shop_product
    WHERE userid = NEW.userid;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_order_insert
AFTER INSERT ON order_table
FOR EACH ROW
EXECUTE FUNCTION handle_order_operations();

-- Shopping Cart Insert when a Customer Inserted

CREATE OR REPLACE FUNCTION public.insert_into_specialization()
 RETURNS trigger
AS $$
BEGIN
    IF NEW.usertype = 'customer' THEN
		INSERT INTO shopping_cart(userid)
		VALUES (NEW.userid);
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER user_insert_trigger AFTER
INSERT
    ON
    public.user_account FOR EACH ROW EXECUTE FUNCTION insert_into_specialization()
	
	
-- Shop Rating Update
CREATE OR REPLACE FUNCTION update_shop_rating()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shop
    SET rating = (
        SELECT AVG(rating)::DECIMAL(3,2)
        FROM review
        WHERE shopid = NEW.shopid
    )
    WHERE shopid = NEW.shopid;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_review_insert
AFTER INSERT OR UPDATE ON review
FOR EACH ROW
EXECUTE FUNCTION update_shop_rating();

--Handling expired coupons
CREATE OR REPLACE FUNCTION handle_expired_coupons()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE shopping_cart
    SET coupon_no = NULL
    WHERE coupon_no IN (
        SELECT coupon_no 
        FROM coupon 
        WHERE due_date < CURRENT_DATE
    );
    UPDATE coupon
    SET status = 'expired'
    WHERE due_date < CURRENT_DATE
    AND status != 'expired';
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_expired_coupons
AFTER INSERT OR UPDATE ON coupon
FOR EACH ROW
EXECUTE FUNCTION handle_expired_coupons();

--Handling order status
CREATE OR REPLACE FUNCTION order_status_update()
RETURNS TRIGGER AS $$
DECLARE
    all_delivered BOOLEAN;
    current_orderid INTEGER;
    current_userid INTEGER;
BEGIN
    current_orderid := NEW.orderid;
    current_userid := NEW.userid;
    SELECT CASE 
        WHEN COUNT(*) = COUNT(CASE WHEN status = 'delivered' THEN 1 END) THEN TRUE 
        ELSE FALSE 
    END INTO all_delivered
    FROM order_item
    WHERE orderid = current_orderid 
    AND userid = current_userid;
    IF all_delivered THEN
        UPDATE order_table
        SET status = 'completed'
        WHERE orderid = current_orderid 
        AND userid = current_userid;
	END IF;
	RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_order_item_status_update
AFTER UPDATE OF status ON order_item
FOR EACH ROW
WHEN (NEW.status = 'delivered')
EXECUTE FUNCTION order_status_update();

--Calculating Order's Bill
CREATE OR REPLACE FUNCTION calculate_order_bill()
RETURNS TRIGGER AS $$
BEGIN    
    UPDATE ORDER_TABLE
    SET Bill = (
        SELECT COALESCE(SUM(
            sp.Price * oi.Quantity * 
            (1 - COALESCE(d.Rate, 0)/100)
        ), 0)
        FROM ORDER_ITEM oi
        JOIN SHOP_PRODUCT sp ON oi.ProductID = sp.ProductID 
            AND oi.ShopID = sp.ShopID 
            AND oi.OwnerUserID = sp.OwnerUserID
        LEFT JOIN DISCOUNT d ON d.ProductID = sp.ProductID 
            AND d.ShopID = sp.ShopID 
            AND d.OwnerUserID = sp.OwnerUserID
            AND d.Due_Date >= CURRENT_DATE
        WHERE oi.OrderID = NEW.OrderID
        AND oi.UserID = NEW.UserID
    )
    WHERE OrderID = NEW.OrderID
    AND UserID = NEW.UserID;
    
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_order_bill_trigger
AFTER INSERT OR UPDATE ON ORDER_ITEM
FOR EACH ROW
EXECUTE FUNCTION calculate_order_bill();

--Updating shop's income
CREATE OR REPLACE FUNCTION update_shop_income_per_item()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.Status = 'delivered' THEN
        UPDATE SHOP
        SET Income = Income + (
            SELECT 
                sp.Price * NEW.Quantity * 
                COALESCE((1 - d.Rate/100), 1)
            FROM SHOP_PRODUCT sp
            LEFT JOIN DISCOUNT d ON d.ProductID = sp.ProductID 
                AND d.ShopID = sp.ShopID 
                AND d.OwnerUserID = sp.OwnerUserID
                AND d.Due_Date >= CURRENT_DATE
            WHERE sp.ProductID = NEW.ProductID 
                AND sp.ShopID = NEW.ShopID 
                AND sp.OwnerUserID = NEW.OwnerUserID
        )
        WHERE ShopID = NEW.ShopID 
        AND OwnerUserID = NEW.OwnerUserID;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_shop_income_per_item_trigger
AFTER INSERT OR UPDATE ON ORDER_ITEM
FOR EACH ROW
EXECUTE FUNCTION update_shop_income_per_item();

CREATE OR REPLACE FUNCTION handle_return_approval()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.status = 'approved' THEN
        UPDATE shop_product
        SET stock = stock + NEW.quantity
        WHERE productid = NEW.productid 
        AND shopid = NEW.shopid 
        AND owneruserid = NEW.owneruserid;
        UPDATE shop
        SET income = income - (
            SELECT (sp.price * NEW.quantity)
            FROM shop_product sp
            WHERE sp.productid = NEW.productid 
            AND sp.shopid = NEW.shopid 
            AND sp.owneruserid = NEW.owneruserid
        )
        WHERE shopid = NEW.shopid;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER after_return_approval
AFTER UPDATE OF status ON return_item
FOR EACH ROW
WHEN (NEW.status = 'approved')
EXECUTE FUNCTION handle_return_approval();