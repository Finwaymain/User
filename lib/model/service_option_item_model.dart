import 'package:finway/model/service_category_model.dart';
import 'package:finway/page/features/AllServices/service_style.dart';

class ServiceOptionItem {
  final String id;
  final String title;
  final String description;
  final String icon;

  const ServiceOptionItem({
    required this.id,
    required this.title,
    this.description = '',
    this.icon = '✓',
  });

  factory ServiceOptionItem.fromCategory(ServiceCategoryData data) {
    final clean = cleanServiceName(data.libelle);
    return ServiceOptionItem(
      id: (data.id ?? data.libelle ?? '').toString(),
      title: clean,
      description: _descFor(clean),
      icon: _iconFor(clean),
    );
  }

  static String _descFor(String name) {
    final clean = name.toLowerCase();
    if (clean.contains('cbc')) return 'Checks overall health, infection & anemia indicators';
    if (clean.contains('sugar')) return 'Fasting, PP sugar and blood glucose levels';
    if (clean.contains('hba1c')) return '3-month average blood sugar control';
    if (clean.contains('thyroid')) return 'Evaluates T3, T4, TSH hormone levels & metabolism';
    if (clean.contains('lipid')) return 'Cholesterol, HDL, LDL, and Triglycerides profile';
    if (clean.contains('lft')) return 'Liver enzymes, Bilirubin & SGPT assessment';
    if (clean.contains('kft')) return 'Creatinine, Urea & Kidney function evaluation';
    if (clean.contains('vitamin')) return 'Essential bone, nerve & immunity vitamin check';
    if (clean.contains('urine')) return 'Screening for infection, protein & kidney health';
    if (clean.contains('fever') || clean.contains('dengue')) return 'Rapid diagnostic screening for infections & fevers';
    if (clean.contains('full body')) return 'Comprehensive 60+ parameters essential health suite';
    if (clean.contains('sample') || clean.contains('collection')) return 'Technician arrives at home for certified sample collection';
    return '';
  }

  static String _iconFor(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('cbc') || lower.contains('blood')) return '🩸';
    if (lower.contains('sugar') || lower.contains('diabetes')) return '🍬';
    if (lower.contains('thyroid')) return '🦋';
    if (lower.contains('lipid') || lower.contains('heart') || lower.contains('bp')) return '❤️';
    if (lower.contains('lft') || lower.contains('kft') || lower.contains('kidney') || lower.contains('liver')) return '🏥';
    if (lower.contains('vitamin')) return '☀️';
    if (lower.contains('urine') || lower.contains('stool') || lower.contains('test')) return '🧪';
    if (lower.contains('fever') || lower.contains('dengue') || lower.contains('malaria')) return '🤒';
    if (lower.contains('full body') || lower.contains('package')) return '🔬';
    if (lower.contains('physician') || lower.contains('doctor')) return '🩺';
    if (lower.contains('pediatric') || lower.contains('child')) return '👶';
    if (lower.contains('elderly') || lower.contains('geriatric')) return '🧓';
    if (lower.contains('women')) return '👩‍⚕️';
    if (lower.contains('physio') || lower.contains('rehab')) return '🦴';
    if (lower.contains('nurse') || lower.contains('injection')) return '💉';
    if (lower.contains('tutor') || lower.contains('tuition')) return '📚';
    if (lower.contains('jee') || lower.contains('neet')) return '🎯';
    return '🧪';
  }
}
