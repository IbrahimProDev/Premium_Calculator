import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:math_expressions/math_expressions.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Premium Calculator',
      theme: ThemeData(primarySwatch: Colors.deepPurple, useMaterial3: true),
      home: CalculatorScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class CalculatorScreen extends StatefulWidget {
  @override
  _CalculatorScreenState createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String _input = '';
  String _result = '0';
  List<String> _history = [];
  bool _showHistory = false;
  int _cursorPosition = 0;
  bool _cursorVisible = true;

  // Scroll controllers
  final ScrollController _inputScrollController = ScrollController();
  final ScrollController _resultScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _startCursorAnimation();
  }

  void _startCursorAnimation() {
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _cursorVisible = !_cursorVisible;
        });
        _startCursorAnimation();
      }
    });
  }

  void _playClickSound() async {
    await _audioPlayer.play(AssetSource('sounds/click.mp3'));
  }

  void _onButtonPressed(String buttonText) {
    _playClickSound();

    setState(() {
      if (buttonText == 'C') {
        _input = '';
        _result = '0';
        _cursorPosition = 0;
      } else if (buttonText == '⌫') {
        _deleteAtCursor();
      } else if (buttonText == '=') {
        if (_input.isNotEmpty) {
          _calculateResult();
        }
      } else if (buttonText == '📜') {
        _showHistory = !_showHistory;
      } else if (buttonText == '◀') {
        _moveCursorLeft();
      } else if (buttonText == '▶') {
        _moveCursorRight();
      } else if (buttonText == '%') {
        _insertPercentage();
      } else {
        _insertAtCursor(buttonText);
      }
    });

    // Auto scroll input to end
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_inputScrollController.hasClients) {
        _inputScrollController.animateTo(
          _inputScrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _insertAtCursor(String text) {
    _input =
        _input.substring(0, _cursorPosition) +
        text +
        _input.substring(_cursorPosition);
    _cursorPosition += text.length;
  }

  void _insertPercentage() {
    // If input is empty, just add 0%
    if (_input.isEmpty) {
      _input = '0%';
      _cursorPosition = 2;
      return;
    }

    // Find the last number in the input
    String lastNumber = '';
    int i = _cursorPosition - 1;

    // Traverse backwards to find the complete number
    while (i >= 0 && '0123456789.'.contains(_input[i])) {
      lastNumber = _input[i] + lastNumber;
      i--;
    }

    if (lastNumber.isNotEmpty) {
      double number = double.tryParse(lastNumber) ?? 0;
      double percentage = number / 100;

      // Replace the number with its percentage value
      String beforeNumber = _input.substring(0, i + 1);
      String afterNumber = _input.substring(_cursorPosition);

      _input = beforeNumber + percentage.toString() + afterNumber;
      _cursorPosition = (beforeNumber + percentage.toString()).length;
    } else {
      // If no number found, just add % at cursor
      _insertAtCursor('%');
    }
  }

  void _deleteAtCursor() {
    if (_cursorPosition > 0 && _input.isNotEmpty) {
      _input =
          _input.substring(0, _cursorPosition - 1) +
          _input.substring(_cursorPosition);
      _cursorPosition--;
    }
  }

  void _moveCursorLeft() {
    if (_cursorPosition > 0) {
      _cursorPosition--;
    }
  }

  void _moveCursorRight() {
    if (_cursorPosition < _input.length) {
      _cursorPosition++;
    }
  }

  void _calculateResult() {
    try {
      String expression = _input;
      expression = expression.replaceAll('×', '*');
      expression = expression.replaceAll('÷', '/');
      expression = expression.replaceAll('%', '/100');

      Parser p = Parser();
      Expression exp = p.parse(expression);
      ContextModel cm = ContextModel();
      double eval = exp.evaluate(EvaluationType.REAL, cm);

      setState(() {
        _result = _formatResult(eval);
        _history.add('$_input = $_result');
        if (_history.length > 10) _history.removeAt(0);
        _cursorPosition = _input.length;
      });

      // Auto scroll result to end
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_resultScrollController.hasClients) {
          _resultScrollController.animateTo(
            _resultScrollController.position.maxScrollExtent,
            duration: Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (e) {
      setState(() {
        _result = 'Error';
      });
    }
  }

  String _formatResult(double num) {
    if (num == double.infinity || num == double.negativeInfinity) {
      return 'Error';
    }

    if (num.truncateToDouble() == num) {
      return num.toInt().toString();
    } else {
      // Remove trailing zeros
      String result = num.toStringAsFixed(6);
      while (result.contains('.') &&
          (result.endsWith('0') || result.endsWith('.'))) {
        result = result.substring(0, result.length - 1);
      }
      return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF0F0F1E),
      appBar: AppBar(
        title: Text(
          'Premium Calculator',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF1A1A2E),
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Premium Display Area
          _buildPremiumDisplay(),

          // Cursor Control Buttons - Premium Design
          _buildPremiumCursorControls(),

          // History or Keypad
          Expanded(child: _showHistory ? _buildHistory() : _buildKeypad()),
        ],
      ),
    );
  }

  Widget _buildPremiumDisplay() {
    return Container(
      padding: EdgeInsets.all(25),
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.4),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Input Section with Cursor
          Container(
            height: 40,
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              controller: _inputScrollController,
              scrollDirection: Axis.horizontal,
              child: Row(children: _buildInputWithCursor()),
            ),
          ),

          SizedBox(height: 25),

          // Divider
          Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  Colors.deepPurple.withOpacity(0.5),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          SizedBox(height: 15),

          // Result Section
          Container(
            height: 50,
            alignment: Alignment.centerRight,
            child: SingleChildScrollView(
              controller: _resultScrollController,
              scrollDirection: Axis.horizontal,
              child: Text(
                _result,
                style: TextStyle(
                  fontSize: 35,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: 1.5,
                  shadows: [
                    Shadow(
                      color: Colors.deepPurple.withOpacity(0.5),
                      blurRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildInputWithCursor() {
    List<Widget> children = [];

    // Text before cursor
    if (_cursorPosition > 0) {
      children.add(
        Text(
          _input.substring(0, _cursorPosition),
          style: TextStyle(
            fontSize: 24,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    // Blinking cursor
    children.add(
      AnimatedContainer(
        duration: Duration(milliseconds: 500),
        width: 3,
        height: 30,
        color: _cursorVisible ? Colors.cyan : Colors.transparent,
        margin: EdgeInsets.symmetric(horizontal: 2),
      ),
    );

    // Text after cursor
    if (_cursorPosition < _input.length) {
      children.add(
        Text(
          _input.substring(_cursorPosition),
          style: TextStyle(
            fontSize: 24,
            color: Colors.white.withOpacity(0.9),
            fontWeight: FontWeight.w500,
          ),
        ),
      );
    }

    return children;
  }

  Widget _buildPremiumCursorControls() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E).withOpacity(0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildPremiumControlButton(
            '◀',
            'Left',
            Icons.arrow_back_ios_rounded,
            Colors.blueAccent,
          ),
          _buildPremiumControlButton(
            '▶',
            'Right',
            Icons.arrow_forward_ios_rounded,
            Colors.blueAccent,
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumControlButton(
    String text,
    String label,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.8), color],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.4),
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _onButtonPressed(text),
              child: Icon(icon, size: 22, color: Colors.white),
            ),
          ),
        ),
        SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.white.withOpacity(0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildHistory() {
    return Container(
      margin: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
        border: Border.all(color: Colors.deepPurple.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(Icons.history_rounded, color: Colors.cyan, size: 24),
                SizedBox(width: 12),
                Text(
                  'Calculation History',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: Colors.white54),
                  onPressed: () {
                    setState(() {
                      _showHistory = false;
                    });
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: _history.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.history_toggle_off_rounded,
                          size: 60,
                          color: Colors.white38,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No calculations yet',
                          style: TextStyle(fontSize: 16, color: Colors.white54),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _history.length,
                    itemBuilder: (context, index) {
                      return Container(
                        margin: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Color(0xFF16213E).withOpacity(0.5),
                              Color(0xFF1A1A2E).withOpacity(0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.deepPurple.withOpacity(0.2),
                            width: 1,
                          ),
                        ),
                        child: ListTile(
                          leading: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.cyan, Colors.blueAccent],
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                '${_history.length - index}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          title: Text(
                            _history.reversed.toList()[index],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                          trailing: IconButton(
                            icon: Icon(
                              Icons.delete_rounded,
                              color: Colors.redAccent,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _history.removeAt(_history.length - 1 - index);
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypad() {
    return Container(
      padding: EdgeInsets.all(20),
      child: Column(
        children: [
          // First row
          Expanded(
            child: Row(
              children: [
                _buildPremiumButton('📜', Colors.cyan),
                _buildPremiumButton('C', Colors.redAccent),
                _buildPremiumButton('⌫', Colors.redAccent),
                _buildPremiumButton('%', Colors.purpleAccent),
                _buildPremiumButton('÷', Colors.deepPurple),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Second row
          Expanded(
            child: Row(
              children: [
                _buildPremiumButton('7', Color(0xFF2D3748)),
                _buildPremiumButton('8', Color(0xFF2D3748)),
                _buildPremiumButton('9', Color(0xFF2D3748)),
                _buildPremiumButton('×', Colors.deepPurple),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Third row
          Expanded(
            child: Row(
              children: [
                _buildPremiumButton('4', Color(0xFF2D3748)),
                _buildPremiumButton('5', Color(0xFF2D3748)),
                _buildPremiumButton('6', Color(0xFF2D3748)),
                _buildPremiumButton('-', Colors.deepPurple),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Fourth row
          Expanded(
            child: Row(
              children: [
                _buildPremiumButton('1', Color(0xFF2D3748)),
                _buildPremiumButton('2', Color(0xFF2D3748)),
                _buildPremiumButton('3', Color(0xFF2D3748)),
                _buildPremiumButton('+', Colors.deepPurple),
              ],
            ),
          ),
          SizedBox(height: 12),
          // Fifth row
          Expanded(
            child: Row(
              children: [
                _buildPremiumButton('0', Color(0xFF2D3748), flex: 1),
                _buildPremiumButton('.', Color(0xFF2D3748)),
                _buildPremiumButton('=', Colors.orange, flex: 2),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumButton(String text, Color color, {int flex = 1}) {
    return Expanded(
      flex: flex,
      child: Container(
        margin: EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _onButtonPressed(text),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _getButtonGradient(text, color),
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Center(
                child: text == '📜'
                    ? Icon(Icons.history_rounded, size: 26, color: Colors.white)
                    : text == '⌫'
                    ? Icon(
                        Icons.backspace_rounded,
                        size: 26,
                        color: Colors.white,
                      )
                    : Text(
                        text,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: _getTextColor(text),
                          shadows: [
                            Shadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 2,
                              offset: Offset(1, 1),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Color> _getButtonGradient(String button, Color baseColor) {
    if (button == '=') return [Color(0xFFFF6B35), Color(0xFFF7931E)];
    if (button == 'C' || button == '⌫')
      return [Color(0xFFE53E3E), Color(0xFFC53030)];
    if (button == '%') return [Color(0xFF9F7AEA), Color(0xFF805AD5)];
    if (button == '÷' || button == '×' || button == '-' || button == '+')
      return [Color(0xFF805AD5), Color(0xFF6B46C1)];
    if (button == '📜') return [Color(0xFF00B5D8), Color(0xFF00A3C4)];
    return [baseColor.withOpacity(0.9), baseColor];
  }

  Color _getTextColor(String button) {
    return Colors.white;
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _inputScrollController.dispose();
    _resultScrollController.dispose();
    super.dispose();
  }
}
