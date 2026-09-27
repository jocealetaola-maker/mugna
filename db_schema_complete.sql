-- ============================================================
-- COMPLETE MUGNA CAFÉ LEDGER SCHEMA
-- Run this in Supabase SQL Editor to set up the full database
-- ============================================================

-- ============================================================
-- 1. INGREDIENTS TABLE (Base inventory items)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.ingredients (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    name TEXT NOT NULL UNIQUE,
    unit TEXT DEFAULT 'qty', -- kg, L, pcs, etc.
    stock_qty NUMERIC(12,2) DEFAULT 0.00,
    cost_per_unit NUMERIC(10,2) DEFAULT 0.00,
    modifier_price NUMERIC(10,2) DEFAULT 0.00, -- For milk/cup upcharges
    reorder_level NUMERIC(12,2) DEFAULT 0.00,
    supplier TEXT,
    notes TEXT
);

-- ============================================================
-- 2. MENU TABLE (Products/drinks for sale)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.menu (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    name TEXT NOT NULL,
    category TEXT DEFAULT 'Drinks', -- Drinks, Food, Add-ons, etc.
    price NUMERIC(10,2) NOT NULL,
    description TEXT,
    photo_url TEXT,
    recipe JSONB DEFAULT '[]'::jsonb, -- Array of {ingredient_id, qty}
    
    times_sold INT DEFAULT 0,
    last_sold TIMESTAMPTZ,
    active BOOLEAN DEFAULT true,
    
    UNIQUE(name)
);

-- ============================================================
-- 3. SALES TABLE (Transactions)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    items JSONB NOT NULL DEFAULT '[]'::jsonb, -- Array of {menu_id, qty, name, price, mods}
    subtotal NUMERIC(10,2) DEFAULT 0.00,
    discount_amount NUMERIC(10,2) DEFAULT 0.00,
    discount_type TEXT DEFAULT 'amount', -- 'amount' or 'percentage'
    tip_amount NUMERIC(10,2) DEFAULT 0.00,
    total NUMERIC(10,2) NOT NULL,
    
    payment_method TEXT DEFAULT 'Cash', -- Cash, Card, GCash, Bank
    payment_status TEXT DEFAULT 'paid', -- paid, pending, refunded
    
    staff_id UUID REFERENCES public.staff_roster(id),
    customer_phone TEXT, -- For loyalty tracking
    loyalty_redeemed BOOLEAN DEFAULT false,
    
    sold_at TIMESTAMPTZ DEFAULT NOW(),
    inventory_deducted BOOLEAN DEFAULT true,
    note TEXT
);

-- ============================================================
-- 4. EXPENSES TABLE (Money going out)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    spent_at DATE DEFAULT CURRENT_DATE,
    supplier TEXT,
    description TEXT,
    category TEXT DEFAULT 'Supplies', -- Supplies, Utilities, Rent, etc.
    items JSONB DEFAULT '[]'::jsonb, -- Array of {name, qty, price}
    amount NUMERIC(10,2) NOT NULL,
    
    expense_type TEXT DEFAULT 'Consumables', -- Consumables, Equipment, Utility, etc.
    source TEXT DEFAULT 'Business', -- Business or Personal
    payment_method TEXT DEFAULT 'Cash',
    has_receipt TEXT DEFAULT 'No', -- Yes/No
    
    staff_id UUID REFERENCES public.staff_roster(id),
    status TEXT DEFAULT 'approved', -- pending, approved, rejected
    
    notes TEXT
);

-- ============================================================
-- 5. LOYALTY TABLE (Customer rewards program)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.loyalty (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    phone TEXT UNIQUE NOT NULL,
    name TEXT,
    
    cups INT DEFAULT 0, -- Current stamps
    lifetime_cups INT DEFAULT 0,
    rewards_redeemed INT DEFAULT 0,
    
    notes TEXT
);

