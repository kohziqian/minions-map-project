// Reading/building the text stored inside QR codes.
String getQRValue(String qrData, String key) {
  final lines = qrData.split('\n');

  for (final rawLine in lines) {
    final line = rawLine.trim();

    if (line.startsWith('$key=')) {
      return line.substring(key.length + 1).trim();
    }
  }

  return 'Unknown';
}

// Extract and convert to uppercase for matric card student ID
String extractStudentId(String qrData) {
  final studentId = getQRValue(qrData, 'studentId');

  if (studentId != 'Unknown' && studentId.isNotEmpty) {
    return studentId.toUpperCase();
  }

  final matricNo = getQRValue(qrData, 'matricNo');

  if (matricNo != 'Unknown' && matricNo.isNotEmpty) {
    return matricNo.toUpperCase();
  }

  return qrData.trim().toUpperCase();
}

// QR payload for an exam session
String sessionQrData(String sessionId) => 'sessionId=$sessionId';

// QR payload for a student's matric QR on profile page
String studentQrData(String matricNo) => 'studentId=$matricNo';
