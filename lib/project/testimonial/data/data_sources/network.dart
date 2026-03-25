import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/testimonial_dto.dart';
import '../../domain/data_sources/network.dart';
import '../../domain/entities/testimonial.dart';
import '../../domain/exception/failures.dart';

/// Firestore-backed network data source for testimonials.
class TestimonialNetwork implements ITestimonialNetwork {
  final FirebaseFirestore _firestore;

  TestimonialNetwork({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection('testimonials');

  @override
  Future<Result<List<Testimonial>>> fetchApprovedTestimonials() async {
    try {
      final snapshot = await _collection
          .where('status', isEqualTo: 'approved')
          .orderBy('createdAt', descending: true)
          .get();

      final testimonials = snapshot.docs.map((doc) {
        final data = doc.data();
        // Convert Firestore Timestamp to DateTime for the DTO parser.
        if (data['createdAt'] is Timestamp) {
          data['createdAt'] = (data['createdAt'] as Timestamp).toDate();
        }
        return TestimonialDto.fromJson(data, doc.id).toDomain();
      }).toList();

      return Success(testimonials);
    } catch (e) {
      return Failure(TestimonialFailure.fetchFailed, e.toString());
    }
  }

  @override
  Future<Result<Testimonial>> submitTestimonial(
    Map<String, dynamic> data,
  ) async {
    try {
      // Force status to pending and use server timestamp.
      final payload = {
        ...data,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _collection.add(payload);

      // Read back the created document to return a full entity.
      final snapshot = await docRef.get();
      final docData = snapshot.data()!;
      if (docData['createdAt'] is Timestamp) {
        docData['createdAt'] = (docData['createdAt'] as Timestamp).toDate();
      }

      final testimonial =
          TestimonialDto.fromJson(docData, snapshot.id).toDomain();
      return Success(testimonial);
    } catch (e) {
      return Failure(TestimonialFailure.submitFailed, e.toString());
    }
  }

  @override
  Stream<List<Testimonial>> watchApprovedTestimonials() {
    return _collection
        .where('status', isEqualTo: 'approved')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              if (data['createdAt'] is Timestamp) {
                data['createdAt'] =
                    (data['createdAt'] as Timestamp).toDate();
              }
              return TestimonialDto.fromJson(data, doc.id).toDomain();
            }).toList());
  }
}
