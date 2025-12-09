-- Professional search and booking functions

-- Function to get professionals based on search criteria
CREATE OR REPLACE FUNCTION get_professionals(
  sport_id INTEGER,
  location_id INTEGER DEFAULT NULL,
  role_filter TEXT DEFAULT NULL,
  timeslots JSONB DEFAULT NULL,
  offset_count INTEGER DEFAULT 0,
  limit_count INTEGER DEFAULT 10
)
RETURNS TABLE(
  id INTEGER,
  name TEXT,
  bio TEXT,
  role TEXT,
  avatar_url TEXT,
  rating DECIMAL,
  review_count INTEGER,
  experience_years INTEGER,
  is_verified BOOLEAN,
  is_available BOOLEAN,
  services JSONB,
  created_at TIMESTAMP,
  updated_at TIMESTAMP
) 
LANGUAGE sql
AS $$
  SELECT 
    p.id,
    p.name,
    p.bio,
    p.role,
    p.avatar_url,
    p.rating,
    p.review_count,
    p.experience_years,
    p.is_verified,
    p.is_available,
    COALESCE(
      json_agg(
        CASE 
          WHEN ps.id IS NOT NULL THEN
            json_build_object(
              'id', ps.id,
              'name', ps.name,
              'description', ps.description,
              'price', ps.price,
              'duration_minutes', ps.duration_minutes,
              'is_active', ps.is_active
            )
          ELSE NULL
        END
      ) FILTER (WHERE ps.id IS NOT NULL), 
      '[]'::jsonb
    ) as services,
    p.created_at,
    p.updated_at
  FROM professional p
  LEFT JOIN professional_service ps ON p.id = ps.professional_id AND ps.is_active = true
  WHERE 
    p.is_available = true
    AND (sport_id IS NULL OR p.sport_id = sport_id)
    AND (location_id IS NULL OR p.location_id = location_id)
    AND (role_filter IS NULL OR p.role = role_filter)
    -- TODO: Add timeslot filtering logic based on availability
  GROUP BY p.id, p.name, p.bio, p.role, p.avatar_url, p.rating, p.review_count, 
           p.experience_years, p.is_verified, p.is_available, p.created_at, p.updated_at
  ORDER BY 
    p.rating DESC NULLS LAST,
    p.review_count DESC,
    p.name ASC
  OFFSET offset_count
  LIMIT limit_count;
$$;

-- Function to get professional availability for a specific date
CREATE OR REPLACE FUNCTION get_professional_availability(
  professional_id INTEGER,
  target_date DATE
)
RETURNS TABLE(
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  is_available BOOLEAN,
  price DECIMAL
) 
LANGUAGE sql
AS $$
  WITH 
  -- Generate time slots for the day (9 AM to 9 PM, 1-hour slots)
  time_slots AS (
    SELECT 
      (target_date + (generate_series(9, 20) || ' hour')::interval) as slot_start,
      (target_date + (generate_series(10, 21) || ' hour')::interval) as slot_end
  ),
  -- Get existing bookings for the professional on this date
  existing_bookings AS (
    SELECT start_time, end_time
    FROM professional_booking
    WHERE 
      professional_id = get_professional_availability.professional_id
      AND DATE(start_time) = target_date
      AND status IN ('confirmed', 'pending')
  )
  SELECT 
    ts.slot_start as start_time,
    ts.slot_end as end_time,
    CASE 
      WHEN eb.start_time IS NULL THEN true
      ELSE false
    END as is_available,
    50.0 as price  -- Default hourly rate, should come from professional settings
  FROM time_slots ts
  LEFT JOIN existing_bookings eb ON (
    ts.slot_start < eb.end_time AND 
    ts.slot_end > eb.start_time
  )
  ORDER BY ts.slot_start;
$$;

-- Function to create a professional booking
CREATE OR REPLACE FUNCTION create_professional_booking(
  professional_id INTEGER,
  service_id INTEGER,
  user_id UUID,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  notes TEXT DEFAULT NULL
)
RETURNS TABLE(
  booking_id INTEGER,
  status TEXT,
  total_price DECIMAL
)
LANGUAGE plpgsql
AS $$
DECLARE
  booking_id INTEGER;
  service_price DECIMAL;
  hourly_rate DECIMAL := 50.0; -- Default rate
  duration_hours DECIMAL;
BEGIN
  -- Check if the time slot is available
  IF EXISTS (
    SELECT 1 FROM professional_booking 
    WHERE 
      professional_booking.professional_id = create_professional_booking.professional_id
      AND start_time < create_professional_booking.end_time 
      AND end_time > create_professional_booking.start_time
      AND status IN ('confirmed', 'pending')
  ) THEN
    RAISE EXCEPTION 'Time slot is not available';
  END IF;

  -- Get service price
  SELECT price INTO service_price
  FROM professional_service 
  WHERE id = service_id AND is_active = true;

  IF service_price IS NULL THEN
    RAISE EXCEPTION 'Service not found or inactive';
  END IF;

  -- Calculate duration and total price
  duration_hours := EXTRACT(EPOCH FROM (create_professional_booking.end_time - create_professional_booking.start_time)) / 3600;
  
  -- Insert the booking
  INSERT INTO professional_booking (
    professional_id, service_id, user_id, start_time, end_time, 
    notes, status, total_price, created_at, updated_at
  ) VALUES (
    create_professional_booking.professional_id,
    create_professional_booking.service_id,
    create_professional_booking.user_id,
    create_professional_booking.start_time,
    create_professional_booking.end_time,
    create_professional_booking.notes,
    'pending',
    service_price + (hourly_rate * duration_hours),
    NOW(),
    NOW()
  ) RETURNING id INTO booking_id;

  RETURN QUERY SELECT 
    booking_id,
    'pending'::TEXT as status,
    service_price + (hourly_rate * duration_hours) as total_price;
END;
$$;

-- Function to get user's bookings
CREATE OR REPLACE FUNCTION get_user_bookings(
  user_id UUID,
  limit_count INTEGER DEFAULT 10,
  offset_count INTEGER DEFAULT 0
)
RETURNS TABLE(
  id INTEGER,
  professional_name TEXT,
  service_name TEXT,
  start_time TIMESTAMP,
  end_time TIMESTAMP,
  status TEXT,
  total_price DECIMAL,
  notes TEXT,
  created_at TIMESTAMP
)
LANGUAGE sql
AS $$
  SELECT 
    pb.id,
    p.name as professional_name,
    ps.name as service_name,
    pb.start_time,
    pb.end_time,
    pb.status,
    pb.total_price,
    pb.notes,
    pb.created_at
  FROM professional_booking pb
  JOIN professional p ON pb.professional_id = p.id
  JOIN professional_service ps ON pb.service_id = ps.id
  WHERE pb.user_id = get_user_bookings.user_id
  ORDER BY pb.start_time DESC
  LIMIT limit_count
  OFFSET offset_count;
$$;

-- Indexes for better performance
CREATE INDEX IF NOT EXISTS idx_professional_sport_location 
ON professional (sport_id, location_id, is_available);

CREATE INDEX IF NOT EXISTS idx_professional_rating 
ON professional (rating DESC, review_count DESC);

CREATE INDEX IF NOT EXISTS idx_professional_booking_time 
ON professional_booking (professional_id, start_time, end_time);

CREATE INDEX IF NOT EXISTS idx_professional_booking_user 
ON professional_booking (user_id, start_time DESC);