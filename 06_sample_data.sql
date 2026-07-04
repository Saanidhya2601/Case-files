-- ============================================================
-- Boston Crime Reports Database
-- File: 06_sample_data.sql
-- Description: Sample data for testing and demonstration
--              (use this if you don't yet have the CSV)
-- ============================================================

-- Offense codes
INSERT INTO crimes.offense_codes (offense_code, offense_description) VALUES
    (111,  'MURDER, NON-NEGLIGIENT MANSLAUGHTER'),
    (301,  'ROBBERY - STREET'),
    (401,  'AGGRAVATED ASSAULT'),
    (520,  'BURGLARY - RESIDENTIAL - NIGHT'),
    (619,  'LARCENY THEFT FROM BUILDING'),
    (724,  'AUTO THEFT'),
    (801,  'DRUG - POSSESSION/ SALE'),
    (900,  'VANDALISM'),
    (1001, 'FRAUD - CREDIT CARD / ATM FRAUD'),
    (1402, 'DISORDERLY CONDUCT')
ON CONFLICT DO NOTHING;

-- Districts
INSERT INTO crimes.districts (district_id, district_name) VALUES
    ('A1',  'Downtown'),
    ('A15', 'Charlestown'),
    ('A7',  'East Boston'),
    ('B2',  'Roxbury'),
    ('B3',  'Mattapan'),
    ('C6',  'South Boston'),
    ('C11', 'Dorchester'),
    ('D4',  'South End'),
    ('D14', 'Brighton'),
    ('E5',  'West Roxbury'),
    ('E13', 'Jamaica Plain'),
    ('E18', 'Hyde Park')
ON CONFLICT DO NOTHING;

-- Streets
INSERT INTO crimes.streets (street_name) VALUES
    ('WASHINGTON ST'),
    ('TREMONT ST'),
    ('BLUE HILL AVE'),
    ('COLUMBIA RD'),
    ('COMMONWEALTH AVE'),
    ('BOYLSTON ST'),
    ('HARRISON AVE'),
    ('MORTON ST'),
    ('WARREN ST'),
    ('CENTRE ST')
ON CONFLICT DO NOTHING;

-- Crime reports (sample incidents)
INSERT INTO crimes.reports (
    incident_number, offense_code, offense_code_group,
    district_id, reporting_area, shooting,
    occurred_on_date, year, month, day_of_week, hour,
    street_id, lat, long
) VALUES
    ('I192073798', 619,  'Larceny',              'B2',  806,  'N', '2019-07-04 09:00:00', 2019, 7,  'Thursday',  9,  1, 42.3201, -71.0839),
    ('I182031735', 301,  'Robbery',              'C11', 494,  'N', '2018-09-02 22:30:00', 2018, 9,  'Sunday',    22, 3, 42.3180, -71.0752),
    ('I162069653', 401,  'Aggravated Assault',   'B2',  700,  'Y', '2016-06-26 01:15:00', 2016, 6,  'Sunday',    1,  2, 42.3270, -71.0837),
    ('I172097048', 724,  'Motor Vehicle Accident','A1',  118,  'N', '2017-08-31 08:45:00', 2017, 8,  'Thursday',  8,  5, 42.3594, -71.0587),
    ('I152071047', 801,  'Drug Violation',        'D4',  208,  'N', '2015-04-13 17:00:00', 2015, 4,  'Monday',    17, 7, 42.3451, -71.0727),
    ('I192090001', 520,  'Burglary',              'E5',  982,  'N', '2019-10-17 03:20:00', 2019, 10, 'Thursday',  3,  9, 42.2901, -71.1601),
    ('I172030055', 111,  'Homicide',              'B3',  540,  'Y', '2017-02-09 23:55:00', 2017, 2,  'Thursday',  23, 4, 42.2771, -71.0910),
    ('I162045600', 900,  'Vandalism',             'A15', 250,  'N', '2016-03-22 14:00:00', 2016, 3,  'Tuesday',   14, 6, 42.3786, -71.0600),
    ('I182044120', 1001, 'Fraud',                 'D14', 710,  'N', '2018-05-30 10:30:00', 2018, 5,  'Wednesday', 10, 10, 42.3529, -71.1563),
    ('I192055678', 1402, 'Disorderly Conduct',    'C6',  180,  'N', '2019-01-12 21:00:00', 2019, 1,  'Saturday',  21, 8, 42.3388, -71.0476),
    ('I162100002', 401,  'Aggravated Assault',    'B2',  720,  'Y', '2016-11-05 00:30:00', 2016, 11, 'Saturday',  0,  2, 42.3255, -71.0820),
    ('I172055543', 619,  'Larceny',               'A1',  120,  'N', '2017-12-24 16:45:00', 2017, 12, 'Sunday',    16, 5, 42.3561, -71.0611),
    ('I182077900', 301,  'Robbery',               'C11', 510,  'Y', '2018-07-14 20:00:00', 2018, 7,  'Saturday',  20, 3, 42.3145, -71.0777),
    ('I192033100', 724,  'Motor Vehicle Accident','B3',  560,  'N', '2019-04-01 07:15:00', 2019, 4,  'Monday',    7,  4, 42.2799, -71.0923),
    ('I152099010', 801,  'Drug Violation',         'E13', 840,  'N', '2015-09-09 13:50:00', 2015, 9,  'Wednesday', 13, 1, 42.3098, -71.1132)
ON CONFLICT DO NOTHING;

-- Quick verification
SELECT
    r.incident_number,
    oc.offense_description,
    d.district_name,
    st.street_name,
    r.shooting,
    r.occurred_on_date
FROM crimes.reports r
JOIN crimes.offense_codes oc ON r.offense_code = oc.offense_code
LEFT JOIN crimes.districts d  ON r.district_id  = d.district_id
LEFT JOIN crimes.streets   st ON r.street_id    = st.street_id
ORDER BY r.occurred_on_date DESC;