-- ============================================================
-- 6. PARTNERS TABLE (Investors, suppliers, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.partners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    name TEXT NOT NULL UNIQUE,
    type TEXT DEFAULT 'supplier', -- supplier, investor, distributor, etc.
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    
    account_balance NUMERIC(12,2) DEFAULT 0.00,
    notes TEXT
);

-- ============================================================
-- 7. DOCUMENTS/FILES TABLE (Receipts, invoices, etc.)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.documents (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    name TEXT NOT NULL,
    file_type TEXT, -- invoice, receipt, report, etc.
    file_url TEXT NOT NULL,
    uploaded_by TEXT,
    
    related_expense_id UUID REFERENCES public.expenses(id),
    
    notes TEXT
);

-- ============================================================
-- 8. NOTES/NOTEBOOK TABLE (Owner observations)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    title TEXT,
    content TEXT NOT NULL,
    tags JSONB DEFAULT '[]'::jsonb,
    
    is_pinned BOOLEAN DEFAULT false
);

-- ============================================================
-- 9. PETTY CASH TABLE (Small cash expenses)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.petty_cash (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    description TEXT NOT NULL,
    amount NUMERIC(10,2) NOT NULL,
    direction TEXT DEFAULT 'out', -- 'in' or 'out'
    
    timestamp TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- ============================================================
-- 10. SHIFTS TABLE (Shift management)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.shifts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    shift_date DATE NOT NULL,
    staff_id UUID REFERENCES public.staff_roster(id),
    
    start_time TIMESTAMPTZ,
    end_time TIMESTAMPTZ,
    hours_worked NUMERIC(5,2),
    
    notes TEXT
);

-- ============================================================
-- 11. PARKED ORDERS TABLE (Unfinished orders)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.parked_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    customer_name TEXT,
    total NUMERIC(10,2),
    
    parked_at TIMESTAMPTZ DEFAULT NOW(),
    notes TEXT
);

-- ============================================================
-- 12. STAFF LOG TABLE (Activity tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.staff_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    staff_id UUID REFERENCES public.staff_roster(id),
    action TEXT, -- clock_in, clock_out, sale, expense, etc.
    details JSONB,
    
    timestamp TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================
-- 13. CUSTOMER ORDERS TABLE (Online/digital orders)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.customer_orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    customer_name TEXT,
    customer_phone TEXT,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    total NUMERIC(10,2) NOT NULL,
    
    status TEXT DEFAULT 'pending', -- pending, preparing, ready, completed, cancelled
    order_type TEXT DEFAULT 'online', -- online, walk-in, delivery, etc.
    
    notes TEXT,
    ready_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ
);

-- ============================================================
-- 14. FEEDBACK TABLE (Customer feedback/reviews)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.feedback (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    customer_name TEXT,
    rating INT CHECK (rating >= 1 AND rating <= 5),
    message TEXT,
    
    order_id UUID REFERENCES public.customer_orders(id)
);

-- ============================================================
-- 15. DISTRIBUTIONS TABLE (Profit sharing/draws)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.distributions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    distribution_date DATE NOT NULL,
    description TEXT,
    amount NUMERIC(12,2) NOT NULL,
    
    recipient TEXT,
    distribution_type TEXT DEFAULT 'draw', -- draw, dividend, settlement, etc.
    
    notes TEXT
);

-- ============================================================
-- 16. SETTINGS TABLE (Global app config)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.settings (
    id INT PRIMARY KEY DEFAULT 1,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    business_name TEXT DEFAULT 'Mugnâ Café',
    profit_model TEXT DEFAULT 'draw_then_prorata',
    reserve_pct NUMERIC(5,2) DEFAULT 10.00,
    
    config JSONB DEFAULT '{
        "bonus_pool": 0,
        "bonus_pool_pct": 0,
        "sales_timeframe": "weekly",
        "logo_url": ""
    }'::jsonb,
    
    CONSTRAINT single_row CHECK (id = 1)
);

