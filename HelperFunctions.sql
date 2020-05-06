
/*Helper function that returns total monthly salary for a rider given a month and year */
CREATE OR REPLACE FUNCTION totalMthSalary (rId INTEGER, mth INTEGER, yr INTEGER) RETURNS REAL 
AS $$
    DECLARE
        deliveryFee REAL := 0;
        baseSal REAL := 0;

    BEGIN
        SELECT SUM(O.deliveryfee) INTO deliveryFee
        FROM Orders O
        WHERE O.riderid = rId
        AND (SELECT EXTRACT(MONTH FROM O.ordertime[1])) = mth 
        AND (SELECT EXTRACT(YEAR FROM O.ordertime[1])) = yr
        ;
        
        SELECT COALESCE(M.baseSalary, 0) INTO baseSal
        FROM MWS M
        WHERE M.riderid = rId
        AND (SELECT EXTRACT(MONTH FROM M.startdate)) = mth
        AND (SELECT EXTRACT(YEAR FROM M.startdate)) = yr
        ;

        IF baseSal = 0 THEN
            SELECT SUM(W.basesalary) INTO baseSal
            FROM WWS W
            WHERE W.riderid = rId
            AND (SELECT EXTRACT(MONTH FROM W.startdate)) = mth
            AND (SELECT EXTRACT(YEAR FROM W.startdate)) = yr
            ;
        
        END IF;
        RETURN (deliveryFee + baseSal);
    END;

$$ LANGUAGE plpgsql;

/*Helper function that returns the total number of new customers, total orders, total cost per given month and year*/
CREATE OR REPLACE FUNCTION totalMthlyFdsStatistics (mth INTEGER, yr INTEGER)
RETURNS TABLE (
    cust_count INTEGER,
    order_count INTEGER,
    total_cost REAL
) 
AS $$
    BEGIN

        SELECT COALESCE(COUNT(DISTINCT U.userid), 0) INTO cust_count
        FROM Users U
        WHERE U.type = 1
        AND (SELECT EXTRACT(MONTH FROM U.registrationdate)) = mth
        AND (SELECT EXTRACT(YEAR FROM U.registrationdate)) = yr
        ;

        SELECT COALESCE(COUNT(DISTINCT O.orderid),0), COALESCE(SUM(O.foodfee + O.deliveryfee),0) INTO cust_count, total_cost
        FROM Orders O
        WHERE (SELECT EXTRACT(MONTH FROM O.ordertime[1])) = mth 
        AND (SELECT EXTRACT(YEAR FROM O.ordertime[1])) = yr
        ;

    END;

$$ LANGUAGE plpgsql;

/*Helper function that returns the number of orders placed and total cost of orders per given customer,mth,year*/
CREATE OR REPLACE FUNCTION mthlyCustomerStatistics (cId INTEGER, mth INTEGER, yr INTEGER)
RETURNS TABLE (
    order_count INTEGER,
    total_cost REAL
)
AS $$
    BEGIN
        SELECT COALESCE(COUNT(DISTINCT O.orderId),0), COALESCE(SUM(O.foodfee + O.deliveryfee),0) INTO order_count, total_cost
        FROM Orders O
        WHERE O.customerid = cId
        AND (SELECT EXTRACT(MONTH FROM O.ordertime[1])) = mth 
        AND (SELECT EXTRACT(YEAR FROM O.ordertime[1])) = yr
        ;
    END;

$$ LANGUAGE plpgsql;


/*Helper function that returns the total number of ordeers, hours, salary, average delivery time,
 *number of ratings and average ratings given a rider and month */
 CREATE OR REPLACE FUNCTION mthlyRiderStatistics (rId INTEGER, mth INTEGER, yr INTEGER)
 RETURNS TABLE (
     order_count INTEGER,
     total_hours INTEGER,
     total_salary REAL,
     average_del_time REAL,
     rating_count INTEGER,
     average_rating REAL
 )
 AS $$
    BEGIN
        SELECT COALESCE(COUNT(DISTINCT O.orderId),0), COALESCE(AVG(O.ordertime[5] - O.ordertime[4]),0) INTO order_count, average_del_time
        FROM Orders O
        WHERE O.riderid = rId
        AND (SELECT EXTRACT(MONTH FROM O.ordertime[1])) = mth 
        AND (SELECT EXTRACT(YEAR FROM O.ordertime[1])) = yr
        ;

        SELECT totalMthSalary(rId, mth, year) INTO total_salary;

        SELECT COALESCE(COUNT(O.ratings),0), COALESCE(AVG(O.ratings), 0) INTO rating_count, average_rating
        FROM Orders O
        WHERE O.riderid = rId
        AND O.ratings <> 0
        AND (SELECT EXTRACT(MONTH FROM O.ordertime[1])) = mth 
        AND (SELECT EXTRACT(YEAR FROM O.ordertime[1])) = yr
        ;

        WITH WWSMerged AS (
            SELECT W.riderid, WS.starttime, WS.endtime, W.startdate
            FROM WWS W JOIN WWS_Schedules WS ON W.workid = WS.workid
        )
        SELECT COALESCE(SUM(WM.endtime - WM.starttime),0) INTO total_hours
        FROM WWSMerged WM
        WHERE WM.riderid = rId
        AND (SELECT EXTRACT(MONTH FROM WM.startdate)) = mth 
        AND (SELECT EXTRACT(YEAR FROM WM.startdate)) = yr
        ;
    END;
 $$ LANGUAGE plpgsql;