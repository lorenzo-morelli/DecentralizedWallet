import 'package:decentralized_wallet/views/list_tile.dart';
import 'package:decentralized_wallet/views/shared/constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool loading = true;
  bool depositOnTapDown = false;
  bool withdrawOnTapDown = false;
  var balance;
  int selectedAmount = 0;
  List<dynamic> history = [];
  late Client httpClient;
  late Web3Client ethClient;

  @override
  void initState() {
    loading = true;
    httpClient = Client();
    ethClient = Web3Client("https://rinkeby.infura.io/v3/b87185b951054eafa98c372ea689e15e", httpClient);
    getBalance();
    getHistory();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[200],
      body: Stack(
        children: [
          Container(
            padding: EdgeInsets.all(30),
            width: double.infinity,
            height: 400,
            decoration: BoxDecoration(
              color: Color(0xff4b56c0),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Current balance:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w400)),
                !loading
                    ? Text('\$$balance', style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.w500))
                    : Padding(
                      padding: const EdgeInsets.all(10.0),
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    GestureDetector(
                      child: Transform.scale(
                        scale: !depositOnTapDown ? 1 : 0.9,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          decoration: BoxDecoration(
                            color: !depositOnTapDown ? Colors.white : Colors.grey[200],
                            borderRadius: BorderRadius.circular(2000),
                          ),
                          child: Text('Deposit', style: TextStyle(color: Constants.purple, fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      onTapDown: (val) => setState(() => depositOnTapDown = !depositOnTapDown),
                      onTapUp: (val) => setState(() => depositOnTapDown = !depositOnTapDown),
                      onTap: () async {
                        await transaction("depositBalance", selectedAmount);
                      },
                    ),
                    SizedBox(width: 20),
                    GestureDetector(
                      child: Transform.scale(
                        scale: !withdrawOnTapDown ? 1 : 0.9,
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                          decoration: BoxDecoration(
                            color: !withdrawOnTapDown ? Constants.purple : Color(0xff21275e),
                            borderRadius: BorderRadius.circular(2000),
                            border: Border.all(
                              width: 1,
                              color: !withdrawOnTapDown ? Colors.white70 : Color(0xff21275e),
                            ),
                          ),
                          child: Text('Withdraw', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w500)),
                        ),
                      ),
                      onTapDown: (val) => setState(() => withdrawOnTapDown = !withdrawOnTapDown),
                      onTapUp: (val) => setState(() => withdrawOnTapDown = !withdrawOnTapDown),
                      onTap: () async {
                        balance - selectedAmount >= 0
                            ? await transaction("withdrawBalance", selectedAmount)
                            : showSnackBar(label: 'Insufficient funds!', color: Colors.red);
                      },
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    SizedBox(
                      width: 40,
                      child: Text('\$${selectedAmount.toStringAsFixed(0)}', style: TextStyle(color: Colors.white, fontSize: 15)),
                    ),
                    Expanded(
                      child: Slider(
                        onChanged: (val) => setState(() => selectedAmount = val.round()),
                        value: selectedAmount + 0.0,
                        min: 0,
                        max: 100,
                        divisions: 100,
                        thumbColor: Colors.white,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Center(child: Text('See history:', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w500))),
                SizedBox(height: 5),
              ],
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 380),
            child: ListView.builder(
              reverse: true,
              itemCount: history.length,
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemBuilder: (context, index) {
                return ListItem(buy: history[index] >= 0 ? true : false, quantity: history[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Constants.purple,
        elevation: 10,
        onPressed: () => resetHistory(),
        tooltip: 'Reset History',
        icon: Icon(Icons.close),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(2000),
            topRight: Radius.circular(2000),
            bottomLeft: Radius.circular(2000),
            bottomRight: Radius.circular(2000),
          ),
        ),
        label: Text('Reset history', style: TextStyle(fontFamily: '')),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<DeployedContract> getContract() async {
    String abiFile = await rootBundle.loadString('assets/contracts/wallet.json');
    String contractAddress = "0x0e2F82CB8E10539d76568eDC738BDc7E5E8A62da";
    final contract = DeployedContract(ContractAbi.fromJson(abiFile, 'Wallet'), EthereumAddress.fromHex(contractAddress));
    return contract;
  }

  Future<List<dynamic>> callFunction(String name, List<dynamic> args) async {
    final contract = await getContract();
    final ethFunction = contract.function(name);
    final result = await ethClient.call(contract: contract, function: ethFunction, params: args);
    return result;
  }

  Future<void> getBalance() async {
    List<dynamic> result = await callFunction("getBalance", []);
    var resBalance = result[0].toInt();
    setState(() {
      balance = resBalance;
      loading = false;
    });
  }

  Future<void> getHistory() async {
    List<dynamic> result = await callFunction("getHistory", []);
    var hist = result[0].map((value) => value.toInt()).toList();
    setState(() => history = hist);
  }

  Future<void> resetHistory() async {
    await transaction("resetHistory", null);
  }

  Future<void> transaction(String name, int? amt) async {
    setState(() => loading = true);
    Credentials key = EthPrivateKey.fromHex('a722124a2f71caccdf6afb2fe4c93a08dada9a58172a262938250dc8618c621f');
    final contract = await getContract();
    final ethFunc = contract.function(name);
    showSnackBar(label: chooseLabel(name));
    await ethClient.sendTransaction(
        key, Transaction.callContract(contract: contract, function: ethFunc, parameters: amt != null ? [BigInt.from(amt)] : []),
        chainId: 4);
    await Future.delayed(Duration(seconds: 12));
    getBalance();
    getHistory();
  }

  void showSnackBar({required String label, Color? color}) {
    final snackBar = SnackBar(
      content: Text(label),
      backgroundColor: color ?? Constants.purple,
    );
    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }

  String chooseLabel(name) {
    if (name == 'depositBalance') {
      return 'Deposit requested, please wait';
    } else if (name == 'withdrawBalance') {
      return 'Withdrawal requested, please wait';
    } else {
      return 'History being reset, please wait';
    }
  }
}
