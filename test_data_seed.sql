-- Test Data Seed Script for Flock Manager
-- Generated: 2024-12-28
-- 
-- Run this against your SQLite database to populate with test data
-- WARNING: This will clear existing data!

-- ============================================
-- CLEAR EXISTING DATA
-- ============================================
DELETE FROM health_notes;
DELETE FROM medication_logs;
DELETE FROM income;
DELETE FROM expenses;
DELETE FROM egg_logs;
DELETE FROM bird_photos;
DELETE FROM birds;
DELETE FROM flocks;

-- ============================================
-- FLOCKS
-- ============================================
INSERT INTO flocks (id, name, description, icon, color, is_archived, created_at) VALUES
('flock-backyard-001', 'Backyard Layers', 'Main egg production flock - mixed breeds for colorful egg basket', '🥚', '#4CAF50', 0, datetime('now', '-180 days')),
('flock-bantams-002', 'Bantam Buddies', 'Small ornamental flock - mostly pets', '🐤', '#FF9800', 0, datetime('now', '-90 days')),
('flock-breeding-003', 'Marans Project', 'Black Copper Marans breeding for dark eggs', '🪺', '#795548', 0, datetime('now', '-60 days'));

-- ============================================
-- BIRDS
-- ============================================
INSERT INTO birds (id, flock_id, name, breed, breed_id, photo_primary, hatch_date, acquired_date, source, egg_color, status, status_date, status_notes, notes, created_at) VALUES
-- Backyard Layers
('bird-henrietta-001', 'flock-backyard-001', 'Henrietta', 'Barred Plymouth Rock', 'plymouth_rock_barred', NULL, date('now', '-540 days'), date('now', '-480 days'), 'Local feed store', 'Brown', 'active', NULL, NULL, 'Flock leader. First to the treat bowl, keeps everyone in line.', datetime('now', '-180 days')),
('bird-ginger-002', 'flock-backyard-001', 'Ginger', 'Buff Orpington', 'orpington_buff', NULL, date('now', '-510 days'), date('now', '-480 days'), 'Local feed store', 'Brown', 'active', NULL, NULL, 'Sweetest bird in the flock. Goes broody every spring.', datetime('now', '-180 days')),
('bird-pepper-003', 'flock-backyard-001', 'Pepper', 'Silver Laced Wyandotte', 'wyandotte', NULL, date('now', '-400 days'), date('now', '-380 days'), 'Neighbor hatched', 'Brown', 'active', NULL, NULL, 'Beautiful lacing. Consistent layer even in winter.', datetime('now', '-150 days')),
('bird-dottie-004', 'flock-backyard-001', 'Dottie', 'Speckled Sussex', 'sussex_speckled', NULL, date('now', '-380 days'), date('now', '-360 days'), 'Tractor Supply', 'Brown', 'active', NULL, NULL, 'Most curious bird - always investigating everything.', datetime('now', '-140 days')),
('bird-olive-005', 'flock-backyard-001', 'Olive', 'Olive Egger', 'olive_egger', NULL, date('now', '-320 days'), date('now', '-300 days'), 'Online hatchery', 'Olive', 'active', NULL, NULL, 'Beautiful olive eggs! F1 cross from Marans x Ameraucana.', datetime('now', '-120 days')),
('bird-hazel-006', 'flock-backyard-001', 'Hazel', 'Easter Egger', 'easter_egger', NULL, date('now', '-290 days'), date('now', '-270 days'), 'Local breeder', 'Blue', 'active', NULL, NULL, 'Lays pretty blue eggs. Has a cute beard and muffs.', datetime('now', '-100 days')),
('bird-maple-007', 'flock-backyard-001', 'Maple', 'Rhode Island Red', 'rhode_island_red', NULL, date('now', '-600 days'), date('now', '-560 days'), 'Friend''s farm', 'Brown', 'deceased', date('now', '-15 days'), 'Found in coop, passed peacefully in sleep. Good layer for 2 years.', 'Was our best layer. RIP sweet girl.', datetime('now', '-180 days')),
-- Bantams
('bird-pebbles-008', 'flock-bantams-002', 'Pebbles', 'Silkie', 'silkie', NULL, date('now', '-450 days'), date('now', '-420 days'), 'Poultry show', 'Cream', 'active', NULL, NULL, 'White silkie. Goes broody constantly - great foster mom.', datetime('now', '-90 days')),
('bird-cookie-009', 'flock-bantams-002', 'Cookie', 'Sebright', 'sebright', NULL, date('now', '-380 days'), date('now', '-350 days'), 'Poultry show', 'Cream', 'active', NULL, NULL, 'Golden Sebright. Tiny eggs but so pretty!', datetime('now', '-85 days')),
-- Breeding Flock
('bird-midnight-010', 'flock-breeding-003', 'Midnight', 'Black Copper Marans', 'marans_black_copper', NULL, date('now', '-300 days'), date('now', '-280 days'), 'Marans breeder - show quality', 'Chocolate', 'active', NULL, NULL, 'Best egg color in the flock. Eggs consistently #6-7 on Marans scale.', datetime('now', '-60 days')),
('bird-copper-011', 'flock-breeding-003', 'Copper', 'Black Copper Marans', 'marans_black_copper', NULL, date('now', '-310 days'), date('now', '-280 days'), 'Marans breeder - show quality', 'Chocolate', 'active', NULL, NULL, 'Beautiful copper hackles. Eggs lighter than Midnight (#5).', datetime('now', '-60 days')),
('bird-shadow-012', 'flock-breeding-003', 'Shadow', 'Black Copper Marans', 'marans_black_copper', NULL, date('now', '-295 days'), date('now', '-280 days'), 'Marans breeder - show quality', 'Chocolate', 'active', NULL, NULL, 'Rooster. Great temperament, protective but not aggressive.', datetime('now', '-60 days'));

