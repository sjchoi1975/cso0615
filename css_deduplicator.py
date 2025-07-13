#!/usr/bin/env python3
import re
import sys

def remove_css_duplicates(css_content):
    """CSS 파일에서 중복된 스타일 블록을 제거합니다."""
    
    # CSS 블록을 찾는 정규식 (선택자 + 중괄호 내용)
    block_pattern = r'([^{}]+\{[^{}]*\})'
    
    # 주석 블록을 찾는 정규식
    comment_pattern = r'/\*[^*]*\*+(?:[^/*][^*]*\*+)*/'
    
    # 모든 블록을 찾습니다
    blocks = re.findall(block_pattern, css_content, re.DOTALL)
    
    # 중복 제거를 위한 딕셔너리
    unique_blocks = {}
    seen_selectors = set()
    
    # 각 블록을 처리합니다
    for block in blocks:
        # 블록을 정규화합니다 (공백 제거)
        normalized_block = re.sub(r'\s+', ' ', block.strip())
        
        # 선택자 부분을 추출합니다
        selector_match = re.match(r'([^{]+)\{', normalized_block)
        if selector_match:
            selector = selector_match.group(1).strip()
            
            # 같은 선택자가 이미 있는지 확인
            if selector not in seen_selectors:
                seen_selectors.add(selector)
                unique_blocks[selector] = block
    
    # 결과를 조합합니다
    result = []
    
    # 원본 CSS에서 순서를 유지하면서 unique 블록들을 추가
    for block in blocks:
        normalized_block = re.sub(r'\s+', ' ', block.strip())
        selector_match = re.match(r'([^{]+)\{', normalized_block)
        if selector_match:
            selector = selector_match.group(1).strip()
            if selector in unique_blocks:
                result.append(unique_blocks[selector])
                del unique_blocks[selector]  # 한 번만 추가되도록
    
    return '\n\n'.join(result)

def main():
    # CSS 파일 읽기
    with open('src/assets/main.css', 'r', encoding='utf-8') as f:
        css_content = f.read()
    
    print(f"원본 파일 크기: {len(css_content)} 문자")
    print(f"원본 파일 라인 수: {len(css_content.splitlines())} 줄")
    
    # 중복 제거 실행
    cleaned_css = remove_css_duplicates(css_content)
    
    print(f"정리된 파일 크기: {len(cleaned_css)} 문자")
    print(f"정리된 파일 라인 수: {len(cleaned_css.splitlines())} 줄")
    
    # 정리된 CSS 파일 저장
    with open('src/assets/main.css.cleaned', 'w', encoding='utf-8') as f:
        f.write(cleaned_css)
    
    print("정리된 CSS 파일이 main.css.cleaned로 저장되었습니다.")

if __name__ == "__main__":
    main() 