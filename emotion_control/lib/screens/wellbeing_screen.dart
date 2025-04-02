import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/digital_wellbeing.dart';
import '../services/wellbeing_service.dart';

class WellbeingScreen extends StatefulWidget {
  const WellbeingScreen({Key? key}) : super(key: key);

  @override
  State<WellbeingScreen> createState() => _WellbeingScreenState();
}

class _WellbeingScreenState extends State<WellbeingScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _hasPermission = false;
  DigitalWellbeingData? _todayData;
  late TabController _tabController;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _checkPermissionAndLoadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _checkPermissionAndLoadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final wellbeingService = Provider.of<WellbeingService>(context, listen: false);
    
    setState(() {
      _hasPermission = wellbeingService.hasPermission;
    });
    
    if (_hasPermission) {
      await _loadData();
    }
    
    setState(() {
      _isLoading = false;
    });
  }
  
  Future<void> _requestPermission() async {
    setState(() {
      _isLoading = true;
    });
    
    final wellbeingService = Provider.of<WellbeingService>(context, listen: false);
    final granted = await wellbeingService.requestPermission();
    
    setState(() {
      _hasPermission = granted;
      _isLoading = false;
    });
    
    if (granted) {
      await _loadData();
    }
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    final wellbeingService = Provider.of<WellbeingService>(context, listen: false);
    
    // 오늘의 데이터 수집
    final data = await wellbeingService.collectTodayData();
    
    setState(() {
      _todayData = data;
      _isLoading = false;
    });
  }
  
  // 시간 형식으로 변환
  String _formatDuration(int seconds) {
    final hours = seconds ~/ 3600;
    final minutes = (seconds % 3600) ~/ 60;
    
    if (hours > 0) {
      return '$hours시간 ${minutes > 0 ? '$minutes분' : ''}';
    } else if (minutes > 0) {
      return '$minutes분';
    } else {
      return '$seconds초';
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('디지털 웰빙', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: _hasPermission ? TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '오늘'),
            Tab(text: '주간'),
            Tab(text: '월간'),
          ],
        ) : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _hasPermission ? _loadData : null,
            tooltip: '데이터 갱신',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : !_hasPermission
              ? _buildPermissionRequest()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayView(),
                    _buildWeeklyView(),
                    _buildMonthlyView(),
                  ],
                ),
    );
  }
  
  Widget _buildPermissionRequest() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.phone_android,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 24),
            const Text(
              '앱 사용 시간 통계에 접근하려면 권한이 필요합니다',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              '디지털 웰빙 기능을 사용하면 앱 사용 패턴을 분석하고 감정 상태와의 연관성을 찾을 수 있습니다.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.app_settings_alt),
              label: const Text('권한 요청'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTodayView() {
    if (_todayData == null) {
      return const Center(
        child: Text(
          '오늘의 디지털 웰빙 데이터가 없습니다.\n새로고침을 눌러 데이터를 수집해보세요.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }
    
    // 앱 사용 시간 상위 5개
    final topApps = _todayData!.appUsage.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final top5Apps = topApps.take(5).toList();
    
    // 기타 앱 사용 시간
    final otherApps = topApps.length > 5
        ? topApps.skip(5).fold(0, (sum, entry) => sum + entry.value)
        : 0;
    
    final totalTime = _todayData!.totalScreenTime;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 오늘의 총 스크린 타임
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 스크린 타임',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _formatDuration(totalTime),
                          style: const TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                        Text(
                          DateFormat('yyyy년 MM월 dd일').format(_todayData!.date),
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // 앱별 사용 시간
          const Text(
            '앱별 사용 시간',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          
          // 앱 사용 시간 차트
          Container(
            height: 180,
            padding: const EdgeInsets.all(8.0),
            child: totalTime > 0 
                ? PieChart(
                    PieChartData(
                      sections: [
                        ...top5Apps.map((entry) => PieChartSectionData(
                          value: entry.value.toDouble(),
                          title: '',
                          radius: 60,
                          color: Colors.primaries[top5Apps.indexOf(entry) % Colors.primaries.length],
                        )),
                        if (otherApps > 0)
                          PieChartSectionData(
                            value: otherApps.toDouble(),
                            title: '',
                            radius: 60,
                            color: Colors.grey,
                          ),
                      ],
                      centerSpaceRadius: 40,
                      sectionsSpace: 2,
                    ),
                  )
                : const Center(
                    child: Text(
                      '앱 사용 데이터가 충분하지 않습니다',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
          ),
          
          const SizedBox(height: 16),
          
          // 앱 목록
          Column(
            children: [
              ...top5Apps.map((entry) => _buildAppUsageItem(
                entry.key,
                entry.value,
                totalTime,
                Colors.primaries[top5Apps.indexOf(entry) % Colors.primaries.length],
              )),
              if (otherApps > 0)
                _buildAppUsageItem('기타 앱', otherApps, totalTime, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildAppUsageItem(String appName, int seconds, int totalTime, Color color) {
    final percentage = totalTime > 0 ? (seconds / totalTime * 100).toStringAsFixed(1) : '0';
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              appName,
              style: const TextStyle(fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            _formatDuration(seconds),
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '$percentage%',
              textAlign: TextAlign.right,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeeklyView() {
    return const Center(
      child: Text(
        '주간 통계 기능은 아직 개발 중입니다.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
  
  Widget _buildMonthlyView() {
    return const Center(
      child: Text(
        '월간 통계 기능은 아직 개발 중입니다.',
        style: TextStyle(fontSize: 16, color: Colors.grey),
      ),
    );
  }
} 