import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // 1. Kullanıcıyı Kaydetme/Güncelleme (Normal zamanlarda)
  Future<void> updateNormalLocation(String userId, String name, String groupId, double lat, double lng) async {
    await _db.collection('users').doc(userId).set({
      'name': name,
      'group_id': groupId,
      'last_location': GeoPoint(lat, lng),
    }, SetOptions(merge: true));
  }

  // 2. KRİTİK: Acil Durum Pingi Gönderme (Deprem butonu tetiklendiğinde)
  Future<void> sendEmergencyPing(String userId, String groupId, double lat, double lng) async {
    await _db.collection('emergency_pings').add({
      'user_id': userId,
      'group_id': groupId,
      'location': GeoPoint(lat, lng),
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  // 3. Aile Üyelerini Anlık Dinleme (Harita üzerinde göstermek için)
  Stream<QuerySnapshot> getFamilyLocations(String groupId) {
    return _db.collection('users')
        .where('group_id', isEqualTo: groupId)
        .snapshots();
  }

  // 4. Son Acil Durum Pinglerini Dinleme
  Stream<QuerySnapshot> getEmergencyPings(String groupId) {
    return _db.collection('emergency_pings')
        .where('group_id', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .snapshots();
  }
}