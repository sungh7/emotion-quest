import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import '../services/emotion_service.dart';

class EmotionStatsScreen extends StatefulWidget {
  const EmotionStatsScreen({Key? key}) : super(key: key);

  @override
  State<EmotionStatsScreen> createState() => _EmotionStatsScreenState();
}

class _EmotionStatsScreenState extends State<EmotionStatsScreen> {
  bool _isLoading = false;
  final Map<String, int> _emotionCounts = {};
  final Map<String, int> _tagCounts = {};
  List<Map<String, dynamic>> _weeklyData = [];
  TimeRange _selectedTimeRange = TimeRange.week;
  
  @override
  void initState() {
    super.initState();
    _loadStats();
  }
  
  Future<void> _loadStats() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }
    
    try {
      final emotionService = Provider.of<EmotionService>(context, listen: false);
      
      // 감정 기록 가져오기 (캐치 추가)
      List<dynamic> records = [];
      try {
        records = await emotionService.getEmotionRecords();
        print('감정 기록 ${records.length}개 로드됨');
      } catch (e) {
        print('감정 기록 로드 오류: $e');
        records = [];
      }
      
      // 시간 범위에 따라 필터링
      final filteredRecords = _filterRecordsByTimeRange(records);
      
      // 감정별 카운트
      final emotionCounts = <String, int>{};
      // 태그별 카운트
      final tagCounts = <String, int>{};
      // 주간 데이터
      final weeklyData = <Map<String, dynamic>>[];
      
      // 오늘 날짜
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      // 일주일 전 날짜
      final weekAgo = today.subtract(const Duration(days: 7));
      
      // 일별 기록 개수 초기화
      for (int i = 0; i <= 7; i++) {
        final date = weekAgo.add(Duration(days: i));
        weeklyData.add({
          'date': date,
          'count': 0,
        });
      }
      
      // 레코드 순회하며 통계 데이터 수집
      for (final record in filteredRecords) {
        try {
          // 감정 카운트
          final emotion = record.emotion;
          emotionCounts[emotion] = (emotionCounts[emotion] ?? 0) + 1;
          
          // 태그 카운트
          for (final tag in record.tags) {
            tagCounts[tag] = (tagCounts[tag] ?? 0) + 1;
          }
          
          // 일별 기록 카운트
          DateTime recordDate;
          try {
            if (record.timestamp is String) {
              recordDate = DateTime.parse(record.timestamp);
            } else if (record.timestamp is DateTime) {
              recordDate = record.timestamp;
            } else {
              print('지원되지 않는 timestamp 형식: ${record.timestamp.runtimeType}');
              continue;
            }
          } catch (e) {
            print('날짜 파싱 오류: ${record.timestamp} - $e');
            continue;
          }
          
          final recordDay = DateTime(recordDate.year, recordDate.month, recordDate.day);
          
          // 지난 7일 내의 기록인지 확인
          if (recordDay.isAfter(weekAgo.subtract(const Duration(days: 1))) && 
              recordDay.isBefore(today.add(const Duration(days: 1)))) {
            // 날짜에 해당하는 데이터 찾기
            for (final dayData in weeklyData) {
              final date = dayData['date'] as DateTime;
              if (date.year == recordDay.year && 
                  date.month == recordDay.month && 
                  date.day == recordDay.day) {
                dayData['count'] = (dayData['count'] as int) + 1;
                break;
              }
            }
          }
        } catch (e) {
          print('레코드 처리 중 오류: $e');
          // 오류가 발생한 레코드는 건너뛰고 계속 진행
          continue;
        }
      }
      
      if (mounted) {
        setState(() {
          _emotionCounts.clear();
          _emotionCounts.addAll(emotionCounts);
          
          _tagCounts.clear();
          _tagCounts.addAll(tagCounts);
          
          _weeklyData = weeklyData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('통계 로딩 오류: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('통계 데이터를 불러오는 중 오류가 발생했습니다: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  // 시간 범위에 따른 기록 필터링
  List<dynamic> _filterRecordsByTimeRange(List<dynamic> records) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    
    return records.where((record) {
      try {
        // timestamp가 string인지 DateTime인지 확인하고 처리
        DateTime recordDate;
        if (record.timestamp is String) {
          recordDate = DateTime.parse(record.timestamp);
        } else if (record.timestamp is DateTime) {
          recordDate = record.timestamp;
        } else {
          return false; // 형식을 알 수 없는 경우 제외
        }

        // 선택된 시간 범위에 따라 필터링
        switch (_selectedTimeRange) {
          case TimeRange.week:
            final weekAgo = today.subtract(const Duration(days: 7));
            return recordDate.isAfter(weekAgo) && recordDate.isBefore(today.add(const Duration(days: 1)));
          
          case TimeRange.month:
            final monthAgo = DateTime(today.year, today.month - 1, today.day);
            return recordDate.isAfter(monthAgo) && recordDate.isBefore(today.add(const Duration(days: 1)));
          
          case TimeRange.year:
            final yearAgo = DateTime(today.year - 1, today.month, today.day);
            return recordDate.isAfter(yearAgo) && recordDate.isBefore(today.add(const Duration(days: 1)));
          
          case TimeRange.all:
          default:
            return true;
        }
      } catch (e) {
        print('기록 필터링 중 오류: $e');
        return false; // 오류가 발생한 레코드는 제외
      }
    }).toList();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('감정 통계'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadStats,
            tooltip: '새로고침',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimeRangeSelector(),
                  const SizedBox(height: 24),
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  _buildEmotionDistribution(),
                  const SizedBox(height: 24),
                  _buildWeeklyChart(),
                  const SizedBox(height: 24),
                  _buildTopTags(),
                ],
              ),
            ),
    );
  }
  
  // 시간 범위 선택기
  Widget _buildTimeRangeSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '기간 선택',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildTimeButton(TimeRange.week, '1주일'),
                  const SizedBox(width: 8),
                  _buildTimeButton(TimeRange.month, '1개월'),
                  const SizedBox(width: 8),
                  _buildTimeButton(TimeRange.year, '1년'),
                  const SizedBox(width: 8),
                  _buildTimeButton(TimeRange.all, '전체'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // 시간 범위 버튼
  Widget _buildTimeButton(TimeRange range, String label) {
    final isSelected = _selectedTimeRange == range;
    
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.surface,
        foregroundColor: isSelected 
            ? Theme.of(context).colorScheme.onPrimary 
            : Theme.of(context).colorScheme.onSurface,
      ),
      onPressed: () {
        setState(() {
          _selectedTimeRange = range;
        });
        _loadStats();
      },
      child: Text(label),
    );
  }
  
  // 요약 통계 카드
  Widget _buildSummaryCard() {
    // 기록 개수
    final recordCount = _emotionCounts.values.fold(0, (sum, count) => sum + count);
    
    // 가장 많은 감정 찾기
    String mostFrequentEmotion = '없음';
    int maxCount = 0;
    
    _emotionCounts.forEach((emotion, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentEmotion = emotion;
      }
    });
    
    // 가장 많은 태그 찾기
    String mostFrequentTag = '없음';
    maxCount = 0;
    
    _tagCounts.forEach((tag, count) {
      if (count > maxCount) {
        maxCount = count;
        mostFrequentTag = tag;
      }
    });
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '통계 요약',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.assignment,
                    '기록 개수',
                    '$recordCount',
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.emoji_emotions,
                    '가장 많은 감정',
                    mostFrequentEmotion,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.tag,
                    '가장 많은 태그',
                    mostFrequentTag,
                  ),
                ),
                Expanded(
                  child: _buildSummaryItem(
                    context,
                    Icons.calendar_today,
                    '기준 날짜',
                    DateFormat('yyyy.MM.dd').format(DateTime.now()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  // 요약 항목 위젯
  Widget _buildSummaryItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
  
  // 감정 분포 위젯
  Widget _buildEmotionDistribution() {
    try {
      // 데이터가 비어있는 경우 표시할 위젯
      if (_emotionCounts.isEmpty) {
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '감정 분포',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('기록된 감정이 없습니다'),
                  ),
                ),
              ],
            ),
          ),
        );
      }
      
      final isDarkMode = Theme.of(context).brightness == Brightness.dark;
      final emotionColors = {
        '행복': Colors.green,
        '슬픔': Colors.blue,
        '분노': Colors.red,
        '불안': Colors.amber,
        '놀람': Colors.purple,
        '혐오': Colors.brown,
        '지루함': Colors.grey,
      };
      
      // 감정 데이터를 PieChartSectionData 목록으로 변환
      final sections = _emotionCounts.entries.map((entry) {
        final color = emotionColors[entry.key] ?? 
            Colors.primaries[_emotionCounts.keys.toList().indexOf(entry.key) % Colors.primaries.length];
        
        return PieChartSectionData(
          color: color,
          value: entry.value.toDouble(),
          title: '${entry.key}\n${entry.value}회',
          radius: 60,
          titleStyle: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDarkMode ? Colors.white : Colors.black,
          ),
        );
      }).toList();
      
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '감정 분포',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              AspectRatio(
                aspectRatio: 1.5,
                child: PieChart(
                  PieChartData(
                    sections: sections,
                    sectionsSpace: 0,
                    centerSpaceRadius: 40,
                    pieTouchData: PieTouchData(
                      enabled: true,
                      touchCallback: (FlTouchEvent event, pieTouchResponse) {},
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('감정 분포 차트 생성 오류: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '감정 분포',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text('차트를 표시할 수 없습니다'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // 주간 차트
  Widget _buildWeeklyChart() {
    try {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주간 기록 활동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              
              // 데이터가 비어있거나 모든 값이 0인 경우 메시지 표시
              if (_weeklyData.isEmpty || _weeklyData.every((data) => (data['count'] as int) == 0))
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Text('주간 기록 데이터가 없습니다'),
                  ),
                )
              else
                SizedBox(
                  height: 200,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: _weeklyData.map((data) {
                      final date = data['date'] as DateTime;
                      final count = data['count'] as int;
                      
                      // 최대 높이 계산 (최대값을 170px로)
                      final maxCount = _weeklyData.fold(0, (max, data) => math.max(max as int, data['count'] as int));
                      final height = maxCount > 0 
                          ? 170 * (count / maxCount)
                          : 0.0;
                      
                      // 오늘인지 확인
                      final now = DateTime.now();
                      final today = DateTime(now.year, now.month, now.day);
                      final isToday = date.year == today.year && 
                                     date.month == today.month && 
                                     date.day == today.day;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              // 갯수 표시
                              Text(
                                '$count',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 바 차트
                              Container(
                                height: height,
                                decoration: BoxDecoration(
                                  color: isToday 
                                      ? Theme.of(context).colorScheme.primary
                                      : Theme.of(context).colorScheme.primary.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                              const SizedBox(height: 4),
                              // 요일 표시
                              Text(
                                DateFormat('E').format(date),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                                  color: isToday ? Theme.of(context).colorScheme.primary : Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      );
    } catch (e) {
      print('주간 차트 생성 오류: $e');
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                '주간 기록 활동',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text('차트를 표시할 수 없습니다'),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  // 자주 사용된 태그
  Widget _buildTopTags() {
    // 태그 정렬 (가장 많은 순)
    final sortedTags = _tagCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // 상위 10개만 표시
    final topTags = sortedTags.take(10).toList();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '자주 사용된 태그',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            if (topTags.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Text('사용된 태그가 없습니다'),
                ),
              )
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: topTags.map((entry) {
                  final tag = entry.key;
                  final count = entry.value;
                  
                  return Chip(
                    label: Text('$tag ($count)'),
                    backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    side: BorderSide(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }
}

// 시간 범위 열거형
enum TimeRange {
  week,
  month,
  year,
  all,
} 