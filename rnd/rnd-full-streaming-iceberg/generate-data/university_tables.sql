-- University Database Tables (Clean version for Python execution)

-- Faculties Table
CREATE TABLE IF NOT EXISTS faculty (
    id SERIAL PRIMARY KEY,
    faculty_code VARCHAR(10) UNIQUE NOT NULL,
    faculty_name VARCHAR(100) NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Programs Table
CREATE TABLE IF NOT EXISTS program (
    id SERIAL PRIMARY KEY,
    program_code VARCHAR(10) UNIQUE NOT NULL,
    program_name VARCHAR(100) NOT NULL,
    faculty_id INTEGER NOT NULL,
    degree VARCHAR(20) NOT NULL DEFAULT 'S1',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (faculty_id) REFERENCES faculty(id)
);

-- Students Table
CREATE TABLE IF NOT EXISTS students (
    student_id VARCHAR(20) PRIMARY KEY,
    full_name VARCHAR(100) NOT NULL,
    entry_year INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    degree VARCHAR(20) NOT NULL DEFAULT 'S1',
    faculty_id INTEGER NOT NULL,
    status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (program_id) REFERENCES program(id),
    FOREIGN KEY (faculty_id) REFERENCES faculty(id)
);

-- Student Details Table
CREATE TABLE IF NOT EXISTS student_detail (
    id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    gender VARCHAR(10),
    birth_date DATE,
    birth_place VARCHAR(100),
    religion VARCHAR(20),
    nationality VARCHAR(50) DEFAULT 'Indonesia',
    registration_date DATE,
    address TEXT,
    city VARCHAR(50),
    province VARCHAR(50),
    postal_code VARCHAR(10),
    phone_number VARCHAR(20),
    high_school VARCHAR(100),
    high_school_year INTEGER,
    parent_name VARCHAR(100),
    parent_income DECIMAL(15,2),
    parent_occupation VARCHAR(100),
    blood_type VARCHAR(5),
    health_insurance VARCHAR(50),
    accommodation VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Student Fees Table
CREATE TABLE IF NOT EXISTS student_fee (
    fee_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    ukt_fee DECIMAL(12,2),
    bop_fee DECIMAL(12,2),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Lecturers Table
CREATE TABLE IF NOT EXISTS lecturer (
    id SERIAL PRIMARY KEY,
    lecturer_id VARCHAR(20) UNIQUE NOT NULL,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(100) NOT NULL,
    faculty_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (faculty_id) REFERENCES faculty(id)
);

-- Rooms Table
CREATE TABLE IF NOT EXISTS room (
    id SERIAL PRIMARY KEY,
    room_code VARCHAR(20) UNIQUE NOT NULL,
    building VARCHAR(50) NOT NULL,
    capacity INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Courses Table
CREATE TABLE IF NOT EXISTS course (
    id SERIAL PRIMARY KEY,
    course_code VARCHAR(10) UNIQUE NOT NULL,
    course_name VARCHAR(100) NOT NULL,
    credits INTEGER NOT NULL,
    program_id INTEGER NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (program_id) REFERENCES program(id)
);

-- Registration Table
CREATE TABLE IF NOT EXISTS registration (
    registration_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    academic_year VARCHAR(10) NOT NULL,
    semester INTEGER NOT NULL,
    semester_code VARCHAR(20) NOT NULL,
    registration_date DATE NOT NULL,
    registration_status VARCHAR(20) DEFAULT 'active',
    total_sks INTEGER DEFAULT 0,
    late_registration BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id)
);

-- Class Table
CREATE TABLE IF NOT EXISTS class (
    class_id VARCHAR(50) PRIMARY KEY,
    course_id INTEGER NOT NULL,
    lecturer_id INTEGER NOT NULL,
    academic_year VARCHAR(10) NOT NULL,
    semester INTEGER NOT NULL,
    class_code VARCHAR(20) NOT NULL,
    room_code VARCHAR(20),
    schedule_day VARCHAR(10),
    schedule_time VARCHAR(20),
    capacity INTEGER DEFAULT 40,
    enrolled_count INTEGER DEFAULT 0,
    class_status VARCHAR(20) DEFAULT 'active',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (course_id) REFERENCES course(id),
    FOREIGN KEY (lecturer_id) REFERENCES lecturer(id)
);

-- Student Enrollment Table
CREATE TABLE IF NOT EXISTS student_enrollment (
    enrollment_id SERIAL PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    registration_id VARCHAR(50) NOT NULL,
    class_id VARCHAR(50) NOT NULL,
    enrollment_date DATE NOT NULL,
    enrollment_status VARCHAR(20) DEFAULT 'enrolled',
    final_grade DECIMAL(5,2),
    grade_point DECIMAL(3,2),
    attendance_percentage DECIMAL(5,2),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (registration_id) REFERENCES registration(registration_id),
    FOREIGN KEY (class_id) REFERENCES class(class_id),
    UNIQUE (student_id, class_id)
);

-- Payment Table
CREATE TABLE IF NOT EXISTS payment (
    payment_id VARCHAR(50) PRIMARY KEY,
    student_id VARCHAR(20) NOT NULL,
    registration_id VARCHAR(50) NOT NULL,
    payment_type VARCHAR(20) NOT NULL,
    payment_amount DECIMAL(12,2) NOT NULL,
    bank_name VARCHAR(50),
    virtual_account_number VARCHAR(50),
    payment_channel VARCHAR(20),
    payment_time TIMESTAMP,
    payment_status VARCHAR(20) DEFAULT 'pending',
    installment_number INTEGER DEFAULT 1,
    late_fee_charged DECIMAL(12,2) DEFAULT 0,
    total_paid_amount DECIMAL(12,2),
    payment_proof_url TEXT,
    due_date DATE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (student_id) REFERENCES students(student_id),
    FOREIGN KEY (registration_id) REFERENCES registration(registration_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_students_entry_year ON students(entry_year);
CREATE INDEX IF NOT EXISTS idx_registration_academic_year ON registration(academic_year);
CREATE INDEX IF NOT EXISTS idx_registration_semester ON registration(semester);
CREATE INDEX IF NOT EXISTS idx_class_academic_year ON class(academic_year);
CREATE INDEX IF NOT EXISTS idx_enrollment_student_id ON student_enrollment(student_id);
CREATE INDEX IF NOT EXISTS idx_payment_student_id ON payment(student_id); 