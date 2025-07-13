CREATE OR REPLACE VIEW filtering_requests_view AS
SELECT 
    fr.id,
    fr.created_at,
    fr.updated_at,
    fr.member_id,
    fr.hospital_id,
    fr.pharmaceutical_company_id,
    fr.filter_type,
    fr.status,
    fr.user_remarks as member_comments,
    fr.admin_comments,
    m.company_name as member_name,
    m.ceo_name,
    m.biz_no as member_biz_no,
    h.hospital_name,
    h.business_registration_number as hospita_biz_no,
    h.director_name as hospita_director_name,
    h.address as hospita_address,
    pc.company_name as pharmacist_name,
    CASE WHEN fr.status = 'pending' THEN 0 ELSE 1 END as is_processed,
    CASE WHEN fr.status = 'pending' THEN fr.created_at ELSE fr.updated_at END as sort_date,
    fr.updated_at as processed_at
FROM filtering_requests fr
LEFT JOIN members m ON fr.member_id = m.id
LEFT JOIN hospitals h ON fr.hospital_id = h.id
LEFT JOIN pharmaceutical_companies pc ON fr.pharmaceutical_company_id = pc.id
ORDER BY is_processed ASC, sort_date DESC; 