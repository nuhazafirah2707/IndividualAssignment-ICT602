import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
 
void main() => runApp(const MyApp());
 
class AppColors {
  static const Color colorPrimary = Color(0xFF0D47A1);
  static const Color colorOnPrimary = Color(0xFFFFFFFF);
  static const Color colorSecondary = Color(0xFFFF8F00);
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Baggage Fee Calculator',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.colorPrimary,
        ).copyWith(
          primary: AppColors.colorPrimary,
          onPrimary: AppColors.colorOnPrimary,
          secondary: AppColors.colorSecondary,
        ),
      ),
      home: const HomePage(),
    );
  }
}
 
// Navigation menu (left side)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentPage});
 
  final String currentPage;
 
  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: Text(
                'Baggage Fee Calculator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          ListTile(
            title: const Text('Home'),
            selected: currentPage == 'Home',
            onTap: () {
              Navigator.pop(context); // close the drawer
              if (currentPage != 'Home') {
                Navigator.pop(context); // back to Home page
              }
            },
          ),
          ListTile(
            title: const Text('About'),
            selected: currentPage == 'About',
            onTap: () {
              Navigator.pop(context); // close the drawer
              if (currentPage != 'About') {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AboutPage()),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
 
class HomePage extends StatefulWidget {
  const HomePage({super.key});
 
  @override
  State<HomePage> createState() => _HomePageState();
}
 
class _HomePageState extends State<HomePage> {
  final TextEditingController weightController = TextEditingController();
  final TextEditingController rateController = TextEditingController();
 
  String? selectedClass; // null = nothing selected yet
 
  bool showResult = false;
  String excessWeightText = '';
  String excessChargeText = '';
  String totalPayableText = '';
  String notice = '';
 
  @override
  void dispose() {
    weightController.dispose();
    rateController.dispose();
    super.dispose();
  }
 
  void calculateFee() {
    FocusScope.of(context).unfocus(); // hide the keyboard
 
    // 1. Weight empty or not a number?
    final double? weight = double.tryParse(weightController.text.trim());
    if (weightController.text.trim().isEmpty) {
      showMessage('Please enter the baggage weight.');
      return;
    }
    if (weight == null) {
      showMessage('Baggage weight must be a number (e.g. 25 or 42.5).');
      return;
    }
    if (weight <= 0) {
      showMessage('Baggage weight must be more than 0 kg.');
      return;
    }
 
    // 2. Ticket class not selected?
    if (selectedClass == null) {
      showMessage('Please select a ticket class.');
      return;
    }
 
    // 3. Rate empty or not a number?
    final double? rate = double.tryParse(rateController.text.trim());
    if (rateController.text.trim().isEmpty) {
      showMessage('Please enter the excess baggage rate per kg.');
      return;
    }
    if (rate == null) {
      showMessage('Rate must be a number (e.g. 15 or 12.50).');
      return;
    }
    if (rate <= 0) {
      showMessage('Rate must be more than RM 0.');
      return;
    }
 
    // 4. Free baggage allowance (X) based on ticket class
    double allowance;
    if (selectedClass == 'Economy') {
      allowance = 20;
    } else {
      allowance = 40;
    }
 
    // 5. Excess baggage weight (never negative)
    double excessWeight;
    if (weight > allowance) {
      excessWeight = weight - allowance;
    } else {
      excessWeight = 0;
    }
 
    // 6. Excess baggage charge and total payable (8% service tax)
    double excessCharge = excessWeight * rate;
    double totalPayable = excessCharge + (excessCharge * 0.08);
 
    // 7. Notice for the user
    String noticeText;
    if (excessWeight == 0) {
      noticeText = 'Your baggage is within the ${allowance.toStringAsFixed(0)} kg '
          'free allowance. No excess fee is charged.';
    } else {
      noticeText = 'Your baggage is ${excessWeight.toStringAsFixed(2)} kg over '
          'the ${allowance.toStringAsFixed(0)} kg free allowance for '
          '$selectedClass class.';
    }
 
    setState(() {
      excessWeightText = '${excessWeight.toStringAsFixed(2)} kg';
      excessChargeText = 'RM ${excessCharge.toStringAsFixed(2)}';
      totalPayableText = 'RM ${totalPayable.toStringAsFixed(2)}';
      notice = noticeText;
      showResult = true;
    });
  }
 
  void resetForm() {
    setState(() {
      weightController.clear();
      rateController.clear();
      selectedClass = null;
      showResult = false;
    });
  }
 
  void showMessage(String text) {
    setState(() => showResult = false);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 2),
        ),
      );
  }
 
  Widget buildResultRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Baggage Fee Calculator'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.colorPrimary,
          statusBarIconBrightness: Brightness.light, // white icons (Android)
          statusBarBrightness: Brightness.dark, // white icons (iOS)
        ),
      ),
      drawer: const AppDrawer(currentPage: 'Home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            const Text(
              'Excess Baggage Fee Estimator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your checked baggage weight, choose your ticket class '
              'and the excess rate per kg, then tap CALCULATE.',
            ),
            const SizedBox(height: 12),
 
            // Notice
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Free baggage allowance:\n'
                '- Economy class: 20 kg\n'
                '- Business class: 40 kg\n'
                '8% service tax is added to the excess baggage charge.',
              ),
            ),
            const SizedBox(height: 20),
 
            // TextField: baggage weight
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Baggage weight (kg)',
                hintText: 'e.g. 25.5',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
 
            // Radio buttons: ticket class
            const Text(
              'Ticket class',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioGroup<String>(
              groupValue: selectedClass,
              onChanged: (v) => setState(() => selectedClass = v),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Economy'),
                    subtitle: Text('Free allowance 20 kg'),
                    value: 'Economy',
                  ),
                  RadioListTile<String>(
                    title: Text('Business'),
                    subtitle: Text('Free allowance 40 kg'),
                    value: 'Business',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
 
            // TextField: excess rate
            TextField(
              controller: rateController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Excess baggage rate per kg',
                hintText: 'e.g. 15',
                prefixText: 'RM ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
 
            // Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton(
                  onPressed: calculateFee,
                  child: const Text('CALCULATE'),
                ),
                const SizedBox(width: 16),
                OutlinedButton(
                  onPressed: resetForm,
                  child: const Text('RESET'),
                ),
              ],
            ),
            const SizedBox(height: 24),
 
            // Output
            if (showResult)
              SizedBox(
                width: double.infinity,
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Result',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const Divider(),
                        buildResultRow(
                            'Excess baggage weight', excessWeightText),
                        buildResultRow(
                            'Excess baggage charge', excessChargeText),
                        const Divider(),
                        buildResultRow(
                          'Total amount payable',
                          totalPayableText,
                          isBold: true,
                        ),
                        const Text(
                          '(including 8% service tax)',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          notice,
                          style: TextStyle(
                            fontStyle: FontStyle.italic,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
 
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
 
  // Change these to your own details
  static const String authorName = 'YOUR FULL NAME';
  static const String matricNo = '20XXXXXXXX';
  static const String course =
      'Bachelor of Computer Science (Hons.) Netcentric Computing';
  static const String githubUrl =
      'https://github.com/your-username/baggage_fee_calculator';
 
  Future<void> openGitHub(BuildContext context) async {
    final Uri url = Uri.parse(githubUrl);
    try {
      bool opened = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!opened) {
        throw Exception('Could not open $githubUrl');
      }
    } catch (e) {
      debugPrint('Launch error: $e'); // trace in the Debug Console
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open the GitHub link.')),
      );
    }
  }
 
  Widget buildInfoCard(String imagePath, String title, Widget content) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.asset(
              imagePath,
              width: 48,
              height: 48,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  content,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.colorPrimary,
          statusBarIconBrightness: Brightness.light, // white icons (Android)
          statusBarBrightness: Brightness.dark, // white icons (iOS)
        ),
      ),
      drawer: const AppDrawer(currentPage: 'About'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Application icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/images/appicon.jpg',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Baggage Fee Calculator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text('Version 1.0.0'),
            const SizedBox(height: 8),
            const Text(
              'This app estimates the excess baggage fee for air travel '
              'based on baggage weight, ticket class and rate per kg.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
 
            // Author information
            buildInfoCard(
              'assets/images/authorinfo.jpg',
              'Author Information',
              const Text(
                'Name: $authorName\n'
                'Matric No: $matricNo\n'
                'Course: $course',
              ),
            ),
            const SizedBox(height: 12),
 
            // Copyright notice
            buildInfoCard(
              'assets/images/copyrightnotice.jpg',
              'Copyright Notice',
              const Text(
                '© 2026 $authorName. All rights reserved.\n'
                'This application was developed for the ICT602 Mobile '
                'Technology individual assignment.',
              ),
            ),
            const SizedBox(height: 12),
 
            // GitHub repository (clickable URL)
            buildInfoCard(
              'assets/images/githubicon.png',
              'GitHub Repository',
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => openGitHub(context),
                    child: const Text(
                      githubUrl,
                      style: TextStyle(
                        color: Colors.blue,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tap the link to view the source code.',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 