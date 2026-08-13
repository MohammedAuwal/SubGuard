import '../models/billing_cycle.dart';

class RecurringBillingService {
  
  static DateTime calculateNextBillingDate(DateTime currentNextBilling, BillingCycle cycle, {DateTime? nowOverride}) {
    final now = nowOverride ?? DateTime.now();
    
    if (currentNextBilling.isAfter(now)) {
      return currentNextBilling;
    }

    DateTime newDate = currentNextBilling;
    
    while (newDate.isBefore(now) || newDate.isAtSameMomentAs(now)) {
      if (cycle == BillingCycle.monthly) {
        newDate = _addMonth(newDate);
      } else if (cycle == BillingCycle.yearly) {
        newDate = _addYear(newDate);
      }
    }
    
    return newDate;
  }

  static DateTime _addMonth(DateTime date) {
    int nextMonth = date.month == 12 ? 1 : date.month + 1;
    int nextYear = date.month == 12 ? date.year + 1 : date.year;
    int nextDay = date.day;

    int daysInNextMonth = DateUtils.getDaysInMonth(nextYear, nextMonth);
    if (nextDay > daysInNextMonth) {
      nextDay = daysInNextMonth;
    }

    return DateTime(nextYear, nextMonth, nextDay, date.hour, date.minute);
  }

  static DateTime _addYear(DateTime date) {
    int nextYear = date.year + 1;
    int nextDay = date.day;
    int month = date.month;

    if (month == 2 && nextDay == 29) {
      if (DateUtils.getDaysInMonth(nextYear, month) != 29) {
        nextDay = 28;
      }
    }

    return DateTime(nextYear, month, nextDay, date.hour, date.minute);
  }
}

class DateUtils {
  static int getDaysInMonth(int year, int month) {
    if (month == 2) {
      bool isLeapYear = (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
      return isLeapYear ? 29 : 28;
    }
    const daysInMonth = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month - 1];
  }
}
