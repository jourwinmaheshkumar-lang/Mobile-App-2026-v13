import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/office.dart';

class OfficeRepository {
  static final OfficeRepository _instance = OfficeRepository._internal();
  factory OfficeRepository() => _instance;
  OfficeRepository._internal();

  final CollectionReference _collection = FirebaseFirestore.instance.collection('offices');

  Stream<List<Office>> get officesStream {
    return _collection.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Office.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  Future<void> addOffice(Office office) async {
    await _collection.doc(office.id).set(office.toMap());
  }

  Future<void> updateOffice(Office office) async {
    await _collection.doc(office.id).update(office.toMap());
  }

  Future<void> deleteOffice(String id) async {
    await _collection.doc(id).delete();
  }
  
  // Initialize with default offices if empty
  Future<void> initializeDefaults() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isEmpty) {
      final defaults = [
        Office(
          id: 'head-office',
          name: 'Head Office',
          type: 'Head Office',
          location: 'Chennai',
          address: 'Main Building, 1st Floor',
        ),
        Office(
          id: 'corporate-office',
          name: 'Corporate Office',
          type: 'Corporate Office',
          location: 'Bangalore',
          address: 'Tech Park, Sector 5',
        ),
      ];
      
      for (var office in defaults) {
        await addOffice(office);
      }
    }
  }
}

final officeRepository = OfficeRepository();
