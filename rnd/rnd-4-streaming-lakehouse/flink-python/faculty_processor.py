from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import StreamTableEnvironment, EnvironmentSettings
from pyflink.common.typeinfo import Types
from pyflink.common.watermark_strategy import WatermarkStrategy
from pyflink.datastream.connectors import KafkaSource, KafkaSourceBuilder, KafkaSink, KafkaSinkBuilder
from pyflink.common.serialization import SimpleStringSchema
from iceberg_connector import IcebergConnector
import json
import time
import re

# class FacultyProcessor:
#     def __init__(self):
#         # Setup environments
#         self.env = StreamExecutionEnvironment.get_execution_environment()
#         self.env.set_parallelism(1)
        
#         settings = EnvironmentSettings.new_instance() \
#             .in_streaming_mode() \
#             .build()
        
#         self.table_env = StreamTableEnvironment.create(self.env, settings)
#         self.iceberg = IcebergConnector(self.table_env)

#     def create_kafka_source(self):
#         return KafkaSourceBuilder() \
#             .set_bootstrap_servers('kafka-broker:29092') \
#             .set_topics('faculty-topic') \
#             .set_group_id('faculty-python-processor') \
#             .set_starting_offsets('earliest') \
#             .set_value_only_deserializer(SimpleStringSchema()) \
#             .build()

#     def create_kafka_error_sink(self):
#         return KafkaSinkBuilder() \
#             .set_bootstrap_servers('kafka-broker:29092') \
#             .set_record_serializer(SimpleStringSchema()) \
#             .set_topic('faculty-errors') \
#             .build()

#     def validate_faculty(self, data):
#         """Complex faculty data validation"""
#         errors = []
        
#         # Basic validation
#         if not data.get('faculty_code'):
#             errors.append('Faculty code is required')
#         if not data.get('faculty_name'):
#             errors.append('Faculty name is required')
        
#         # Format validation for faculty_code
#         if data.get('faculty_code'):
#             # Must be alphanumeric and between 3-10 characters
#             if not re.match(r'^[A-Za-z0-9]{3,10}$', data['faculty_code']):
#                 errors.append('Faculty code must be alphanumeric and between 3-10 characters')
            
#             # Must start with letter
#             if not data['faculty_code'][0].isalpha():
#                 errors.append('Faculty code must start with a letter')
            
#             # Check for existing faculty
#             if self.iceberg.check_faculty_exists(data['faculty_code']):
#                 errors.append('Faculty code already exists')

#         # Format validation for faculty_name
#         if data.get('faculty_name'):
#             # Must be between 5-100 characters
#             if not 5 <= len(data['faculty_name']) <= 100:
#                 errors.append('Faculty name must be between 5 and 100 characters')
            
#             # Must contain only letters, numbers, spaces, and basic punctuation
#             if not re.match(r'^[A-Za-z0-9\s\.,\-\']+$', data['faculty_name']):
#                 errors.append('Faculty name contains invalid characters')

#         return {
#             'is_valid': len(errors) == 0,
#             'errors': errors,
#             'data': data
#         }

#     def process_faculty(self, data):
#         """Process and enrich faculty data"""
#         try:
#             # Parse JSON data
#             faculty_data = json.loads(data)
            
#             # Add processing metadata
#             faculty_data['processing_timestamp'] = int(time.time() * 1000)
            
#             # Validate data
#             validation_result = self.validate_faculty(faculty_data)
            
#             if validation_result['is_valid']:
#                 faculty_data['validation_status'] = 'VALID'
#                 # Save to Iceberg
#                 if self.iceberg.save_faculty(faculty_data):
#                     faculty_data['storage_status'] = 'SAVED'
#                 else:
#                     faculty_data['storage_status'] = 'FAILED'
#                     faculty_data['error_message'] = 'Failed to save to Iceberg'
#             else:
#                 faculty_data['validation_status'] = 'INVALID'
#                 faculty_data['error_messages'] = validation_result['errors']
            
#             return json.dumps(faculty_data)
            
#         except Exception as e:
#             error_data = {
#                 'original_data': data,
#                 'validation_status': 'ERROR',
#                 'error_message': str(e),
#                 'processing_timestamp': int(time.time() * 1000)
#             }
#             return json.dumps(error_data)

#     def run(self):
#         """Run the faculty processing pipeline"""
#         try:
#             # Create source and sink
#             source = self.create_kafka_source()
#             error_sink = self.create_kafka_error_sink()
            