-- Insert default settings
INSERT INTO public.settings (id, business_name, config)
VALUES (1, 'Mugnâ Café', '{"bonus_pool": 0, "bonus_pool_pct": 10, "sales_timeframe": "weekly", "logo_url": ""}'::jsonb)
ON CONFLICT (id) DO NOTHING;

-- ============================================================
-- 17. COFFEE SHOP SETTINGS TABLE (White-label, future multi-tenant)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.coffee_shop_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    business_name TEXT DEFAULT 'Mugnâ Café',
    business_logo_url TEXT,
    owner_id UUID,
    
    bonus_pool_pct NUMERIC(5,2) DEFAULT 10.00,
    sales_period TEXT DEFAULT 'weekly', -- 'weekly' or 'monthly'
    sales_period_day INT DEFAULT 1 -- day of week (1=Mon) or month
);

-- Insert default white-label settings
INSERT INTO public.coffee_shop_settings (business_name, bonus_pool_pct, sales_period)
VALUES ('Mugnâ Café', 10.00, 'weekly')
ON CONFLICT DO NOTHING;

-- ============================================================
-- 18. STAFF ROSTER TABLE (Employees with full payroll info)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.staff_roster (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    name TEXT NOT NULL,
    email TEXT UNIQUE NOT NULL,
    staff_pin TEXT NOT NULL, -- 4-digit PIN for login
    role_title TEXT DEFAULT 'Barista',
    start_date DATE DEFAULT CURRENT_DATE,
    
    -- COMPENSATION (PH labor law rates)
    daily_rate NUMERIC(10,2) DEFAULT 0.00,
    daily_allowance NUMERIC(10,2) DEFAULT 0.00,
    ot_rate_hourly NUMERIC(10,2) DEFAULT 0.00,
    rest_day_rate NUMERIC(10,2) DEFAULT 0.00,
    rest_day_ot_rate NUMERIC(10,2) DEFAULT 0.00,
    
    -- SHIFT TRACKING
    shift_active BOOLEAN DEFAULT false,
    shift_started TIMESTAMPTZ,
    shift_ended TIMESTAMPTZ,
    
    -- STATUS
    is_active BOOLEAN DEFAULT true,
    
    CONSTRAINT valid_pin CHECK (LENGTH(staff_pin) = 4)
);

-- ============================================================
-- 19. DAILY FLOATS TABLE (Money float tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.daily_floats (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    float_date DATE NOT NULL,
    
    cash_float_today NUMERIC(10,2) DEFAULT 0.00,
    cash_float_next_day NUMERIC(10,2) DEFAULT 0.00,
    
    gcash_float_today NUMERIC(10,2) DEFAULT 0.00,
    gcash_float_next_day NUMERIC(10,2) DEFAULT 0.00,
    
    logged_by TEXT,
    notes TEXT,
    
    UNIQUE(float_date)
);

-- Insert today's float as default
INSERT INTO public.daily_floats (float_date, cash_float_today, cash_float_next_day, gcash_float_today, gcash_float_next_day)
VALUES (CURRENT_DATE, 500.00, 500.00, 0.00, 0.00)
ON CONFLICT (float_date) DO NOTHING;

-- ============================================================
-- 20. DAILY RECONCILIATION TABLE (Cash verification)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.daily_reconciliation (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    reconciliation_date DATE NOT NULL,
    reconciled_by UUID,
    
    -- CASH RECONCILIATION
    cash_float_previous NUMERIC(10,2) DEFAULT 0.00,
    cash_sales_total NUMERIC(10,2) DEFAULT 0.00,
    cash_expenses_total NUMERIC(10,2) DEFAULT 0.00,
    cash_in_register NUMERIC(10,2),
    cash_expected NUMERIC(10,2),
    cash_variance NUMERIC(10,2),
    cash_status TEXT DEFAULT 'pending',
    
    -- GCASH RECONCILIATION
    gcash_float_previous NUMERIC(10,2) DEFAULT 0.00,
    gcash_sales_total NUMERIC(10,2) DEFAULT 0.00,
    gcash_expenses_total NUMERIC(10,2) DEFAULT 0.00,
    gcash_total NUMERIC(10,2),
    gcash_variance NUMERIC(10,2),
    gcash_status TEXT DEFAULT 'pending',
    
    notes TEXT,
    
    UNIQUE(reconciliation_date)
);

-- ============================================================
-- 21. STAFF SHIFT LOG TABLE (Clock in/out tracking)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.staff_shift_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    staff_id UUID NOT NULL REFERENCES public.staff_roster(id) ON DELETE CASCADE,
    
    shift_date DATE NOT NULL,
    clock_in_time TIMESTAMPTZ,
    clock_out_time TIMESTAMPTZ,
    hours_worked NUMERIC(5,2),
    break_duration NUMERIC(5,2) DEFAULT 0.00,
    
    is_rest_day BOOLEAN DEFAULT false,
    shift_notes TEXT,
    
    UNIQUE(staff_id, shift_date)
);

