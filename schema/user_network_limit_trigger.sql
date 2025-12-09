-- Trigger to limit the number of networks a user can join to 2
-- This trigger prevents users from joining more than 2 networks

-- Function to check network count before insert/update
CREATE OR REPLACE FUNCTION check_user_network_limit()
RETURNS TRIGGER AS $$
BEGIN
    -- Check if this would exceed the limit of 2 networks per user
    IF (SELECT COUNT(*) FROM user_network WHERE user_id = NEW.user_id) >= 2 THEN
        RAISE EXCEPTION 'User cannot join more than 2 networks. Current limit: 2';
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger on user_network table
-- This trigger fires BEFORE INSERT to prevent exceeding the limit
DROP TRIGGER IF EXISTS user_network_limit_trigger ON user_network;

CREATE TRIGGER user_network_limit_trigger
    BEFORE INSERT ON user_network
    FOR EACH ROW
    EXECUTE FUNCTION check_user_network_limit();

-- Create trigger for UPDATE operations that might change user_id
-- This handles edge cases where user_id might be updated
DROP TRIGGER IF EXISTS user_network_limit_update_trigger ON user_network;

CREATE TRIGGER user_network_limit_update_trigger
    BEFORE UPDATE ON user_network
    FOR EACH ROW
    WHEN (OLD.user_id IS DISTINCT FROM NEW.user_id)
    EXECUTE FUNCTION check_user_network_limit();

-- Grant necessary permissions
GRANT EXECUTE ON FUNCTION check_user_network_limit() TO authenticated;
GRANT EXECUTE ON FUNCTION check_user_network_limit() TO anon;