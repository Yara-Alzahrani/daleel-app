import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/trip_preferences.dart';
import '../../widgets/custom_widgets.dart';

class GeneralInfoStep extends StatefulWidget {
  final TripPreferences preferences;
  final VoidCallback onContinue;

  const GeneralInfoStep(
      {Key? key, required this.preferences, required this.onContinue})
      : super(key: key);

  @override
  State<GeneralInfoStep> createState() => _GeneralInfoStepState();
}

class _GeneralInfoStepState extends State<GeneralInfoStep> {
  late DateTime _focusedDay;
  DateTime? _selectedStartDay;
  DateTime? _selectedEndDay;
  bool _isSelectingStartDate = true;
  String _selectedCity = '';

  final List<String> _saudiCities = ['Riyadh', 'Jeddah', 'Al-Ula'];

  @override
  void initState() {
    super.initState();
    _selectedCity = widget.preferences.city;
    _focusedDay = DateTime.now();
    _selectedStartDay = widget.preferences.startDate;
    _selectedEndDay = widget.preferences.endDate;
  }

  void _showCityBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('Select City',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _saudiCities.length,
                  itemBuilder: (context, index) {
                    final city = _saudiCities[index];
                    return ListTile(
                      title: Text(city),
                      leading: const Icon(Icons.location_city,
                          color: Color(0xFF006E51)),
                      onTap: () {
                        setState(() => _selectedCity = city);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _incrementChildren() =>
      setState(() => widget.preferences.numberOfChildren++);
  void _decrementChildren() {
    if (widget.preferences.numberOfChildren > 0) {
      setState(() => widget.preferences.numberOfChildren--);
    }
  }

  void _incrementParents() =>
      setState(() => widget.preferences.numberOfParents++);
  void _decrementParents() {
    if (widget.preferences.numberOfParents > 1) {
      setState(() => widget.preferences.numberOfParents--);
    }
  }

  void _handleContinue() {
    if (_selectedCity.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select a city'), backgroundColor: Colors.red));
      return;
    }
    if (_selectedStartDay == null || _selectedEndDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red));
      return;
    }
    widget.preferences.city = _selectedCity;
    widget.preferences.startDate = _selectedStartDay;
    widget.preferences.endDate = _selectedEndDay;
    widget.onContinue();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // City - label جنب الخانة
          GestureDetector(
            onTap: _showCityBottomSheet,
            child: Row(
              children: [
                // label
                Text('City  ',
                    style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w400)),
                // gradient border field
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(1.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(25),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF006E51), Color(0xFFA384DA)],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedCity.isEmpty
                                ? 'Select City'
                                : _selectedCity,
                            style: TextStyle(
                              color: _selectedCity.isEmpty
                                  ? Colors.grey[400]
                                  : Colors.black87,
                              fontSize: 15,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down,
                              color: Color(0xFFA384DA), size: 22),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Number of Children
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Number of Children',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700])),
              Row(
                children: [
                  _counterBtn(Icons.add, _incrementChildren),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${widget.preferences.numberOfChildren}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  _counterBtn(Icons.remove, _decrementChildren),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Number of Adults
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Number of Adults',
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.grey[700])),
              Row(
                children: [
                  _counterBtn(Icons.add, _incrementParents),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${widget.preferences.numberOfParents}',
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w600)),
                  ),
                  _counterBtn(Icons.remove, _decrementParents),
                ],
              ),
            ],
          ),
          const SizedBox(height: 28),

          // Date Selection
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Start date',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => setState(() => _isSelectingStartDate = true),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: _isSelectingStartDate
                                ? const Color(0xFF006E51)
                                : const Color(0xFFA384DA),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedStartDay != null
                              ? '${_selectedStartDay!.day}/${_selectedStartDay!.month}'
                              : 'Select',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('End date',
                        style:
                            TextStyle(fontSize: 13, color: Colors.grey[600])),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () =>
                          setState(() => _isSelectingStartDate = false),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: !_isSelectingStartDate
                                ? const Color(0xFF006E51)
                                : const Color(0xFFA384DA),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _selectedEndDay != null
                              ? '${_selectedEndDay!.day}/${_selectedEndDay!.month}'
                              : 'Select',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          Container(
            decoration: BoxDecoration(
              border:
                  Border.all(color: const Color(0xFFA384DA).withOpacity(0.3)),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(8),
            child: TableCalendar(
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              focusedDay: _focusedDay,
              selectedDayPredicate: (day) =>
                  isSameDay(_selectedStartDay, day) ||
                  isSameDay(_selectedEndDay, day),
              rangeStartDay: _selectedStartDay,
              rangeEndDay: _selectedEndDay,
              onDaySelected: (selectedDay, focusedDay) {
                setState(() {
                  _focusedDay = focusedDay;
                  if (_isSelectingStartDate) {
                    _selectedStartDay = selectedDay;
                    _selectedEndDay = null;
                    _isSelectingStartDate = false;
                  } else {
                    if (_selectedStartDay != null &&
                        selectedDay.isBefore(_selectedStartDay!)) {
                      _selectedEndDay = _selectedStartDay;
                      _selectedStartDay = selectedDay;
                    } else {
                      _selectedEndDay = selectedDay;
                    }
                  }
                });
              },
              calendarStyle: CalendarStyle(
                selectedDecoration: const BoxDecoration(
                    color: Color(0xFF006E51), shape: BoxShape.circle),
                rangeStartDecoration: const BoxDecoration(
                    color: Color(0xFF006E51), shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(
                    color: Color(0xFF006E51), shape: BoxShape.circle),
                rangeHighlightColor: const Color(0xFFA384DA).withOpacity(0.2),
                todayDecoration: BoxDecoration(
                    color: const Color(0xFFA384DA).withOpacity(0.3),
                    shape: BoxShape.circle),
                outsideDaysVisible: false,
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                weekendStyle:
                    TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 32),
          CustomButton(text: 'Continue', onPressed: _handleContinue),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: const BoxDecoration(
            shape: BoxShape.circle, color: Color(0xFF006E51)),
        child: Icon(icon, color: Colors.white, size: 18),
      ),
    );
  }
}
