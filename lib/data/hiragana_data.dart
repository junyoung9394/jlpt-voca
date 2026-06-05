import '../models/kana_item.dart';

const List<KanaItem> hiraganaData = [
  // あ行
  KanaItem(character: 'あ', readingKo: '아', romaji: 'a', exampleWord: 'あめ', exampleMeaning: '비'),
  KanaItem(character: 'い', readingKo: '이', romaji: 'i', exampleWord: 'いぬ', exampleMeaning: '개'),
  KanaItem(character: 'う', readingKo: '우', romaji: 'u', exampleWord: 'うみ', exampleMeaning: '바다'),
  KanaItem(character: 'え', readingKo: '에', romaji: 'e', exampleWord: 'えき', exampleMeaning: '역'),
  KanaItem(character: 'お', readingKo: '오', romaji: 'o', exampleWord: 'おかね', exampleMeaning: '돈'),
  // か行
  KanaItem(character: 'か', readingKo: '카', romaji: 'ka', exampleWord: 'かさ', exampleMeaning: '우산'),
  KanaItem(character: 'き', readingKo: '키', romaji: 'ki', exampleWord: 'きって', exampleMeaning: '우표'),
  KanaItem(character: 'く', readingKo: '쿠', romaji: 'ku', exampleWord: 'くつ', exampleMeaning: '신발'),
  KanaItem(character: 'け', readingKo: '케', romaji: 'ke', exampleWord: 'けいたい', exampleMeaning: '휴대폰'),
  KanaItem(character: 'こ', readingKo: '코', romaji: 'ko', exampleWord: 'こうえん', exampleMeaning: '공원'),
  // さ行
  KanaItem(character: 'さ', readingKo: '사', romaji: 'sa', exampleWord: 'さくら', exampleMeaning: '벚꽃'),
  KanaItem(character: 'し', readingKo: '시', romaji: 'shi', exampleWord: 'しんぶん', exampleMeaning: '신문'),
  KanaItem(character: 'す', readingKo: '스', romaji: 'su', exampleWord: 'すし', exampleMeaning: '스시'),
  KanaItem(character: 'せ', readingKo: '세', romaji: 'se', exampleWord: 'せんせい', exampleMeaning: '선생님'),
  KanaItem(character: 'そ', readingKo: '소', romaji: 'so', exampleWord: 'そら', exampleMeaning: '하늘'),
  // た行
  KanaItem(character: 'た', readingKo: '타', romaji: 'ta', exampleWord: 'たまご', exampleMeaning: '달걀'),
  KanaItem(character: 'ち', readingKo: '치', romaji: 'chi', exampleWord: 'ちかてつ', exampleMeaning: '지하철'),
  KanaItem(character: 'つ', readingKo: '츠', romaji: 'tsu', exampleWord: 'つき', exampleMeaning: '달'),
  KanaItem(character: 'て', readingKo: '테', romaji: 'te', exampleWord: 'てがみ', exampleMeaning: '편지'),
  KanaItem(character: 'と', readingKo: '토', romaji: 'to', exampleWord: 'とり', exampleMeaning: '새'),
  // な行
  KanaItem(character: 'な', readingKo: '나', romaji: 'na', exampleWord: 'なまえ', exampleMeaning: '이름'),
  KanaItem(character: 'に', readingKo: '니', romaji: 'ni', exampleWord: 'にほん', exampleMeaning: '일본'),
  KanaItem(character: 'ぬ', readingKo: '누', romaji: 'nu', exampleWord: 'ぬいぐるみ', exampleMeaning: '인형'),
  KanaItem(character: 'ね', readingKo: '네', romaji: 'ne', exampleWord: 'ねこ', exampleMeaning: '고양이'),
  KanaItem(character: 'の', readingKo: '노', romaji: 'no', exampleWord: 'のみもの', exampleMeaning: '음료'),
  // は行
  KanaItem(character: 'は', readingKo: '하', romaji: 'ha', exampleWord: 'はな', exampleMeaning: '꽃'),
  KanaItem(character: 'ひ', readingKo: '히', romaji: 'hi', exampleWord: 'ひと', exampleMeaning: '사람'),
  KanaItem(character: 'ふ', readingKo: '후', romaji: 'fu', exampleWord: 'ふね', exampleMeaning: '배'),
  KanaItem(character: 'へ', readingKo: '헤', romaji: 'he', exampleWord: 'へや', exampleMeaning: '방'),
  KanaItem(character: 'ほ', readingKo: '호', romaji: 'ho', exampleWord: 'ほん', exampleMeaning: '책'),
  // ま行
  KanaItem(character: 'ま', readingKo: '마', romaji: 'ma', exampleWord: 'まち', exampleMeaning: '마을'),
  KanaItem(character: 'み', readingKo: '미', romaji: 'mi', exampleWord: 'みず', exampleMeaning: '물'),
  KanaItem(character: 'む', readingKo: '무', romaji: 'mu', exampleWord: 'むし', exampleMeaning: '벌레'),
  KanaItem(character: 'め', readingKo: '메', romaji: 'me', exampleWord: 'めがね', exampleMeaning: '안경'),
  KanaItem(character: 'も', readingKo: '모', romaji: 'mo', exampleWord: 'もり', exampleMeaning: '숲'),
  // や行
  KanaItem(character: 'や', readingKo: '야', romaji: 'ya', exampleWord: 'やま', exampleMeaning: '산'),
  KanaItem(character: 'ゆ', readingKo: '유', romaji: 'yu', exampleWord: 'ゆき', exampleMeaning: '눈'),
  KanaItem(character: 'よ', readingKo: '요', romaji: 'yo', exampleWord: 'よる', exampleMeaning: '밤'),
  // ら行
  KanaItem(character: 'ら', readingKo: '라', romaji: 'ra', exampleWord: 'らじお', exampleMeaning: '라디오'),
  KanaItem(character: 'り', readingKo: '리', romaji: 'ri', exampleWord: 'りんご', exampleMeaning: '사과'),
  KanaItem(character: 'る', readingKo: '루', romaji: 'ru', exampleWord: 'るす', exampleMeaning: '부재중'),
  KanaItem(character: 'れ', readingKo: '레', romaji: 're', exampleWord: 'れいぞうこ', exampleMeaning: '냉장고'),
  KanaItem(character: 'ろ', readingKo: '로', romaji: 'ro', exampleWord: 'ろうか', exampleMeaning: '복도'),
  // わ行
  KanaItem(character: 'わ', readingKo: '와', romaji: 'wa', exampleWord: 'わたし', exampleMeaning: '나'),
  KanaItem(character: 'を', readingKo: '오(를)', romaji: 'wo', exampleWord: 'をつかう', exampleMeaning: '~을/를 (조사)'),
  KanaItem(character: 'ん', readingKo: '응/은', romaji: 'n', exampleWord: 'でんわ', exampleMeaning: '전화'),
  // が行 (탁음)
  KanaItem(character: 'が', readingKo: '가', romaji: 'ga', exampleWord: 'がっこう', exampleMeaning: '학교'),
  KanaItem(character: 'ぎ', readingKo: '기', romaji: 'gi', exampleWord: 'ぎんこう', exampleMeaning: '은행'),
  KanaItem(character: 'ぐ', readingKo: '구', romaji: 'gu', exampleWord: 'ぐあい', exampleMeaning: '상태'),
  KanaItem(character: 'げ', readingKo: '게', romaji: 'ge', exampleWord: 'げんき', exampleMeaning: '건강'),
  KanaItem(character: 'ご', readingKo: '고', romaji: 'go', exampleWord: 'ごはん', exampleMeaning: '밥'),
  // ざ行
  KanaItem(character: 'ざ', readingKo: '자', romaji: 'za', exampleWord: 'ざっし', exampleMeaning: '잡지'),
  KanaItem(character: 'じ', readingKo: '지', romaji: 'ji', exampleWord: 'じかん', exampleMeaning: '시간'),
  KanaItem(character: 'ず', readingKo: '즈', romaji: 'zu', exampleWord: 'ずつう', exampleMeaning: '두통'),
  KanaItem(character: 'ぜ', readingKo: '제', romaji: 'ze', exampleWord: 'ぜんぶ', exampleMeaning: '전부'),
  KanaItem(character: 'ぞ', readingKo: '조', romaji: 'zo', exampleWord: 'ぞう', exampleMeaning: '코끼리'),
  // だ行
  KanaItem(character: 'だ', readingKo: '다', romaji: 'da', exampleWord: 'だいがく', exampleMeaning: '대학교'),
  KanaItem(character: 'ぢ', readingKo: '지', romaji: 'di', exampleWord: 'はなぢ', exampleMeaning: '코피'),
  KanaItem(character: 'づ', readingKo: '즈', romaji: 'du', exampleWord: 'こづつみ', exampleMeaning: '소포'),
  KanaItem(character: 'で', readingKo: '데', romaji: 'de', exampleWord: 'でんしゃ', exampleMeaning: '전철'),
  KanaItem(character: 'ど', readingKo: '도', romaji: 'do', exampleWord: 'どこ', exampleMeaning: '어디'),
  // ば行
  KanaItem(character: 'ば', readingKo: '바', romaji: 'ba', exampleWord: 'ばしょ', exampleMeaning: '장소'),
  KanaItem(character: 'び', readingKo: '비', romaji: 'bi', exampleWord: 'びょういん', exampleMeaning: '병원'),
  KanaItem(character: 'ぶ', readingKo: '부', romaji: 'bu', exampleWord: 'ぶんか', exampleMeaning: '문화'),
  KanaItem(character: 'べ', readingKo: '베', romaji: 'be', exampleWord: 'べんきょう', exampleMeaning: '공부'),
  KanaItem(character: 'ぼ', readingKo: '보', romaji: 'bo', exampleWord: 'ぼうし', exampleMeaning: '모자'),
  // ぱ行 (반탁음)
  KanaItem(character: 'ぱ', readingKo: '파', romaji: 'pa', exampleWord: 'ぱんだ', exampleMeaning: '판다'),
  KanaItem(character: 'ぴ', readingKo: '피', romaji: 'pi', exampleWord: 'ぴあの', exampleMeaning: '피아노'),
  KanaItem(character: 'ぷ', readingKo: '푸', romaji: 'pu', exampleWord: 'ぷーる', exampleMeaning: '수영장'),
  KanaItem(character: 'ぺ', readingKo: '페', romaji: 'pe', exampleWord: 'ぺん', exampleMeaning: '펜'),
  KanaItem(character: 'ぽ', readingKo: '포', romaji: 'po', exampleWord: 'ぽすと', exampleMeaning: '우체통'),
];
