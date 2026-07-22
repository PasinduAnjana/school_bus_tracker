-- Migration to wrap existing orphaned routes into Buses automatically
DO $$
DECLARE
    r record;
    new_bus_id UUID;
    bus_count INTEGER := 1;
BEGIN
    -- 1. Create a bus for each driver that currently has routes
    FOR r IN 
        SELECT DISTINCT driver_id 
        FROM routes 
        WHERE driver_id IS NOT NULL AND bus_id IS NULL 
    LOOP
        -- Create a bus for this driver
        INSERT INTO buses (name, driver_id) 
        VALUES ('Bus ' || bus_count, r.driver_id) 
        RETURNING id INTO new_bus_id;
        
        -- Update all this driver's orphaned routes to belong to this new bus
        UPDATE routes 
        SET bus_id = new_bus_id 
        WHERE driver_id = r.driver_id AND bus_id IS NULL;
        
        bus_count := bus_count + 1;
    END LOOP;
    
    -- 2. Catch any remaining routes that don't even have a driver assigned
    IF EXISTS (SELECT 1 FROM routes WHERE bus_id IS NULL) THEN
        INSERT INTO buses (name) 
        VALUES ('Unassigned Routes Bus') 
        RETURNING id INTO new_bus_id;
        
        UPDATE routes 
        SET bus_id = new_bus_id 
        WHERE bus_id IS NULL;
    END IF;
END $$;
