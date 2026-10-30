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
      title: 'Neo Baggage Fee Calculator',
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
      home: const HomePage(), // first page shown when the app opens
    );
  }
}
 
// App bar used by every page (same colours and status bar)
AppBar buildAppBar(BuildContext context, String title) {
  return AppBar(
    title: Text(title),
    backgroundColor: Theme.of(context).colorScheme.primary,
    foregroundColor: Theme.of(context).colorScheme.onPrimary,
    systemOverlayStyle: const SystemUiOverlayStyle(
      statusBarColor: AppColors.colorPrimary,
      statusBarIconBrightness: Brightness.light, // white icons (Android)
      statusBarBrightness: Brightness.dark, // white icons (iOS)
    ),
  );
}
 
// Navigation menu (left side)
class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key, required this.currentPage});
 
  final String currentPage;
 
  void goTo(BuildContext context, String page) {
    final NavigatorState nav = Navigator.of(context);
    nav.pop(); // close the drawer
    if (page == currentPage) return; // already on this page
 
    nav.popUntil((route) => route.isFirst); // back to Home page
    if (page == 'About') {
      nav.push(
        MaterialPageRoute(builder: (context) => const AboutPage()),
      );
    }
  }
 
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
                'Neo Baggage Fee Calculator',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            selected: currentPage == 'Home',
            onTap: () => goTo(context, 'Home'),
          ),
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            selected: currentPage == 'About',
            onTap: () => goTo(context, 'About'),
          ),
        ],
      ),
    );
  }
}
 
// ---------------------------------------------------------------
// PAGE 1: Home (welcome page)
// ---------------------------------------------------------------
class HomePage extends StatelessWidget {
  const HomePage({super.key});
 
  Widget buildInfoBox(String title, String content, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(content),
        ],
      ),
    );
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: buildAppBar(context, 'Neo Baggage Fee Calculator'),
      drawer: const AppDrawer(currentPage: 'Home'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Application icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/appicon.jpg',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 16),
 
            // Short description
            const Text(
              'Not sure wether your baggage is over the limit?',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Need help to identify your excess baggage weight and calculate '
              'how much to pay? Start using Neo Baggage Fee Calculator now!',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 24),
 
            // Box 1: free baggage allowance
            buildInfoBox(
              'Free Baggage Allowance',
              '- Economy class: 20 kg\n'
              '- Business class: 40 kg',
              Theme.of(context).colorScheme.primaryContainer,
            ),
            const SizedBox(height: 12),
 
            // Box 2: excess baggage rate
            buildInfoBox(
              'Excess Baggage Rate per KG',
              '- Economy class: RM 15.00 / kg\n'
              '- Business class: RM 12.00 / kg\n'
              '\n8% service tax is added to the excess baggage charge.',
              Colors.orange.shade50,
            ),
            const SizedBox(height: 32),
 
            // Button to go to the calculator page
            FilledButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CalculatorPage(),
                  ),
                );
              },
              style: FilledButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: const Text(
                'START CALCULATING',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
 
// ---------------------------------------------------------------
// PAGE 2: Calculator
// ---------------------------------------------------------------
class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});
 
  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}
 
class _CalculatorPageState extends State<CalculatorPage> {
  final TextEditingController weightController = TextEditingController();
 
  String? selectedClass; // null = nothing selected yet
 
  bool showResult = false;
  String excessWeightText = '';
  String excessChargeText = '';
  String serviceTaxText = '';
  String totalPayableText = '';
  String notice = '';
 
  @override
  void dispose() {
    weightController.dispose();
    super.dispose();
  }
 
  // Free baggage allowance (X) is set automatically by ticket class
  double getAllowance() {
    if (selectedClass == 'Economy') {
      return 20;
    } else {
      return 40;
    }
  }
 
  // Excess baggage rate per kg is set automatically by ticket class
  double getRate() {
    if (selectedClass == 'Economy') {
      return 15;
    } else {
      return 12;
    }
  }
 
