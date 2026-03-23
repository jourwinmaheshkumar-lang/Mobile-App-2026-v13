import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/club_member.dart';

class ClubRepository {
  final _db = FirebaseFirestore.instance;
  final String _membersCol = 'club_members';

  Stream<List<ClubMember>> getMembersAtLevel(ClubLevel level) {
    return _db.collection(_membersCol)
        .where('level', isEqualTo: level.id)
        .snapshots()
        .map((snapshot) {
          final members = snapshot.docs.map((doc) => ClubMember.fromDoc(doc)).toList();
          // Sort manually: primary by custom order, secondary by joinedAt (newest first)
          members.sort((a, b) {
            final orderComp = a.order.compareTo(b.order);
            if (orderComp != 0) return orderComp;
            return b.joinedAt.compareTo(a.joinedAt);
          });
          return members;
        });
  }

  /// Bulk update orders for a list of members
  Future<void> reorderMembers(List<ClubMember> reorderedMembers) async {
    final batch = _db.batch();
    for (int i = 0; i < reorderedMembers.length; i++) {
      final docRef = _db.collection(_membersCol).doc(reorderedMembers[i].id);
      batch.update(docRef, {'order': i});
    }
    await batch.commit();
  }

  /// Add a director to a club level
  Future<void> addMember({
    required String directorId,
    required String directorName,
    required ClubLevel level,
  }) async {
    // Check if member already exists in THIS level
    final existing = await _db.collection(_membersCol)
        .where('directorId', isEqualTo: directorId)
        .where('level', isEqualTo: level.id)
        .limit(1)
        .get();

    if (existing.docs.isEmpty) {
      await _db.collection(_membersCol).add({
        'directorId': directorId,
        'directorName': directorName,
        'level': level.id,
        'joinedAt': Timestamp.now(),
      });
    }
  }

  /// Remove a member from a club level
  Future<void> removeMember(String memberDocId) async {
    await _db.collection(_membersCol).doc(memberDocId).delete();
  }
}

final clubRepository = ClubRepository();
