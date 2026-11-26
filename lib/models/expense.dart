import 'dart:convert';
import 'package:flutter/material.dart';

class Expense {
  final String id;
  final String title;
  final double amount;
  final String category;
  final DateTime date;

  Expense({
    required this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.date,
  });

  IconData get categoryIcon {
    switch (category) {
      case 'Food':
      case 'Food & Drinks':
        return Icons.fastfood;
      case 'Utilities':
        return Icons.bolt;
      case 'Entertainment':
        return Icons.movie;
      case 'Transport':
        return Icons.directions_bus;
      case 'Shopping':
        return Icons.shopping_bag;
      case 'Healthcare':
        return Icons.medical_services;
      case 'Education':
      case 'Study':
        return Icons.school;
      case 'Bills':
        return Icons.receipt_long;
      default:
        return Icons.category;
    }
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'date': date.toIso8601String(),
      'category': category,
    };
  }

  String toJsonString() {
    return jsonEncode(toMap());
  }

  factory Expense.fromJsonString(String jsonString) {
    final decoded = jsonDecode(jsonString);

    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expense record must be a JSON object.');
    }

    return Expense.fromMap(Map<String, Object?>.from(decoded));
  }

  factory Expense.fromMap(Map<String, Object?> map) {
    return Expense(
      id: map['id'] as String,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.parse(map['date'] as String),
      category: map['category'] as String,
    );
  }
}