  void calculateFee() {
    FocusScope.of(context).unfocus(); // hide the keyboard
 
    // 1. Weight empty or not a number?
    final String weightText = weightController.text.trim();
    final double? weight = double.tryParse(weightText);
    if (weightText.isEmpty) {
      showMessage('Please enter your baggage weight.');
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
      showMessage('Please select your ticket class.');
      return;
    }
 
    // 3. Allowance (X) and rate per kg based on ticket class
    double allowance = getAllowance();
    double rate = getRate();
 
    // 4. Excess baggage weight (never negative)
    double excessWeight;
    if (weight > allowance) {
      excessWeight = weight - allowance;
    } else {
      excessWeight = 0;
    }
 
    // 5. Excess baggage charge, service tax and total payable
    double excessCharge = excessWeight * rate;
    double serviceTax = excessCharge * 0.08;
    double totalPayable = excessCharge + serviceTax;
 
    setState(() {
      excessWeightText = '${excessWeight.toStringAsFixed(2)} kg';
      excessChargeText = 'RM ${excessCharge.toStringAsFixed(2)}';
      serviceTaxText = 'RM ${serviceTax.toStringAsFixed(2)}';
      totalPayableText = 'RM ${totalPayable.toStringAsFixed(2)}';
      showResult = true;
    });
 
    // 6. Pop-up message to tell the user the calculation is done
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 40),
        title: const Text('Calculation Complete'),
        content: const Text(
          'Tap OK, then scroll down to see the total amount.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // close the pop-up
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
 
  void resetForm() {
    setState(() {
      weightController.clear();
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
 
  // Live message: tells the customer straight away whether their
  // baggage is over the free allowance (after both questions are answered)
  Widget buildWeightNotice() {
    final double? weight = double.tryParse(weightController.text.trim());
    if (selectedClass == null || weight == null || weight <= 0) {
      return const SizedBox.shrink(); // show nothing yet
    }
 
    double allowance = getAllowance();
    double rate = getRate();
 
    String message;
    Color boxColor;
    IconData icon;
    if (weight > allowance) {
      message = 'Your baggage is more than ${allowance.toStringAsFixed(0)} kg, '
          'so you will have to pay excess baggage. Each extra kg is charged '
          'RM ${rate.toStringAsFixed(2)} for $selectedClass class, '
          'with 8% service tax added to the excess charge.';
      boxColor = Colors.orange.shade100;
      icon = Icons.warning_amber;
    } else {
      message = 'Your baggage is within the ${allowance.toStringAsFixed(0)} kg '
          'free allowance for $selectedClass class. No excess fee.';
      boxColor = Colors.green.shade100;
      icon = Icons.check_circle;
    }
 
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: boxColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
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
        // Back button (top left): returns to the first Home page
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Home',
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Calculate Fee'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: AppColors.colorPrimary,
          statusBarIconBrightness: Brightness.light, // white icons (Android)
          statusBarBrightness: Brightness.dark, // white icons (iOS)
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Instructions
            const Text(
              'Excess Baggage Fee Calculator',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your checked baggage weight, select your ticket class, '
              'then click button calculate.',
            ),
            const SizedBox(height: 24),
 
            // Question 1 - TextField: baggage weight
            const Text(
              '1. What is your baggage weight?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: weightController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              onChanged: (v) => setState(() => showResult = false),
              decoration: const InputDecoration(
                labelText: 'Baggage weight (kg)',
                suffixText: 'kg',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),
 
            // Question 2 - Radio buttons: ticket class
            const Text(
              '2. What is your ticket class?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            RadioGroup<String>(
              groupValue: selectedClass,
              onChanged: (v) => setState(() {
                selectedClass = v;
                showResult = false;
              }),
              child: const Column(
                children: [
                  RadioListTile<String>(
                    title: Text('Economy class'),
                    value: 'Economy',
                  ),
                  RadioListTile<String>(
                    title: Text('Business class'),
                    value: 'Business',
                  ),
                ],
              ),
            ),
 
            // Live notice (over or within the free allowance)
            buildWeightNotice(),
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
                        buildResultRow('Service tax (8%)', serviceTaxText),
                        const Divider(),
                        buildResultRow('Total amount payable', totalPayableText,
                          isBold: true,
                        ),
                        const SizedBox(height: 8),
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
 
// ---------------------------------------------------------------
// PAGE 3: About
// ---------------------------------------------------------------
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});
 
  // Change these to your own details
  static const String authorName = 'Nuha Zafirah Binti Azmi';
  static const String matricNo = '2024237022';
  static const String course =
      'Bachelor of Computer Science (Hons.) Netcentric Computing';
  static const String githubUrl =
      'https://github.com/nuhazafirah2707/IndividualAssignment-ICT602';
 
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
      appBar: buildAppBar(context, 'About'),
      drawer: const AppDrawer(currentPage: 'About'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Application icon
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.asset(
                'assets/icon/appicon.jpg',
                width: 100,
                height: 100,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Neo Baggage Fee Calculator',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'This app estimates the excess baggage fee for air travel '
              'based on baggage weight and ticket class',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
 
            // Author information
            buildInfoCard(
              'assets/icon/authorinfo.jpg',
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
              'assets/icon/copyrightnotice.jpg',
              'Copyright Notice',
              const Text(
                '© 2026 $authorName. \n'
                'All rights reserved.\n'
                'This application was developed for the ICT602 Mobile '
                'Technology Individual Assignment.',
              ),
            ),
            const SizedBox(height: 12),
 
            // GitHub repository (clickable URL)
            buildInfoCard(
              'assets/icon/githubicon.png',
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