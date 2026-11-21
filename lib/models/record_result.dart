// Not implemented yet
// attendance{sessionId}_{studentId}
// examSubmissions{sessionId}_{studentId}
// Both student/;invigilator scan method records student id as document to avoid duplication

class RecordResult {
  final bool created;   // false = already existed
  final DateTime? time; // time of the existing record

  const RecordResult({required this.created, this.time});
}
