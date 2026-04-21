class TripPreferences {
  String city;
  int numberOfChildren;
  int numberOfParents;
  DateTime? startDate;
  DateTime? endDate;
  List<String> activities;
  List<String> restaurants;
  String budget;

  TripPreferences({
    this.city = '',
    this.numberOfChildren = 0,
    this.numberOfParents = 1,
    this.startDate,
    this.endDate,
    this.activities = const [],
    this.restaurants = const [],
    this.budget = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'numberOfChildren': numberOfChildren,
      'numberOfParents': numberOfParents,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
      'activities': activities,
      'restaurants': restaurants,
      'budget': budget,
    };
  }

  factory TripPreferences.fromJson(Map<String, dynamic> json) {
    return TripPreferences(
      city: json['city'] ?? '',
      numberOfChildren: json['numberOfChildren'] ?? 0,
      numberOfParents: json['numberOfParents'] ?? 1,
      startDate: json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      activities: List<String>.from(json['activities'] ?? []),
      restaurants: List<String>.from(json['restaurants'] ?? []),
      budget: json['budget'] ?? '',
    );
  }

  bool get isComplete {
    return city.isNotEmpty &&
        startDate != null &&
        endDate != null &&
        activities.isNotEmpty &&
        restaurants.isNotEmpty &&
        budget.isNotEmpty;
  }
}