-- ============================================================
-- 22. PAYROLL SUMMARY TABLE (Auto-calculated payroll)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.payroll_summary (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES public.staff_roster(id) ON DELETE CASCADE,
    
    days_worked INT DEFAULT 0,
    regular_hours NUMERIC(8,2) DEFAULT 0.00,
    overtime_hours NUMERIC(8,2) DEFAULT 0.00,
    rest_day_hours NUMERIC(8,2) DEFAULT 0.00,
    rest_day_ot_hours NUMERIC(8,2) DEFAULT 0.00,
    
    base_pay NUMERIC(10,2) DEFAULT 0.00,
    allowance NUMERIC(10,2) DEFAULT 0.00,
    overtime_pay NUMERIC(10,2) DEFAULT 0.00,
    rest_day_pay NUMERIC(10,2) DEFAULT 0.00,
    rest_day_ot_pay NUMERIC(10,2) DEFAULT 0.00,
    bonus_share NUMERIC(10,2) DEFAULT 0.00,
    
    gross_pay NUMERIC(10,2) DEFAULT 0.00,
    deductions NUMERIC(10,2) DEFAULT 0.00,
    net_pay NUMERIC(10,2) DEFAULT 0.00,
    
    notes TEXT,
    
    UNIQUE(staff_id, period_start, period_end)
);

-- ============================================================
-- 23. SALES COMMISSION TABLE (Weekly/Monthly bonus)
-- ============================================================
CREATE TABLE IF NOT EXISTS public.sales_commission (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    period_start DATE NOT NULL,
    period_end DATE NOT NULL,
    staff_id UUID NOT NULL REFERENCES public.staff_roster(id) ON DELETE CASCADE,
    
    total_sales NUMERIC(10,2) DEFAULT 0.00,
    sales_count INT DEFAULT 0,
    commission_rate NUMERIC(5,2) DEFAULT 0.00,
    commission_earned NUMERIC(10,2) DEFAULT 0.00,
    
    UNIQUE(staff_id, period_start, period_end)
);

-- ============================================================
-- DISABLE ROW LEVEL SECURITY (RLS) FOR FULL APP ACCESS
-- ============================================================
ALTER TABLE public.ingredients DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.menu DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.expenses DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.loyalty DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.partners DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.documents DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.notes DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.petty_cash DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.shifts DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.parked_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.customer_orders DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.feedback DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.distributions DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.coffee_shop_settings DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_roster DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_floats DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.daily_reconciliation DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.staff_shift_log DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.payroll_summary DISABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_commission DISABLE ROW LEVEL SECURITY;

-- ============================================================
-- GRANT PERMISSIONS TO SUPABASE ROLES
-- ============================================================
GRANT ALL ON TABLE public.ingredients TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.menu TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.sales TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.expenses TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.loyalty TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.partners TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.documents TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.notes TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.petty_cash TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.shifts TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.parked_orders TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.staff_log TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.customer_orders TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.feedback TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.distributions TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.settings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.coffee_shop_settings TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.staff_roster TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.daily_floats TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.daily_reconciliation TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.staff_shift_log TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.payroll_summary TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.sales_commission TO anon, authenticated, service_role;

