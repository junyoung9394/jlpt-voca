import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ExamScreen extends StatefulWidget {
  const ExamScreen({super.key});
  @override
  State<ExamScreen> createState() => _ExamScreenState();
}

class _ExamScreenState extends State<ExamScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  static const _accentColor = Color(0xFF7B61FF);

  // ── 2026 JLPT 공식 일정 ──
  static const _exam1 = '2026-07-05'; // 제1회
  static const _exam2 = '2026-12-06'; // 제2회

  static const _jlptUrl = 'https://www.jlpt.or.kr';
  static const _registerUrl = 'https://www.jlpt.or.kr/html/sub2.html';
  static const _scheduleUrl = 'https://www.jlpt.or.kr/html/index.html';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  int _daysUntil(String dateStr) {
    final target = DateTime.parse(dateStr);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return target.difference(today).inDays;
  }

  String _formatDate(String dateStr) {
    final d = DateTime.parse(dateStr);
    const weekdays = ['월', '화', '수', '목', '금', '토', '일'];
    return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdays[d.weekday - 1]})';
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final d1 = _daysUntil(_exam1);
    final d2 = _daysUntil(_exam2);
    final nextExam = d1 >= 0 ? _exam1 : _exam2;
    final nextDays = d1 >= 0 ? d1 : d2;
    final nextRound = d1 >= 0 ? '제1회' : '제2회';

    return Scaffold(
      appBar: AppBar(
        title: const Text('🗓️ JLPT 시험 정보'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: _accentColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: _accentColor,
          tabs: const [
            Tab(text: 'D-Day'),
            Tab(text: '시험 일정'),
            Tab(text: '시험 안내'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDDayTab(nextExam, nextDays, nextRound, d1, d2),
          _buildScheduleTab(d1, d2),
          _buildInfoTab(),
        ],
      ),
    );
  }

  // ── TAB 1: D-Day ──
  Widget _buildDDayTab(
      String nextExam, int nextDays, String nextRound, int d1, int d2) {
    final isUrgent = nextDays <= 30;
    final isVeryUrgent = nextDays <= 7;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        children: [
          // 메인 D-Day 카드
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isVeryUrgent
                    ? [const Color(0xFFE91E63), const Color(0xFFFF5722)]
                    : isUrgent
                        ? [const Color(0xFFFF9800), const Color(0xFFFF5722)]
                        : [_accentColor, const Color(0xFFFF6B9D)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: (isUrgent ? Colors.orange : _accentColor)
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                )
              ],
            ),
            child: Column(
              children: [
                Text(
                  isVeryUrgent
                      ? '🔥 시험이 코앞이에요!'
                      : isUrgent
                          ? '⚡ 막판 스퍼트!'
                          : '🎯 시험 준비 중',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 12),
                Text(
                  nextDays == 0 ? '오늘이 시험 날!' : 'D-$nextDays',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 72,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text('2026년 JLPT $nextRound',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text(_formatDate(nextExam),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 두 회차 모두 표시
          Row(
            children: [
              Expanded(
                  child: _ExamRoundCard(
                round: '제1회',
                date: _formatDate(_exam1),
                days: d1,
                color: const Color(0xFF7B61FF),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _ExamRoundCard(
                round: '제2회',
                date: _formatDate(_exam2),
                days: d2,
                color: const Color(0xFFE91E63),
              )),
            ],
          ),
          const SizedBox(height: 16),

          // 오늘 학습 독려
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191B2A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _accentColor.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Text('💡 오늘의 학습 팁',
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold,
                        fontSize: 14)),
                const SizedBox(height: 8),
                Text(
                  nextDays > 60
                      ? 'D-$nextDays 남았어요. 매일 10단어씩 꾸준히 학습하면 충분해요! 🌱'
                      : nextDays > 30
                          ? 'D-$nextDays 남았어요. 모르는 단어 위주로 집중 복습할 시간이에요! 📚'
                          : nextDays > 7
                              ? 'D-$nextDays 남았어요! 오답노트 중심으로 마무리 점검하세요! ⚡'
                              : '시험이 $nextDays일 남았어요! 컨디션 관리하면서 최종 점검하세요! 🔥',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13,
                      color: isDark ? Colors.white70 : Colors.grey,
                      height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 접수 바로가기
          _LinkButton(
            label: '📝 시험 접수 바로가기',
            subtitle: '공식 JLPT 접수 페이지',
            color: _accentColor,
            onTap: () => _openUrl(_registerUrl),
          ),
        ],
      ),
    );
  }

  // ── TAB 2: 시험 일정 ──
  Widget _buildScheduleTab(int d1, int d2) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 2026 접수 일정
          const _SectionTitle('📅 2026년 제1회 접수 일정'),
          const _ScheduleCard(items: [
            ('일반 접수', '2026.04.01 (수) ~ 04.19 (일)'),
            ('추가 접수', '2026.04.27 (월) ~ 05.03 (일)'),
            ('일반 접수 취소', '2026.04.01 (수) ~ 04.26 (일)'),
            ('추가 접수 취소', '2026.04.27 (월) ~ 05.10 (일)'),
            ('정보 변경', '2026.04.01 (수) ~ 05.10 (일)'),
            ('제1회 시험일', '2026.07.05 (일)'),
          ], color: Color(0xFF7B61FF)),
          const SizedBox(height: 12),

          const _SectionTitle('📅 2026년 제2회 접수 일정'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF191B2A) : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: isDark ? Colors.white12 : Colors.grey.shade200),
            ),
            child: Row(
              children: [
                const Text('📢', style: TextStyle(fontSize: 22)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('추후 공지 예정',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.grey)),
                      const SizedBox(height: 4),
                      Text('제2회 접수 일정은 보통 8~9월에 공지돼요.\n공식 사이트를 확인해주세요.',
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey,
                              height: 1.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // 시험 날짜
          const _SectionTitle('🗓️ 2026년 시험 날짜'),
          Row(
            children: [
              Expanded(
                  child: _ExamDateCard(
                round: '제1회',
                date: '2026.07.05 (일)',
                days: d1,
                color: const Color(0xFF7B61FF),
              )),
              const SizedBox(width: 12),
              Expanded(
                  child: _ExamDateCard(
                round: '제2회',
                date: '2026.12.06 (일)',
                days: d2,
                color: const Color(0xFFE91E63),
              )),
            ],
          ),
          const SizedBox(height: 16),

          const _SectionTitle('🔗 바로가기'),
          _LinkButton(
            label: '📝 시험 접수',
            subtitle: 'jlpt.or.kr 공식 접수',
            color: _accentColor,
            onTap: () => _openUrl(_registerUrl),
          ),
          const SizedBox(height: 8),
          _LinkButton(
            label: '📋 전체 일정 보기',
            subtitle: '공식 사이트 일정 안내',
            color: const Color(0xFF00BCD4),
            onTap: () => _openUrl(_scheduleUrl),
          ),
          const SizedBox(height: 8),
          _LinkButton(
            label: '🌐 JLPT 공식 사이트',
            subtitle: 'jlpt.or.kr',
            color: const Color(0xFF4CAF50),
            onTap: () => _openUrl(_jlptUrl),
          ),
        ],
      ),
    );
  }

  // ── TAB 3: 시험 안내 ──
  Widget _buildInfoTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, 16 + MediaQuery.of(context).padding.bottom),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('📋 시험 시간표'),

          // ⚠️ 면책 문구
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF8E1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFCC02)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Text('⚠️', style: TextStyle(fontSize: 14)),
                    SizedBox(width: 6),
                    Text('주의사항',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFE65100))),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  '아래 시간표는 참고용입니다. 시험 시간은 매년 변경될 수 있으므로 반드시 공식 사이트에서 최종 확인하세요.',
                  style: TextStyle(
                      fontSize: 12, color: Color(0xFFE65100), height: 1.5),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () async {
                    final uri = Uri.parse(
                        'https://www.jlpt.or.kr/html/information_05.html');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE65100),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('공식 시간표 확인하기 →',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),

          // N1, N2
          const _TimeTableCard(
            levels: 'N1 · N2',
            color: Color(0xFFE91E63),
            rows: [
              ('시험장 개방', '09:10'),
              ('입실 완료', '09:40 (이후 입실 불가)'),
              ('1교시 (언어지식·독해)', 'N1: 10:00~11:50 / N2: 10:00~11:45'),
              ('휴식', 'N1: 11:50~12:10 / N2: 11:45~12:05'),
              ('2교시 (청해)', 'N1: 12:10~13:10 / N2: 12:05~13:00'),
            ],
          ),
          const SizedBox(height: 12),

          // N3, N4, N5
          const _TimeTableCard(
            levels: 'N3 · N4 · N5',
            color: Color(0xFF7B61FF),
            rows: [
              ('시험장 개방', '13:10'),
              ('입실 완료', '13:40 (이후 입실 불가)'),
              (
                '1교시 (언어지식·어휘)',
                'N3: 14:00~14:30 / N4: 14:00~14:25 / N5: 14:00~14:20'
              ),
              (
                '2교시 (언어지식·독해)',
                'N3: 14:35~15:45 / N4: 14:30~15:25 / N5: 14:25~15:05'
              ),
              ('휴식', 'N3: 15:45~16:05 / N4: 15:25~15:45 / N5: 15:05~15:25'),
              (
                '3교시 (청해)',
                'N3: 16:05~16:50 / N4: 15:45~16:25 / N5: 15:25~16:00'
              ),
            ],
          ),
          const SizedBox(height: 16),

          const _SectionTitle('📊 레벨별 합격 기준'),
          const Padding(
            padding: EdgeInsets.only(bottom: 8),
            child: Text('※ 합격 기준은 변경될 수 있으니 공식 사이트를 참고하세요.',
                style: TextStyle(fontSize: 11, color: Colors.grey)),
          ),
          const _PassScoreCard(),
          const SizedBox(height: 16),

          const _SectionTitle('⚠️ 시험 당일 준비물'),
          const _PrepCard(),
          SizedBox(height: 28 + MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

// ── 위젯 컴포넌트 ──

class _ExamRoundCard extends StatelessWidget {
  final String round, date;
  final int days;
  final Color color;
  const _ExamRoundCard(
      {required this.round,
      required this.date,
      required this.days,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isPast = days < 0;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isPast
            ? (isDark ? const Color(0xFF191B2A) : Colors.grey.shade100)
            : color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isPast
                ? (isDark ? Colors.white12 : Colors.grey.shade300)
                : color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(round,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isPast ? Colors.grey : color)),
          const SizedBox(height: 4),
          Text(isPast ? '시험 완료' : 'D-$days',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: isPast ? Colors.grey : color)),
          Text(date,
              style: TextStyle(
                  fontSize: 10, color: isDark ? Colors.white70 : Colors.grey)),
        ],
      ),
    );
  }
}

