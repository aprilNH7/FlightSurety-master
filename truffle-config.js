var HDWalletProvider = require("truffle-hdwallet-provider");
var mnemonic = "access jaguar undo clock type jaguar rookie exist device gospel client verb";

module.exports = {
  networks: {
    development: {
      provider: function() {
        return new HDWalletProvider(mnemonic, "http://127.0.0.1:9545/", 0, 50);
      },
      network_id: '*',
      gas: 4600000
    }
  },
  compilers: {
    solc: {
      version: "^0.5.16"
    }
  }
};
