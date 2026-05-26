-- ============================================================
-- PROJECT   : GMC Education Portal
-- DATABASE  : edu_portal
-- VERSION   : PostgreSQL 18
-- CREATED   : 2024
-- NOTE      : uuidv7() use kiya hai gen_random_uuid() ki jagah
--             kyunki PostgreSQL 18 mein timestamp-ordered UUID
--             milta hai — better index performance ke liye
-- ============================================================


-- ============================================================
-- STEP 1: DATABASE BANAO
-- ============================================================

-- UTF8 encoding isliye — Gujarati, Hindi, English teeno support kare
CREATE DATABASE edu_portal
  ENCODING 'UTF8'
  LC_COLLATE 'en_US.UTF-8'
  LC_CTYPE 'en_US.UTF-8';


-- ============================================================
-- TABLE 1: municipalities
-- Sabse top level — GMC, AMC jaise bodies
-- Koi foreign key dependency nahi — isliye pehle banate hain
-- ============================================================

CREATE TABLE municipalities (
  id         UUID PRIMARY KEY DEFAULT uuidv7(), -- unique ID, timestamp-ordered
  name       VARCHAR(255) NOT NULL,             -- "Gandhinagar Municipal Corporation"
  name_gu    VARCHAR(255),                      -- Gujarati name (optional)
  state      VARCHAR(100) NOT NULL DEFAULT 'Gujarat', -- default Gujarat
  code       VARCHAR(50) UNIQUE NOT NULL,       -- unique code jaise "GMC-GN-001"
  is_active  BOOLEAN DEFAULT TRUE,              -- active hai ya nahi
  created_at TIMESTAMPTZ DEFAULT NOW(),         -- kab banaya — UTC mein store
  updated_at TIMESTAMPTZ DEFAULT NOW()          -- kab update hua
);


-- ============================================================
-- TABLE 2: schools
-- Har school ek municipality ke under hoti hai
-- municipalities table pehle chahiye — foreign key ke liye
-- ============================================================