class _ExamDateCard extends StatelessWidget {
  final String round, date;
  final int days;
  final Color color;
  const _ExamDateCard(
      {required this.round,
      required this.date,
      required this.days,
      required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(children: [
        Text(round,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.bold, color: color)),
        const SizedBox(height: 6),
        Text(date,
            style: TextStyle(
                color: isDark ? Colors.white : Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(days >= 0 ? 'D-$days' : '종료',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.w900, color: color)),
      ]),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle(this.title);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(title,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white
                    : Colors.black87)),
      );
}

class _ScheduleCard extends StatelessWidget {
  final List<(String, String)> items;
  final Color color;
  const _ScheduleCard({required this.items, required this.color});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final i = e.key;
          final item = e.value;
          return Column(children: [
            if (i > 0)
              Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade100),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(children: [
                Container(
                    width: 6,
                    height: 6,
                    decoration:
                        BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 10),
                Text(item.$1,
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark ? Colors.white70 : Colors.grey)),
                const Spacer(),
                Text(item.$2,
                    style: TextStyle(
                        color: isDark ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.bold)),
              ]),
            ),
          ]);
        }).toList(),
      ),
    );
  }
}

class _TimeTableCard extends StatelessWidget {
  final String levels;
  final Color color;
  final List<(String, String)> rows;
  const _TimeTableCard(
      {required this.levels, required this.color, required this.rows});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: isDark ? 0.17 : 0.1),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
            ),
            child: Text(levels,
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
          ),
          ...rows.asMap().entries.map((e) {
            final i = e.key;
            final row = e.value;
            return Column(children: [
              if (i > 0)
                Divider(
                    height: 1,
                    color: isDark ? Colors.white12 : Colors.grey.shade100),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 110,
                      child: Text(row.$1,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey)),
                    ),
                    Expanded(
                      child: Text(row.$2,
                          style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 12,
                              fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ),
            ]);
          }),
        ],
      ),
    );
  }
}

