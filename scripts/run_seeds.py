from dotenv import load_dotenv
import os
import oracledb
from pathlib import Path

load_dotenv() 
DB_USER = os.getenv("DB_USER")
DB_PASSWORD = os.getenv("DB_PASSWORD")
WALLET_PASSWORD = os.getenv("WALLET_PASSWORD")

# Use the correct Oracle Cloud connection string
# Try the _medium or _low service instead of _high
CONNECT_STRING = '(description= (retry_count=20)(retry_delay=3)(address=(protocol=tcps)(port=1522)(host=adb.sa-santiago-1.oraclecloud.com))(connect_data=(service_name=gd0dfbff1d28f8f_mat4141_medium.adb.oraclecloud.com))(security=(ssl_server_dn_match=yes)))'

seed_files = [
    'regiones.sql',
    'provincias.sql',
    'comunas.sql',
    # 'generos.sql',
    # 'rangos_edad.sql',
    # 'tipos_institucion.sql',
    # 'tipos_acreditacion.sql',
    # 'requisitos_ingreso.sql',
    # 'vias_ingreso.sql',
    # 'modalidades.sql',
    # 'jornadas.sql',
    # 'tipos_plan.sql',
    # 'tipos_educacion.sql',
    # 'niveles_formacion.sql',
    # 'areas_conocimiento.sql'
]

def test_connection():
    connection_variants = [
        "mat4141_medium",
        "mat4141_low",
        "mat4141_high",
    ]
    
    for i, conn_str in enumerate(connection_variants):
        try:
            print(f"Testing connection variant {i+1}...")
            CONNECT_STRING = conn_str
            pool = oracledb.create_pool(
                config_dir="./wallet-mat4141",
                user=DB_USER,
                password=DB_PASSWORD,
                dsn=CONNECT_STRING,
                # If THIN mode is needed and your Python version is 3.13 and above, uncomment the following lines.
                wallet_location="./wallet-mat4141",
                wallet_password=WALLET_PASSWORD
            )
            with pool.acquire() as connection:
                with connection.cursor() as cursor:
                    cursor.execute("SELECT 1 FROM DUAL")
                    result = cursor.fetchone()
                    if result:
                        print(f"Connected successfully! Query result: {result[0]}")
            
        except oracledb.Error as e:
            print(f"✗ Connection variant {i+1} failed: {e}")
            continue
    
    return None

def run_seeds():
    try:
        print("Finding working connection...")
        working_connection = test_connection()
        
        if not working_connection:
            print("❌ No working connection found. Please check your credentials and service names.")
            return
        
        print(f"Using working connection string...")
        
        # Connect to Oracle database
        connection = oracledb.connect(
            user=DB_USER,
            password=DB_PASSWORD,
            dsn=working_connection
        )
        
        cursor = connection.cursor()
        seeds_dir = Path('seeds')
        
        for seed_file in seed_files:
            file_path = seeds_dir / seed_file
            if file_path.exists():
                print(f"Running {seed_file}...")
                with open(file_path, 'r', encoding='utf-8') as f:
                    sql_content = f.read()
                    
                    # Remove empty lines and comments
                    statements = []
                    for line in sql_content.split('\n'):
                        line = line.strip()
                        if line and not line.startswith('--'):
                            statements.append(line)
                    
                    # Join back and split by semicolon
                    full_sql = ' '.join(statements)
                    statements = [stmt.strip() for stmt in full_sql.split(';') if stmt.strip()]
                    
                    for statement in statements:
                        if statement:
                            cursor.execute(statement)
                
                print(f"✓ {seed_file} completed")
            else:
                print(f"⚠ {seed_file} not found, skipping...")
        
        # Commit all changes
        connection.commit()
        print("🎉 All seeds executed successfully!")
        
    except oracledb.Error as e:
        print(f"Oracle error: {e}")
        # Rollback on error
        if 'connection' in locals():
            connection.rollback()
    except Exception as e:
        print(f"Error: {e}")
        import traceback
        traceback.print_exc()
    finally:
        if 'cursor' in locals():
            cursor.close()
        if 'connection' in locals():
            connection.close()

if __name__ == "__main__":
    run_seeds()