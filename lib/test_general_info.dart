import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(const TestGeneralInfoApp());
}

class TestGeneralInfoApp extends StatelessWidget {
  const TestGeneralInfoApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Test General Info Step',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF006E51),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const TestGeneralInfoScreen(),
    );
  }
}

class TestGeneralInfoScreen extends StatefulWidget {
  const TestGeneralInfoScreen({Key? key}) : super(key: key);

  @override
  State<TestGeneralInfoScreen> createState() => _TestGeneralInfoScreenState();
}

class _TestGeneralInfoScreenState extends State<TestGeneralInfoScreen> {
  final _cityController = TextEditingController();
  int _numberOfChildren = 0;
  int _numberOfParents = 1;
  late DateTime _focusedDay;
  DateTime? _selectedStartDay;
  DateTime? _selectedEndDay;
  bool _isSelectingStartDate = true;

  @override
  void initState() {
    super.initState();
    _focusedDay = DateTime.now();
  }

  @override
  void dispose() {
    _cityController.dispose();
    super.dispose();
  }

  void _incrementChildren() {
    setState(() => _numberOfChildren++);
  }

  void _decrementChildren() {
    if (_numberOfChildren > 0) {
      setState(() => _numberOfChildren--);
    }
  }

  void _incrementParents() {
    setState(() => _numberOfParents++);
  }

  void _decrementParents() {
    if (_numberOfParents > 1) {
      setState(() => _numberOfParents--);
    }
  }

  void _handleContinue() {
    if (_cityController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a city'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_selectedStartDay == null || _selectedEndDay == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show success message
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Success! City: ${_cityController.text}, '
          'Children: $_numberOfChildren, Parents: $_numberOfParents, '
          'Dates: ${_selectedStartDay!.day}/${_selectedStartDay!.month} - '
          '${_selectedEndDay!.day}/${_selectedEndDay!.month}',
        ),
        backgroundColor: const Color(0xFF006E51),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFFA384DA),
        elevation: 0,
        title: const Text(
          'General Info Step - TEST',
          style: TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // City Input
            const Text(
              'City',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _cityController,
              decoration: InputDecoration(
                hintText: 'City',
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFA384DA), width: 2),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFFA384DA), width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: const BorderSide(color: Color(0xFF006E51), width: 2),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            const SizedBox(height: 24),

            // Number of Children
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of\nChildren',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _incrementChildren,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFA384DA),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_numberOfChildren',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _decrementChildren,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFA384DA),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Number of Parents
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Number of\nparents',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    IconButton(
                      onPressed: _incrementParents,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFA384DA),
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        '$_numberOfParents',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _decrementParents,
                      icon: Container(
                        width: 36,
                        height: 36,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color(0xFFA384DA),
                        ),
                        child: const Icon(Icons.remove, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Date Selection
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Start date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
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
                      const Text(
                        'End date',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () => setState(() => _isSelectingStartDate = false),
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

            // Calendar
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFA384DA).withOpacity(0.3)),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(8),
              child: TableCalendar(
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 365)),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedStartDay, day) || isSameDay(_selectedEndDay, day);
                },
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
                      if (_selectedStartDay != null && selectedDay.isBefore(_selectedStartDay!)) {
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
                    color: Color(0xFF006E51),
                    shape: BoxShape.circle,
                  ),
                  rangeStartDecoration: const BoxDecoration(
                    color: Color(0xFF006E51),
                    shape: BoxShape.circle,
                  ),
                  rangeEndDecoration: const BoxDecoration(
                    color: Color(0xFF006E51),
                    shape: BoxShape.circle,
                  ),
                  rangeHighlightColor: const Color(0xFFA384DA).withOpacity(0.2),
                  todayDecoration: BoxDecoration(
                    color: const Color(0xFFA384DA).withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  outsideDaysVisible: false,
                ),
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontWeight: FontWeight.bold),
                  weekendStyle: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 32),

            // Continue Button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _handleContinue,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFA384DA),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Continue'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}