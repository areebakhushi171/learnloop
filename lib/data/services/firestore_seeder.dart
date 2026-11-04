import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/course_model.dart';
import '../models/lesson_model.dart';
import '../models/quiz_model.dart';

class FirestoreSeeder {
  final FirebaseFirestore _firestore;

  FirestoreSeeder({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Future<void> seedInitialCoursesIfEmpty() async {
    final snapshot = await _firestore.collection('courses').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = _firestore.batch();

    final List<Map<String, dynamic>> sampleCourses = [
      {
        'id': 'flutter-masterclass',
        'title': 'Flutter 3 & Dart Deep Dive',
        'description': 'Master mobile development with Riverpod, Clean Architecture, and high-performance UI engineering.',
        'category': 'Mobile Dev',
        'instructorName': 'Dr. Elena Rostova',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1551650975-87deedd944c3',
        'durationMinutes': 320,
        'totalLessons': 12,
        'rating': 4.9,
        'level': 'Intermediate',
        'isFeatured': true,
      },
      {
        'id': 'python-data-science',
        'title': 'Data Science & Machine Learning Foundations',
        'description': 'Learn NumPy, Pandas, Scikit-learn, and statistical modeling with real-world datasets.',
        'category': 'Data Science',
        'instructorName': 'Prof. Marcus Chen',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1551288049-bebda4e38f71',
        'durationMinutes': 240,
        'totalLessons': 10,
        'rating': 4.8,
        'level': 'Beginner',
        'isFeatured': true,
      },
      {
        'id': 'uiux-design-systems',
        'title': 'Design Systems & Figma Mastery',
        'description': 'From tokens to interactive prototypes: building scalable design frameworks for modern apps.',
        'category': 'UI/UX Design',
        'instructorName': 'Sarah Lindqvist',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1507238691740-187a5b1d37b8',
        'durationMinutes': 180,
        'totalLessons': 8,
        'rating': 4.9,
        'level': 'Beginner',
        'isFeatured': true,
      },
      {
        'id': 'cloud-architecture-aws',
        'title': 'Serverless Cloud Architecture',
        'description': 'Deploy resilient microservices using Docker, Kubernetes, and event-driven computing.',
        'category': 'Cloud Computing',
        'instructorName': 'David Miller',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1451187580459-43490279c0fa',
        'durationMinutes': 290,
        'totalLessons': 9,
        'rating': 4.7,
        'level': 'Advanced',
        'isFeatured': false,
      },
      {
        'id': 'algorithms-data-structures',
        'title': 'Algorithms & Data Structures in Practice',
        'description': 'Ace technical interviews: dynamic programming, graphs, trees, and complexity analysis.',
        'category': 'Computer Science',
        'instructorName': 'Alex Rivera',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1516116211227-bbc141e6c434',
        'durationMinutes': 400,
        'totalLessons': 15,
        'rating': 5.0,
        'level': 'Advanced',
        'isFeatured': true,
      },
      {
        'id': 'tech-entrepreneurship',
        'title': 'From Prototype to Product-Market Fit',
        'description': 'Building venture-scale software companies: unit economics, growth loops, and MVP validation.',
        'category': 'Business & Tech',
        'instructorName': 'Amina Patel',
        'thumbnailUrl': 'https://images.unsplash.com/photo-1460925895917-afdab827c52f',
        'durationMinutes': 150,
        'totalLessons': 6,
        'rating': 4.6,
        'level': 'Beginner',
        'isFeatured': false,
      },
    ];

    for (final c in sampleCourses) {
      final docRef = _firestore.collection('courses').doc(c['id']);
      final course = CourseModel(
        id: c['id'],
        title: c['title'],
        description: c['description'],
        category: c['category'],
        instructorName: c['instructorName'],
        thumbnailUrl: c['thumbnailUrl'],
        durationMinutes: c['durationMinutes'],
        totalLessons: c['totalLessons'],
        rating: c['rating'],
        level: c['level'],
        isFeatured: c['isFeatured'],
        createdAt: DateTime.now(),
      );
      batch.set(docRef, course.toFirestore());

      for (int i = 1; i <= 3; i++) {
        final lessonRef = docRef.collection('lessons').doc('lesson-$i');
        final lesson = LessonModel(
          id: 'lesson-$i',
          courseId: c['id'],
          title: 'Lesson $i: Foundations & Principles',
          description: 'Detailed walkthrough of core concepts, architecture patterns, and practical execution.',
          orderIndex: i,
          durationMinutes: 15,
          videoUrl: 'https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4',
          markdownContent: '''
# Welcome to Lesson $i

In this comprehensive session, we explore the core building blocks of this discipline.

### Key Objectives:
- Master architectural trade-offs
- Formulate optimal state flow
- Validate edge cases and production reliability

Ensure you review the summary notes and prepare for the timed module assessment.
''',
          hasQuiz: i == 3,
        );
        batch.set(lessonRef, lesson.toFirestore());
      }

      final quizRef = docRef.collection('quizzes').doc('quiz-1');
      final quiz = QuizModel(
        id: 'quiz-1',
        courseId: c['id'],
        title: '${c['title']} Mastery Quiz',
        timeLimitSeconds: 120,
        passScorePercent: 70,
        questions: const [
          QuizQuestion(
            id: 'q1',
            questionText: 'What is the primary architectural advantage of state immutability?',
            options: [
              'Predictable time-travel debugging and race-free concurrency',
              'Decreases app file size by 50%',
              'Eliminates the need for testing',
              'Directly accelerates network requests'
            ],
            correctOptionIndex: 0,
            explanation: 'Immutability ensures state transitions are transparent, pure, and safe from unexpected mutation across threads.',
          ),
          QuizQuestion(
            id: 'q2',
            questionText: 'Which data structure provides amortized O(1) time complexity for insertions and lookups?',
            options: ['Linked List', 'Hash Map', 'Binary Search Tree', 'Min Heap'],
            correctOptionIndex: 1,
            explanation: 'Hash maps compute a hash code for direct bucket addressing, yielding O(1) average lookup and insertion time.',
          ),
          QuizQuestion(
            id: 'q3',
            questionText: 'Why should presentation widgets remain decoupled from direct data transport clients?',
            options: [
              'To comply with design system color schemes',
              'To enable seamless unit testing, repository swapping, and separation of concerns',
              'Because Flutter prohibits HTTP calls inside stateful widgets',
              'To increase GPU frame rates'
            ],
            correctOptionIndex: 1,
            explanation: 'Clean separation allows the presentation layer to remain purely declarative while domain logic can be independently mocked.',
          ),
        ],
      );
      batch.set(quizRef, quiz.toFirestore());
    }

    await batch.commit();
  }
}
