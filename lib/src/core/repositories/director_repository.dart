import '../models/director.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/activity_log_service.dart';
import '../models/activity_log.dart';

class DirectorRepository {
  static final DirectorRepository _instance = DirectorRepository._internal();
  factory DirectorRepository() => _instance;
  
  DirectorRepository._internal();

  CollectionReference get _collection => FirebaseFirestore.instance.collection('directors');

  List<Director> _localCache = [];
  bool _isLoaded = false;

  // Stream for active (non-removed) directors only
  Stream<List<Director>> get directorsStream {
    return _collection.snapshots().map((snapshot) {
      _localCache = snapshot.docs.map((doc) => _directorFromDoc(doc)).toList();
      // Sort by serial number
      _localCache.sort((a, b) => a.serialNo.compareTo(b.serialNo));
      _isLoaded = true;
      return _localCache.where((d) => !d.isRemoved).toList();
    });
  }

  // Stream for removed directors only
  Stream<List<Director>> get removedDirectorsStream {
    return _collection.snapshots().map((snapshot) {
      final allDirectors = snapshot.docs.map((doc) => _directorFromDoc(doc)).toList();
      // Sort by removal date (most recent first)
      final removed = allDirectors.where((d) => d.isRemoved).toList();
      removed.sort((a, b) => (b.removedAt ?? DateTime.now()).compareTo(a.removedAt ?? DateTime.now()));
      return removed;
    });
  }

  // Get active directors only
  List<Director> get all => _localCache.where((d) => !d.isRemoved).toList();
  
  // Get removed directors from cache
  List<Director> get removedDirectors => _localCache.where((d) => d.isRemoved).toList();
  
  int get totalCount => all.length;
  int get removedCount => removedDirectors.length;
  int get noDinCount => all.where((d) => d.hasNoDin).length;
  int get addressMismatchCount => all.where((d) => d.hasAddressMismatch).length;
  
  int get birthdaysThisMonth => 0;
  
  int get activeCount => all.where((d) => d.status == 'Active').length;
  int get inactiveCount => all.where((d) => d.status == 'Inactive').length;
  double get activePercentage => totalCount == 0 ? 0 : (activeCount / totalCount) * 100;

  Future<List<Director>> loadAll() async {
    try {
      final snapshot = await _collection.get().timeout(const Duration(seconds: 5));
      _localCache = snapshot.docs.map((doc) => _directorFromDoc(doc)).toList();
      _localCache.sort((a, b) => a.serialNo.compareTo(b.serialNo));
      _isLoaded = true;
      return all;
    } catch (e) {
      print('Error loading directors: $e');
      return all;
    }
  }

  Director? getById(String id) {
    try {
      return _localCache.firstWhere((d) => d.id == id);
    } catch (_) {
      return null;
    }
  }

  List<Director> search(String query) {
    if (query.isEmpty) return all;
    return all.where((d) =>
      d.name.contains(query) ||
      d.din.contains(query) ||
      d.email.contains(query) ||
      d.pan.contains(query)
    ).toList();
  }

  Future<void> add(Director director) async {
    await _collection.doc(director.id).set(_directorToMap(director));
    await activityLogService.log(
      action: ActivityAction.create,
      entityType: EntityType.director,
      entityName: director.name,
      entityId: director.id,
      details: 'Created new director record',
    );
  }

  Future<void> update(Director director) async {
    await _collection.doc(director.id).update(_directorToMap(director));
    await activityLogService.log(
      action: ActivityAction.update,
      entityType: EntityType.director,
      entityName: director.name,
      entityId: director.id,
      details: 'Updated director information',
    );
  }

  // Soft delete - marks director as removed
  Future<void> remove(String id) async {
    final director = getById(id);
    await _collection.doc(id).update({
      'isRemoved': true,
      'removedAt': FieldValue.serverTimestamp(),
    });
    if (director != null) {
      await activityLogService.log(
        action: ActivityAction.delete,
        entityType: EntityType.director,
        entityName: director.name,
        entityId: id,
        details: 'Moved director to trash',
      );
    }
  }

  // Restore a removed director
  Future<void> restore(String id) async {
    final director = getById(id);
    await _collection.doc(id).update({
      'isRemoved': false,
      'removedAt': null,
    });
    if (director != null) {
      await activityLogService.log(
        action: ActivityAction.restore,
        entityType: EntityType.director,
        entityName: director.name,
        entityId: id,
        details: 'Restored director from trash',
      );
    }
  }

  // Permanently delete a director (use with caution)
  Future<void> permanentlyDelete(String id) async {
    final director = getById(id);
    await _collection.doc(id).delete();
    if (director != null) {
      await activityLogService.log(
        action: ActivityAction.permanentDelete,
        entityType: EntityType.director,
        entityName: director.name,
        entityId: id,
        details: 'Permanently deleted director record',
      );
    }
  }