-- ============================================================
-- CREATE PERFORMANCE INDEXES
-- ============================================================
CREATE INDEX idx_menu_category ON public.menu(category);
CREATE INDEX idx_menu_active ON public.menu(active);
CREATE INDEX idx_sales_sold_at ON public.sales(sold_at);
CREATE INDEX idx_sales_staff_id ON public.sales(staff_id);
CREATE INDEX idx_sales_payment_method ON public.sales(payment_method);
CREATE INDEX idx_expenses_spent_at ON public.expenses(spent_at);
CREATE INDEX idx_expenses_staff_id ON public.expenses(staff_id);
CREATE INDEX idx_loyalty_phone ON public.loyalty(phone);
CREATE INDEX idx_customer_orders_status ON public.customer_orders(status);
CREATE INDEX idx_staff_email ON public.staff_roster(email);
CREATE INDEX idx_staff_active ON public.staff_roster(is_active);
CREATE INDEX idx_shift_log_staff_date ON public.staff_shift_log(staff_id, shift_date);
CREATE INDEX idx_reconciliation_date ON public.daily_reconciliation(reconciliation_date);
CREATE INDEX idx_floats_date ON public.daily_floats(float_date);
CREATE INDEX idx_payroll_period ON public.payroll_summary(period_start, period_end);
CREATE INDEX idx_commission_period ON public.sales_commission(period_start, period_end);

-- ============================================================
-- CREATE USEFUL FUNCTIONS FOR TRIGGERS
-- ============================================================

-- Auto-update menu sales count when a sale is made
CREATE OR REPLACE FUNCTION update_menu_sales_count()
RETURNS TRIGGER AS $$
DECLARE
    item_record JSONB;
    menu_id UUID;
    qty_sold INT;
BEGIN
    FOR item_record IN SELECT * FROM jsonb_array_elements(NEW.items)
    LOOP
        menu_id := (item_record->>'menu_id')::UUID;
        qty_sold := COALESCE((item_record->>'qty')::INT, 1);
        
        UPDATE public.menu
        SET times_sold = COALESCE(times_sold, 0) + qty_sold,
            last_sold = NOW()
        WHERE id = menu_id;
    END LOOP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_menu_sales
AFTER INSERT ON public.sales
FOR EACH ROW
EXECUTE FUNCTION update_menu_sales_count();

-- Auto-calculate shift hours when clocking out
CREATE OR REPLACE FUNCTION calculate_shift_hours()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.clock_out_time IS NOT NULL AND NEW.clock_in_time IS NOT NULL THEN
        NEW.hours_worked := EXTRACT(EPOCH FROM (NEW.clock_out_time - NEW.clock_in_time)) / 3600.0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_calculate_shift_hours
BEFORE INSERT OR UPDATE ON public.staff_shift_log
FOR EACH ROW
EXECUTE FUNCTION calculate_shift_hours();

-- ============================================================
-- CREATE VIEWS FOR EASY REPORTING
-- ============================================================

-- Daily Sales Summary by Payment Method
CREATE OR REPLACE VIEW daily_sales_by_method AS
SELECT 
    DATE(s.sold_at) as sale_date,
    s.payment_method,
    COUNT(*) as transaction_count,
    COALESCE(SUM(s.total), 0) as total_amount,
    COALESCE(SUM(s.discount_amount), 0) as total_discount,
    COALESCE(SUM(s.tip_amount), 0) as total_tips
FROM public.sales s
GROUP BY DATE(s.sold_at), s.payment_method
ORDER BY sale_date DESC, payment_method;

-- Staff Daily Performance
CREATE OR REPLACE VIEW staff_daily_performance AS
SELECT 
    DATE(s.sold_at) as sale_date,
    s.staff_id,
    COALESCE(sr.name, 'Unknown') as staff_name,
    COUNT(s.id) as sales_count,
    COALESCE(SUM(s.total), 0) as sales_total,
    COALESCE(SUM(s.tip_amount), 0) as tips_earned
