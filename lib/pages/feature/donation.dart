import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/donation_options.dart';
import '../../utils/router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: "/donation",
      onGenerateRoute: onGenerateRoute,
    );
  }
}

class DonationOptionWidget extends StatelessWidget {
  final String title;
  final String description;
  final String imageURL;
  final int percentage;
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const DonationOptionWidget({
    super.key,
    required this.title,
    required this.description,
    required this.imageURL,
    required this.percentage,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Color(0xFF2E5BFF) : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Color(0xFF2E5BFF).withOpacity(0.3),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : [],
        ),
        child: Row(
          children: [
            // Circular image on the left
            ClipOval(
              child: Image.asset(
                imageURL,
                width: 50,
                height: 50,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.grey[300],
                    ),
                    child: Icon(
                      Icons.image_not_supported,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  );
                },
              ),
            ),
            
            SizedBox(width: 12),
            
            // Title and description in the middle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 4),
                  // Description with text wrapping
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            
            SizedBox(width: 12),
            
            // Checkbox on the right
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? Color(0xFF2E5BFF) : Colors.white,
                border: Border.all(
                  color: isSelected ? Color(0xFF2E5BFF) : Colors.grey[400]!,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

class DonationPage extends StatefulWidget {
  const DonationPage({super.key});

  @override
  State<DonationPage> createState() => _DonationPageState();
}

class _DonationPageState extends State<DonationPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  
  int? selectedCategory;
  int? selectedAmount;
  List<int> donationAmount = [10, 25, 50, 100, 150, 200];

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _selectPresetAmount(int amount) {
    setState(() {
      selectedAmount = amount;
      _amountController.text = amount.toString();
    });
  }

  bool _canProceed() {
    return selectedCategory != null && 
           _amountController.text.isNotEmpty &&
           (double.tryParse(_amountController.text) ?? 0) >= 1;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Donation',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Center(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: TextStyle(fontSize: 20),
                      children: [
                        TextSpan(
                          text: "Help us ",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "save ",
                          style: TextStyle(
                            color: Color(0xFF2E5BFF),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextSpan(
                          text: "the world",
                          style: TextStyle(
                            color: Colors.black87,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 24),

                // Categories section
                Text(
                  "Select Categories",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                
                SizedBox(height: 12),

                ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: donationOptions.length,
                  itemBuilder: (context, index) {
                    final option = donationOptions[index];
                    return DonationOptionWidget(
                      title: option['title'],
                      description: option['description'],
                      imageURL: option['imageURL'],
                      percentage: option['percentage'],
                      color: option['color'],
                      isSelected: selectedCategory == index,
                      onTap: () {
                        setState(() {
                          selectedCategory = index;
                        });
                      },
                    );
                  },
                ),

                SizedBox(height: 24),

                // Amount section
                Text(
                  "Donation Amount",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                SizedBox(height: 12),

                // Custom amount input
                TextFormField(
                  controller: _amountController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey[300]!),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Color(0xFF2E5BFF), width: 2),
                    ),
                    labelText: "Enter Amount (RM)",
                    prefixText: "RM ",
                    prefixStyle: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Please enter donation amount";
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount < 1) {
                      return "Minimum donation is RM 1";
                    }
                    return null;
                  },
                  onChanged: (value) {
                    setState(() {
                      selectedAmount = null;
                    });
                  },
                ),

                SizedBox(height: 16),

                // Preset amounts
                GridView.count(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  crossAxisCount: 3,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 2.5,
                  children: donationAmount.map((amount) {
                    final isSelected = selectedAmount == amount;
                    return GestureDetector(
                      onTap: () => _selectPresetAmount(amount),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFF2E5BFF) : Colors.white,
                          border: Border.all(
                            color: Color(0xFF2E5BFF),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          "RM $amount",
                          style: TextStyle(
                            color: isSelected ? Colors.white : Color(0xFF2E5BFF),
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: 24),

                // Green coin info
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Color(0xFF1B6839).withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage('assets/images/icon/Green Coin.png'),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          SizedBox(width: 12),
                          Text(
                            "Earn Green Coins",
                            style: TextStyle(
                              color: Color(0xFF1B6839),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Make a difference! Every RM10 donated earns you 20 Green Coins that you can use for rewards.",
                        style: TextStyle(
                          color: Color(0xFF1B6839),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            selectedCategory = null;
                            selectedAmount = null;
                            _amountController.clear();
                          });
                        },
                        icon: Icon(Icons.clear),
                        label: Text("Clear"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Color(0xFF2E5BFF),
                          side: BorderSide(color: Color(0xFF2E5BFF), width: 2),
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _canProceed()
                            ? () {
                                if (_formKey.currentState!.validate()) {
                                  // Handle payment navigation
                                  final selectedTitle = donationOptions[selectedCategory!]['title'];
                                  
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Proceeding with RM${_amountController.text} for: $selectedTitle',
                                      ),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pushNamed(
                                    context,
                                    '/payment',
                                    arguments: {
                                      'amount': double.parse(_amountController.text),
                                      'category': selectedTitle,
                                    },
                                  );
                                }
                              }
                            : null,
                        icon: Icon(Icons.payment),
                        label: Text("Proceed to Payment"),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFF2E5BFF),
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}