  // Legacy delete method - now does soft delete
  Future<void> delete(String id) async {
    await remove(id);
  }

  Director _directorFromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parse serial number
    int serialNo = 0;
    if (data['S.NO'] != null) {
      if (data['S.NO'] is int) {
        serialNo = data['S.NO'];
      } else if (data['S.NO'] is String) {
        serialNo = int.tryParse(data['S.NO'].toString()) ?? 0;
      }
    }
    
    // Parse DIN (can be int or string) - check multiple field names
    String din = '';
    if (data['din'] != null) {
      din = data['din'].toString();
    } else if (data['DIN NUMBER'] != null) {
      din = data['DIN NUMBER'].toString();
    } else if (data['DIN'] != null) {
      din = data['DIN'].toString();
    }
    
    // Parse phone numbers (can be int or string)
    String bankPhone = _parsePhone(data['Bank link Phone number'] ?? data['Bank \nlink Phone number'] ?? data['bankLinkedPhone'] ?? '');
    String aadhaarPanPhone = _parsePhone(data['Aadhar Pan link Phone number'] ?? data['aadhaarPanLinkedPhone'] ?? '');
    String emailPhone = _parsePhone(data['Email ID Phone number'] ?? data['emailLinkedPhone'] ?? '');
    
    // Parse IDBI and eMudhra account details - check multiple field name variations
    String idbiDetails = data['IDBI ACCOUNT DETAILS'] ?? 
                         data['IDBI Account Details'] ?? 
                         data['idbiAccountDetails'] ?? 
                         data['IDBI_ACCOUNT_DETAILS'] ?? '';
    
    String emudhraDetails = data['EMUDRA ACCOUNT DETAILS'] ?? 
                            data['eMUDHRA ACCOUNT DETAILS'] ?? 
                            data['eMudhra Account Details'] ?? 
                            data['emudhraAccountDetails'] ?? 
                            data['EMUDRA_ACCOUNT_DETAILS'] ?? '';
    
    // Parse soft delete fields
    bool isRemoved = data['isRemoved'] ?? false;
    DateTime? removedAt;
    if (data['removedAt'] != null) {
      if (data['removedAt'] is Timestamp) {
        removedAt = (data['removedAt'] as Timestamp).toDate();
      }
    }
    
    // Parse companies list
    List<CompanyDetail> companies = [];
    if (data['companies'] != null && data['companies'] is List) {
      companies = (data['companies'] as List)
          .map((c) => CompanyDetail.fromMap(c as Map<String, dynamic>))
          .toList();
    }

    return Director(
      id: doc.id,
      serialNo: serialNo,
      name: data['DIRECTORS NAMES'] ?? data['name'] ?? '',
      din: din,
      email: data['EMAIL ID'] ?? data['email'] ?? '',
      status: data['status'] ?? data['directorType'] ?? 'Active',
      aadhaarAddress: data['Aadhar Address'] ?? data['aadhaarAddress'] ?? '',
      residentialAddress: data['Residential Address'] ?? data['residentialAddress'] ?? data['currentAddress'] ?? '',
      aadhaarNumber: data['AADHAR NUMBER'] ?? data['aadhaarNumber'] ?? '',
      pan: data['PAN NUMBER'] ?? data['pan'] ?? '',
      idbiAccountDetails: idbiDetails,
      emudhraAccountDetails: emudhraDetails,
      bankLinkedPhone: bankPhone,
      aadhaarPanLinkedPhone: aadhaarPanPhone,
      emailLinkedPhone: emailPhone,
      isRemoved: isRemoved,
      removedAt: removedAt,
      companies: companies,
    );
  }

  String _parsePhone(dynamic value) {
    if (value == null) return '';
    if (value is int) return value.toString();
    return value.toString();
  }

  Map<String, dynamic> _directorToMap(Director d) {
    return {
      'S.NO': d.serialNo,
      'DIRECTORS NAMES': d.name,
      'DIN NUMBER': d.din,
      'EMAIL ID': d.email,
      'status': d.status,
      'Aadhar Address': d.aadhaarAddress,
      'Residential Address': d.residentialAddress,
      'AADHAR NUMBER': d.aadhaarNumber,
      'PAN NUMBER': d.pan,
      'IDBI ACCOUNT DETAILS': d.idbiAccountDetails,
      'EMUDRA ACCOUNT DETAILS': d.emudhraAccountDetails,
      'Bank link Phone number': d.bankLinkedPhone,
      'Aadhar Pan link Phone number': d.aadhaarPanLinkedPhone,
      'Email ID Phone number': d.emailLinkedPhone,
      'isRemoved': d.isRemoved,
      'removedAt': d.removedAt != null ? Timestamp.fromDate(d.removedAt!) : null,
      'companies': d.companies.map((c) => c.toMap()).toList(),
    };
  }
}