CREATE TABLE schools (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  municipality_id  UUID NOT NULL REFERENCES municipalities(id), -- konsi municipality
  name             VARCHAR(255) NOT NULL,           -- school ka naam
  name_gu          VARCHAR(255),                    -- Gujarati naam
  code             VARCHAR(50) UNIQUE NOT NULL,     -- unique code "GMC-SCH-0001"
  address          TEXT,                            -- school ka address
  ward_number      VARCHAR(50),                     -- ward number
  principal_id     UUID,                            -- principal ka user ID (baad mein FK add hoga)
  medium           VARCHAR(50) DEFAULT 'Gujarati',  -- teaching medium
  board            VARCHAR(100) DEFAULT 'GSEB',     -- education board
  established_year INTEGER,                         -- kab shuru hui school
  phone            VARCHAR(20),                     -- contact number
  status           VARCHAR(20) DEFAULT 'ACTIVE'
                   CHECK (status IN ('ACTIVE', 'INACTIVE', 'ARCHIVED')), -- school ki state
  storage_quota_mb INTEGER DEFAULT 51200,           -- 50GB storage limit
  storage_used_mb  INTEGER DEFAULT 0,               -- abhi kitna use hua
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

-- municipality ke basis pe fast search ke liye index
CREATE INDEX idx_schools_municipality ON schools(municipality_id);


-- ============================================================
-- TABLE 3: users
-- Saare roles ek hi table mein — TEACHER, STUDENT, PARENT, etc.
-- schools aur municipalities dono pe depend karta hai
-- ============================================================

CREATE TABLE users (
  id                 UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id          UUID REFERENCES schools(id),          -- NULL ho sakta hai SUPER_ADMIN ke liye
  municipality_id    UUID REFERENCES municipalities(id),   -- NULL ho sakta hai
  role               VARCHAR(30) NOT NULL
                     CHECK (role IN (
                       'SUPER_ADMIN',    -- highest level
                       'GMC_ADMIN',      -- municipality level
                       'PRINCIPAL',      -- school head
                       'TEACHER',        -- class teacher
                       'STUDENT',        -- student
                       'PARENT'          -- parent
                     )),
  name               VARCHAR(255) NOT NULL,       -- full name
  name_gu            VARCHAR(255),                -- Gujarati naam
  email              VARCHAR(255) UNIQUE,         -- teachers aur upar ke liye
  phone              VARCHAR(20),                 -- parents + teachers
  student_code       VARCHAR(50) UNIQUE,          -- sirf students ke liye: "GJ-2024-SCH01-0001"
  password_hash      VARCHAR(255),                -- bcrypt hashed password
  pin_hash           VARCHAR(255),                -- students ke liye 6-digit PIN hash
  token_version      INTEGER DEFAULT 0,           -- increment karo to invalidate all JWTs
  status             VARCHAR(20) DEFAULT 'ACTIVE'
                     CHECK (status IN (
                       'ACTIVE',
                       'INACTIVE',
                       'SUSPENDED',
                       'PENDING_APPROVAL'
                     )),
  is_verified        BOOLEAN DEFAULT FALSE,       -- verified hai ya nahi
  last_login_at      TIMESTAMPTZ,                 -- aakhri baar kab login kiya
  failed_login_count INTEGER DEFAULT 0,           -- galat password kitni baar
  locked_until       TIMESTAMPTZ,                 -- kab tak locked hai account
  language           VARCHAR(10) DEFAULT 'gu'
                     CHECK (language IN ('gu', 'en')), -- preferred language
  created_at         TIMESTAMPTZ DEFAULT NOW(),
  updated_at         TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_users_school ON users(school_id);       -- school se users dhundne ke liye
CREATE INDEX idx_users_role ON users(role);              -- role se filter ke liye
CREATE INDEX idx_users_student_code ON users(student_code); -- student code se dhundne ke liye

-- Ab schools mein principal_id ka FK add karo
-- Pehle nahi kar sakte the — users table pehle nahi thi
ALTER TABLE schools
ADD CONSTRAINT fk_principal
FOREIGN KEY (principal_id) REFERENCES users(id);


-- ============================================================
-- TABLE 4: academic_years
-- Har school ka apna academic year hota hai — "2024-25"
-- ============================================================

CREATE TABLE academic_years (
  id          UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id   UUID NOT NULL REFERENCES schools(id), -- konsi school ka year
  name        VARCHAR(50) NOT NULL,                 -- "2024-25"
  start_date  DATE NOT NULL,                        -- 2024-06-01
  end_date    DATE NOT NULL,                        -- 2025-03-31
  is_current  BOOLEAN DEFAULT FALSE,               -- abhi chal raha hai?
  is_archived BOOLEAN DEFAULT FALSE,               -- purana ho gaya?
  archived_at TIMESTAMPTZ,                          -- kab archive kiya
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (school_id, name) -- ek school mein ek naam ek baar
);

-- Partial unique index — ek school ka sirf ek current year ho sakta hai
-- WHERE clause ki wajah se sirf is_current=TRUE rows pe apply hota hai
CREATE UNIQUE INDEX one_current_year_per_school
ON academic_years (school_id)
WHERE is_current = TRUE;


-- ============================================================
-- TABLE 5: subjects
-- Har school apne subjects define karti hai
-- ============================================================

CREATE TABLE subjects (
  id          UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id   UUID NOT NULL REFERENCES schools(id), -- konsi school ka subject
  name        VARCHAR(255) NOT NULL,                -- "Mathematics"
  name_gu     VARCHAR(255),                         -- "ગણિત"
  code        VARCHAR(50),                          -- "MATH-8"
  grade_level INTEGER,                              -- 8 (Class 8 ke liye)
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (school_id, code) -- ek school mein ek code ek baar
);


-- ============================================================
-- TABLE 6: classes
-- Har school ki classes — 8A, 8B, 9A, etc.
-- ============================================================

CREATE TABLE classes (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id        UUID NOT NULL REFERENCES schools(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id), -- konse year ki class
  name             VARCHAR(50) NOT NULL,       -- "8A"
  grade            INTEGER NOT NULL,           -- 8
  section          VARCHAR(10),                -- "A"
  class_teacher_id UUID REFERENCES users(id), -- class teacher kaun hai
  room_number      VARCHAR(20),               -- room number
  capacity         INTEGER DEFAULT 40,        -- kitne students aa sakte hain
  created_at       TIMESTAMPTZ DEFAULT NOW(),

  -- ek school mein ek saal mein same grade+section dobara nahi ban sakta
  UNIQUE (school_id, academic_year_id, grade, section)
);

CREATE INDEX idx_classes_school ON classes(school_id);
CREATE INDEX idx_classes_year ON classes(academic_year_id);


-- ============================================================
-- TABLE 7: class_subjects
-- Schema ki HEART — class + subject + teacher ka mapping
-- "8B mein Mathematics Ramesh padhata hai"
-- ============================================================

CREATE TABLE class_subjects (
  id         UUID PRIMARY KEY DEFAULT uuidv7(),
  class_id   UUID NOT NULL REFERENCES classes(id),   -- konsi class
  subject_id UUID NOT NULL REFERENCES subjects(id),  -- konsa subject
  teacher_id UUID NOT NULL REFERENCES users(id),     -- kaun padhata hai
  school_id  UUID NOT NULL REFERENCES schools(id),   -- RLS ke liye denormalized
  is_active  BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW(),

  -- ek class mein ek subject sirf ek teacher padha sakta hai
  UNIQUE (class_id, subject_id)
);

CREATE INDEX idx_class_subjects_teacher ON class_subjects(teacher_id);
CREATE INDEX idx_class_subjects_class ON class_subjects(class_id);


-- ============================================================
-- TABLE 8: student_classes
-- Student ka class mein enrollment
-- ============================================================

CREATE TABLE student_classes (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  student_id       UUID NOT NULL REFERENCES users(id),           -- kaun sa student
  class_id         UUID NOT NULL REFERENCES classes(id),         -- kaun si class
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),  -- konse saal
  school_id        UUID NOT NULL REFERENCES schools(id),
  roll_number      VARCHAR(20),              -- class mein roll number
  enrolled_at      DATE NOT NULL DEFAULT CURRENT_DATE, -- kab enroll hua
  left_at          DATE,                     -- kab chhoda (transfer/dropout)
  status           VARCHAR(20) DEFAULT 'ACTIVE'
                   CHECK (status IN (
                     'ACTIVE',
                     'TRANSFERRED',
                     'DROPPED',
                     'GRADUATED'
                   )),

  UNIQUE (class_id, roll_number),        -- ek class mein roll number unique
  UNIQUE (student_id, academic_year_id)  -- ek student ek saal mein sirf ek class
);


-- ============================================================
-- TABLE 9: student_parents
-- Student aur parent ka link
-- ============================================================

CREATE TABLE student_parents (
  id          UUID PRIMARY KEY DEFAULT uuidv7(),
  student_id  UUID NOT NULL REFERENCES users(id),  -- kaun sa student
  parent_id   UUID NOT NULL REFERENCES users(id),  -- kaun sa parent
  relation    VARCHAR(50) DEFAULT 'Parent'
              CHECK (relation IN (
                'Father', 'Mother', 'Guardian', 'Parent'
              )),
  is_primary  BOOLEAN DEFAULT TRUE,                -- SMS is ko jaayega
  verified_by UUID REFERENCES users(id),           -- teacher jisne verify kiya
  verified_at TIMESTAMPTZ,
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (student_id, parent_id) -- ek student-parent link ek baar
);


-- ============================================================
-- TABLE 10: timetable_slots
-- Har class ka timetable — Monday Period 1 mein kya hai
-- ============================================================

CREATE TABLE timetable_slots (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  class_id         UUID NOT NULL REFERENCES classes(id),
  class_subject_id UUID NOT NULL REFERENCES class_subjects(id), -- kaun sa subject+teacher
  school_id        UUID NOT NULL REFERENCES schools(id),
  day_of_week      INTEGER NOT NULL CHECK (day_of_week BETWEEN 1 AND 6), -- 1=Mon, 6=Sat
  period_number    INTEGER NOT NULL,   -- period 1, 2, 3...
  start_time       TIME NOT NULL,      -- 08:00
  end_time         TIME NOT NULL,      -- 08:45
  effective_from   DATE NOT NULL,      -- kab se valid hai yeh slot
  effective_until  DATE,               -- kab tak (NULL = abhi bhi valid)
  created_at       TIMESTAMPTZ DEFAULT NOW(),

  -- ek class ka ek din ka ek period ek baar
  UNIQUE (class_id, day_of_week, period_number, effective_from)
);

-- FUNCTION: Teacher double booking rokne ke liye
-- Ek teacher ek saath do classes mein nahi padha sakta
CREATE OR REPLACE FUNCTION check_teacher_double_booking()
RETURNS TRIGGER AS $$
DECLARE
  new_teacher_id UUID;   -- nayi slot ka teacher
  conflict_found BOOLEAN; -- clash hai ya nahi
BEGIN
  -- nayi slot ka teacher_id nikalo class_subjects se
  SELECT teacher_id INTO new_teacher_id
  FROM class_subjects
  WHERE id = NEW.class_subject_id;

  -- check karo kya yeh teacher is din is period mein pehle se book hai
  SELECT EXISTS (
    SELECT 1
    FROM timetable_slots ts
    JOIN class_subjects cs ON ts.class_subject_id = cs.id
    WHERE cs.teacher_id = new_teacher_id
      AND ts.day_of_week = NEW.day_of_week      -- same din
      AND ts.period_number = NEW.period_number  -- same period
      AND ts.id != NEW.id                       -- khud ko ignore karo
      AND (ts.effective_until IS NULL OR NEW.effective_from <= ts.effective_until)
      AND (NEW.effective_until IS NULL OR ts.effective_from <= NEW.effective_until)
  ) INTO conflict_found;

  -- agar clash mila toh error do
  IF conflict_found THEN
    RAISE EXCEPTION 'Teacher % is already booked in another class for day %, period %',
      new_teacher_id, NEW.day_of_week, NEW.period_number;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: INSERT ya UPDATE se pehle check karo
CREATE TRIGGER enforce_no_teacher_double_booking
BEFORE INSERT OR UPDATE ON timetable_slots
FOR EACH ROW EXECUTE FUNCTION check_teacher_double_booking();


-- ============================================================
-- TABLE 11: school_holidays
-- Har school ki holidays — Diwali, Annual Day, etc.
-- ============================================================

CREATE TABLE school_holidays (
  id         UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id  UUID NOT NULL REFERENCES schools(id),
  date       DATE NOT NULL,           -- holiday ki date
  name       VARCHAR(255) NOT NULL,   -- "Diwali Holiday"
  name_gu    VARCHAR(255),            -- Gujarati naam
  type       VARCHAR(50) DEFAULT 'PUBLIC'
             CHECK (type IN (
               'PUBLIC',           -- government holiday
               'SCHOOL_SPECIFIC',  -- sirf is school ki
               'EMERGENCY'         -- sudden closure
             )),
  created_by UUID REFERENCES users(id), -- kisne add kiya
  created_at TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (school_id, date) -- ek school ek date pe sirf ek holiday
);


-- ============================================================
-- TABLE 12: attendance_records
-- Ek class ka ek din ka attendance "sheet"
-- ============================================================

CREATE TABLE attendance_records (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  class_id         UUID NOT NULL REFERENCES classes(id),
  school_id        UUID NOT NULL REFERENCES schools(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  date             DATE NOT NULL,          -- kis din ka attendance
  submitted_by     UUID NOT NULL REFERENCES users(id), -- teacher ne submit kiya
  submitted_at     TIMESTAMPTZ,            -- kab submit hua
  status           VARCHAR(20) DEFAULT 'DRAFT'
                   CHECK (status IN (
                     'DRAFT',      -- abhi bhar raha hai
                     'SUBMITTED',  -- submit ho gaya
                     'APPROVED',   -- principal ne approve kiya
                     'CORRECTED'   -- correction hua
                   )),
  correction_reason TEXT,           -- kyun correct kiya
  corrected_by     UUID REFERENCES users(id), -- kisne correct kiya
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (class_id, date) -- ek class ka ek din ka sirf ek record
);

CREATE INDEX idx_attendance_class_date ON attendance_records(class_id, date); -- fast date search
CREATE INDEX idx_attendance_school ON attendance_records(school_id);          -- school ke saare records


-- ============================================================
-- TABLE 13: attendance_entries
-- Har student ki ek din ki entry — PRESENT/ABSENT/LATE
-- ============================================================

CREATE TABLE attendance_entries (
  id                   UUID PRIMARY KEY DEFAULT uuidv7(),
  attendance_record_id UUID NOT NULL REFERENCES attendance_records(id) ON DELETE CASCADE,
  -- agar record delete ho toh entries bhi delete ho jaayein
  student_id           UUID NOT NULL REFERENCES users(id),
  school_id            UUID NOT NULL REFERENCES schools(id),
  status               VARCHAR(20) NOT NULL
                       CHECK (status IN (
                         'PRESENT',  -- aaya
                         'ABSENT',   -- nahi aaya
                         'LATE',     -- late aaya
                         'EXCUSED',  -- maafi ke saath absent
                         'HOLIDAY'   -- holiday tha
                       )),
  remark               TEXT,       -- extra note
  created_at           TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (attendance_record_id, student_id) -- ek student ek din ek entry
);

CREATE INDEX idx_attendance_entries_student ON attendance_entries(student_id);


-- ============================================================
-- TABLE 14: materials
-- Teacher ke upload kiye PDFs, videos, images
-- ============================================================

CREATE TABLE materials (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  class_subject_id UUID NOT NULL REFERENCES class_subjects(id), -- konse subject ka
  school_id        UUID NOT NULL REFERENCES schools(id),
  uploaded_by      UUID NOT NULL REFERENCES users(id),          -- kisne upload kiya
  title            VARCHAR(500) NOT NULL,     -- material ka title
  title_gu         VARCHAR(500),              -- Gujarati title
  description      TEXT,                      -- description
  file_url         TEXT NOT NULL,             -- S3 path
  file_name        VARCHAR(500) NOT NULL,     -- original file naam
  file_type        VARCHAR(50) NOT NULL
                   CHECK (file_type IN ('PDF', 'IMAGE', 'VIDEO')),
  file_size_kb     INTEGER NOT NULL,          -- file size KB mein
  checksum         VARCHAR(64) NOT NULL,      -- SHA256 — duplicate check ke liye
  version          INTEGER DEFAULT 1,         -- version number
  is_active        BOOLEAN DEFAULT TRUE,
  approved_by      UUID REFERENCES users(id), -- kisne approve kiya
  approved_at      TIMESTAMPTZ,
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW(),

  -- same subject mein same file dobara upload nahi ho sakti
  CONSTRAINT unique_file_per_subject UNIQUE (class_subject_id, checksum)
);

CREATE INDEX idx_materials_class_subject ON materials(class_subject_id);

-- FUNCTION: Storage quota check karo
-- School ka storage limit cross na ho
CREATE OR REPLACE FUNCTION check_storage_quota()
RETURNS TRIGGER AS $$
DECLARE
  quota INTEGER; -- school ka total quota
  used  INTEGER; -- abhi tak kitna use hua
BEGIN
  -- school ka quota aur used storage lo
  SELECT storage_quota_mb, storage_used_mb
  INTO quota, used
  FROM schools WHERE id = NEW.school_id;

  -- naya file KB mein hai — MB mein convert karke check karo
  IF (used + (NEW.file_size_kb / 1024.0)) > quota THEN
    RAISE EXCEPTION
      'Storage quota exceeded for school. Used: %MB, Quota: %MB',
      used, quota;
  END IF;

  -- quota ok hai toh used storage update karo
  UPDATE schools
  SET storage_used_mb = storage_used_mb + (NEW.file_size_kb / 1024.0)
  WHERE id = NEW.school_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: File insert se pehle quota check karo
CREATE TRIGGER enforce_storage_quota
BEFORE INSERT ON materials
FOR EACH ROW EXECUTE FUNCTION check_storage_quota();


-- ============================================================
-- TABLE 15: material_versions
-- Material ke purane versions track karo
-- ============================================================

CREATE TABLE material_versions (
  id           UUID PRIMARY KEY DEFAULT uuidv7(),
  material_id  UUID NOT NULL REFERENCES materials(id) ON DELETE CASCADE,
  -- material delete ho toh versions bhi delete ho
  version      INTEGER NOT NULL,      -- version number
  file_url     TEXT NOT NULL,         -- us version ka S3 path
  checksum     VARCHAR(64) NOT NULL,  -- us version ka hash
  file_size_kb INTEGER NOT NULL,
  uploaded_by  UUID REFERENCES users(id),
  change_note  TEXT,                  -- kyun update kiya
  created_at   TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (material_id, version) -- ek material ka ek version ek baar
);


-- ============================================================
-- TABLE 16: assignments
-- Teacher ke diye homework/tasks
-- ============================================================

CREATE TABLE assignments (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  class_subject_id UUID NOT NULL REFERENCES class_subjects(id),
  school_id        UUID NOT NULL REFERENCES schools(id),
  created_by       UUID NOT NULL REFERENCES users(id),   -- teacher
  title            VARCHAR(500) NOT NULL,
  description      TEXT,
  instructions     TEXT,
  file_url         TEXT,                    -- attached file (optional)
  max_marks        INTEGER NOT NULL DEFAULT 100,
  deadline_at      TIMESTAMPTZ NOT NULL,    -- exact deadline UTC mein
  grace_period_min INTEGER DEFAULT 120,     -- offline ke liye 2 ghante grace
  status           VARCHAR(20) DEFAULT 'ACTIVE'
                   CHECK (status IN (
                     'DRAFT', 'ACTIVE', 'CLOSED', 'ARCHIVED'
                   )),
  created_at       TIMESTAMPTZ DEFAULT NOW(),
  updated_at       TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_assignments_class_subject ON assignments(class_subject_id);
CREATE INDEX idx_assignments_deadline ON assignments(deadline_at); -- deadline se filter ke liye


-- ============================================================
-- TABLE 17: submissions
-- Student ka assignment ka jawab
-- ============================================================

CREATE TABLE submissions (
  id                    UUID PRIMARY KEY DEFAULT uuidv7(),
  assignment_id         UUID NOT NULL REFERENCES assignments(id),
  student_id            UUID NOT NULL REFERENCES users(id),
  school_id             UUID NOT NULL REFERENCES schools(id),
  file_url              TEXT NOT NULL,       -- submitted file ka S3 path
  file_name             VARCHAR(500),
  file_size_kb          INTEGER,
  checksum              VARCHAR(64),
  submitted_at          TIMESTAMPTZ NOT NULL, -- student ne kab submit kiya
  synced_at             TIMESTAMPTZ,          -- server pe kab pahuncha (offline ke liye alag)
  is_late               BOOLEAN DEFAULT FALSE,         -- deadline ke baad?
  is_offline_submission BOOLEAN DEFAULT FALSE,         -- offline tha?
  status                VARCHAR(20) DEFAULT 'SUBMITTED'
                        CHECK (status IN (
                          'SUBMITTED', 'GRADING', 'GRADED', 'RETURNED'
                        )),
  grade                 INTEGER,             -- teacher ka diya grade
  grade_remark          TEXT,               -- teacher ka comment
  graded_by             UUID REFERENCES users(id),
  graded_at             TIMESTAMPTZ,
  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE (assignment_id, student_id) -- ek student ek assignment ek baar
);

CREATE INDEX idx_submissions_assignment ON submissions(assignment_id);
CREATE INDEX idx_submissions_student ON submissions(student_id);

-- FUNCTION: Deadline check karo
CREATE OR REPLACE FUNCTION check_submission_deadline()
RETURNS TRIGGER AS $$
DECLARE
  deadline      TIMESTAMPTZ; -- assignment ki deadline
  grace_minutes INTEGER;     -- grace period minutes mein
BEGIN
  -- assignment ki deadline aur grace period lo
  SELECT deadline_at, grace_period_min
  INTO deadline, grace_minutes
  FROM assignments
  WHERE id = NEW.assignment_id;

  -- hard cutoff = deadline + grace period — isse baad reject karo
  IF NEW.submitted_at > (deadline + (grace_minutes || ' minutes')::INTERVAL) THEN
    RAISE EXCEPTION
      'Submission rejected. Deadline was %, grace period % minutes.',
      deadline, grace_minutes;
  END IF;

  -- deadline ke baad lekin grace ke andar — is_late mark karo
  IF NEW.submitted_at > deadline THEN
    NEW.is_late := TRUE;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: Submission se pehle deadline check karo
CREATE TRIGGER enforce_submission_deadline
BEFORE INSERT ON submissions
FOR EACH ROW EXECUTE FUNCTION check_submission_deadline();


-- ============================================================
-- TABLE 18: assessments
-- Unit Test, Mid Term, Final Exam, etc.
-- ============================================================

CREATE TABLE assessments (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  class_subject_id UUID NOT NULL REFERENCES class_subjects(id),
  school_id        UUID NOT NULL REFERENCES schools(id),
  academic_year_id UUID NOT NULL REFERENCES academic_years(id),
  name             VARCHAR(255) NOT NULL,   -- "Unit Test 1"
  name_gu          VARCHAR(255),
  type             VARCHAR(50) NOT NULL
                   CHECK (type IN (
                     'UNIT_TEST',   -- unit test
                     'MID_TERM',    -- mid term exam
                     'FINAL_EXAM',  -- final exam
                     'ASSIGNMENT',  -- assignment based
                     'PROJECT',     -- project
                     'ORAL'         -- oral exam
                   )),
  max_marks        INTEGER NOT NULL,    -- total marks
  exam_date        DATE,               -- NULL ho sakta hai projects ke liye
  is_published     BOOLEAN DEFAULT FALSE,  -- students ko dikhana hai?
  published_at     TIMESTAMPTZ,            -- kab publish kiya
  published_by     UUID REFERENCES users(id),
  created_at       TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- TABLE 19: mark_entries
-- Har student ke marks har assessment mein
-- ============================================================

CREATE TABLE mark_entries (
  id                UUID PRIMARY KEY DEFAULT uuidv7(),
  assessment_id     UUID NOT NULL REFERENCES assessments(id),
  student_id        UUID NOT NULL REFERENCES users(id),
  school_id         UUID NOT NULL REFERENCES schools(id),
  marks_obtained    NUMERIC(5,2),   -- NULL = abhi enter nahi kiye, decimal allowed (18.50)
  is_absent         BOOLEAN DEFAULT FALSE,  -- exam mein absent tha?
  is_exempt         BOOLEAN DEFAULT FALSE,  -- exempt kiya gaya?
  remark            TEXT,
  entered_by        UUID NOT NULL REFERENCES users(id),  -- teacher jisne daale
  entered_at        TIMESTAMPTZ DEFAULT NOW(),
  original_marks    NUMERIC(5,2),   -- correction se pehle ke marks
  corrected_by      UUID REFERENCES users(id),    -- kisne correct kiya
  corrected_at      TIMESTAMPTZ,
  correction_reason TEXT,           -- kyun correct kiya
  approved_by       UUID REFERENCES users(id),    -- kisne approve kiya

  UNIQUE (assessment_id, student_id), -- ek student ka ek assessment mein ek entry

  -- marks negative nahi ho sakte
  CONSTRAINT valid_marks CHECK (
    marks_obtained IS NULL OR
    marks_obtained >= 0
  )
);

CREATE INDEX idx_mark_entries_student ON mark_entries(student_id);
CREATE INDEX idx_mark_entries_assessment ON mark_entries(assessment_id);

-- FUNCTION: Marks limit check karo
CREATE OR REPLACE FUNCTION check_marks_limit()
RETURNS TRIGGER AS $$
DECLARE
  max INTEGER; -- assessment ke max_marks
BEGIN
  -- assessment ka max_marks lo
  SELECT max_marks INTO max
  FROM assessments
  WHERE id = NEW.assessment_id;

  -- entered marks max se zyada nahi hone chahiye
  IF NEW.marks_obtained > max THEN
    RAISE EXCEPTION 'Marks % exceed max_marks %',
      NEW.marks_obtained, max;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- TRIGGER: INSERT ya UPDATE dono pe check karo
CREATE TRIGGER enforce_marks_limit
BEFORE INSERT OR UPDATE ON mark_entries
FOR EACH ROW EXECUTE FUNCTION check_marks_limit();


-- ============================================================
-- TABLE 20: notifications
-- SMS, Push, In-App notifications
-- ============================================================

CREATE TABLE notifications (
  id           UUID PRIMARY KEY DEFAULT uuidv7(),
  school_id    UUID REFERENCES schools(id),          -- NULL ho sakta hai system notifications ke liye
  recipient_id UUID NOT NULL REFERENCES users(id),   -- kisko bheja
  event_type   VARCHAR(100) NOT NULL,                -- "CHILD_ABSENT", "MARKS_PUBLISHED", etc.
  title        VARCHAR(500),
  body         TEXT NOT NULL,    -- notification ka content
  body_gu      TEXT,             -- Gujarati version
  channel      VARCHAR(20) NOT NULL
               CHECK (channel IN (
                 'SMS',     -- text message
                 'PUSH',    -- mobile push notification
                 'IN_APP'   -- app ke andar
               )),
  status       VARCHAR(20) DEFAULT 'PENDING'
               CHECK (status IN (
                 'PENDING',    -- abhi bheja nahi
                 'SENT',       -- bhej diya
                 'DELIVERED',  -- pahunch gaya
                 'FAILED',     -- fail hua
                 'OPTED_OUT'   -- user ne opt out kiya
               )),
  retry_count  INTEGER DEFAULT 0,    -- kitni baar retry kiya
  sent_at      TIMESTAMPTZ,          -- kab bheja
  delivered_at TIMESTAMPTZ,          -- kab pahuncha
  error_message TEXT,                -- error tha toh kya
  batch_id     UUID,                 -- batch notifications ke liye group ID
  is_batched   BOOLEAN DEFAULT FALSE,
  metadata     JSONB,                -- extra context {studentId, classId, etc.}
  created_at   TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_recipient ON notifications(recipient_id); -- user ke notifications
CREATE INDEX idx_notifications_status ON notifications(status);          -- pending process karo
CREATE INDEX idx_notifications_created ON notifications(created_at);     -- time se filter


-- ============================================================
-- TABLE 21: refresh_tokens
-- JWT refresh tokens store karo
-- ============================================================

CREATE TABLE refresh_tokens (
  id          UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  -- user delete ho toh tokens bhi delete ho
  token_hash  VARCHAR(255) NOT NULL UNIQUE, -- actual token nahi — sirf hash
  device_info TEXT,      -- "Redmi 9A, Android 10"
  ip_address  INET,      -- login ka IP address
  expires_at  TIMESTAMPTZ NOT NULL, -- kab expire hoga
  is_revoked  BOOLEAN DEFAULT FALSE, -- revoke hua hai?
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_refresh_tokens_user ON refresh_tokens(user_id);


-- ============================================================
-- TABLE 22: otp_requests
-- Parents ke liye OTP login
-- ============================================================

CREATE TABLE otp_requests (
  id            UUID PRIMARY KEY DEFAULT uuidv7(),
  phone         VARCHAR(20) NOT NULL,     -- phone number
  otp_hash      VARCHAR(255) NOT NULL,    -- actual OTP nahi — bcrypt hash
  purpose       VARCHAR(50) NOT NULL
                CHECK (purpose IN (
                  'LOGIN',          -- normal login
                  'PASSWORD_RESET', -- password bhool gaye
                  'DEVICE_VERIFY'   -- naya device
                )),
  attempt_count INTEGER DEFAULT 0,  -- kitni baar galat try kiya
  is_used       BOOLEAN DEFAULT FALSE, -- use ho gaya?
  expires_at    TIMESTAMPTZ NOT NULL,  -- kab expire hoga (usually 10 min)
  created_at    TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- TABLE 23: consent_records
-- DPDP Act compliance — parent ki consent
-- ============================================================

CREATE TABLE consent_records (
  id              UUID PRIMARY KEY DEFAULT uuidv7(),
  student_id      UUID NOT NULL REFERENCES users(id),
  parent_id       UUID NOT NULL REFERENCES users(id),
  consent_type    VARCHAR(100) NOT NULL
                  CHECK (consent_type IN (
                    'DATA_PROCESSING', -- data store karne ki permission
                    'SMS_ALERTS',      -- SMS bhejne ki permission
                    'PHOTO_UPLOAD'     -- photo upload ki permission
                  )),
  is_granted      BOOLEAN NOT NULL,   -- diya ya nahi
  granted_at      TIMESTAMPTZ,        -- kab diya
  revoked_at      TIMESTAMPTZ,        -- kab wapas liya
  ip_address      INET,
  device_info     TEXT,
  consent_version VARCHAR(20) NOT NULL, -- "v1.0" — policy version
  created_at      TIMESTAMPTZ DEFAULT NOW(),

  -- same student, same consent type, same version ek baar
  UNIQUE (student_id, consent_type, consent_version)
);


-- ============================================================
-- TABLE 24: data_erasure_requests
-- DPDP Act — data delete karne ki request
-- ============================================================

CREATE TABLE data_erasure_requests (
  id               UUID PRIMARY KEY DEFAULT uuidv7(),
  requested_by     UUID NOT NULL REFERENCES users(id), -- parent jisne request ki
  student_id       UUID NOT NULL REFERENCES users(id), -- jis student ka data
  reason           TEXT,
  status           VARCHAR(30) DEFAULT 'PENDING'
                   CHECK (status IN (
                     'PENDING',      -- nayi request
                     'IN_PROGRESS',  -- process ho raha hai
                     'COMPLETED',    -- complete ho gaya
                     'REJECTED'      -- reject hua
                   )),
  rejection_reason TEXT,           -- reject kyun kiya
  due_by           TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '72 hours'),
  -- DPDP Act: 72 ghante mein process karna zaroori
  completed_at     TIMESTAMPTZ,    -- kab complete hua
  processed_by     UUID REFERENCES users(id), -- admin jisne process kiya
  created_at       TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- TABLE 25: student_transfers
-- Student ek school se doosri school mein transfer
-- ============================================================

CREATE TABLE student_transfers (
  id             UUID PRIMARY KEY DEFAULT uuidv7(),
  student_id     UUID NOT NULL REFERENCES users(id),
  from_school_id UUID NOT NULL REFERENCES schools(id), -- jahan se gaya
  to_school_id   UUID NOT NULL REFERENCES schools(id), -- jahan gaya
  from_class_id  UUID REFERENCES classes(id),          -- NULL ho sakta hai
  transfer_date  DATE NOT NULL,   -- kab hua transfer
  reason         TEXT,            -- kyun hua
  approved_by    UUID REFERENCES users(id), -- kisne approve kiya
  documents_url  TEXT,            -- transfer certificate S3 path
  created_at     TIMESTAMPTZ DEFAULT NOW()
);


-- ============================================================
-- TABLE 26: audit_logs
-- APPEND-ONLY — koi bhi sensitive change record hota hai
-- DELETE ya UPDATE allowed nahi hai app user ko
-- ============================================================

CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT uuidv7(),
  user_id     UUID REFERENCES users(id),    -- NULL ho sakta hai system actions ke liye
  school_id   UUID REFERENCES schools(id),  -- NULL ho sakta hai
  action      VARCHAR(100) NOT NULL,        -- "MARKS_CHANGED", "USER_LOGIN", etc.
  entity_type VARCHAR(100),                 -- "marks", "attendance", "user"
  entity_id   UUID,                         -- kaun sa record change hua
  old_value   JSONB,                        -- pehle kya tha
  new_value   JSONB,                        -- ab kya hai
  ip_address  INET,                         -- kis IP se
  device_info TEXT,                         -- kaun sa device
  reason      TEXT,                         -- sensitive changes ke liye reason zaroori
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_user ON audit_logs(user_id);
CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_created ON audit_logs(created_at);


-- ============================================================
-- APP USER PERMISSIONS
-- App ke liye alag user — limited permissions
-- ============================================================

-- App ke liye alag DB user banao
CREATE USER edu_app WITH PASSWORD 'strong_password_yahan';

-- Saari tables pe normal permissions do
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO edu_app;

-- audit_logs pe DELETE aur UPDATE nahi — append-only enforce karo
REVOKE UPDATE, DELETE ON audit_logs FROM edu_app;


-- ============================================================
-- MATERIALIZED VIEW: student_attendance_summary
-- Attendance percentage pre-calculate karke store karo
-- Har baar calculate nahi karna — fast reads ke liye
-- ============================================================

CREATE MATERIALIZED VIEW student_attendance_summary AS
SELECT
  sc.student_id,
  sc.class_id,
  sc.school_id,
  sc.academic_year_id,
  -- sirf PRESENT wale din count karo
  COUNT(ae.id) FILTER (WHERE ae.status = 'PRESENT') AS present_days,
  -- HOLIDAY ko total mein count mat karo
  COUNT(ae.id) FILTER (WHERE ae.status != 'HOLIDAY') AS total_days,
  -- percentage nikalo — NULLIF se divide-by-zero se bachao
  ROUND(
    COUNT(ae.id) FILTER (WHERE ae.status = 'PRESENT') * 100.0
    / NULLIF(COUNT(ae.id) FILTER (WHERE ae.status != 'HOLIDAY'), 0),
    2
  ) AS attendance_percentage
FROM student_classes sc
LEFT JOIN attendance_entries ae ON ae.student_id = sc.student_id
LEFT JOIN attendance_records ar ON ar.id = ae.attendance_record_id
  AND ar.class_id = sc.class_id
GROUP BY sc.student_id, sc.class_id, sc.school_id, sc.academic_year_id;

-- unique index — student + year combination unique honi chahiye
CREATE UNIQUE INDEX ON student_attendance_summary(student_id, academic_year_id);

-- Refresh karne ka command (background mein — queries block nahi hoti)
-- REFRESH MATERIALIZED VIEW CONCURRENTLY student_attendance_summary;


-- ============================================================
-- ROW LEVEL SECURITY (RLS)
-- School data isolation — database level pe
-- Teacher sirf apne school ka data dekh sakta hai
-- ============================================================

-- Sensitive tables pe RLS enable karo
ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_records ENABLE ROW LEVEL SECURITY;
ALTER TABLE attendance_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE mark_entries ENABLE ROW LEVEL SECURITY;
ALTER TABLE materials ENABLE ROW LEVEL SECURITY;
ALTER TABLE assignments ENABLE ROW LEVEL SECURITY;
ALTER TABLE submissions ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE audit_logs ENABLE ROW LEVEL SECURITY;

-- Har table pe school isolation policy
-- app.current_school_id har API request mein JWT se set hota hai

CREATE POLICY school_isolation_attendance
ON attendance_records
USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation_entries
ON attendance_entries
USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation_marks
ON mark_entries
USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation_materials
ON materials
USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation_assignments
ON assignments
USING (school_id = current_setting('app.current_school_id')::UUID);

CREATE POLICY school_isolation_submissions
ON submissions
USING (school_id = current_setting('app.current_school_id')::UUID);

-- Har API request ke shuru mein yeh set karo JWT se:
-- SET app.current_school_id = '<jwt_se_nikala_school_id>';


-- ============================================================
-- DUMMY DATA — Testing ke liye
-- ============================================================

-- Municipality
INSERT INTO municipalities (name, name_gu, code)
VALUES (
  'Gandhinagar Municipal Corporation',
  'ગાંધીનગર મ્યુનિસિપલ કોર્પોરેશન',
  'GMC-GN-001'
);

-- School (municipality ka UUID use karo)
INSERT INTO schools (municipality_id, name, name_gu, code, medium, board)
VALUES (
  '019e63d8-5021-7bea-9bb4-7ed1ac99d53c', -- municipalities se mila UUID
  'Gandhinagar Primary School No. 1',
  'ગાંધીનગર પ્રાથમિક શાળા નં. ૧',
  'GMC-SCH-0001',
  'Gujarati',
  'GSEB'
);

-- Academic Year
INSERT INTO academic_years (school_id, name, start_date, end_date, is_current)
VALUES (
  '019e63d9-9808-78ec-98b8-70b0df11d543', -- schools se mila UUID
  '2024-25',
  '2024-06-01',
  '2025-03-31',
  TRUE
);

-- 5 Subjects
INSERT INTO subjects (school_id, name, name_gu, code, grade_level)
VALUES
  ('019e63d9-9808-78ec-98b8-70b0df11d543', 'Mathematics', 'ગણિત', 'MATH-8', 8),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', 'Science', 'વિજ્ઞાન', 'SCI-8', 8),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', 'Gujarati', 'ગુજરાતી', 'GUJ-8', 8),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', 'English', 'અંગ્રેજી', 'ENG-8', 8),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', 'Social Science', 'સામાજિક વિજ્ઞાન', 'SS-8', 8);

-- 2 Teachers
INSERT INTO users (school_id, municipality_id, role, name, name_gu, email, phone, password_hash)
VALUES
  (
    '019e63d9-9808-78ec-98b8-70b0df11d543',
    '019e63d8-5021-7bea-9bb4-7ed1ac99d53c',
    'TEACHER', 'Ramesh Patel', 'રમેશ પટેલ',
    'ramesh@gmc.edu', '9876543210', '$2b$10$dummy_hash_ramesh'
  ),
  (
    '019e63d9-9808-78ec-98b8-70b0df11d543',
    '019e63d8-5021-7bea-9bb4-7ed1ac99d53c',
    'TEACHER', 'Priya Shah', 'પ્રિયા શાહ',
    'priya@gmc.edu', '9876543211', '$2b$10$dummy_hash_priya'
  );

-- 2 Classes
INSERT INTO classes (school_id, academic_year_id, name, grade, section, class_teacher_id, capacity)
VALUES
  (
    '019e63d9-9808-78ec-98b8-70b0df11d543',
    '019e63e5-b504-7f62-9fc7-dbf4a9a22d35',
    '8A', 8, 'A', '019e63e8-76c8-782c-a624-47bdcd9aea61', 40
  ),
  (
    '019e63d9-9808-78ec-98b8-70b0df11d543',
    '019e63e5-b504-7f62-9fc7-dbf4a9a22d35',
    '8B', 8, 'B', '019e63e8-76c8-7a92-a4e7-ceecbe222ce9', 40
  );

-- Class-Subject mapping
INSERT INTO class_subjects (class_id, subject_id, teacher_id, school_id)
VALUES
  ('019e63e9-b6c0-7be4-8424-484f085011e3', '019e63e6-618d-7c94-8789-2d97d91ea905', '019e63e8-76c8-782c-a624-47bdcd9aea61', '019e63d9-9808-78ec-98b8-70b0df11d543'),
  ('019e63e9-b6c0-7be4-8424-484f085011e3', '019e63e6-6191-7723-b39a-6f07fb994498', '019e63e8-76c8-7a92-a4e7-ceecbe222ce9', '019e63d9-9808-78ec-98b8-70b0df11d543'),
  ('019e63e9-b6c6-7d62-aa8c-d6b1850b9430', '019e63e6-618d-7c94-8789-2d97d91ea905', '019e63e8-76c8-782c-a624-47bdcd9aea61', '019e63d9-9808-78ec-98b8-70b0df11d543'),
  ('019e63e9-b6c6-7d62-aa8c-d6b1850b9430', '019e63e6-6191-7723-b39a-6f07fb994498', '019e63e8-76c8-7a92-a4e7-ceecbe222ce9', '019e63d9-9808-78ec-98b8-70b0df11d543');

-- 4 Students
INSERT INTO users (school_id, municipality_id, role, name, name_gu, student_code, pin_hash)
VALUES
  ('019e63d9-9808-78ec-98b8-70b0df11d543', '019e63d8-5021-7bea-9bb4-7ed1ac99d53c', 'STUDENT', 'Rahul Patel', 'રાહુલ પટેલ', 'GJ-2024-SCH01-0001', '$2b$10$dummy_pin_1'),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', '019e63d8-5021-7bea-9bb4-7ed1ac99d53c', 'STUDENT', 'Priya Modi', 'પ્રિયા મોદી', 'GJ-2024-SCH01-0002', '$2b$10$dummy_pin_2'),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', '019e63d8-5021-7bea-9bb4-7ed1ac99d53c', 'STUDENT', 'Amit Shah', 'અમિત શાહ', 'GJ-2024-SCH01-0003', '$2b$10$dummy_pin_3'),
  ('019e63d9-9808-78ec-98b8-70b0df11d543', '019e63d8-5021-7bea-9bb4-7ed1ac99d53c', 'STUDENT', 'Sneha Desai', 'સ્નેહા દેસાઈ', 'GJ-2024-SCH01-0004', '$2b$10$dummy_pin_4');

-- Student enrollment
INSERT INTO student_classes (student_id, class_id, academic_year_id, school_id, roll_number)
VALUES
  ('019e63eb-54f2-76d3-8ba1-0fae88bfa189', '019e63e9-b6c0-7be4-8424-484f085011e3', '019e63e5-b504-7f62-9fc7-dbf4a9a22d35', '019e63d9-9808-78ec-98b8-70b0df11d543', '01'),
  ('019e63eb-54f2-78b5-94f3-24f843e95867', '019e63e9-b6c0-7be4-8424-484f085011e3', '019e63e5-b504-7f62-9fc7-dbf4a9a22d35', '019e63d9-9808-78ec-98b8-70b0df11d543', '02'),
  ('019e63eb-54f2-78f9-a438-d8059890c3ac', '019e63e9-b6c6-7d62-aa8c-d6b1850b9430', '019e63e5-b504-7f62-9fc7-dbf4a9a22d35', '019e63d9-9808-78ec-98b8-70b0df11d543', '01'),
  ('019e63eb-54f2-7927-a4a5-d9ca6ed3c874', '019e63e9-b6c6-7d62-aa8c-d6b1850b9430', '019e63e5-b504-7f62-9fc7-dbf4a9a22d35', '019e63d9-9808-78ec-98b8-70b0df11d543', '02');

-- Attendance record (Class 8A, 15 June)
INSERT INTO attendance_records
(class_id, school_id, academic_year_id, date, submitted_by, status)
VALUES (
  '019e63e9-b6c0-7be4-8424-484f085011e3',
  '019e63d9-9808-78ec-98b8-70b0df11d543',
  '019e63e5-b504-7f62-9fc7-dbf4a9a22d35',
  '2024-06-15',
  '019e63e8-76c8-782c-a624-47bdcd9aea61',
  'SUBMITTED'
);

-- Attendance entries
INSERT INTO attendance_entries
(attendance_record_id, student_id, school_id, status)
VALUES
  ('019e63ed-31a1-745c-9da4-787e3fe3ea98', '019e63eb-54f2-76d3-8ba1-0fae88bfa189', '019e63d9-9808-78ec-98b8-70b0df11d543', 'PRESENT'),
  ('019e63ed-31a1-745c-9da4-787e3fe3ea98', '019e63eb-54f2-78b5-94f3-24f843e95867', '019e63d9-9808-78ec-98b8-70b0df11d543', 'ABSENT');


-- ============================================================
-- TEST QUERY — Sab kaam kar raha hai check karo
-- ============================================================

SELECT
  u.name AS student,          -- student ka naam
  c.name AS class,            -- class ka naam
  ar.date AS attendance_date, -- date
  ae.status AS attendance_status -- present/absent
FROM attendance_entries ae
JOIN users u ON ae.student_id = u.id
JOIN attendance_records ar ON ae.attendance_record_id = ar.id
JOIN classes c ON ar.class_id = c.id
ORDER BY ar.date, u.name;

-- ============================================================
-- END OF FILE
-- Total: 26 Tables + 4 Triggers + 1 Materialized View + RLS
-- ============================================================