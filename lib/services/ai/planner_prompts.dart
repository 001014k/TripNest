/// 공통 규칙과 간결한 메뉴별 요청을 정의합니다. 응답 항목 이름은
/// 플래너의 장소 파서 및 저장된 장소 형식과 호환되도록 유지합니다.
class PlannerPrompts {
  static const system = '''당신은 국내 여행 계획을 돕는 AI입니다.
추천 원칙:
- 사용자가 선택한 지역·목적·동행·기간·추가 조건을 우선하고, 선택하지 않은 취향이나 동행 조건은 가정하지 않는다.
- 장소는 searchGoogleMaps로 검색하고 found: true이며 요청 지역과 일치하는 결과만 추천한다. 검색할 때 지역과 장소명을 함께 사용한다.
- 검색 결과의 장소명과 주소를 사용한다. 장소 존재 확인은 영업 여부·가격·예약·접근성 확인이 아니다.
- 도구가 제공하지 않은 거리·반경 충족 여부·시설·운영 정보는 단정하지 말고 확인이 필요함을 표시한다. 검색 실패를 폐업으로 해석하지 않는다.
- 특정 장소 질문은 해당 1곳, 목록과 코스는 최대 5곳을 추천한다. 코스는 기간에 맞춰 배분하고 긴 일정에 부족하면 추가 추천을 안내한다.
- 후보는 최대 5곳을 선정해 한 번에 검증한다. 부족한 개수를 채우기 위한 반복 검색은 하지 않는다. 조건에 맞는 결과가 부족하거나 없으면 그 사실을 알린다.
응답 규칙:
- 한국어로 간결하게 답하며 인사말은 생략한다.
- 모든 장소 추천은 아래 형식을 사용한다. 장소명 앞에 번호나 '추천 장소:'를 붙이지 않는다.
[여행 제목]
• 실제 장소명 (검증됨)
 → 주소: 검색 결과의 주소
 → 설명: 선택 조건에 맞는 추천 이유
- '(검증됨)'은 지도에서 장소 존재를 확인했다는 뜻만 가진다. 답변 끝에 이 의미를 짧게 안내한다.
- 코스는 목록 순서가 방문 순서이며, 각 설명에 예상 체류시간을 덧붙인다. 체류시간은 계획상 예상임을 명시한다.
- 검증 결과가 없으면 위 장소 형식을 채우지 말고 부족한 정보나 대안을 짧게 안내한다.''';

  static String theme(String region, Iterable<String> themes) {
    final selected = themes.toSet();
    return [
      '메뉴: 테마 여행',
      '지역: ${region.trim()}',
      '테마: ${selected.join(', ')}',
      '기간: 반나절',
      '추천 기준: ${[
        if (selected.contains('힐링')) '산책·휴식 중심, 적은 방문지와 여유로운 체류',
        if (selected.contains('맛집')) '식사 시간에 맞춘 지역 음식, 메뉴 중복 최소화',
        if (selected.contains('카페')) '분위기·뷰·디저트 특징과 이동 거리 고려',
      ].join('; ')}',
      '결과: 선택 테마를 연결한 여행 코스',
    ].join('\n');
  }

  static String nearby(
          String region, Iterable<String> categories, String radius) =>
      [
        '메뉴: 근처 명소',
        '기준 위치: ${region.trim()}',
        '종류: ${categories.join(', ')}',
        '희망 반경: $radius',
        '결과: 주변 장소 목록과 추천 이유, 거리 확인 시 가까운 순서',
      ].join('\n');

  static String stay(String region, String space, Iterable<String> moods,
          Iterable<String> types) =>
      [
        '메뉴: 스테이 & 무드',
        '지역: ${region.trim()}',
        '공간: $space',
        '분위기: ${moods.join(', ')}',
        if (types.isNotEmpty) '선호 유형: ${types.join(', ')}',
        '결과: 공간별 분위기와 추천 이유 비교',
      ].join('\n');

  static String companion(String region, String companion, String duration,
      Iterable<String> extras) {
    final selected = extras.toSet();
    final criteria = <String>{
      if (selected.contains('아이와 함께')) '짧은 이동과 중간 휴식',
      if (selected.contains('어르신과 함께') || selected.contains('걷기 적게'))
        '걷는 양과 계단 최소화, 휴식 배치',
      if (selected.contains('여러 명이 함께')) '단체 이용과 이동 편의',
    };
    return [
      '메뉴: 함께하는 여행',
      '지역: ${region.trim()}',
      '동행: $companion',
      '기간: $duration',
      if (selected.isNotEmpty) '추가 조건: ${selected.join(', ')}',
      if (criteria.isNotEmpty) '추천 기준: ${criteria.join('; ')}',
      '결과: 방문 순서가 있는 여행 코스',
    ].join('\n');
  }
}
