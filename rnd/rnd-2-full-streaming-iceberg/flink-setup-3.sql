


INSERT INTO polaris_catalog.university_db.faculty
SELECT 
    id,
    faculty_code,
    faculty_name,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.faculty;


INSERT INTO polaris_catalog.university_db.program
SELECT 
    id,
    program_code,
    program_name,
    faculty_id,
    degree_level,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.program;


INSERT INTO polaris_catalog.university_db.students
SELECT 
    id,
    student_id,
    first_name,
    last_name,
    email,
    phone,
    program_id,
    admission_year,
    status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.students;


INSERT INTO polaris_catalog.university_db.class
SELECT 
    id,
    class_code,
    class_name,
    course_id,
    lecturer_id,
    room_id,
    semester,
    academic_year,
    schedule_day,
    schedule_time,
    max_capacity,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.class;

INSERT INTO polaris_catalog.university_db.course
SELECT 
    id,
    course_code,
    course_name,
    credits,
    program_id,
    prerequisite_course_id,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.course;


INSERT INTO polaris_catalog.university_db.lecturer
SELECT 
    id,
    lecturer_id,
    first_name,
    last_name,
    email,
    phone,
    faculty_id,
    specialization,
    employment_status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.lecturer;

INSERT INTO polaris_catalog.university_db.payment
SELECT 
    id,
    student_id,
    fee_type,
    amount,
    semester,
    academic_year,
    due_date,
    status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.payment;

INSERT INTO polaris_catalog.university_db.registration
SELECT 
    id,
    student_id,
    registration_date,
    status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.registration;

INSERT INTO polaris_catalog.university_db.room
SELECT 
    id,
    room_code,
    room_name,
    building,
    floor_number,
    capacity,
    room_type,
    facilities,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.room;

INSERT INTO polaris_catalog.university_db.student_detail
SELECT 
    id,
    student_id,
    date_of_birth,
    address,
    phone,
    email,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_detail;

INSERT INTO polaris_catalog.university_db.student_enrollment
SELECT 
    id,
    student_id,
    enrollment_date,
    status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_enrollment;

INSERT INTO polaris_catalog.university_db.student_fee
SELECT 
    id,
    student_id,
    fee_type,
    amount,
    semester,
    academic_year,
    due_date,
    status,
    CAST(FROM_UNIXTIME(created_at/1000000) AS TIMESTAMP(3)) as created_at
FROM kafka_catalog.university_db.student_fee;