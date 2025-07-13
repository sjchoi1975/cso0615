import csv
import sys

def csv_to_sql(csv_file_path, output_file_path):
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        
        # 헤더 스킵
        next(reader)
        
        sql_statements = []
        sql_statements.append("-- products_mfds 테이블 데이터 INSERT")
        sql_statements.append("BEGIN;")
        
        for row in reader:
            if len(row) >= 2 and row[0] and row[1]:  # insurance_code와 detail_url이 모두 있는 경우만
                insurance_code = row[0].strip()
                detail_url = row[1].strip()
                
                # SQL 인젝션 방지를 위한 단순 이스케이프
                detail_url = detail_url.replace("'", "''")
                
                sql = f"INSERT INTO products_mfds (insurance_code, detail_url) VALUES ('{insurance_code}', '{detail_url}');"
                sql_statements.append(sql)
        
        sql_statements.append("COMMIT;")
        
        # 파일로 저장
        with open(output_file_path, 'w', encoding='utf-8') as outfile:
            outfile.write('\n'.join(sql_statements))
        
        print(f"SQL 파일이 생성되었습니다: {output_file_path}")
        print(f"총 {len(sql_statements) - 3} 개의 INSERT문이 생성되었습니다.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("사용법: python csv_to_sql.py <csv파일경로> <출력sql파일경로>")
        print("예시: python csv_to_sql.py products_mfds.csv products_mfds_insert.sql")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        csv_to_sql(csv_file, output_file)
    except Exception as e:
        print(f"오류 발생: {e}") 