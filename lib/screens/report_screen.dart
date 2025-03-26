import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/emotion_record.dart';
import '../services/emotion_service.dart';
import '../services/firebase_service.dart';
import '../services/theme_service.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({Key? key}) : super(key: key);

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> with SingleTickerProviderStateMixin {
  final EmotionService _emotionService = EmotionService();
  List<EmotionRecord> _records = [];
  bool _isLoading = true;
  late TabController _tabController;
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  
  // 태그 검색 관련 상태
  List<String> _allTags = [];
  String? _selectedTag;
  List<EmotionRecord> _filteredRecords = [];
  
  // 달력 이벤트
  Map<DateTime, List<EmotionRecord>> _calendarEvents = {};
  
  final Map<String, String> _emojiMap = {
    '행복': '😊',
    '기쁨': '😄',
    '사랑': '🥰',
    '화남': '😡',
    '슬픔': '😢',
    '불안': '😰',
    '무기력': '😴',
    '지루함': '🙄',
  };
  
  // 통계 정보
  int _totalEntries = 0;
  int _daysLogged = 0;
  String _averageMood = '';
  
  // 추세 분석을 위한 변수들
  List<FlSpot> _weeklyMoodSpots = [];
  String _trendInsight = '';
  double _moodChangePercentage = 0;
  bool _isMoodImproving = false;
  
  // Common Patterns을 위한 변수들
  List<Map<String, dynamic>> _emotionPatterns = [];
  Map<String, List<EmotionRecord>> _patternRecords = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadRecords();
    _loadTags();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
    });
    
    _records = await _emotionService.getEmotionRecords();
    _records.sort((a, b) => b.timestamp.compareTo(a.timestamp)); // 최신순 정렬
    
    // 태그가 선택되어 있는 경우 필터링
    _filterRecordsByTag();
    
    // 달력 이벤트 생성
    _generateCalendarEvents();
    
    // 통계 정보 계산
    _calculateStats();
    
    // 추세 분석 실행
    _analyzeTrends();
    
    // 감정 패턴 분석
    _analyzeEmotionPatterns();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  // 태그 목록 로드
  Future<void> _loadTags() async {
    final tags = await _emotionService.getAllTags();
    setState(() {
      _allTags = tags;
    });
  }
  
  // 태그별 기록 필터링
  void _filterRecordsByTag() {
    if (_selectedTag == null) {
      _filteredRecords = List.from(_records);
    } else {
      _filteredRecords = _records
          .where((record) => record.tags.contains(_selectedTag))
          .toList();
    }
  }
  
  // 달력 이벤트 생성
  void _generateCalendarEvents() {
    _calendarEvents = {};
    
    for (var record in _records) {
      final date = DateTime(
        record.timestamp.year,
        record.timestamp.month,
        record.timestamp.day,
      );
      
      if (!_calendarEvents.containsKey(date)) {
        _calendarEvents[date] = [];
      }
      
      _calendarEvents[date]!.add(record);
    }
  }
  
  void _calculateStats() {
    // 총 기록 수
    _totalEntries = _records.length;
    
    // 기록된 날짜 수 (고유한 날짜 기준)
    final Set<String> uniqueDates = {};
    for (var record in _records) {
      uniqueDates.add(DateFormat('yyyy-MM-dd').format(record.timestamp));
    }
    _daysLogged = uniqueDates.length;
    
    // 평균 감정 계산
    if (_records.isNotEmpty) {
      final Map<String, int> emotionCounts = {};
      for (var record in _records) {
        emotionCounts[record.emotion] = (emotionCounts[record.emotion] ?? 0) + 1;
      }
      
      // 가장 많이 기록된 감정 찾기
      String mostFrequentEmotion = '';
      int maxCount = 0;
      
      emotionCounts.forEach((emotion, count) {
        if (count > maxCount) {
          maxCount = count;
          mostFrequentEmotion = emotion;
        }
      });
      
      // 영문명으로 변환 (UI 디자인과 맞추기)
      _averageMood = _getEnglishMoodName(mostFrequentEmotion);
    } else {
      _averageMood = 'No Data';
    }
  }
  
  String _getEnglishMoodName(String koreanMood) {
    // 한국어 감정 이름을 영어로 변환
    switch (koreanMood) {
      case '행복': return 'Happy';
      case '기쁨': return 'Content';
      case '사랑': return 'Loved';
      case '화남': return 'Angry';
      case '슬픔': return 'Sad';
      case '불안': return 'Anxious';
      case '무기력': return 'Tired';
      case '지루함': return 'Bored';
      default: return koreanMood;
    }
  }
  
  void _analyzeTrends() {
    if (_records.isEmpty) {
      _weeklyMoodSpots = _getDefaultSpots();
      _trendInsight = "감정 데이터가 충분하지 않습니다.";
      return;
    }
    
    // 요일별 감정 점수 계산 (0-6: 월-일)
    Map<int, List<double>> dayScores = {};
    
    // 감정 점수 매핑 (1-5 사이 값으로 변환)
    Map<String, double> emotionScores = {
      '행복': 5.0,
      '기쁨': 4.5,
      '사랑': 4.0,
      '평온': 3.5,
      '무기력': 2.5,
      '지루함': 2.0,
      '불안': 1.5,
      '슬픔': 1.0,
      '화남': 0.5,
    };
    
    // 최근 기록 사용 (2주에서 모든 기록으로 변경)
    final recentRecords = _records;
    
    // 지난주와 이번주 평균 점수 계산용
    double lastWeekSum = 0;
    int lastWeekCount = 0;
    double thisWeekSum = 0;
    int thisWeekCount = 0;
    
    // 요일별 감정 분류
    for (var record in recentRecords) {
      final score = emotionScores[record.emotion] ?? 3.0; // 기본값 3.0
      final weekday = record.timestamp.weekday % 7; // 0-6 (일-토)
      
      if (!dayScores.containsKey(weekday)) {
        dayScores[weekday] = [];
      }
      dayScores[weekday]!.add(score);
      
      // 지난주/이번주 구분
      final isThisWeek = record.timestamp.isAfter(DateTime.now().subtract(Duration(days: 7)));
      if (isThisWeek) {
        thisWeekSum += score;
        thisWeekCount++;
      } else {
        lastWeekSum += score;
        lastWeekCount++;
      }
    }
    
    // 요일별 평균 계산 및 FlSpot 생성
    _weeklyMoodSpots = [];
    for (int i = 0; i < 7; i++) {
      if (dayScores.containsKey(i) && dayScores[i]!.isNotEmpty) {
        final avg = dayScores[i]!.reduce((a, b) => a + b) / dayScores[i]!.length;
        _weeklyMoodSpots.add(FlSpot(i.toDouble(), avg));
      } else {
        // 데이터가 없는 요일은 null 처리하거나 평균값 사용
        _weeklyMoodSpots.add(FlSpot(i.toDouble(), 3.0));
      }
    }
    
    // 주간 변화 퍼센트 계산
    if (lastWeekCount > 0 && thisWeekCount > 0) {
      final lastWeekAvg = lastWeekSum / lastWeekCount;
      final thisWeekAvg = thisWeekSum / thisWeekCount;
      _moodChangePercentage = ((thisWeekAvg - lastWeekAvg) / lastWeekAvg * 100).abs();
      _isMoodImproving = thisWeekAvg > lastWeekAvg;
      
      _trendInsight = _isMoodImproving 
          ? "지난주보다 긍정적인 감정이 ${_moodChangePercentage.toStringAsFixed(1)}% 증가했습니다."
          : "지난주보다 긍정적인 감정이 ${_moodChangePercentage.toStringAsFixed(1)}% 감소했습니다.";
    } else if (thisWeekCount > 0) {
      // 이번 주 데이터만 있는 경우
      _trendInsight = "충분한 과거 데이터가 없어 비교할 수 없습니다.";
    } else {
      _trendInsight = "최근 데이터가 없습니다.";
    }
    
    // 요일별 패턴 찾기
    if (dayScores.length >= 1) { // 최소 하루 이상의 데이터가 있으면 분석
      int bestDay = -1;
      double bestScore = 0;
      int worstDay = -1;
      double worstScore = 6;
      
      dayScores.forEach((day, scores) {
        if (scores.isEmpty) return;
        
        final avg = scores.reduce((a, b) => a + b) / scores.length;
        if (avg > bestScore) {
          bestScore = avg;
          bestDay = day;
        }
        if (avg < worstScore) {
          worstScore = avg;
          worstDay = day;
        }
      });
      
      if (bestDay != -1) {
        final bestDayName = _getDayName(bestDay);
        
        if (worstDay != -1 && worstDay != bestDay) {
          final worstDayName = _getDayName(worstDay);
          _trendInsight += "\n\n$bestDayName에 가장 긍정적인 감정을, $worstDayName에 가장 부정적인 감정을 느끼는 경향이 있습니다.";
        } else {
          _trendInsight += "\n\n기록이 있는 날 중 $bestDayName에 가장 긍정적인 감정을 느끼는 경향이 있습니다.";
        }
      }
    }
  }
  
  void _analyzeEmotionPatterns() {
    if (_records.isEmpty) {
      // 기본 패턴 설정
      _emotionPatterns = [
        {'emotion': '행복', 'emoji': '😊', 'title': 'Joyful Moments', 'count': 0},
        {'emotion': '사랑', 'emoji': '❤️', 'title': 'Moments of Love', 'count': 0},
        {'emotion': '불안', 'emoji': '😰', 'title': 'Anxious Times', 'count': 0},
        {'emotion': '화남', 'emoji': '👎', 'title': 'Frustrations', 'count': 0},
      ];
      return;
    }
    
    // 감정별 기록 수 계산
    Map<String, int> emotionCounts = {};
    for (var record in _records) {
      emotionCounts[record.emotion] = (emotionCounts[record.emotion] ?? 0) + 1;
    }
    
    // 감정별 기록 그룹화
    _patternRecords = {};
    for (var record in _records) {
      if (!_patternRecords.containsKey(record.emotion)) {
        _patternRecords[record.emotion] = [];
      }
      _patternRecords[record.emotion]!.add(record);
    }
    
    // 감정 패턴 목록 생성 (가장 많은 순으로 최대 4개)
    _emotionPatterns = [];
    
    // 긍정적 감정 매핑
    Map<String, Map<String, dynamic>> positiveEmotions = {
      '행복': {'emoji': '😊', 'title': 'Joyful Moments'},
      '기쁨': {'emoji': '😄', 'title': 'Happy Times'},
      '사랑': {'emoji': '❤️', 'title': 'Moments of Love'},
    };
    
    // 부정적 감정 매핑
    Map<String, Map<String, dynamic>> negativeEmotions = {
      '화남': {'emoji': '😡', 'title': 'Frustrations'},
      '슬픔': {'emoji': '😢', 'title': 'Sad Moments'},
      '불안': {'emoji': '😰', 'title': 'Anxious Times'},
      '무기력': {'emoji': '😴', 'title': 'Low Energy'},
      '지루함': {'emoji': '🙄', 'title': 'Boredom'},
    };
    
    // 긍정적 감정과 부정적 감정 중 가장 많은 것 2개씩 선택
    List<MapEntry<String, int>> positiveEntries = emotionCounts.entries
        .where((e) => positiveEmotions.containsKey(e.key))
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    List<MapEntry<String, int>> negativeEntries = emotionCounts.entries
        .where((e) => negativeEmotions.containsKey(e.key))
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));
    
    // 긍정적 감정 추가 (최대 2개)
    for (int i = 0; i < positiveEntries.length && i < 2; i++) {
      final emotion = positiveEntries[i].key;
      final count = positiveEntries[i].value;
      final emoji = positiveEmotions[emotion]?['emoji'] ?? _emojiMap[emotion] ?? '😊';
      final title = positiveEmotions[emotion]?['title'] ?? 'Positive Moments';
      
      _emotionPatterns.add({
        'emotion': emotion,
        'emoji': emoji,
        'title': title,
        'count': count,
        'isPositive': true,
      });
    }
    
    // 부정적 감정 추가 (최대 2개)
    for (int i = 0; i < negativeEntries.length && i < 2; i++) {
      final emotion = negativeEntries[i].key;
      final count = negativeEntries[i].value;
      final emoji = negativeEmotions[emotion]?['emoji'] ?? _emojiMap[emotion] ?? '😔';
      final title = negativeEmotions[emotion]?['title'] ?? 'Challenging Moments';
      
      _emotionPatterns.add({
        'emotion': emotion,
        'emoji': emoji,
        'title': title,
        'count': count,
        'isPositive': false,
      });
    }
    
    // 패턴이 4개보다 적으면 기본 패턴으로 채우기
    if (_emotionPatterns.length < 4) {
      final defaultPatterns = [
        {'emotion': '행복', 'emoji': '😊', 'title': 'Joyful Moments', 'count': 0, 'isPositive': true},
        {'emotion': '사랑', 'emoji': '❤️', 'title': 'Moments of Love', 'count': 0, 'isPositive': true},
        {'emotion': '불안', 'emoji': '😰', 'title': 'Anxious Times', 'count': 0, 'isPositive': false},
        {'emotion': '화남', 'emoji': '👎', 'title': 'Frustrations', 'count': 0, 'isPositive': false},
      ];
      
      for (var pattern in defaultPatterns) {
        if (_emotionPatterns.length >= 4) break;
        
        // 이미 추가된 감정이 아닌 경우에만 추가
        if (!_emotionPatterns.any((p) => p['emotion'] == pattern['emotion'])) {
          _emotionPatterns.add(pattern);
        }
      }
    }
  }
  
  String _getDayName(int day) {
    const days = ['일요일', '월요일', '화요일', '수요일', '목요일', '금요일', '토요일'];
    return days[day];
  }
  
  List<FlSpot> _getDefaultSpots() {
    return [
      FlSpot(0, 3.5),
      FlSpot(1, 2.0),
      FlSpot(2, 4.0),
      FlSpot(3, 3.0),
      FlSpot(4, 5.0),
      FlSpot(5, 1.5),
      FlSpot(6, 4.0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 리포트'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.analytics), text: '통계'),
            Tab(icon: Icon(Icons.calendar_month), text: '달력'),
            Tab(icon: Icon(Icons.tag), text: '태그 검색'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // 통계 탭 (기존 코드)
                SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Overview 섹션
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Text(
                          'Overview',
                          style: TextStyle(
                            color: isDark ? Colors.white : Color(0xFF111418),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Wrap(
                          spacing: 16,
                          runSpacing: 16,
                          children: [
                            _buildOverviewCard(
                              title: 'Total Entries',
                              value: '$_totalEntries',
                              backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                            ),
                            _buildOverviewCard(
                              title: 'Days Logged',
                              value: '$_daysLogged',
                              backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        child: _buildOverviewCard(
                          title: 'Average Mood',
                          value: _averageMood,
                          backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                          isFullWidth: true,
                        ),
                      ),
                      
                      // Trends 섹션 - 기존 코드에 트렌드 인사이트 추가
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Trends',
                              style: TextStyle(
                                color: isDark ? Colors.white : Color(0xFF111418),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () {
                                showModalBottomSheet(
                                  context: context, 
                                  builder: (context) => _buildTrendDetailSheet(context),
                                );
                              },
                              child: Text('Details'),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: isDark ? Color(0xFF2C2C2C) : Color(0xFFDCE0E5), width: 1),
                          ),
                          color: isDark ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mood Across Time',
                                  style: TextStyle(
                                    color: isDark ? Colors.white : Color(0xFF111418),
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 180,
                                  child: _buildLineChart(context),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                                  children: [
                                    'M', 'T', 'W', 'T', 'F', 'S', 'S'
                                  ].map((day) => Text(
                                    day,
                                    style: TextStyle(
                                      color: Color(0xFF637588),
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )).toList(),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      
                      // Common Patterns 섹션
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                        child: Text(
                          'Common Patterns',
                          style: TextStyle(
                            color: isDark ? Colors.white : Color(0xFF111418),
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                        child: GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: NeverScrollableScrollPhysics(),
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 2.5,
                          children: _emotionPatterns.map((pattern) {
                            return InkWell(
                              onTap: () => _showPatternDetail(context, pattern),
                              child: _buildPatternCard(
                                emoji: pattern['emoji'],
                                title: pattern['title'],
                                borderColor: isDark ? Color(0xFF2C2C2C) : Color(0xFFDCE0E5),
                                backgroundColor: isDark ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                                textColor: isDark ? Colors.white : Color(0xFF111418),
                                count: pattern['count'],
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // 달력 탭 (새로 추가)
                SingleChildScrollView(
                  child: _buildCalendar(),
                ),
                
                // 태그 검색 탭 (새로 추가)
                _buildTagSearch(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await _loadRecords();
          await _loadTags();
        },
        child: const Icon(Icons.refresh),
      ),
    );
  }
  
  Widget _buildOverviewCard({
    required String title, 
    required String value, 
    required Color backgroundColor,
    bool isFullWidth = false,
  }) {
    // 다크 모드 여부 확인
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    
    return Container(
      width: isFullWidth ? double.infinity : 158,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLineChart(BuildContext context) {
    // 실제 데이터로 차트 업데이트
    final spots = _records.isEmpty ? _getDefaultSpots() : _weeklyMoodSpots;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final areaColor = isDarkMode ? Color(0xFF2A2A2A) : Color(0xFFF0F2F4);
    final lineColor = isDarkMode ? Colors.lightBlue : Color(0xFF637588);
    final textColor = isDarkMode ? Colors.white.withOpacity(0.9) : Color(0xFF637588);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LineChart(
          LineChartData(
            gridData: FlGridData(show: false),
            titlesData: FlTitlesData(show: false),
            borderData: FlBorderData(show: false),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: lineColor,
                barWidth: 3,
                isStrokeCapRound: true,
                dotData: FlDotData(
                  show: true,
                  getDotPainter: (spot, percent, barData, index) {
                    return FlDotCirclePainter(
                      radius: 4,
                      color: lineColor,
                      strokeWidth: 2,
                      strokeColor: isDarkMode ? Colors.black : Colors.white,
                    );
                  },
                ),
                belowBarData: BarAreaData(
                  show: true,
                  color: areaColor.withOpacity(0.5),
                ),
              ),
            ],
            lineTouchData: LineTouchData(
              enabled: true,
              touchTooltipData: LineTouchTooltipData(
                tooltipBgColor: isDarkMode ? Colors.grey[800]! : Colors.white,
                tooltipRoundedRadius: 8,
                getTooltipItems: (List<LineBarSpot> touchedBarSpots) {
                  return touchedBarSpots.map((barSpot) {
                    final sentiment = _getSentimentLabel(barSpot.y);
                    return LineTooltipItem(
                      sentiment,
                      TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }).toList();
                },
              ),
            ),
            minX: 0,
            maxX: 6,
            minY: 0,
            maxY: 6,
          ),
        ),
        if (_trendInsight.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Text(
              _trendInsight,
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: _isMoodImproving 
                  ? (isDarkMode ? Colors.green[300] : Colors.green[700])
                  : (isDarkMode ? Colors.orange[300] : Colors.orange[700]),
              ),
            ),
          ),
      ],
    );
  }
  
  String _getSentimentLabel(double score) {
    if (score >= 4.5) return '매우 긍정적';
    if (score >= 3.5) return '긍정적';
    if (score >= 2.5) return '중립적';
    if (score >= 1.5) return '부정적';
    return '매우 부정적';
  }
  
  Widget _buildPatternCard({
    required String emoji, 
    required String title, 
    required Color borderColor,
    required Color backgroundColor,
    required Color textColor,
    int? count,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: borderColor, width: 1),
      ),
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Text(
              emoji,
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15, 
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (count != null && count > 0)
                    Text(
                      '$count회',
                      style: TextStyle(
                        fontSize: 12,
                        color: textColor.withOpacity(0.7),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 트렌드 상세 정보를 보여주는 바텀 시트
  Widget _buildTrendDetailSheet(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    final backgroundColor = isDarkMode ? Color(0xFF121212) : Colors.white;
    
    return Container(
      padding: EdgeInsets.all(20),
      color: backgroundColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '감정 트렌드 상세 분석',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 16),
          Text(
            _trendInsight,
            style: TextStyle(
              fontSize: 16,
              color: textColor,
            ),
          ),
          SizedBox(height: 20),
          Text(
            '요일별 평균 감정 점수',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          SizedBox(height: 8),
          // 요일별 데이터 시각화
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [0, 1, 2, 3, 4, 5, 6].map((day) {
              final score = _weeklyMoodSpots.isNotEmpty 
                  ? _weeklyMoodSpots[day].y 
                  : 3.0;
              
              return Column(
                children: [
                  Container(
                    height: 100 * (score / 6),
                    width: 24,
                    decoration: BoxDecoration(
                      color: _getMoodColor(score, isDarkMode),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _getDayName(day).substring(0, 1), // 첫 글자만
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
  
  Color _getMoodColor(double score, bool isDarkMode) {
    if (isDarkMode) {
      if (score >= 4.5) return Colors.green[300]!;
      if (score >= 3.5) return Colors.lightGreen[300]!;
      if (score >= 2.5) return Colors.amber[300]!;
      if (score >= 1.5) return Colors.orange[300]!;
      return Colors.red[300]!;
    } else {
      if (score >= 4.5) return Colors.green;
      if (score >= 3.5) return Colors.lightGreen;
      if (score >= 2.5) return Colors.amber;
      if (score >= 1.5) return Colors.orange;
      return Colors.red;
    }
  }
  
  // 감정 패턴 상세 화면을 표시하는 메서드
  void _showPatternDetail(BuildContext context, Map<String, dynamic> pattern) {
    final String emotion = pattern['emotion'];
    final records = _patternRecords[emotion] ?? [];
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Color(0xFF111418);
    final backgroundColor = isDarkMode ? Colors.black : Colors.white;
    
    // 시간대별 발생 빈도 분석
    Map<String, int> timeDistribution = {
      '아침 (06:00-12:00)': 0,
      '오후 (12:00-18:00)': 0,
      '저녁 (18:00-00:00)': 0,
      '새벽 (00:00-06:00)': 0,
    };
    
    for (var record in records) {
      final hour = record.timestamp.hour;
      
      if (hour >= 6 && hour < 12) {
        timeDistribution['아침 (06:00-12:00)'] = (timeDistribution['아침 (06:00-12:00)'] ?? 0) + 1;
      } else if (hour >= 12 && hour < 18) {
        timeDistribution['오후 (12:00-18:00)'] = (timeDistribution['오후 (12:00-18:00)'] ?? 0) + 1;
      } else if (hour >= 18) {
        timeDistribution['저녁 (18:00-00:00)'] = (timeDistribution['저녁 (18:00-00:00)'] ?? 0) + 1;
      } else {
        timeDistribution['새벽 (00:00-06:00)'] = (timeDistribution['새벽 (00:00-06:00)'] ?? 0) + 1;
      }
    }
    
    // 가장 흔한 시간대 찾기
    String mostCommonTime = '데이터 없음';
    int maxCount = 0;
    
    timeDistribution.forEach((time, count) {
      if (count > maxCount) {
        maxCount = count;
        mostCommonTime = time;
      }
    });
    
    // 감정 상세 정보에서 공통 키워드 분석
    Set<String> commonWords = {};
    
    if (records.isNotEmpty) {
      // 세부 내용이 있는 기록만 필터링
      final recordsWithDetails = records.where((r) => r.details != null && r.details!.isNotEmpty).toList();
      
      if (recordsWithDetails.isNotEmpty) {
        // 모든 기록의 세부 내용에서 단어 추출 및 빈도 계산
        Map<String, int> wordFrequency = {};
        
        for (var record in recordsWithDetails) {
          final words = record.details!.split(' ').where((w) => w.length > 1);
          
          for (var word in words) {
            wordFrequency[word] = (wordFrequency[word] ?? 0) + 1;
          }
        }
        
        // 빈도가 높은 상위 3개 단어 선택
        final sortedWords = wordFrequency.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        
        if (sortedWords.isNotEmpty) {
          for (int i = 0; i < sortedWords.length && i < 3; i++) {
            commonWords.add(sortedWords[i].key);
          }
        }
      }
    }
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          maxChildSize: 0.9,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return Container(
              color: backgroundColor,
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        pattern['emoji'],
                        style: TextStyle(fontSize: 28),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pattern['title'],
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: textColor,
                              ),
                            ),
                            Text(
                              '총 ${pattern['count']}회 기록됨',
                              style: TextStyle(
                                fontSize: 14,
                                color: textColor.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  Divider(height: 32),
                  
                  // 시간 패턴
                  Text(
                    '발생 시간대',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    records.isEmpty
                        ? '아직 데이터가 충분하지 않습니다.'
                        : '주로 $mostCommonTime에 느끼는 경향이 있습니다.',
                    style: TextStyle(
                      fontSize: 15,
                      color: textColor,
                    ),
                  ),
                  
                  if (commonWords.isNotEmpty) ...[
                    SizedBox(height: 16),
                    Text(
                      '연관 키워드',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: commonWords.map((word) {
                        return Container(
                          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: pattern['isPositive'] == true
                                ? Colors.green.withOpacity(0.1)
                                : Colors.red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: pattern['isPositive'] == true
                                  ? Colors.green.withOpacity(0.3)
                                  : Colors.red.withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            word,
                            style: TextStyle(
                              color: pattern['isPositive'] == true
                                  ? Colors.green[700]
                                  : Colors.red[700],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // 최근 기록
                  Text(
                    '최근 기록',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  Expanded(
                    child: records.isEmpty
                        ? Center(
                            child: Text(
                              '아직 기록이 없습니다.',
                              style: TextStyle(
                                color: textColor.withOpacity(0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: records.length,
                            itemBuilder: (context, index) {
                              final record = records[index];
                              return Card(
                                margin: EdgeInsets.only(bottom: 8),
                                elevation: 0,
                                color: isDarkMode ? Color(0xFF1E1E1E) : Color(0xFFF0F2F4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            DateFormat('yyyy년 MM월 dd일').format(record.timestamp),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: textColor,
                                            ),
                                          ),
                                          Text(
                                            DateFormat('HH:mm').format(record.timestamp),
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: textColor.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (record.details != null && record.details!.isNotEmpty) ...[
                                        SizedBox(height: 8),
                                        Text(
                                          record.details!,
                                          style: TextStyle(
                                            color: textColor.withOpacity(0.9),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // 캘린더 위젯 빌드
  Widget _buildCalendar() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Column(
      children: [
        TableCalendar<EmotionRecord>(
          firstDay: DateTime.utc(2021, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          calendarFormat: CalendarFormat.month,
          eventLoader: (day) {
            return _calendarEvents[DateTime(day.year, day.month, day.day)] ?? [];
          },
          selectedDayPredicate: (day) {
            return isSameDay(_selectedDay, day);
          },
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
          },
          onPageChanged: (focusedDay) {
            _focusedDay = focusedDay;
          },
          calendarStyle: CalendarStyle(
            markersMaxCount: 3,
            markerDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.8),
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.3),
              shape: BoxShape.circle,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            markerBuilder: (context, date, events) {
              if (events.isEmpty) return const SizedBox.shrink();
              
              return Positioned(
                bottom: 1,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: events.take(3).map((event) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 1),
                        child: Text(
                          event.emoji,
                          style: const TextStyle(fontSize: 8),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        _buildSelectedDayEvents(),
      ],
    );
  }
  
  // 선택한 날짜의 감정 기록 표시
  Widget _buildSelectedDayEvents() {
    final events = _calendarEvents[DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    )] ?? [];
    
    if (events.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32.0),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.event_busy,
                size: 48,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                '${DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDay)}\n기록된 감정이 없습니다',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            '${DateFormat('yyyy년 MM월 dd일 (E)', 'ko_KR').format(_selectedDay)} 기록',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: events.length,
          itemBuilder: (context, index) {
            final record = events[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: ListTile(
                leading: Text(
                  record.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                title: Text(record.emotion),
                subtitle: record.details != null ? Text(record.details!) : null,
                trailing: Text(
                  DateFormat('HH:mm').format(record.timestamp),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
  
  // 태그 검색 UI
  Widget _buildTagSearch() {
    final textFieldFocus = FocusNode();
    
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '태그로 감정 기록 찾기',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      focusNode: textFieldFocus,
                      decoration: const InputDecoration(
                        labelText: '태그 검색',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.search),
                        hintText: '태그 이름 입력',
                        helperText: 'Enter 키를 눌러 검색',
                      ),
                      onSubmitted: (value) {
                        // 입력된 태그로 검색
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            _selectedTag = _allTags.contains(value.trim()) 
                                ? value.trim() 
                                : null;
                            _filterRecordsByTag();
                          });
                        } else {
                          // 비어있으면 모든 태그 보기
                          setState(() {
                            _selectedTag = null;
                            _filterRecordsByTag();
                          });
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      textFieldFocus.unfocus();
                      // 현재 필터 초기화
                      setState(() {
                        _selectedTag = null;
                        _filterRecordsByTag();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('초기화'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _allTags.map((tag) {
                  final isSelected = _selectedTag == tag;
                  return FilterChip(
                    label: Text(tag),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedTag = selected ? tag : null;
                        _filterRecordsByTag();
                      });
                    },
                    selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    checkmarkColor: Theme.of(context).colorScheme.primary,
                  );
                }).toList(),
              ),
            ],
          ),
        ),
        Expanded(
          child: _filteredRecords.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedTag != null
                            ? '"$_selectedTag" 태그가 있는 기록이 없습니다'
                            : '기록된 감정이 없습니다',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _filteredRecords.length,
                  itemBuilder: (context, index) {
                    final record = _filteredRecords[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      child: ListTile(
                        leading: Text(
                          record.emoji,
                          style: const TextStyle(fontSize: 32),
                        ),
                        title: Text(record.emotion),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (record.details != null)
                              Text(
                                record.details!,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 4,
                              children: record.tags.map((tag) => Chip(
                                label: Text(tag, style: const TextStyle(fontSize: 10)),
                                padding: EdgeInsets.zero,
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              )).toList(),
                            ),
                          ],
                        ),
                        trailing: Text(
                          DateFormat('yyyy-MM-dd\nHH:mm').format(record.timestamp),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12),
                        ),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
} 