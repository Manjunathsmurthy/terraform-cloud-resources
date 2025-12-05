#!/usr/bin/env python3
"""
Database Migration Tool
Supports: SQL Server → PostgreSQL/Oracle, Oracle → Aurora/PostgreSQL, On-Premise → Cloud
Author: Cloud Data Engineering Team
"""

import argparse
import json
import logging
from typing import Dict, List, Tuple
import sys
from dataclasses import dataclass
from datetime import datetime

try:
    import sqlalchemy
    import pandas as pd
except ImportError:
    print("Required packages: sqlalchemy, pandas, pymssql, psycopg2-binary, cx_Oracle")
    sys.exit(1)

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

@dataclass
class DatabaseConfig:
    """Database connection configuration"""
    host: str
    port: int
    database: str
    username: str
    password: str
    db_type: str  # mssql, postgresql, oracle, mysql, aurora

class DatabaseMigrationTool:
    """Comprehensive database migration tool"""
    
    def __init__(self, source_db: DatabaseConfig, target_db: DatabaseConfig):
        self.source_db = source_db
        self.target_db = target_db
        self.source_conn = None
        self.target_conn = None
        self.migration_stats = {
            'tables_migrated': 0,
            'rows_migrated': 0,
            'errors': [],
            'start_time': datetime.now(),
            'end_time': None
        }
    
    def build_connection_string(self, db_config: DatabaseConfig) -> str:
        """Build SQLAlchemy connection string based on database type"""
        if db_config.db_type == 'mssql':
            return f"mssql+pyodbc://{db_config.username}:{db_config.password}@{db_config.host}:{db_config.port}/{db_config.database}?driver=ODBC+Driver+17+for+SQL+Server"
        elif db_config.db_type == 'postgresql' or db_config.db_type == 'aurora':
            return f"postgresql://{db_config.username}:{db_config.password}@{db_config.host}:{db_config.port}/{db_config.database}"
        elif db_config.db_type == 'oracle':
            return f"oracle+cx_oracle://{db_config.username}:{db_config.password}@{db_config.host}:{db_config.port}/{db_config.database}"
        elif db_config.db_type == 'mysql':
            return f"mysql+pymysql://{db_config.username}:{db_config.password}@{db_config.host}:{db_config.port}/{db_config.database}"
        else:
            raise ValueError(f"Unsupported database type: {db_config.db_type}")
    
    def connect(self) -> bool:
        """Establish database connections"""
        try:
            logger.info(f"Connecting to source database: {self.source_db.host}")
            source_engine = sqlalchemy.create_engine(
                self.build_connection_string(self.source_db),
                echo=False
            )
            self.source_conn = source_engine.connect()
            
            logger.info(f"Connecting to target database: {self.target_db.host}")
            target_engine = sqlalchemy.create_engine(
                self.build_connection_string(self.target_db),
                echo=False
            )
            self.target_conn = target_engine.connect()
            
            logger.info("✓ Database connections established")
            return True
        except Exception as e:
            logger.error(f"✗ Connection failed: {str(e)}")
            return False
    
    def get_tables(self) -> List[str]:
        """Get list of tables from source database"""
        try:
            inspector = sqlalchemy.inspect(self.source_conn.engine)
            tables = inspector.get_table_names()
            logger.info(f"Found {len(tables)} tables in source database")
            return tables
        except Exception as e:
            logger.error(f"Error retrieving tables: {str(e)}")
            return []
    
    def migrate_table(self, table_name: str, chunk_size: int = 10000) -> bool:
        """Migrate single table with chunking for large tables"""
        try:
            logger.info(f"Migrating table: {table_name}")
            
            # Read in chunks
            chunks_migrated = 0
            total_rows = 0
            
            for chunk in pd.read_sql_table(
                table_name,
                self.source_conn,
                chunksize=chunk_size
            ):
                chunk.to_sql(
                    table_name,
                    self.target_conn,
                    if_exists='append' if chunks_migrated > 0 else 'replace',
                    index=False
                )
                chunks_migrated += 1
                total_rows += len(chunk)
            
            self.migration_stats['tables_migrated'] += 1
            self.migration_stats['rows_migrated'] += total_rows
            logger.info(f"✓ {table_name}: {total_rows} rows migrated")
            return True
        except Exception as e:
            error_msg = f"Error migrating {table_name}: {str(e)}"
            logger.error(f"✗ {error_msg}")
            self.migration_stats['errors'].append(error_msg)
            return False
    
    def validate_migration(self, table_name: str) -> bool:
        """Validate table migration"""
        try:
            source_count = pd.read_sql(
                f"SELECT COUNT(*) as cnt FROM {table_name}",
                self.source_conn
            ).iloc[0, 0]
            
            target_count = pd.read_sql(
                f"SELECT COUNT(*) as cnt FROM {table_name}",
                self.target_conn
            ).iloc[0, 0]
            
            if source_count == target_count:
                logger.info(f"✓ Validation passed for {table_name}: {source_count} rows")
                return True
            else:
                logger.warning(f"✗ Row count mismatch for {table_name}: Source={source_count}, Target={target_count}")
                return False
        except Exception as e:
            logger.error(f"Validation error for {table_name}: {str(e)}")
            return False
    
    def perform_migration(self, tables: List[str] = None) -> Dict:
        """Execute full migration"""
        if not self.connect():
            return self.migration_stats
        
        if tables is None:
            tables = self.get_tables()
        
        logger.info(f"Starting migration of {len(tables)} tables...")
        
        for table in tables:
            self.migrate_table(table)
            self.validate_migration(table)
        
        self.migration_stats['end_time'] = datetime.now()
        self.migration_stats['duration'] = str(
            self.migration_stats['end_time'] - self.migration_stats['start_time']
        )
        
        return self.migration_stats
    
    def close_connections(self):
        """Close database connections"""
        if self.source_conn:
            self.source_conn.close()
        if self.target_conn:
            self.target_conn.close()
        logger.info("Database connections closed")