-- ============================================
-- EGG LOGS (35 days)
-- ============================================

-- Day 0 (today)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-0 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-0 days')),
(lower(hex(randomblob(16))), date('now', '-0 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-0 days'));

-- Day 1
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-1 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-1 days')),
(lower(hex(randomblob(16))), date('now', '-1 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-1 days'));

-- Day 2
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-2 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-2 days')),
(lower(hex(randomblob(16))), date('now', '-2 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-2 days')),
(lower(hex(randomblob(16))), date('now', '-2 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-2 days'));

-- Day 3
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-3 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-3 days')),
(lower(hex(randomblob(16))), date('now', '-3 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-3 days')),
(lower(hex(randomblob(16))), date('now', '-3 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', 'Saved for incubator - great color', datetime('now', '-3 days'));

-- Day 4 (with bird attribution)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-4 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-4 days')),
(lower(hex(randomblob(16))), date('now', '-4 days'), 'flock-backyard-001', NULL, 3, 'large', 'normal', NULL, datetime('now', '-4 days')),
(lower(hex(randomblob(16))), date('now', '-4 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-4 days'));

-- Day 5 (olive egger attribution)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-5 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', 'Beautiful dark olive color today', datetime('now', '-5 days')),
(lower(hex(randomblob(16))), date('now', '-5 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-5 days')),
(lower(hex(randomblob(16))), date('now', '-5 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-5 days')),
(lower(hex(randomblob(16))), date('now', '-5 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-5 days'));

-- Day 6 (weekend - slightly lower)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-6 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-6 days')),
(lower(hex(randomblob(16))), date('now', '-6 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-6 days')),
(lower(hex(randomblob(16))), date('now', '-6 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-6 days'));

-- Day 7
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-7 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-7 days')),
(lower(hex(randomblob(16))), date('now', '-7 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-7 days'));

-- Day 8 (soft shell)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-8 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-8 days')),
(lower(hex(randomblob(16))), date('now', '-8 days'), 'flock-backyard-001', NULL, 3, 'large', 'softShell', 'Found one soft shell, might need more calcium', datetime('now', '-8 days')),
(lower(hex(randomblob(16))), date('now', '-8 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-8 days')),
(lower(hex(randomblob(16))), date('now', '-8 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-8 days'));

-- Day 9 (last before broody)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-9 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-9 days')),
(lower(hex(randomblob(16))), date('now', '-9 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', 'Last eggs before Pebbles went broody', datetime('now', '-9 days')),
(lower(hex(randomblob(16))), date('now', '-9 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-9 days'));

-- Days 10-14 (Pebbles broody - no bantam eggs)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-10 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', NULL, datetime('now', '-10 days')),
(lower(hex(randomblob(16))), date('now', '-10 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-10 days')),
(lower(hex(randomblob(16))), date('now', '-10 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-10 days')),

(lower(hex(randomblob(16))), date('now', '-11 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-11 days')),
(lower(hex(randomblob(16))), date('now', '-11 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-11 days')),

(lower(hex(randomblob(16))), date('now', '-12 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-12 days')),
(lower(hex(randomblob(16))), date('now', '-12 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-12 days')),
(lower(hex(randomblob(16))), date('now', '-12 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-12 days')),

(lower(hex(randomblob(16))), date('now', '-13 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-13 days')),
(lower(hex(randomblob(16))), date('now', '-13 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-13 days')),

(lower(hex(randomblob(16))), date('now', '-14 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-14 days')),
(lower(hex(randomblob(16))), date('now', '-14 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-14 days'));

-- Day 15+ (after Maple passed - one fewer bird)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-15 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', NULL, datetime('now', '-15 days')),
(lower(hex(randomblob(16))), date('now', '-15 days'), 'flock-backyard-001', NULL, 3, 'large', 'normal', NULL, datetime('now', '-15 days')),
(lower(hex(randomblob(16))), date('now', '-15 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-15 days')),

(lower(hex(randomblob(16))), date('now', '-16 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-16 days')),
(lower(hex(randomblob(16))), date('now', '-16 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-16 days')),
(lower(hex(randomblob(16))), date('now', '-16 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-16 days')),

(lower(hex(randomblob(16))), date('now', '-17 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-17 days')),
(lower(hex(randomblob(16))), date('now', '-17 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-17 days')),

(lower(hex(randomblob(16))), date('now', '-18 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-18 days')),
(lower(hex(randomblob(16))), date('now', '-18 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-18 days')),

(lower(hex(randomblob(16))), date('now', '-19 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-19 days')),
(lower(hex(randomblob(16))), date('now', '-19 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-19 days'));

-- Days 20-22 (cold snap - reduced production)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-20 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', NULL, datetime('now', '-20 days')),
(lower(hex(randomblob(16))), date('now', '-20 days'), 'flock-backyard-001', NULL, 2, 'large', 'normal', 'Cold weather affecting production', datetime('now', '-20 days')),
(lower(hex(randomblob(16))), date('now', '-20 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-20 days')),

(lower(hex(randomblob(16))), date('now', '-21 days'), 'flock-backyard-001', NULL, 3, 'large', 'normal', 'Cold snap continues', datetime('now', '-21 days')),
(lower(hex(randomblob(16))), date('now', '-21 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-21 days')),

(lower(hex(randomblob(16))), date('now', '-22 days'), 'flock-backyard-001', NULL, 3, 'large', 'normal', 'Warming up finally', datetime('now', '-22 days')),
(lower(hex(randomblob(16))), date('now', '-22 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', 'Pebbles breaking out of broody!', datetime('now', '-22 days')),
(lower(hex(randomblob(16))), date('now', '-22 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-22 days'));

-- Days 23-34 (normal production resumes)
INSERT INTO egg_logs (id, date, flock_id, bird_id, count, size, quality, notes, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-23 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-23 days')),
(lower(hex(randomblob(16))), date('now', '-23 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-23 days')),
(lower(hex(randomblob(16))), date('now', '-23 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-23 days')),

(lower(hex(randomblob(16))), date('now', '-24 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-24 days')),
(lower(hex(randomblob(16))), date('now', '-24 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-24 days')),
(lower(hex(randomblob(16))), date('now', '-24 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-24 days')),
(lower(hex(randomblob(16))), date('now', '-24 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-24 days')),

-- Day 25 (double yolker!)
(lower(hex(randomblob(16))), date('now', '-25 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', NULL, datetime('now', '-25 days')),
(lower(hex(randomblob(16))), date('now', '-25 days'), 'flock-backyard-001', NULL, 4, 'jumbo', 'doubleYolk', 'Double yolker from one of the Orpingtons!', datetime('now', '-25 days')),
(lower(hex(randomblob(16))), date('now', '-25 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-25 days')),

(lower(hex(randomblob(16))), date('now', '-26 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-26 days')),
(lower(hex(randomblob(16))), date('now', '-26 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-26 days')),
(lower(hex(randomblob(16))), date('now', '-26 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-26 days')),

(lower(hex(randomblob(16))), date('now', '-27 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-27 days')),
(lower(hex(randomblob(16))), date('now', '-27 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-27 days')),
(lower(hex(randomblob(16))), date('now', '-27 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-27 days')),

(lower(hex(randomblob(16))), date('now', '-28 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-28 days')),
(lower(hex(randomblob(16))), date('now', '-28 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-28 days')),
(lower(hex(randomblob(16))), date('now', '-28 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-28 days')),

(lower(hex(randomblob(16))), date('now', '-29 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-29 days')),
(lower(hex(randomblob(16))), date('now', '-29 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-29 days')),
(lower(hex(randomblob(16))), date('now', '-29 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-29 days')),

(lower(hex(randomblob(16))), date('now', '-30 days'), 'flock-backyard-001', 'bird-olive-005', 1, 'medium', 'normal', NULL, datetime('now', '-30 days')),
(lower(hex(randomblob(16))), date('now', '-30 days'), 'flock-backyard-001', NULL, 4, 'large', 'normal', NULL, datetime('now', '-30 days')),
(lower(hex(randomblob(16))), date('now', '-30 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-30 days')),
(lower(hex(randomblob(16))), date('now', '-30 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-30 days')),

(lower(hex(randomblob(16))), date('now', '-31 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-31 days')),
(lower(hex(randomblob(16))), date('now', '-31 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-31 days')),

(lower(hex(randomblob(16))), date('now', '-32 days'), 'flock-backyard-001', 'bird-henrietta-001', 1, 'large', 'normal', NULL, datetime('now', '-32 days')),
(lower(hex(randomblob(16))), date('now', '-32 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-32 days')),
(lower(hex(randomblob(16))), date('now', '-32 days'), 'flock-bantams-002', NULL, 1, 'small', 'normal', NULL, datetime('now', '-32 days')),
(lower(hex(randomblob(16))), date('now', '-32 days'), 'flock-breeding-003', NULL, 1, 'large', 'normal', NULL, datetime('now', '-32 days')),

(lower(hex(randomblob(16))), date('now', '-33 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-33 days')),
(lower(hex(randomblob(16))), date('now', '-33 days'), 'flock-bantams-002', NULL, 2, 'small', 'normal', NULL, datetime('now', '-33 days')),
(lower(hex(randomblob(16))), date('now', '-33 days'), 'flock-breeding-003', NULL, 2, 'large', 'normal', NULL, datetime('now', '-33 days')),

(lower(hex(randomblob(16))), date('now', '-34 days'), 'flock-backyard-001', NULL, 5, 'large', 'normal', NULL, datetime('now', '-34 days')),
(lower(hex(randomblob(16))), date('now', '-34 days'), 'flock-breeding-003', 'bird-midnight-010', 1, 'large', 'normal', NULL, datetime('now', '-34 days'));

-- ============================================
-- EXPENSES
-- ============================================
INSERT INTO expenses (id, date, amount, category, description, flock_id, is_recurring, recurring_interval, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-2 days'), 32.99, 'feed', '50lb layer pellets - Purina', NULL, 0, NULL, datetime('now', '-2 days')),
(lower(hex(randomblob(16))), date('now', '-5 days'), 8.99, 'feed', 'Mealworm treats 5lb bag', NULL, 0, NULL, datetime('now', '-5 days')),
(lower(hex(randomblob(16))), date('now', '-8 days'), 15.49, 'bedding', 'Pine shavings - large bale', 'flock-backyard-001', 0, NULL, datetime('now', '-8 days')),
(lower(hex(randomblob(16))), date('now', '-12 days'), 24.99, 'supplies', 'Heated waterer base for winter', NULL, 0, NULL, datetime('now', '-12 days')),
(lower(hex(randomblob(16))), date('now', '-18 days'), 12.95, 'medical', 'Poultry VetRx - respiratory support', 'flock-backyard-001', 0, NULL, datetime('now', '-18 days')),
(lower(hex(randomblob(16))), date('now', '-22 days'), 89.00, 'equipment', 'New nest boxes (3 pack)', 'flock-backyard-001', 0, NULL, datetime('now', '-22 days')),
(lower(hex(randomblob(16))), date('now', '-25 days'), 6.49, 'supplies', 'Oyster shell calcium supplement', NULL, 0, NULL, datetime('now', '-25 days')),
(lower(hex(randomblob(16))), date('now', '-30 days'), 32.99, 'feed', '50lb layer pellets - Purina', NULL, 1, 'monthly', datetime('now', '-30 days')),
(lower(hex(randomblob(16))), date('now', '-32 days'), 45.00, 'other', 'Fertile hatching eggs (Marans) - 6 pack', 'flock-breeding-003', 0, NULL, datetime('now', '-32 days'));

-- ============================================
-- INCOME
-- ============================================
INSERT INTO income (id, date, amount, description, egg_count, created_at) VALUES
(lower(hex(randomblob(16))), date('now', '-3 days'), 6.00, 'Egg sale to neighbor - 1 dozen', 12, datetime('now', '-3 days')),
(lower(hex(randomblob(16))), date('now', '-10 days'), 12.00, 'Egg sale - 2 dozen mixed colors', 24, datetime('now', '-10 days')),
(lower(hex(randomblob(16))), date('now', '-17 days'), 18.00, 'Egg sale at farmers market', 36, datetime('now', '-17 days')),
(lower(hex(randomblob(16))), date('now', '-24 days'), 6.00, 'Coworker egg sale', 12, datetime('now', '-24 days'));

-- ============================================
-- MEDICATION LOGS
-- ============================================
INSERT INTO medication_logs (id, bird_id, flock_id, medication_name, dosage, start_date, end_date, withdrawal_days, notes, created_at) VALUES
(lower(hex(randomblob(16))), NULL, 'flock-backyard-001', 'Corid (Amprolium)', '9.5ml per gallon water', date('now', '-45 days'), date('now', '-40 days'), 0, 'Preventive treatment - new birds introduced', datetime('now', '-45 days')),
(lower(hex(randomblob(16))), 'bird-ginger-002', 'flock-backyard-001', 'VetRx', '2 drops under wing, 2 drops in water', date('now', '-18 days'), date('now', '-14 days'), 0, 'Minor respiratory wheeze, cleared up quickly', datetime('now', '-18 days')),
(lower(hex(randomblob(16))), NULL, 'flock-backyard-001', 'SafeGuard (Fenbendazole)', '0.5ml per bird orally', date('now', '-60 days'), date('now', '-55 days'), 14, 'Quarterly deworming', datetime('now', '-60 days')),
-- Active withdrawal!
(lower(hex(randomblob(16))), NULL, 'flock-breeding-003', 'Valbazen', '0.5ml per bird', date('now', '-5 days'), date('now', '-3 days'), 14, 'Pre-breeding deworming', datetime('now', '-5 days'));

-- ============================================
-- HEALTH NOTES
-- ============================================
INSERT INTO health_notes (id, bird_id, date, type, description, created_at) VALUES
(lower(hex(randomblob(16))), 'bird-ginger-002', date('now', '-18 days'), 'symptom', 'Slight wheeze noticed, no discharge. Eating and drinking normally.', datetime('now', '-18 days')),
(lower(hex(randomblob(16))), 'bird-ginger-002', date('now', '-16 days'), 'treatment', 'Started VetRx treatment. Applied under wings and added to water.', datetime('now', '-16 days')),
(lower(hex(randomblob(16))), 'bird-ginger-002', date('now', '-14 days'), 'observation', 'Wheeze completely cleared. Back to normal.', datetime('now', '-14 days')),
(lower(hex(randomblob(16))), 'bird-pebbles-008', date('now', '-10 days'), 'observation', 'Going broody - puffed up, refusing to leave nest box. Moved to broody breaker.', datetime('now', '-10 days')),
(lower(hex(randomblob(16))), 'bird-pebbles-008', date('now', '-5 days'), 'observation', 'Still broody after 5 days in wire cage. Trying frozen water bottle method.', datetime('now', '-5 days')),
(lower(hex(randomblob(16))), 'bird-maple-007', date('now', '-16 days'), 'symptom', 'Slower than usual, staying on roost more. Eating less. Age catching up?', datetime('now', '-16 days')),
(lower(hex(randomblob(16))), 'bird-maple-007', date('now', '-15 days'), 'other', 'Found passed away on roost this morning. Peaceful. She was a good girl.', datetime('now', '-15 days')),
(lower(hex(randomblob(16))), 'bird-henrietta-001', date('now', '-30 days'), 'observation', 'Annual health check - good weight, clear eyes, healthy comb. Top condition.', datetime('now', '-30 days')),
(lower(hex(randomblob(16))), 'bird-midnight-010', date('now', '-7 days'), 'observation', 'Eggs consistently #6-7 on Marans color scale. Great breeding candidate.', datetime('now', '-7 days'));

-- ============================================
-- VERIFY DATA
-- ============================================
SELECT 'Flocks: ' || COUNT(*) FROM flocks;
SELECT 'Birds: ' || COUNT(*) || ' (' || SUM(CASE WHEN status = 'active' THEN 1 ELSE 0 END) || ' active)' FROM birds;
SELECT 'Egg logs: ' || COUNT(*) || ' entries, ' || SUM(count) || ' total eggs' FROM egg_logs;
SELECT 'Expenses: ' || COUNT(*) || ' entries, $' || ROUND(SUM(amount), 2) || ' total' FROM expenses;
SELECT 'Income: ' || COUNT(*) || ' entries, $' || ROUND(SUM(amount), 2) || ' total' FROM income;
SELECT 'Medication logs: ' || COUNT(*) FROM medication_logs;
SELECT 'Health notes: ' || COUNT(*) FROM health_notes;
