
var FlightSuretyApp = artifacts.require("FlightSuretyApp");
var FlightSuretyData = artifacts.require("FlightSuretyData");
var BigNumber = require('bignumber.js');

var Config = async function(accounts) {

    // These test addresses are useful when you need to add
    // multiple users in test scripts
    let testAddresses = [

        "0x5aF6B92FBB9d816D1fC218c7bfccc0cb144a9B16",
        "0x8C1318C6fcFAc058185BafE075D47C37DE00a605",
        "0x69a17Cd205eD3a5604620C3e6647c783103b9106",
        "0x022BF83216eDC2E1996eEbA57f309d929B7006E6",
        "0x94E9E1aadc10d14A069fC713794d6D9CaBD5d96D",
        "0xEB01404e8A943679cb1292Bd468f7D1bf3191D9B",
        "0x489C17c0125f39Ccb3a9907c0F61F21B350EA1A9",
        "0xFe0B1A6c5EDb970da819Ab59C169e65d2450317e",
        "0x2a1daE0Ad3211208157D5309697a9cF0A805D5b7",
        "0x375CcD943A84B9D275F3E9e1B72776439004884a",
    ];


    let owner = accounts[0];
    let firstAirline = accounts[1];
    let airline2 = accounts[2];
    let airline3 = accounts[3];

    let flightSuretyData = await FlightSuretyData.new(firstAirline);
    let flightSuretyApp = await FlightSuretyApp.new(flightSuretyData.address);


    return {
        owner: owner,
        firstAirline: firstAirline,
        weiMultiple: (new BigNumber(10)).pow(18),
        testAddresses: testAddresses,
        flightSuretyData: flightSuretyData,
        flightSuretyApp: flightSuretyApp
    }
}

module.exports = {
    Config: Config
};