def main():
    parser = argparse.ArgumentParser(description="Database Migration Tool")
    parser.add_argument('--source-type', required=True, choices=['mssql', 'oracle', 'postgresql', 'mysql'])
    parser.add_argument('--source-host', required=True)
    parser.add_argument('--source-port', type=int, required=True)
    parser.add_argument('--source-db', required=True)
    parser.add_argument('--source-user', required=True)
    parser.add_argument('--source-pass', required=True)
    
    parser.add_argument('--target-type', required=True, choices=['postgresql', 'aurora', 'oracle', 'mysql'])
    parser.add_argument('--target-host', required=True)
    parser.add_argument('--target-port', type=int, required=True)
    parser.add_argument('--target-db', required=True)
    parser.add_argument('--target-user', required=True)
    parser.add_argument('--target-pass', required=True)
    
    parser.add_argument('--tables', nargs='*', help='Specific tables to migrate')
    parser.add_argument('--output', help='Output file for migration report')
    
    args = parser.parse_args()
    
    source_config = DatabaseConfig(
        host=args.source_host,
        port=args.source_port,
        database=args.source_db,
        username=args.source_user,
        password=args.source_pass,
        db_type=args.source_type
    )
    
    target_config = DatabaseConfig(
        host=args.target_host,
        port=args.target_port,
        database=args.target_db,
        username=args.target_user,
        password=args.target_pass,
        db_type=args.target_type
    )
    
    tool = DatabaseMigrationTool(source_config, target_config)
    stats = tool.perform_migration(args.tables)
    
    # Print summary
    print("\n=== Migration Summary ===")
    print(f"Tables migrated: {stats['tables_migrated']}")
    print(f"Total rows: {stats['rows_migrated']}")
    print(f"Duration: {stats['duration']}")
    if stats['errors']:
        print(f"Errors: {len(stats['errors'])}")
        for error in stats['errors']:
            print(f"  - {error}")
    
    if args.output:
        with open(args.output, 'w') as f:
            json.dump(stats, f, indent=2, default=str)
        print(f"Report saved to: {args.output}")
    
    tool.close_connections()

if __name__ == "__main__":
    main()
