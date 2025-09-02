"""Payment generator for student fee payments"""

import logging
import random
from datetime import datetime, date, timedelta
from faker import Faker
import db_utils

fake = Faker('id_ID')

class PaymentGenerator:
    def __init__(self):
        self.db = db_utils.get_db_manager()
        
    def generate_payments_for_registrations(self, academic_year, registrations):
        """Generate payments for student registrations"""
        try:
            logging.info(f"💰 Generating payments for {len(registrations)} registrations")
            
            payments = []
            payment_counter = 1
            
            # Bank options
            banks = ['BNI', 'BCA', 'Mandiri', 'BRI', 'BSI', 'CIMB']
            payment_channels = ['Virtual Account', 'Transfer Bank', 'Mobile Banking', 'ATM']
            payment_types = ['UKT', 'BOP', 'Late Fee', 'Reregistration']
            
            for registration_id, student_id, academic_year_reg, semester, semester_code, reg_date in registrations:
                # Get student's fee information
                fee_result = self.db.execute_query(
                    "SELECT ukt_fee, bop_fee FROM student_fee WHERE student_id = %s",
                    (student_id,)
                )
                
                if not fee_result:
                    # Generate default fees if not found
                    ukt_fee = random.randint(5000000, 12500000)
                    bop_fee = 0  # BOP usually only for new students
                else:
                    ukt_fee, bop_fee = fee_result[0]
                
                # Generate UKT payment (every semester)
                self._generate_payment(
                    payments, payment_counter, student_id, registration_id,
                    'UKT', ukt_fee, reg_date, banks, payment_channels
                )
                payment_counter += 1
                
                # BOP payment (only for first year students, semester 1)
                if semester == 1:
                    # Check if this is the student's first registration
                    first_reg = self.db.execute_query(
                        """SELECT COUNT(*) FROM registration 
                           WHERE student_id = %s AND registration_date < %s""",
                        (student_id, reg_date)
                    )
                    
                    is_first_registration = first_reg[0][0] == 0 if first_reg else True
                    
                    if is_first_registration and bop_fee > 0:
                        self._generate_payment(
                            payments, payment_counter, student_id, registration_id,
                            'BOP', bop_fee, reg_date, banks, payment_channels
                        )
                        payment_counter += 1
                
                # Late fee (10% chance)
                if random.random() < 0.1:
                    late_fee = random.randint(100000, 500000)  # 100k - 500k IDR
                    late_payment_date = reg_date + timedelta(days=random.randint(30, 60))
                    
                    self._generate_payment(
                        payments, payment_counter, student_id, registration_id,
                        'Late Fee', late_fee, late_payment_date, banks, payment_channels
                    )
                    payment_counter += 1
            
            logging.info(f"✅ Generated {len(payments)} payments")
            return payments
            
        except Exception as e:
            logging.error(f"❌ Error generating payments: {e}")
            raise
    
    def _generate_payment(self, payments, payment_counter, student_id, registration_id, 
                         payment_type, amount, base_date, banks, payment_channels):
        """Generate a single payment record"""
        try:
            payment_id = f"PAY-{student_id}-{payment_counter:06d}"
            bank_name = random.choice(banks)
            virtual_account = f"{bank_name}{random.randint(1000000000, 9999999999)}"
            payment_channel = random.choice(payment_channels)
            
            # Payment timing
            payment_status = random.choices(
                ['paid', 'pending', 'overdue'], 
                weights=[85, 10, 5]  # 85% paid, 10% pending, 5% overdue
            )[0]
            
            payment_time = None
            total_paid_amount = 0
            
            if payment_status == 'paid':
                # Payment usually happens within 30 days of registration
                days_after = random.randint(1, 30)
                # Ensure base_date is a date object
                if isinstance(base_date, datetime):
                    payment_date = base_date.date() + timedelta(days=days_after)
                else:
                    payment_date = base_date + timedelta(days=days_after)
                payment_time = datetime.combine(payment_date, fake.time())
                total_paid_amount = amount
                
                # Sometimes there's additional admin fee
                if random.random() < 0.2:  # 20% chance
                    admin_fee = random.randint(5000, 25000)
                    total_paid_amount += admin_fee
            
            # Due date (usually 30 days from registration)
            if isinstance(base_date, datetime):
                due_date = base_date.date() + timedelta(days=30)
            else:
                due_date = base_date + timedelta(days=30)
            
            # Late fee
            late_fee_charged = 0
            if payment_status == 'overdue' or (payment_time and payment_time.date() > due_date):
                late_fee_charged = random.randint(50000, 200000)  # 50k - 200k IDR
                total_paid_amount += late_fee_charged
            
            # Payment proof URL (for paid payments)
            payment_proof_url = None
            if payment_status == 'paid':
                payment_proof_url = f"https://payment-proof.ui.ac.id/{payment_id}.pdf"
            
            # Installment number (most payments are single installment)
            installment_number = 1
            if payment_type == 'BOP' and amount > 50000000:  # Large BOP can be installments
                installment_number = random.choice([1, 2, 3])
            
            payments.append((
                payment_id,
                student_id,
                registration_id,
                payment_type,
                amount,
                bank_name,
                virtual_account,
                payment_channel,
                payment_time,
                payment_status,
                installment_number,
                late_fee_charged,
                total_paid_amount,
                payment_proof_url,
                due_date,
                datetime.now(),
                datetime.now()
            ))
            
        except Exception as e:
            logging.error(f"❌ Error generating single payment: {e}")
            raise

def get_payment_generator():
    """Factory function to get payment generator instance"""
    return PaymentGenerator() 