class _PassScoreCard extends StatelessWidget {
  const _PassScoreCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const levels = [
      ('N1', '180점', '100점', '19점', Color(0xFFFF5722)),
      ('N2', '180점', '90점', '19점', Color(0xFFE91E63)),
      ('N3', '180점', '95점', '19점', Color(0xFF9C27B0)),
      ('N4', '180점', '90점', '38점', Color(0xFF2196F3)),
      ('N5', '180점', '80점', '38점', Color(0xFF4CAF50)),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(children: [
        // 헤더
        Container(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF232536) : Colors.grey.shade100,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(13)),
          ),
          child: Row(children: [
            SizedBox(
                width: 36,
                child: Text('레벨',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87))),
            const SizedBox(width: 8),
            Expanded(
                child: Text('총점',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center)),
            Expanded(
                child: Text('합격점',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center)),
            Expanded(
                child: Text('과목별 최저',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87),
                    textAlign: TextAlign.center)),
          ]),
        ),
        ...levels.map((l) => Column(children: [
              Divider(
                  height: 1,
                  color: isDark ? Colors.white12 : Colors.grey.shade100),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Row(children: [
                  Container(
                    width: 36,
                    height: 24,
                    decoration: BoxDecoration(
                        color: l.$5.withValues(alpha: isDark ? 0.18 : 0.1),
                        borderRadius: BorderRadius.circular(6)),
                    child: Center(
                        child: Text(l.$1,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: l.$5))),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                      child: Text(l.$2,
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? Colors.white : Colors.black87),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text(l.$3,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: l.$5),
                          textAlign: TextAlign.center)),
                  Expanded(
                      child: Text(l.$4,
                          style: TextStyle(
                              fontSize: 12,
                              color: isDark ? Colors.white70 : Colors.grey),
                          textAlign: TextAlign.center)),
                ]),
              ),
            ])),
      ]),
    );
  }
}

class _PrepCard extends StatelessWidget {
  const _PrepCard();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const items = [
      ('✅', '수험표 (사전 출력 필수)'),
      ('✅', '신분증 (주민등록증, 여권, 운전면허증)'),
      ('✅', '연필 또는 샤프 (볼펜 사용 불가)'),
      ('✅', '지우개'),
      ('⚠️', '전자기기 시험 중 사용 금지'),
      ('⚠️', '입실 완료 시간 이후 입장 불가'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF191B2A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
      ),
      child: Column(
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(children: [
                    Text(item.$1, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 10),
                    Expanded(
                        child: Text(item.$2,
                            style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark ? Colors.white : Colors.black87))),
                  ]),
                ))
            .toList(),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  final String label, subtitle;
  final Color color;
  final VoidCallback onTap;
  const _LinkButton(
      {required this.label,
      required this.subtitle,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF191B2A) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.25)),
          boxShadow: [
            BoxShadow(
                color: color.withValues(alpha: 0.08),
                blurRadius: 8,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.16 : 0.1),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.open_in_new, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white70 : Colors.grey)),
              ])),
          Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey.shade400),
        ]),
      ),
    );
  }
}
