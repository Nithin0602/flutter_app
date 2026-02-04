// lib/models/dashboard_model.dart - UPDATED
class DashboardData {
  final JoiningDetails joiningDetails;
  final TodayStatus todayStatus;
  final MonthlyAttendance monthlyAttendance;
  final MonthlyLate monthlyLate;

  DashboardData({
    required this.joiningDetails,
    required this.todayStatus,
    required this.monthlyAttendance,
    required this.monthlyLate,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      joiningDetails: JoiningDetails.fromJson(json['joining_details'] ?? {}),
      todayStatus: TodayStatus.fromJson(json['today_status'] ?? {}),
      monthlyAttendance: MonthlyAttendance.fromJson(json['monthly_attendance'] ?? {}),
      monthlyLate: MonthlyLate.fromJson(json['monthly_late'] ?? {}),
    );
  }
}

class JoiningDetails {
  final String name;
  final String employeeName;
  final String dateOfJoining;
  final String department;
  final int totalDays;

  JoiningDetails({
    required this.name,
    required this.employeeName,
    required this.dateOfJoining,
    required this.department,
    required this.totalDays,
  });

  factory JoiningDetails.fromJson(Map<String, dynamic> json) {
    return JoiningDetails(
      name: json['name']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      dateOfJoining: json['date_of_joining']?.toString() ?? '',
      department: json['department']?.toString() ?? '',
      totalDays: (json['total_days'] ?? 0).toInt(),
    );
  }
}

class TodayStatus {
  final int successKey;
  final String employee;
  final String logType;
  final String checkinTime;
  final String coming;
  final String checkOut;
  final String date;

  TodayStatus({
    required this.successKey,
    required this.employee,
    required this.logType,
    required this.checkinTime,
    required this.coming,
    required this.checkOut,
    required this.date,
  });

  factory TodayStatus.fromJson(Map<String, dynamic> json) {
    return TodayStatus(
      successKey: (json['success_key'] ?? 0).toInt(),
      employee: json['employee']?.toString() ?? '',
      logType: json['log_type']?.toString() ?? '',
      checkinTime: json['checkin_time']?.toString() ?? '-',
      coming: json['coming']?.toString() ?? '',
      checkOut: json['check_out']?.toString() ?? '-',
      date: json['date']?.toString() ?? '',
    );
  }
}

class MonthlyAttendance {
  final double present;
  final double halfDay;
  final double absent;
  final double totalPresent;
  final double totalAbsents;

  MonthlyAttendance({
    required this.present,
    required this.halfDay,
    required this.absent,
    required this.totalPresent,
    required this.totalAbsents,
  });

  factory MonthlyAttendance.fromJson(Map<String, dynamic> json) {
    // Handle different response structures
    if (json.containsKey('summary')) {
      final summary = json['summary'];
      return MonthlyAttendance(
        present: (summary['present'] ?? 0).toDouble(),
        halfDay: (summary['half_day'] ?? 0).toDouble(),
        absent: (summary['absent'] ?? 0).toDouble(),
        totalPresent: (summary['present'] ?? 0).toDouble() + (summary['half_day'] ?? 0).toDouble() * 0.5,
        totalAbsents: (summary['absent'] ?? 0).toDouble(),
      );
    } else {
      // Original structure from your Postman response
      return MonthlyAttendance(
        present: (json['present'] ?? 0).toDouble(),
        halfDay: (json['half_day'] ?? 0).toDouble(),
        absent: (json['absent'] ?? 0).toDouble(),
        totalPresent: (json['Total Presnet'] ?? 0).toDouble(),
        totalAbsents: (json['Total Absents'] ?? 0).toDouble(),
      );
    }
  }
}

class MonthlyLate {
  final int totalLate;
  final List<String> lateDays;
  final String fromDate;
  final String toDate;

  MonthlyLate({
    required this.totalLate,
    required this.lateDays,
    required this.fromDate,
    required this.toDate,
  });

  factory MonthlyLate.fromJson(Map<String, dynamic> json) {
    // Handle different response structures
    if (json.containsKey('total_late')) {
      return MonthlyLate(
        totalLate: (json['total_late'] ?? 0).toInt(),
        lateDays: List<String>.from(json['late_days'] ?? []),
        fromDate: json['from_date']?.toString() ?? '',
        toDate: json['to_date']?.toString() ?? '',
      );
    } else if (json.containsKey('late_count')) {
      final lateCount = json['late_count'];
      return MonthlyLate(
        totalLate: (lateCount['total_late'] ?? 0).toInt(),
        lateDays: List<String>.from(lateCount['late_days'] ?? []),
        fromDate: '',
        toDate: '',
      );
    } else {
      return MonthlyLate(
        totalLate: 0,
        lateDays: [],
        fromDate: '',
        toDate: '',
      );
    }
  }
}