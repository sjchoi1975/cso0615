import csv
import sys
from collections import defaultdict

def csv_to_sql_with_duplicates(csv_file_path, output_file_path):
    data_dict = {}  # 중복 제거용 딕셔너리
    duplicates = defaultdict(list)  # 중복 데이터 추적
    
    with open(csv_file_path, 'r', encoding='utf-8') as csvfile:
        reader = csv.reader(csvfile)
        
        # 헤더 스킵
        next(reader)
        
        for row_num, row in enumerate(reader, start=2):  # 헤더 다음부터 시작
            if len(row) >= 2 and row[0] and row[1]:
                insurance_code = row[0].strip()
                detail_url = row[1].strip()
                
                if insurance_code in data_dict:
                    # 중복 발견
                    duplicates[insurance_code].append({
                        'row': row_num,
                        'url': detail_url
                    })
                    print(f"중복 발견: {insurance_code} (행 {row_num})")
                else:
                    data_dict[insurance_code] = detail_url
    
    # 중복 리포트
    if duplicates:
        print(f"\n=== 중복 데이터 리포트 ===")
        for insurance_code, dup_list in duplicates.items():
            print(f"보험코드: {insurance_code}")
            print(f"  - 원본 URL: {data_dict[insurance_code]}")
            for dup in dup_list:
                print(f"  - 중복 (행 {dup['row']}): {dup['url']}")
        print(f"총 {len(duplicates)}개의 중복 보험코드 발견")
    
    # SQL 생성
    sql_statements = []
    sql_statements.append("-- products_mfds 테이블 데이터 INSERT (중복 제거됨)")
    sql_statements.append("BEGIN;")
    
    for insurance_code, detail_url in data_dict.items():
        # SQL 인젝션 방지
        detail_url = detail_url.replace("'", "''")
        
        sql = f"INSERT INTO products_mfds (insurance_code, detail_url) VALUES ('{insurance_code}', '{detail_url}') ON CONFLICT (insurance_code) DO UPDATE SET detail_url = EXCLUDED.detail_url, updated_at = NOW();"
        sql_statements.append(sql)
    
    sql_statements.append("COMMIT;")
    
    # 파일로 저장
    with open(output_file_path, 'w', encoding='utf-8') as outfile:
        outfile.write('\n'.join(sql_statements))
    
    print(f"\nSQL 파일이 생성되었습니다: {output_file_path}")
    print(f"총 {len(data_dict)}개의 고유한 INSERT문이 생성되었습니다.")
    if duplicates:
        print(f"중복 제거로 {sum(len(dup_list) for dup_list in duplicates.values())}개 행이 제외되었습니다.")

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("사용법: python csv_to_sql_with_duplicates.py <csv파일경로> <출력sql파일경로>")
        print("예시: python csv_to_sql_with_duplicates.py products_mfds.csv products_mfds_insert.sql")
        sys.exit(1)
    
    csv_file = sys.argv[1]
    output_file = sys.argv[2]
    
    try:
        csv_to_sql_with_duplicates(csv_file, output_file)
    except Exception as e:
        print(f"오류 발생: {e}") 