FROM public.sales s
LEFT JOIN public.staff_roster sr ON s.staff_id = sr.id
GROUP BY DATE(s.sold_at), s.staff_id, sr.name
ORDER BY sale_date DESC, sales_total DESC;

-- Best Selling Menu Items (This Month)
CREATE OR REPLACE VIEW best_sellers_month AS
SELECT 
    m.id,
    m.name,
    m.category,
    m.price,
    COALESCE(m.times_sold, 0) as units_sold
FROM public.menu m
WHERE m.active = true
ORDER BY m.times_sold DESC NULLS LAST;

GRANT SELECT ON public.daily_sales_by_method TO anon, authenticated, service_role;
GRANT SELECT ON public.staff_daily_performance TO anon, authenticated, service_role;
GRANT SELECT ON public.best_sellers_month TO anon, authenticated, service_role;

-- ============================================================
-- INSERT SAMPLE DATA (Optional - for testing)
-- ============================================================

-- Sample Ingredients
INSERT INTO public.ingredients (name, unit, stock_qty, cost_per_unit)
VALUES 
    ('Espresso Beans', 'kg', 10.00, 250.00),
    ('Whole Milk', 'L', 20.00, 60.00),
    ('Oat Milk', 'L', 15.00, 120.00),
    ('Almond Milk', 'L', 10.00, 150.00),
    ('Sugar', 'kg', 5.00, 40.00),
    ('Vanilla Syrup', 'L', 2.00, 300.00),
    ('Caramel Syrup', 'L', 2.00, 300.00),
    ('Hazelnut Syrup', 'L', 2.00, 300.00),
    ('Cups 12oz', 'box', 100.00, 150.00),
    ('Cups 16oz', 'box', 100.00, 200.00)
ON CONFLICT (name) DO NOTHING;

-- Sample Menu Items
INSERT INTO public.menu (name, category, price, recipe, active)
VALUES 
    ('Americano', 'Drinks', 120.00, '[{"ingredient_id":"espresso","qty":2}]'::jsonb, true),
    ('Latte', 'Drinks', 150.00, '[{"ingredient_id":"espresso","qty":1},{"ingredient_id":"milk","qty":1}]'::jsonb, true),
    ('Cappuccino', 'Drinks', 150.00, '[{"ingredient_id":"espresso","qty":1},{"ingredient_id":"milk","qty":1}]'::jsonb, true),
    ('Iced Coffee', 'Drinks', 140.00, '[{"ingredient_id":"espresso","qty":2}]'::jsonb, true),
    ('Vanilla Latte', 'Drinks', 180.00, '[{"ingredient_id":"espresso","qty":1},{"ingredient_id":"milk","qty":1},{"ingredient_id":"vanilla","qty":0.5}]'::jsonb, true)
ON CONFLICT (name) DO NOTHING;

-- Sample Staff
INSERT INTO public.staff_roster (name, email, staff_pin, role_title, start_date, daily_rate, daily_allowance, ot_rate_hourly, rest_day_rate, rest_day_ot_rate)
VALUES 
    ('Maria Santos', 'maria@mugna.coffee', '1234', 'Barista', CURRENT_DATE - INTERVAL '6 months', 600.00, 100.00, 150.00, 780.00, 1014.00),
    ('Juan Dela Cruz', 'juan@mugna.coffee', '5678', 'Cashier', CURRENT_DATE - INTERVAL '3 months', 550.00, 100.00, 137.50, 715.00, 929.50)
ON CONFLICT (email) DO NOTHING;

-- Sample Daily Float
INSERT INTO public.daily_floats (float_date, cash_float_today, cash_float_next_day, gcash_float_today, gcash_float_next_day, logged_by)
VALUES (CURRENT_DATE, 500.00, 500.00, 0.00, 0.00, 'System')
ON CONFLICT (float_date) DO NOTHING;

COMMIT;