#             # Create the data stream
#             stream = self.env.from_source(
#                 source=source,
#                 watermark_strategy=WatermarkStrategy.no_watermarks(),
#                 source_name="kafka_source"
#             )
            
#             # Process the stream
#             processed_stream = stream.map(
#                 self.process_faculty,
#                 output_type=Types.STRING()
#             )
            
#             # Split stream based on validation status
#             error_stream = processed_stream.filter(
#                 lambda x: json.loads(x)['validation_status'] != 'VALID'
#             )
            
#             # Send errors back to Kafka
#             error_stream.sink_to(error_sink)
            
#             # Execute the job
#             self.env.execute("Faculty Data Processor")
            
#         except Exception as e:
#             print(f"Error running faculty processor: {str(e)}")
#             raise

# if __name__ == '__main__':
#     processor = FacultyProcessor()
#     processor.run() 

# faculty_processor_rich.py
import json
import time
import re
from pyflink.datastream import StreamExecutionEnvironment
from pyflink.table import EnvironmentSettings, StreamTableEnvironment
from pyflink.common.typeinfo import Types
from pyflink.datastream.functions import RichMapFunction

class FacultyMapFunction(RichMapFunction):
    def open(self, runtime_context):
        # buat koneksi / client Iceberg di sini (per task)
        # contoh: self.iceberg = IcebergConnector.create_client(...)
        self.iceberg = IcebergConnector(self.get_runtime_context())  # sesuaikan
    def map(self, value):
        try:
            faculty_data = json.loads(value)
            faculty_data['processing_timestamp'] = int(time.time() * 1000)

            errors = []
            code = faculty_data.get('faculty_code')
            name = faculty_data.get('faculty_name')

            if not code:
                errors.append('Faculty code is required')
            else:
                if not re.match(r'^[A-Za-z0-9]{3,10}$', code):
                    errors.append('Faculty code must be alphanumeric and 3-10 chars')
                if not code[0].isalpha():
                    errors.append('Faculty code must start with a letter')
                # check exists via client (blocking) — consider async for production
                if self.iceberg.check_faculty_exists(code):
                    errors.append('Faculty code already exists')

            if not name:
                errors.append('Faculty name is required')
            else:
                if not 5 <= len(name) <= 100:
                    errors.append('Faculty name must be between 5 and 100 chars')
                if not re.match(r'^[A-Za-z0-9\s\.,\-\']+$', name):
                    errors.append('Faculty name contains invalid characters')

            if errors:
                faculty_data['validation_status'] = 'INVALID'
                faculty_data['error_messages'] = errors
            else:
                faculty_data['validation_status'] = 'VALID'
                saved = self.iceberg.save_faculty(faculty_data)
                faculty_data['storage_status'] = 'SAVED' if saved else 'FAILED'
                if not saved:
                    faculty_data['error_message'] = 'Failed to save to Iceberg'

            return json.dumps(faculty_data)
        except Exception as e:
            return json.dumps({
                'original_data': value,
                'validation_status': 'ERROR',
                'error_message': str(e),
                'processing_timestamp': int(time.time() * 1000)
            })
        
def create_kafka_source(self):
        return KafkaSourceBuilder() \
            .set_bootstrap_servers('kafka-broker:29092') \
            .set_topics('faculty-topic') \
            .set_group_id('faculty-python-processor') \
            .set_starting_offsets('earliest') \
            .set_value_only_deserializer(SimpleStringSchema()) \
            .build()

 def create_kafka_error_sink(self):
        return KafkaSinkBuilder() \
            .set_bootstrap_servers('kafka-broker:29092') \
            .set_record_serializer(SimpleStringSchema()) \
            .set_topic('faculty-errors') \
            .build()

def main():
    env = StreamExecutionEnvironment.get_execution_environment()
    env.set_parallelism(4)
    settings = EnvironmentSettings.new_instance().in_streaming_mode().build()
    table_env = StreamTableEnvironment.create(env, settings)

    # buat source Kafka (sesuaikan API/versi)
    source = create_kafka_source(...)  # implement sesuai versi PyFlink Anda
    sink = create_kafka_error_sink(...)

    stream = env.from_source(source, watermark_strategy=..., source_name="kafka_source")
    processed = stream.map(FacultyMapFunction(), output_type=Types.STRING())

    # kirim semua non-VALID ke error sink
    error_stream = processed.filter(lambda x: json.loads(x).get('validation_status') != 'VALID')
    error_stream.sink_to(sink)

    env.execute("Faculty Data Processor")

if __name__ == '__main__':
    main()
