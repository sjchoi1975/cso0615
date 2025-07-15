-- 정산월과 관련된 모든 데이터를 트랜잭션으로 삭제하는 RPC 함수
CREATE OR REPLACE FUNCTION delete_settlement_month_with_related_data(target_settlement_month text)
RETURNS json
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
    share_count integer := 0;
    settlements_count integer := 0;
    month_count integer := 0;
    result json;
BEGIN
    -- 트랜잭션 시작 (함수 내에서 자동으로 트랜잭션 처리됨)
    
    -- 1. settlements_share 테이블에서 해당 정산월 데이터 삭제
    DELETE FROM settlements_share 
    WHERE settlement_month = target_settlement_month;
    GET DIAGNOSTICS share_count = ROW_COUNT;
    
    -- 2. settlements 테이블에서 해당 정산월 데이터 삭제
    DELETE FROM settlements 
    WHERE settlement_month = target_settlement_month;
    GET DIAGNOSTICS settlements_count = ROW_COUNT;
    
    -- 3. settlement_months 테이블에서 해당 정산월 삭제
    DELETE FROM settlement_months 
    WHERE settlement_month = target_settlement_month;
    GET DIAGNOSTICS month_count = ROW_COUNT;
    
    -- 결과 반환
    result := json_build_object(
        'success', true,
        'settlement_month', target_settlement_month,
        'deleted_counts', json_build_object(
            'settlements_share', share_count,
            'settlements', settlements_count,
            'settlement_months', month_count
        )
    );
    
    RETURN result;
    
EXCEPTION
    WHEN OTHERS THEN
        -- 오류 발생 시 롤백 (함수에서 자동으로 처리됨)
        RAISE EXCEPTION '정산월 삭제 중 오류 발생: %', SQLERRM;
END;
$$;

-- 함수 실행 권한 부여
GRANT EXECUTE ON FUNCTION delete_settlement_month_with_related_data(text) TO authenticated;
GRANT EXECUTE ON FUNCTION delete_settlement_month_with_related_data(text) TO service_role; 