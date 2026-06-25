import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import '../services/api_services.dart';
import '../models/weather_model.dart';
import '../widgets/weather_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  final TextEditingController _controller = TextEditingController();
  final ApiService _apiService = ApiService();
  WeatherModel? _weather;
  bool _isLoading = false;
  String? _error;
  bool _searchExpanded = false;

  late AnimationController _heroController;
  late AnimationController _cardController;
  late Animation<double> _heroFade;
  late Animation<double> _cardFade;
  late Animation<Offset> _cardSlide;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _cardController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroController, curve: Curves.easeOut);
    _cardFade = CurvedAnimation(parent: _cardController, curve: Curves.easeOut);
    _cardSlide = Tween<Offset>(begin: const Offset(0, 0.15), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _cardController, curve: Curves.easeOutCubic),
        );
  }

  @override
  void dispose() {
    _heroController.dispose();
    _cardController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _getWeather() async {
    final city = _controller.text.trim();
    if (city.isEmpty) return;

    HapticFeedback.lightImpact();
    FocusScope.of(context).unfocus();
    setState(() {
      _isLoading = true;
      _error = null;
      _weather = null;
      _searchExpanded = false;
    });
    _heroController.reset();
    _cardController.reset();

    try {
      final weather = await _apiService.fetchWeather(city);
      setState(() => _weather = weather);
      await _heroController.forward();
      await _cardController.forward();
    } catch (e) {
      setState(() {
        _error = e.toString();
        _weather = null;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  List<Color> _getWeatherGradient() {
    if (_weather == null) {
      return [
        const Color(0xFF1E2A5E),
        const Color(0xFF3B1F6B),
        const Color(0xFF0D0D1A),
      ];
    }
    final desc = _weather!.description.toLowerCase();
    if (desc.contains('clear') || desc.contains('sunny')) {
      return [
        const Color(0xFF1A4FA3),
        const Color(0xFF5B8DEF),
        const Color(0xFFF0A500),
      ];
    } else if (desc.contains('rain') || desc.contains('drizzle')) {
      return [
        const Color(0xFF1A2A4A),
        const Color(0xFF2C4A7C),
        const Color(0xFF0A0F1E),
      ];
    } else if (desc.contains('cloud')) {
      return [
        const Color(0xFF2E3A6E),
        const Color(0xFF4A5580),
        const Color(0xFF1A1F3C),
      ];
    } else if (desc.contains('snow')) {
      return [
        const Color(0xFF3A4A7A),
        const Color(0xFF6A7DAA),
        const Color(0xFFCCDDFF),
      ];
    } else if (desc.contains('storm') || desc.contains('thunder')) {
      return [
        const Color(0xFF0D0D1A),
        const Color(0xFF1A1A3A),
        const Color(0xFF2A1A4A),
      ];
    }
    return [
      const Color(0xFF1E2A5E),
      const Color(0xFF3B1F6B),
      const Color(0xFF0D0D1A),
    ];
  }

  IconData _getWeatherIcon() {
    if (_weather == null) return Icons.cloud_queue_rounded;
    final desc = _weather!.description.toLowerCase();
    if (desc.contains('clear') || desc.contains('sunny'))
      return Icons.wb_sunny_rounded;
    if (desc.contains('rain') || desc.contains('drizzle'))
      return Icons.grain_rounded;
    if (desc.contains('cloud')) return Icons.cloud_rounded;
    if (desc.contains('snow')) return Icons.ac_unit_rounded;
    if (desc.contains('storm') || desc.contains('thunder'))
      return Icons.bolt_rounded;
    if (desc.contains('fog') || desc.contains('mist'))
      return Icons.blur_on_rounded;
    return Icons.cloud_queue_rounded;
  }

  String _formatDate() {
    final now = DateTime.now();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}  •  ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getWeatherGradient();
    final size = MediaQuery.of(context).size;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: AnimatedContainer(
          duration: const Duration(milliseconds: 900),
          curve: Curves.easeInOut,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: gradient,
              stops: const [0.0, 0.45, 1.0],
            ),
          ),
          child: Stack(
            children: [
              // Atmospheric glow orbs
              Positioned(
                top: -100,
                right: -80,
                child: _GlowOrb(
                  color: Colors.white.withOpacity(0.06),
                  size: 300,
                ),
              ),
              Positioned(
                top: size.height * 0.22,
                left: -120,
                child: _GlowOrb(
                  color: Colors.white.withOpacity(0.04),
                  size: 240,
                ),
              ),

              SafeArea(
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // ── TOP BAR ──────────────────────────────────────
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                            child: Row(
                              children: [
                                // Location pill
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(30),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.2),
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        _weather?.cityName ?? 'Search a city',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          letterSpacing: 0.2,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Spacer(),
                                // Search toggle button
                                GestureDetector(
                                  onTap: () => setState(
                                    () => _searchExpanded = !_searchExpanded,
                                  ),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    width: 42,
                                    height: 42,
                                    decoration: BoxDecoration(
                                      color: _searchExpanded
                                          ? Colors.white.withOpacity(0.25)
                                          : Colors.white.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.2),
                                      ),
                                    ),
                                    child: Icon(
                                      _searchExpanded
                                          ? Icons.close_rounded
                                          : Icons.search_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ── COLLAPSIBLE SEARCH BAR ───────────────────────
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                            child: _searchExpanded
                                ? Padding(
                                    padding: const EdgeInsets.fromLTRB(
                                      24,
                                      14,
                                      24,
                                      0,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            child: BackdropFilter(
                                              filter: ImageFilter.blur(
                                                sigmaX: 20,
                                                sigmaY: 20,
                                              ),
                                              child: Container(
                                                height: 52,
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.14),
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.22),
                                                  ),
                                                ),
                                                child: TextField(
                                                  controller: _controller,
                                                  autofocus: true,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  onSubmitted: (_) =>
                                                      _getWeather(),
                                                  decoration: InputDecoration(
                                                    hintText:
                                                        'Enter city name...',
                                                    hintStyle: const TextStyle(
                                                      color: Colors.white54,
                                                      fontSize: 15,
                                                    ),
                                                    prefixIcon: const Icon(
                                                      Icons.search_rounded,
                                                      color: Colors.white54,
                                                      size: 20,
                                                    ),
                                                    border: InputBorder.none,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 16,
                                                        ),
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 10),
                                        GestureDetector(
                                          onTap: _isLoading
                                              ? null
                                              : _getWeather,
                                          child: Container(
                                            width: 52,
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.9,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(16),
                                            ),
                                            child: Icon(
                                              Icons.arrow_forward_rounded,
                                              color: gradient[0],
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),

                          // ── HERO TEMPERATURE ─────────────────────────────
                          if (_weather != null)
                            FadeTransition(
                              opacity: _heroFade,
                              child: Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  24,
                                  36,
                                  24,
                                  0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(),
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 13,
                                        letterSpacing: 0.7,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        // Giant temperature number
                                        Text(
                                          '${_weather!.temperature.round()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 110,
                                            fontWeight: FontWeight.w200,
                                            height: 1.0,
                                            letterSpacing: -6,
                                          ),
                                        ),
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            top: 18,
                                            left: 4,
                                          ),
                                          child: Text(
                                            '°C',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 36,
                                              fontWeight: FontWeight.w300,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        // Weather icon + label
                                        Padding(
                                          padding: const EdgeInsets.only(
                                            top: 18,
                                          ),
                                          child: Column(
                                            children: [
                                              Icon(
                                                _getWeatherIcon(),
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
                                                size: 54,
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                _weather!.description,
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 14),

                                    // Hi / Lo badges
                                    Row(
                                      children: [
                                        _TempBadge(
                                          icon: Icons.arrow_upward_rounded,
                                          label:
                                              '${(_weather!.temperature + 2).round()}°',
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 10),
                                        _TempBadge(
                                          icon: Icons.arrow_downward_rounded,
                                          label:
                                              '${(_weather!.temperature - 5).round()}°',
                                          color: Colors.white70,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 28),

                                    // Glassmorphic stats strip
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(22),
                                      child: BackdropFilter(
                                        filter: ImageFilter.blur(
                                          sigmaX: 30,
                                          sigmaY: 30,
                                        ),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 18,
                                            horizontal: 12,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(
                                              0.12,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              22,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.18,
                                              ),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              _StatItem(
                                                icon: Icons.water_drop_outlined,
                                                label: 'Humidity',
                                                value: '${_weather!.humidity}%',
                                              ),
                                              _Divider(),
                                              _StatItem(
                                                icon: Icons.air_rounded,
                                                label: 'Wind',
                                                value:
                                                    '${_weather!.temperature} km/h',
                                              ),
                                              _Divider(),
                                              _StatItem(
                                                icon: Icons
                                                    .thermostat_auto_rounded,
                                                label: 'Feels Like',
                                                value:
                                                    '${(_weather!.temperature - 1).round()}°C',
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          else if (_isLoading)
                            const SizedBox(height: 80)
                          else
                            _EmptyHero(),

                          const SizedBox(height: 28),
                        ],
                      ),
                    ),

                    // ── BOTTOM SHEET (white card panel) ───────────────────
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(36),
                          topRight: Radius.circular(36),
                        ),
                        child: Container(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF4F6FF),
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(36),
                              topRight: Radius.circular(36),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Handle bar
                              Center(
                                child: Container(
                                  margin: const EdgeInsets.only(top: 12),
                                  width: 40,
                                  height: 4,
                                  decoration: BoxDecoration(
                                    color: Colors.black12,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),

                              if (_isLoading) ...[
                                const Center(
                                  child: Padding(
                                    padding: EdgeInsets.only(top: 60),
                                    child: _LoadingWidget(),
                                  ),
                                ),
                              ] else if (_error != null) ...[
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    16,
                                    24,
                                    30,
                                  ),
                                  child: _ErrorCard(
                                    message: _error!,
                                    onRetry: _getWeather,
                                  ),
                                ),
                              ] else if (_weather != null) ...[
                                SlideTransition(
                                  position: _cardSlide,
                                  child: FadeTransition(
                                    opacity: _cardFade,
                                    child: Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                        24,
                                        0,
                                        24,
                                        36,
                                      ),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          _SectionLabel(
                                            label: 'Weather Details',
                                          ),
                                          const SizedBox(height: 16),

                                          // Existing WeatherCard widget
                                          WeatherCard(weather: _weather!),

                                          const SizedBox(height: 28),
                                          _SectionLabel(label: 'Conditions'),
                                          const SizedBox(height: 16),

                                          Row(
                                            children: [
                                              Expanded(
                                                child: _ConditionTile(
                                                  icon:
                                                      Icons.visibility_outlined,
                                                  label: 'Visibility',
                                                  value: '10 km',
                                                  color: const Color(
                                                    0xFF5B6BFF,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _ConditionTile(
                                                  icon: Icons.compress_rounded,
                                                  label: 'Pressure',
                                                  value: '1013 hPa',
                                                  color: const Color(
                                                    0xFF00B4D8,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(height: 12),
                                          Row(
                                            children: [
                                              Expanded(
                                                child: _ConditionTile(
                                                  icon: Icons.wb_sunny_outlined,
                                                  label: 'UV Index',
                                                  value: 'Low (2)',
                                                  color: const Color(
                                                    0xFFF9A825,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Expanded(
                                                child: _ConditionTile(
                                                  icon: Icons.water_outlined,
                                                  label: 'Dew Point',
                                                  value:
                                                      '${(_weather!.temperature - 8).round()}°C',
                                                  color: const Color(
                                                    0xFF48CAE4,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ] else ...[
                                _SearchPrompt(),
                              ],

                              const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────── SUB-WIDGETS ──────────────────────────────────────────────────

class _GlowOrb extends StatelessWidget {
  final Color color;
  final double size;
  const _GlowOrb({required this.color, required this.size});

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: RadialGradient(colors: [color, Colors.transparent]),
    ),
  );
}

class _TempBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _TempBadge({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.white.withOpacity(0.2)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 13),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    ),
  );
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 40, color: Colors.white.withOpacity(0.2));
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF1A1F3C),
      fontSize: 18,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.3,
    ),
  );
}

class _ConditionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  const _ConditionTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: color.withOpacity(0.12),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ],
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 12),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1A1F3C),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black45,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );
}

class _LoadingWidget extends StatelessWidget {
  const _LoadingWidget();

  @override
  Widget build(BuildContext context) => Column(
    children: [
      SizedBox(
        width: 44,
        height: 44,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF5B6BFF)),
        ),
      ),
      const SizedBox(height: 16),
      const Text(
        'Loading weather...',
        style: TextStyle(
          color: Colors.black45,
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    ],
  );
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xFFFFF0F0),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFFFFCDD2)),
    ),
    child: Column(
      children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFFE53935), size: 44),
        const SizedBox(height: 14),
        const Text(
          'Unable to fetch weather',
          style: TextStyle(
            color: Color(0xFF1A1F3C),
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.black45,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 13),
            decoration: BoxDecoration(
              color: const Color(0xFFE53935),
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFE53935).withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Retry',
              style: TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _EmptyHero extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 50, 24, 0),
    child: Column(
      children: [
        const Icon(Icons.search_rounded, color: Colors.white38, size: 64),
        const SizedBox(height: 16),
        const Text(
          'Find Your City',
          style: TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'Tap the search icon above\nto look up live weather',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white54, fontSize: 15, height: 1.6),
        ),
      ],
    ),
  );
}

class _SearchPrompt extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Getting Started',
          style: TextStyle(
            color: Color(0xFF1A1F3C),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 16),
        _HintTile(
          icon: Icons.search_rounded,
          color: const Color(0xFF5B6BFF),
          text: 'Tap the search icon in the top right',
        ),
        const SizedBox(height: 10),
        _HintTile(
          icon: Icons.location_city_rounded,
          color: const Color(0xFF00B4D8),
          text: 'Type any city name worldwide',
        ),
        const SizedBox(height: 10),
        _HintTile(
          icon: Icons.cloud_done_rounded,
          color: const Color(0xFF43A047),
          text: 'Get real-time weather instantly',
        ),
      ],
    ),
  );
}

class _HintTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _HintTile({
    required this.icon,
    required this.color,
    required this.text,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      const SizedBox(width: 14),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF3A3F5C),
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    ],
  );
}
